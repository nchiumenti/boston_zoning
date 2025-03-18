#!/usr/bin/env python
# coding: utf-8

# In[1]:


################################################################################
# File name:    "closest_boundary_no_roads.ipynb"
#
# Project title:    Boston Affordable Housing project (visting scholar porject)
#
# Description:    This program is similar to the original closest_boundary file
#                 except it matches based on admissable boundaries that do not
#                 overlap with minor roads. The original matching program had 
#                 already removed highways and major roads. This is primarily 
#                 as as robustness check. In order to properly assign properties 
#                 we need to re-run the matching alogrithm.
#
# Inputs:    ./warren_address_points_assigned.shp
#            ./adm3_no_roads_crs26986.shp
#            ./regulation_types_moreregs.dta
#
# Outputs:    ./closest_boundary_no_roads_<date>.csv
#             ./closest_boundary_no_roads_log.txt
#
# Created:    10/12/2022
# Updated:    10/17/2022
#
# Author:    Nicholas Chiumenti
################################################################################


# In[2]:


import os
import re
import shutil
import numpy as np
import pandas as pd
import geopandas as gpd
from datetime import datetime
from shapely.geometry import Point, LineString
from shapely.ops import nearest_points


# In[3]:


start_time = datetime.now()
print("Running closest_boundary_no_roads program...")


# # Set all data paths

# In[4]:


prop_path = "/home/a1nfc04/python_projects/closest_boundary_py/points_shapefiles/warren_address_points_assigned.shp"

boundary_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/shapefiles/zoning_boundaries/adm3_no_roads_crs26986/adm3_no_roads_crs26986.shp"

reg_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/regulation_data/regulation_types_moreregs.dta"


# # Import data sources

# In[5]:


# load in regulatory data
regs_df = pd.read_stata(reg_path)

# error check reg data
assert len(regs_df) == 7011, "incorrect number of observations for regulatory data"

print("Finished loading regulation file!")


# In[6]:


# load property shape file as geodataframe
prop_gdf = gpd.read_file(prop_path)

# convert crs to epsg=26986
prop_gdf.to_crs("EPSG:26986", inplace=True)

# error checks
assert len(prop_gdf) == 632286, "incorrect observation count for prop_gdf"
assert prop_gdf.crs == 26986, "incorrect crs for prop_gdf"

print("Finished loading property file!")


# In[7]:


# load no minor roads boundary shape file as geodataframe
boundary_gdf = gpd.read_file(boundary_path)

boundary_gdf

# clean up town names
boundary_gdf['municipal'] = boundary_gdf['municipal'].str.upper()    
boundary_gdf['municipal'].replace({'MARLBOROUGH':'MARLBORO'}, inplace=True)
boundary_gdf['municipal'].replace({'FOXBOROUGH':'FOXBORO'}, inplace=True)
boundary_gdf['municipal'].replace({'SOUTHBOROUGH':'SOUTHBORO'}, inplace=True)
boundary_gdf['municipal'].replace({'BOXBOROUGH':'BOXBORO'}, inplace=True)

# ensure open enrollment municipalities points match regardless of school attendance zone 
boundary_gdf.loc[(boundary_gdf.municipal == 'ACTON'),'ncessch']='ACTON'
boundary_gdf.loc[(boundary_gdf.municipal == 'BOLTON'),'ncessch']='BOLTON'
boundary_gdf.loc[(boundary_gdf.municipal == 'BOSTON'),'ncessch']='BOSTON'
boundary_gdf.loc[(boundary_gdf.municipal == 'BOXBORO'),'ncessch']='BOXBORO'
boundary_gdf.loc[(boundary_gdf.municipal == 'ESSEX'),'ncessch']='ESSEX'
boundary_gdf.loc[(boundary_gdf.municipal == 'MANCHESTER'),'ncessch']='MANCHESTER'
boundary_gdf.loc[(boundary_gdf.municipal == 'SAUGUS'),'ncessch']='SAUGUS'
boundary_gdf.loc[(boundary_gdf.municipal == 'STOW'),'ncessch']='STOW'

# rename original boundary id name
boundary_gdf.rename(columns={"UNIQUE_ID":"boundary_id_orig"}, inplace=True)

# create a static unique id
boundary_gdf["unique_id"] = boundary_gdf.index

# trim fields from boundary dataframe to make it easier to handle
boundary_gdf = boundary_gdf[["unique_id", "boundary_id_orig",
                             "municipal", "ncessch", "zo_usety",
                             "LEFT_FID", "RIGHT_FID", "geometry"]]

# error checks
assert len(boundary_gdf) == 32606, "incorrect observation count for boundary_gdf"
assert boundary_gdf.crs == 26986, "incorrect crs for boundary_gdf"

print("Finished loading boundary file!")


# In[8]:


# check municipalities in points that are not in lines
muni_points = prop_gdf['W_CITY'].unique()

muni_lines = boundary_gdf['municipal'].unique()

missing_munis = list(set(muni_points) - set(muni_lines))

assert all(elem in ["SAUGUS", "STOW"]  for elem in missing_munis), "missing munis is not correct"

# confirm the CRSs are the same
assert prop_gdf.crs == boundary_gdf.crs, "crs between points and boundaries do not match"

print("Finished checking town coverage for errors!")


# # Match properties to closest boundaries left/right side, keep closest 5

# In[10]:


# match properties to all possible left side boundaries
left_side_matches = prop_gdf.merge(boundary_gdf, 
                               how="inner",
                               left_on=["W_CITY", "ncessch", "zo_usety", "l_r_fid"],
                               right_on=["municipal", "ncessch", "zo_usety", "LEFT_FID"],
                               suffixes=("_x", "_fid")
                              )

# tag as a left side match
left_side_matches.loc[:, "boundary_side"] = "LEFT"

# match properties to all possible right side boundaries
right_side_matches = prop_gdf.merge(boundary_gdf, 
                               how="inner",
                               left_on=["W_CITY", "ncessch", "zo_usety", "l_r_fid"],
                               right_on=["municipal", "ncessch", "zo_usety", "RIGHT_FID"],
                               suffixes=("_x", "_fid")
                              )

# tag as a right side match
right_side_matches.loc[:, "boundary_side"] = "RIGHT"

# append the two matched dfs together into one
matches_df = pd.concat([left_side_matches, right_side_matches], ignore_index=True)

# calculate the distance from point to matching boundary
# note this distance is meaningless b/c we are using lat/lon coords
matches_df.loc[:,"dist_m"] = gpd.GeoSeries(matches_df["geometry_x"]).distance(gpd.GeoSeries(matches_df["geometry_fid"]))

# sort by prop_id and distance 
matches_df.sort_values(by=["PROP_ID", "dist_m"], ascending=True, inplace=True)

# keep the 5 closest matches
matches_df = matches_df.groupby("PROP_ID").head(5).reset_index(drop=True)

matches_df.loc[:, "match_num"] = matches_df.groupby("PROP_ID")["dist_m"].rank(method="first", ascending=True)

# error checks
assert len(matches_df) == 2429563, "incorrect observation count for matches_df"

side_counts = dict(matches_df["boundary_side"].value_counts())
assert side_counts["LEFT"] == 1230910, "incorrect count of left side matches"
assert side_counts["RIGHT"] == 1198653, "incorrect count of right side matches"

print("Finished matching properties to left/right side boundaries!")


# # Add on the regulatory data and create <home_> and <nn_> variables

# In[11]:


# define list of reg_df variables and reglation variables
reg_cols = ["zo_usety_y", "mxht_eff", "dupac_eff", "mulfam", "reg_type_y", "LRID", "minlotsize", "maxdu"]
reg_list = ["mxht_eff", "dupac_eff", "mulfam", "minlotsize", "maxdu"]

# merge regulation data using left side fid
matches_df = matches_df.merge(regs_df, how="left", left_on="LEFT_FID", right_on="LRID", suffixes=("", "_y"))

# assign left side regulations to home_, right side to nn_
for reg in reg_list:
    matches_df.loc[matches_df["boundary_side"]=="LEFT", f"home_{reg}"] = matches_df[f"{reg}"]
    matches_df.loc[matches_df["boundary_side"]=="RIGHT", f"nn_{reg}"] = matches_df[f"{reg}"]

# drop merged reg_df variables
matches_df.drop(columns=reg_cols, inplace=True)

# emrge regulation data using right side fid
matches_df = matches_df.merge(regs_df, how="left", left_on="RIGHT_FID", right_on="LRID", suffixes=("", "_y"))

# assign right side regulatiosn to home_, left side to nn_
for reg in reg_list:
    matches_df.loc[matches_df["boundary_side"]=="RIGHT", f"home_{reg}"] = matches_df[f"{reg}"]
    matches_df.loc[matches_df["boundary_side"]=="LEFT", f"nn_{reg}"] = matches_df[f"{reg}"]

# drop merged reg_df variables
matches_df.drop(columns=reg_cols, inplace=True)

print("Finished adding regulation variables!")


# # Drop matches with missing (NaN) regulation data

# In[12]:


# check count of nan values by match number for errors
nan_counts = matches_df[matches_df["home_dupac_eff"].isna() 
                        | matches_df["home_mxht_eff"].isna()
                        | matches_df["home_mulfam"].isna()
                        | matches_df["nn_dupac_eff"].isna()
                        | matches_df["nn_mxht_eff"].isna()
                        | matches_df["nn_mulfam"].isna()
                       ]["match_num"].value_counts()

assert dict(nan_counts) == {1.0: 33320, 2.0: 28963, 3.0: 27002, 4.0: 23360, 5.0: 22872}

# create dataframe without nan values
matches_df2 = matches_df[matches_df["home_dupac_eff"].notna() 
                         & matches_df["home_mxht_eff"].notna()
                         & matches_df["home_mulfam"].notna()
                         & matches_df["nn_dupac_eff"].notna()
                         & matches_df["nn_mxht_eff"].notna()
                         & matches_df["nn_mulfam"].notna()
                       ].copy()

# error check
assert len(matches_df2) == 2294046, "incorrect observation count for matches_df2"


# # Keep the closest match (lowest match_num)

# In[13]:


# keep the closest match (lowest match number)
# sort by prop_id and distance 
matches_df2.sort_values(by=["PROP_ID", "match_num"], ascending=True, inplace=True)

# keep the first item
matches_df2 = matches_df2.groupby("PROP_ID").head(1).reset_index(drop=True)

match_num_count = dict(matches_df2["match_num"].value_counts())
assert match_num_count == {1.0: 556233, 2.0: 15068, 3.0: 6973, 4.0: 4333, 5.0: 1798}, "incorrect match_num count for matches_df2"


# # Identify straight line boundary matches

# In[14]:


ORTH_LEN_M = 100 # set meter length for the orthogonal line
n = 0

for i, row in matches_df2.iterrows():

    n+=1
    
    # get the address and boundary geographies
    address_point = row["geometry_x"] # the address, point object
    boundary_line = row["geometry_fid"] # the boundary, line onject

    # return a line from address to the nearest point on boundary
    nearest_x, nearest_y = nearest_points(address_point, boundary_line)
    nearest_line = LineString([nearest_x, nearest_y])

    # print("the nearest line:", nearest_line)

    # get left/right parallel line half the distance of cd_length
    left = nearest_line.parallel_offset(ORTH_LEN_M / 2, "left")
    right = nearest_line.parallel_offset(ORTH_LEN_M / 2, "right")

    # store the left/right end points that are on/closest the boundary line
    left_point = left.boundary[1]
    right_point = right.boundary[0]

#     # set epsg of the left/right points
#     left_point = gpd.GeoSeries(left_point, crs = "EPSG:26986")
#     right_point = gpd.GeoSeries(right_point, crs = "EPSG:26986")

#     # set epsg for address point and boundary line
#     address_point = gpd.GeoSeries(address_point, crs="EPSG:26986")
#     boundary_line = gpd.GeoSeries(boundary_line, crs="EPSG:26986")

    # calculate nearest distance from left/right orthogonal point to boundary line
    left_dist_m = left_point.distance(boundary_line)
    right_dist_m = right_point.distance(boundary_line)

    matches_df2.loc[i, "left_dist_m"] = float(left_dist_m)
    matches_df2.loc[i, "right_dist_m"] = float(right_dist_m)
    matches_df2.loc[i, "nearest_point"] = str(nearest_y)
    
    print(f"{n:,} of {len(matches_df2):,} orthogonals calculated", end="\r")
    
matches_df2["straight_line"] = 0

matches_df2.loc[(matches_df2["left_dist_m"]<=15) 
            & (matches_df2["right_dist_m"]<=15),
            "straight_line"] = 1

final_df = matches_df2.copy()

print("Finished calculating straight line boundaries!")


# # Error checks of final dataset before export

# In[15]:


# define list of columns to check for errors
column_lst = ["unique_id",
              "zo_usety",
              "reg_type",
              "dist_m",
              "match_num",
              "home_mxht_eff",
              "home_dupac_eff",
              "home_mulfam",
              "nn_mxht_eff",
              "nn_dupac_eff",
              "nn_mulfam",
              "straight_line"]

# define error check values dictionary for output comparison
error_check_dct = {'unique_id': 
                       {'count': 584405.0, 
                        'mean': 11821.47798, 
                        'std': 9412.81908, 
                        'min': 4.0, 
                        '25%': 3195.0, 
                        '50%': 8558.0, 
                        '75%': 22039.0, 
                        'max': 30070.0}, 
                   'zo_usety': 
                       {'count': 584405.0, 
                        'mean': 1.18516, 
                        'std': 0.57957, 
                        'min': 0.0, 
                        '25%': 1.0, 
                        '50%': 1.0, 
                        '75%': 1.0, 
                        'max': 4.0}, 
                   'reg_type': 
                       {'count': 584405.0, 
                        'mean': 164.53933, 
                        'std': 117.99648, 
                        'min': 1.0, 
                        '25%': 45.0, 
                        '50%': 191.0, 
                        '75%': 245.0, 
                        'max': 542.0}, 
                   'dist_m': 
                       {'count': 584405.0, 
                        'mean': 390.94435, 
                        'std': 578.23431, 
                        'min': 0.00161,
                        '25%': 91.54269, 
                        '50%': 205.71943, 
                        '75%': 438.08227, 
                        'max': 7394.96124}, 
                   'match_num': 
                       {'count': 584405.0, 
                        'mean': 1.0842,
                        'std': 0.42706, 
                        'min': 1.0, 
                        '25%': 1.0, 
                        '50%': 1.0, 
                        '75%': 1.0, 
                        'max': 5.0},
                   'home_mxht_eff': 
                       {'count': 584405.0, 
                        'mean': 34.82389, 
                        'std': 10.33554, 
                        'min': 0.0, 
                        '25%': 35.0, 
                        '50%': 35.0, 
                        '75%': 35.0, 
                        'max': 356.0}, 
                   'home_dupac_eff': 
                       {'count': 584405.0, 
                        'mean': 13.05331, 
                        'std': 22.31415, 
                        'min': 0.0, 
                        '25%': 2.0, 
                        '50%': 5.0,
                        '75%': 14.0, 
                        'max': 349.0}, 
                   'home_mulfam': 
                       {'count': 584405.0, 
                        'mean': 0.55077, 
                        'std': 0.49817, 
                        'min': 0.0, 
                        '25%': 0.0, 
                        '50%': 1.0, 
                        '75%': 1.0, 
                        'max': 1.0}, 
                   'nn_mxht_eff': 
                       {'count': 584405.0, 
                        'mean': 35.05074,
                        'std': 15.78515, 
                        'min': 0.0, 
                        '25%': 35.0, 
                        '50%': 35.0, 
                        '75%': 38.0,
                        'max': 400.0}, 
                   'nn_dupac_eff': 
                       {'count': 584405.0, 
                        'mean': 13.23601, 
                        'std': 24.24564, 
                        'min': 0.0, 
                        '25%': 1.0, 
                        '50%': 3.0, 
                        '75%': 14.0, 
                        'max': 349.0}, 
                   'nn_mulfam': 
                       {'count': 584405.0, 
                        'mean': 0.54173, 
                        'std': 0.49896, 
                        'min': 0.0, 
                        '25%': 0.0, 
                        '50%': 1.0, 
                        '75%': 1.0,
                        'max': 1.0}, 
                   'straight_line': 
                       {'count': 584405.0, 
                        'mean': 0.14737, 
                        'std': 0.35447, 
                        'min': 0.0,
                        '25%': 0.0, 
                        '50%': 0.0, 
                        '75%': 0.0, 
                        'max': 1.0}
                  }

# store output values for error check
sum_stats_dct = {col: dict(round(final_df[col].describe(), 5)) 
                 for col in column_lst}

# check observation count for errors
assert len(final_df) == 584405, "incorrect number of observations for final_gdf"

# check boundary side matches for error
side_counts = dict(final_df["boundary_side"].value_counts())
assert side_counts["LEFT"] == 292934, "incorrect count of left side matches"
assert side_counts["RIGHT"] == 291471, "incorrect count of right side matches"

# check remaining variables for error
for x in error_check_dct:
    assert sum_stats_dct[x] == error_check_dct[x], f"summary stats for {x} do not match stored values"

print("Finished checking for errors in final data, none found!")


# # Export data and save log

# In[17]:


# set save and log paths
log_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/closest_boundary_matches/closest_boundary_matches_noroads_log.txt"

# save data paths
save_file = "closest_boundary_matches_noroads.csv"
save_folder = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/closest_boundary_matches"
save_path = os.path.join(save_folder, save_file)

# subdir for old exports
old_saves_folder = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/closest_boundary_matches/old_export_versions"

# check if current save version exists, if so then move it to the old versions folder
contents = [item for item in os.listdir(save_folder)]
if save_file in contents:

    # create previous saves folder is doesn't exist
    if os.path.isdir(old_saves_folder) == False:
        os.makedirs(old_saves_folder)
    
    # move file to sub-directory
    old_file_path = os.path.join(old_saves_folder, save_file)
    shutil.move(save_path, old_file_path)
    
    # rename the old file with creation date
    create_date = datetime.fromtimestamp(os.path.getmtime(old_file_path)).strftime("_%Y-%m-%d")
    new_file_name = os.path.splitext(old_file_path)[0] + create_date + ".csv"   
    os.rename(old_file_path, new_file_name)
    
# create log and save date stamps
end_time = datetime.now()

duration = end_time - start_time

duration_in_s = (duration.days * 24 * 60 * 60) + duration.seconds
mins, secs = divmod(duration_in_s, 60)
hours, mins = divmod(mins, 60)
days, hours  = divmod(hours, 24)

# save dataset as .csv
final_df.to_csv(save_path, index = False)

# write to log
with open(log_path,'a') as file:
    file.write(f"Last run on {datetime.now().strftime('%D at %I:%M:%S %p')}\n")
    file.write(f"{len(final_df):,} observations written to {save_path} \n")
    file.write(f"Total run time: {days} days, {hours:02} hours, {mins:02} minutes, {secs:02} seconds \n\n")

# Done!
print(f"Done, {len(final_df):,} observations written!")


# In[ ]:




