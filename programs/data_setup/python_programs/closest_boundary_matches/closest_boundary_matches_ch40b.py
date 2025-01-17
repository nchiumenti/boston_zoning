#!/usr/bin/env python
# coding: utf-8

# In[1]:


################################################################################
# File name:    "closest_boundary_matches_ch40b.ipynb"
#
# Project title:    Boston Affordable Housing project (visting scholar porject)
#
# Description:    This is a version of the original boundary matching file used
#                 to match CH40B address points to zoning boundaries. It runs 
#                 much faster than the original version of this file but does 
#                 not export a final matches dataset because of inconsistencies 
#                 between this and the old version. The output of this program
#                 is used as input for ./61_ch40b_boundary_matches.do.
#
# Inputs:    ./zone_assignments_ch40b_export.csv
#            ./adm3_crs4269.shp
#            ./regulation_types.dta
#
# Outputs:    ./closest_boundary_matches_ch40b.csv
#             ./closest_boundary_matches_ch40b_log.txt
#
# Created:    11/16/2022
# Updated:    11/16/2022
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
print("Running closest_boundary_matches program...")


# # Set all data paths

# In[4]:


data_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/zone_assignments/zone_assignments_ch40b_export.csv"

boundary_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/shapefiles/zoning_boundaries/adm3_crs4269/adm3_crs4269.shp"

reg_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/regulation_data/regulation_types.dta"


# # Import data sources

# In[5]:


# load in regulatory data
regs_df = pd.read_stata(reg_path)

regs_df["LRID"] = regs_df["LRID"].astype(int)
regs_df["LRID"] = regs_df["LRID"].astype(str)

# error check reg data
assert len(regs_df) == 7011, "incorrect number of observations for regulatory data"

print("Finished loading regulation file!")


# In[6]:


# import zone assignments w/ all columns as string
data_df = pd.read_csv(data_path, dtype=str)

# trim variables
data_df = data_df[["unique_id",
                   "ch40b_id", 
                   "cousub_name", 
                   "ch40b_lat", 
                   "ch40b_lon", 
                   "ncessch", 
                   "reg_type", 
                   "zo_usety", 
                   "l_r_fid"]]

# convert dataframe to geodataframe
data_gdf = gpd.GeoDataFrame(data_df, 
                            geometry = gpd.points_from_xy(data_df["ch40b_lon"], data_df["ch40b_lat"]),
                            crs = "EPSG:4269")

mask = (data_gdf["ncessch"].notna()
        & data_gdf["zo_usety"].notna() 
        & data_gdf["l_r_fid"].notna()
        & data_gdf["reg_type"].notna())

data_gdf = data_gdf[mask]

# error checks
assert len(data_gdf) == 1238, "incorrect number of observations in prop_gdf after missings dropped"
assert data_gdf.crs == 4269, "incorrect crs for prop_gdf"

print("Finished loading property file!")


# In[7]:


# import zoning boundary shape file as geodataframe
boundary_gdf = gpd.read_file(boundary_path)

# clean up town names
boundary_gdf['municipal'] = boundary_gdf['municipal'].str.upper()    
boundary_gdf['municipal'].replace({'MARLBOROUGH':'MARLBORO'}, inplace=True)
boundary_gdf['municipal'].replace({'FOXBOROUGH':'FOXBORO'}, inplace=True)
boundary_gdf['municipal'].replace({'SOUTHBOROUGH':'SOUTHBORO'}, inplace=True)
boundary_gdf['municipal'].replace({'BOXBOROUGH':'BOXBORO'}, inplace=True)

# create a static unique id
boundary_gdf["unique_id"] = boundary_gdf.index

# trim variable list
boundary_gdf = boundary_gdf[["unique_id",
                             "muni_id",
                             "municipal",
                             "ncessch",
                             "zo_usety",
                             "LEFT_FID",
                             "RIGHT_FID",
                             "geometry"]]

# set ncessch as town name for open enrollment municipalities
open_list = ["ACTON",
             "BOLTON",
             "BOSTON",
             "BOXBORO",
             "ESSEX",
             "MANCHESTER",
             "SAUGUS",
             "STOW"]

for x in open_list:
    boundary_gdf.loc[(boundary_gdf["municipal"] == x), "ncessch"] = x

# convert matching variables to string
boundary_gdf["ncessch"] = boundary_gdf["ncessch"].astype(str)
boundary_gdf["zo_usety"] = boundary_gdf["zo_usety"].astype(str)
boundary_gdf["LEFT_FID"] = boundary_gdf["LEFT_FID"].astype(str)
boundary_gdf["RIGHT_FID"] = boundary_gdf["RIGHT_FID"].astype(str)

# error checks
assert len(boundary_gdf) == 36151, "incorrect observation count for boundary_gdf"
assert boundary_gdf.crs == 4269, "incorrect crs for boundary_gdf"
assert all(boundary_gdf["ncessch"].apply(type) == str), "ncessch not all string values"
assert all(boundary_gdf["zo_usety"].apply(type) == str), "zo_usety not all string values"
assert all(boundary_gdf["LEFT_FID"].apply(type) == str), "LEFT_FID not all string values"
assert all(boundary_gdf["RIGHT_FID"].apply(type) == str), "RIGHT_FID not all string values"

print("Finished loading boundary file!")


# # Match properties to closest boundaries left/right side or both l/r

# In[8]:


# confirm the CRSs are the same
assert data_gdf.crs == boundary_gdf.crs, "crs between data_gdf and boundary_gdf do not match"

# match properties to all possible left side boundaries
left_side_matches = data_gdf.merge(boundary_gdf, 
                                   how="inner",
                                   left_on=["cousub_name", "ncessch", "zo_usety", "l_r_fid"],
                                   right_on=["municipal", "ncessch", "zo_usety", "LEFT_FID"],
                                   indicator=True,
                                   suffixes=("_x", "_fid")
                                  )

left_side_matches.rename(columns={"_merge" : "lside_merge"}, inplace=True)

# tag as a left side match
left_side_matches.loc[:, "boundary_side"] = "LEFT"

# match properties to all possible right side boundaries
right_side_matches = data_gdf.merge(boundary_gdf, 
                                   how="inner",
                                   left_on=["cousub_name", "ncessch", "zo_usety", "l_r_fid"],
                                   right_on=["municipal", "ncessch", "zo_usety", "RIGHT_FID"],
                                   indicator=True,
                                   suffixes=("_x", "_fid")
                                  )

right_side_matches.rename(columns={"_merge" : "rside_merge"}, inplace=True)

# tag as a right side match
right_side_matches.loc[:, "boundary_side"] = "RIGHT"

# append the two matched dfs together into one
matches_df = pd.concat([left_side_matches, right_side_matches], ignore_index=True)

matches_df.loc[matches_df["LEFT_FID"]==matches_df["RIGHT_FID"], "boundary_side"] = "BOTH L&R"

# error checks
assert len(matches_df) == 13392, "incorrect number of observations after left/right match"
assert dict(matches_df["boundary_side"].value_counts()) == {'RIGHT': 7417, 'LEFT': 5875, 'BOTH L&R': 100}, "incorrect number of left/right/both matches"

print("Finished left/right boundary matching!")


# # Calculate distance to nearest boundary and store nearest point

# In[9]:


n=0
for i, row in matches_df.iterrows():
    
    n+=1
    
    # get the address and boundary geographies
    address_point = row["geometry_x"] # the address, point object
    boundary_line = row["geometry_fid"] # the boundary, line onject

    # return a line from address to the nearest point on boundary
    nearest_x, nearest_y = nearest_points(address_point, boundary_line)

    matches_df.loc[i, "nearest_point_dist"] = nearest_x.distance(nearest_y)    # distance to nearest point on boundary_line
    matches_df.loc[i, "nearest_point_lat"] = nearest_y.y                     # latitude coordinate of nearest point
    matches_df.loc[i, "nearest_point_lon"] = nearest_y.x                     # longitude coordinate of nearest point
    
    print(f"{n:,} of {len(matches_df):,} distances calculated", end="\r")


# In[10]:


# save_point = matches_df.copy()
# matches_df = save_point.copy()


# # Keep the closest 5 matches

# In[12]:


# sort by prop_id and distance and unique boundary_id if there is a tie
matches_df.sort_values(by=["unique_id_x", "nearest_point_dist", "unique_id_fid"], ascending=True, inplace=True)

# keep the 5 closest matches
matches_df = matches_df.groupby("unique_id_x").head(5)

# number the matches in order of distance
matches_df.loc[:, "match_num"] = matches_df.groupby("unique_id_x")["nearest_point_dist"].rank(method="first", ascending=True)

# trim to final dataset
final_df = matches_df[["unique_id_x",
                       "ch40b_id",
                       "cousub_name",
                       "ch40b_lat",
                       "ch40b_lon",
                       "reg_type",
                       "zo_usety",
                       "l_r_fid",
                       "unique_id_fid",
                       "LEFT_FID",
                       "RIGHT_FID",
                       "boundary_side",
                       "nearest_point_dist",
                       "nearest_point_lat",
                       "nearest_point_lon",
                       "match_num",
                       "lside_merge",
                       "rside_merge"]].copy()

final_df.sort_index(inplace=True)

final_df.rename(columns={"unique_id_x": "unique_id"}, inplace = True)

# error checks
assert len(final_df) == 4298
assert dict(final_df["match_num"].value_counts()) == {1.0: 1133, 2.0: 987, 3.0: 830, 4.0: 727, 5.0: 621}
assert dict(final_df["boundary_side"].value_counts()) == {'LEFT': 2342, 'RIGHT': 1944, 'BOTH L&R': 12}

print("Finished matching properties to left/right side boundaries!")


# # Export data and save log

# In[13]:


# set save and log paths
log_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/closest_boundary_matches/closest_boundary_matches_ch40b_log.txt"

# save data paths
save_file = "closest_boundary_matches_ch40b.csv"
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

