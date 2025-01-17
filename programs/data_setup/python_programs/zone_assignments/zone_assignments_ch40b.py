#!/usr/bin/env python
# coding: utf-8

# In[1]:


################################################################################
# File name:    "zone_assignment_ch40b.ipynb"
#
# Project title:    Boston Affordable Housing project (visting scholar porject)
#
# Description:    This program takes the unique set of CH40B property data
#                 in the MAPC region and assigns them to (1) a
#                 schools attendance area <ncessch>, (2) a zone use type area
#                 <zo_usety>, and (3) a left/right boundary id and regulation 
#                 type area <l_r_fid> and <reg_type>. The exported .csv file
#                 is used in the closest_boundary_matches_ch40b.py program.
#
# Inputs:    ./ch40b_mapc.dta
#            ./sabs_unique_latlong.shp
#            ./roads_mapc_union_sd_dissolved.shp
#            ./zoning_atlas_latlong.shp 
#
# Outputs:    ./zone_assignments_ch40b_export.csv
#             ./zone_assignments_ch40b_log.txt
#
# Created:    11/18/2022
# Updated:    11/18/2022
#
# Author:    Nicholas Chiumenti
################################################################################


# In[2]:


import os
import shutil
import numpy as np
import pandas as pd
import geopandas as gpd
from datetime import datetime


# In[3]:


start_time = datetime.now()
print("Running zone_assignments program...")


# # Set paths

# In[4]:


# full path to warren group property data
data_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/chapter40B/chapter40b_mapc.dta"

# full path to school attendance area data
schools_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/shapefiles/standardized/sabs_unique_latlong.shp"

# full path to zone area data
zones_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/shapefiles/originals/roads_mapc_union_sd_dissolved.shp"

# full path to zone use type data
zuse_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/shapefiles/standardized/zoning_atlas_latlong.shp"


# # Load in initial datasets

# In[5]:


# import warren group property data
data_df = pd.read_stata(data_path)

# import school attendance areas
schools_gdf = gpd.read_file(schools_path) 

# import zone areas
zones_gdf = gpd.read_file(zones_path) # <-- this is the only one we use the original version for 

# import zone use type areas
zuse_gdf = gpd.read_file(zuse_path)

# convert property dataframe to geo-dataframe
data_df["cousub_name"] = data_df["ch40b_city"]
data_df = data_df[["unique_id", "ch40b_id", "cousub_name", "ch40b_city", "ch40b_lat", "ch40b_lon"]]

data_gdf = gpd.GeoDataFrame(data_df, geometry = gpd.points_from_xy(data_df["ch40b_lon"], data_df["ch40b_lat"]),
                            crs = "EPSG:4269")

# convert zone gdf to crs 4269
zones_gdf.to_crs("EPSG:4269", inplace = True)

# error checks
assert len(data_gdf) == 1932, "incorrect observation count for data_gdf"
assert len(schools_gdf) == 231, "incorrect observation count for schools_gdf"
assert len(zones_gdf) == 8719, "incorrect observation count for zones_gdf"
assert len(zuse_gdf) == 1775, "incorrect observation count for zuse_gdf"

assert data_gdf.crs == schools_gdf.crs, "data_gdf crs does not match with schools_gdf"
assert data_gdf.crs == zones_gdf.crs, "data_gdf crs does not match with zones_gdf"
assert data_gdf.crs == zuse_gdf.crs,"data_gdf crs does not match with zuse_gdf"

print("Done loading input datasets!")


# # Assign school attendance areas

# In[6]:


# spatially merge properties to school attendance areas
merge_gdf1 = gpd.sjoin(data_gdf, schools_gdf, how="left", op="within")

# drop all observations that match to >1 school attendance area
merge_gdf1.drop_duplicates(subset="unique_id", keep=False, inplace=True)
# assert len(merge_gdf1) == 811642, "incorrect number of observatins in merge1_gdf, post dup drop"

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
    merge_gdf1.loc[(merge_gdf1["cousub_name"] == x), "ncessch"] = x
    
# set ncessch as NaN for out-of-scope cities and towns
nan_list = ['BELLINGHAM',
            'BRAINTREE',
            'BURLINGTON',
            'CHELSEA',
            'CONCORD',
            'DANVERS',
            'HAMILTON',
            'HINGHAM',
            'IPSWICH',
            'LYNNFIELD',
            'MEDFORD',
            'MELROSE',
            'NATICK',
            'NORWOOD',
            'PEABODY',
            'QUINCY',
            'READING',
            'WATERTOWN',
            'WENHAM',
            'WILMINGTON',
            'WINCHESTER',
            'WOBURN']

for x in nan_list:
    merge_gdf1.loc[(merge_gdf1["cousub_name"] == x), "ncessch"] = np.nan

assert len(merge_gdf1[merge_gdf1["ncessch"].isna()]) == 626, "incorrect number of missing ncessch observations"

# drop missing <ncessch> observations
merge_gdf1 = merge_gdf1[merge_gdf1['ncessch'].notna()]

# convert <ncessch> to string
merge_gdf1["ncessch"] = merge_gdf1["ncessch"].astype(str)

# trim dataset variables, save as school_matches_df
school_matches_df = merge_gdf1[["unique_id", "cousub_name", "ncessch"]].copy()

# final error checks
assert len(school_matches_df) == 1261, "incorrect number of observations in school_matches_df"
assert school_matches_df["unique_id"].nunique() == 1261, "incorrect number of unique prop_ids"
assert school_matches_df["unique_id"].nunique() == len(school_matches_df), "number of observations in merge_gdf1 does not equal number of unique prop_ds"
assert school_matches_df["ncessch"].nunique() == 185, "incorrect number of unique ncessch ids"
assert all(school_matches_df["ncessch"].apply(type) == str), "not all values of ncessch are strings"

print("Done matching school attendance areas!")


# # Assign zone use types

# In[7]:


# standardize city and town names
zuse_gdf['muni'] = zuse_gdf['muni'].str.upper()
zuse_gdf['muni'].replace({'MARLBOROUGH':'MARLBORO'}, inplace = True)
zuse_gdf['muni'].replace({'FOXBOROUGH':'FOXBORO'}, inplace = True)
zuse_gdf['muni'].replace({'SOUTHBOROUGH':'SOUTHBORO'}, inplace = True)
zuse_gdf['muni'].replace({'BOXBOROUGH':'BOXBORO'}, inplace = True)

# check that all towns in data_gdf are in zuse_gdf
assert all([m2 in [m1 for m1 in zuse_gdf["muni"].unique()] 
                  for m2 in data_gdf["cousub_name"].unique()]
          ), "cities/towns are in data_df that are not in zuse_gdf"

assert all([m2 for m2 in zuse_gdf["muni"].unique() 
            if m2 not in [m1 for m1 in data_gdf["cousub_name"].unique()]]
          ), "cities/towns are in zuse_df that are not in data_gdf"

# assign zone use type areas
merge_gdf2 = gpd.sjoin(data_gdf, zuse_gdf, how = "left", op = "within")

# drop all observations that match to >1 zuse area
merge_gdf2.drop_duplicates(subset = "unique_id", keep = False, inplace = True)
assert len(merge_gdf2) == 1931, "incorrect nubmer of observations in merge_gdf2 after duplicates drop"

# check the number of observations with missing zone use types
missing_no = merge_gdf2['zo_usety'].isna().sum()
assert missing_no == 561, "incorrect number of observations with missing zone use types"

## fill in missing zone use types based on closest zone use area
# create dataframe of obs with missing zone use types
missing_zuse = merge_gdf2.loc[merge_gdf2['zo_usety'].isna()]

# merge missings dataframe with zuse_gdf based on city/town name
missing_zuse = missing_zuse[["unique_id", "cousub_name", "ch40b_lat", "ch40b_lon", "geometry"]]

closest_zuse = missing_zuse.merge(zuse_gdf, 
                               how = "left",
                               left_on = "cousub_name",
                               right_on = "muni",
                               suffixes = ("_left", "_zuse"))

# calculate the dist between point (property) and polygon (zuse type area)
closest_zuse.loc[:,"dist"] = gpd.GeoSeries(closest_zuse["geometry_left"], crs = "EPSG:4269").distance(gpd.GeoSeries(closest_zuse["geometry_zuse"], crs = "EPSG:4269"))

# sort by prop_id and distance, keep 1st closest match
closest_zuse.sort_values(by = ["unique_id", "dist"], ascending = True, inplace = True)
closest_zuse = closest_zuse.groupby("unique_id").head(1).reset_index(drop = True)
assert len(closest_zuse) == 561, "incorrect number of observations in closest_zuse"

# flag the observations using closest match
closest_zuse.loc[:, "nan_change"] = 1

# merge closest matches back to main matches gdf
merge_gdf2 = merge_gdf2.merge(closest_zuse, how = "left", on = "unique_id", suffixes = ("", "_r"))

# set nan_change equal to zero if not 1
merge_gdf2['nan_change'] = merge_gdf2['nan_change'].fillna(0)
assert dict(merge_gdf2['nan_change'].value_counts()) == {0.0: 1370, 1.0: 561}, "incorrect value counts for nan_change"

# fill in zone use type if missing (nan_chane==1)
merge_gdf2.loc[merge_gdf2["nan_change"] == 1, "zo_usety"] = merge_gdf2["zo_usety_r"]
assert merge_gdf2["zo_usety"].isna().sum() == 0, "there are still missing zone use types in merge_gdf2"

# convert <zo_usety> to integer and then string
merge_gdf2["zo_usety"] = merge_gdf2["zo_usety"].astype(int)
merge_gdf2["zo_usety"] = merge_gdf2["zo_usety"].astype(str)

# trim dataset variables, save as zuse_matches_df
zuse_matches_df = merge_gdf2[["unique_id", "zo_usety"]].copy()

# final error checks
assert len(zuse_matches_df) == 1931, "incorrect number of observations in zuse_matches_df"
assert zuse_matches_df["unique_id"].nunique() == 1931, "incorrect number of unique prop_ids in zuse_matches_df"
assert zuse_matches_df["unique_id"].nunique() == len(zuse_matches_df), "number of observations and number of unique prop_ids does not match in zuse_matches_df"
assert zuse_matches_df["zo_usety"].nunique() == 5, "incorrect number of unique zo_usety ids in zuse_matches_df"
assert dict(zuse_matches_df["zo_usety"].value_counts()) == {'1': 1083, '3': 531, '2': 244, '0': 37, '4': 36}, "incorrect value counts for zo_usety"
assert all(zuse_matches_df["zo_usety"].apply(type) == str), "not all values of zo_usety are strings"
                       
print("Done assigning zone use types!")


# # Assign zoning regulatin area (l_r_fid)

# In[8]:


# define l_r_fid as the index
zones_gdf.loc[:,'l_r_fid'] = zones_gdf.index

# spatial join with address points
merge_gdf3 = gpd.sjoin(data_gdf, zones_gdf, how = "left", op = "within")

# drop duplicated observations including originals
merge_gdf3.drop_duplicates(subset = "unique_id", keep = False, inplace = True)
assert len(merge_gdf3) == 1931, "incorrect observation count for merge_gdf3 after duplicates drop"

# missing value error checks
assert merge_gdf3["l_r_fid"].isna().sum() == 597, "incorrect number of observations with missing l_r_fid in merge_gdf3"
assert merge_gdf3["reg_type"].isna().sum() == 597, "incorrect number of observations with missing reg_type in merge_gdf3"
assert merge_gdf3["l_r_fid"].isna().sum() == merge_gdf3["reg_type"].isna().sum(), "number of missing l_r_fid and reg_type do not match"

# drop observations with missing l_r_fid values
merge_gdf3 = merge_gdf3[merge_gdf3["l_r_fid"].notna()]

# convert l_r_fid and reg_type to interger and then string
merge_gdf3[["l_r_fid", "reg_type"]] = merge_gdf3[["l_r_fid", "reg_type"]].astype(int)
merge_gdf3[["l_r_fid", "reg_type"]] = merge_gdf3[["l_r_fid", "reg_type"]].astype(str)

# trim dataset variables, save as zone_matches_df
zone_matches_df = merge_gdf3[["unique_id", "reg_type", "l_r_fid"]].copy()

# final error checks
assert len(zone_matches_df) == 1334, "incorrect number of observations in zone_matches_df"
assert zone_matches_df["unique_id"].nunique() == 1334, "incorrect number of unique prop_ids in zone_matches_df"
assert zone_matches_df["unique_id"].nunique() == len(zone_matches_df), "number of observations and number of unique prop_ids does not match in zone_matches_df"
assert zone_matches_df["l_r_fid"].nunique() == 532, "incorrect number of unique l_r_fid ids in zone_matches_df"
assert zone_matches_df["reg_type"].nunique() == 187, "incorrect number of unique reg_type ids in zone_matches_df"
assert all(zone_matches_df["l_r_fid"].apply(type) == str), "not all values of l_r_fids are strings"
assert all(zone_matches_df["reg_type"].apply(type) == str), "not all values of reg_types are strings"

print("Done assigning zone regulation types and l_r_fid!")


# # Combine assigments with base data

# In[9]:


# copy data_df to final_df
final_df = data_df.copy()

# merge with school attendance area matches
final_df = final_df.merge(school_matches_df, how = "outer", on = "unique_id", indicator = True, validate="1:1")
final_df.rename(columns = {"_merge" : "school_merge"}, inplace = True)
assert dict(final_df["school_merge"].value_counts()) == {'both': 1261, 'left_only': 671, 'right_only': 0}, "incorrect merge of school_matches_df"
                                                         
# merge with zone use type area matches
final_df = final_df.merge(zuse_matches_df, how = "outer", on = "unique_id", indicator = True, validate = "1:1")
final_df.rename(columns = {"_merge" : "zuse_merge"}, inplace = True)
assert dict(final_df["zuse_merge"].value_counts()) == {'both': 1931, 'left_only': 1, 'right_only': 0}, "incorrect merge of zuse_matches_df"
                                                         
# merge with zoning area id matches
final_df = final_df.merge(zone_matches_df, how = "outer", on = "unique_id", indicator = True, validate = "1:1")
final_df.rename(columns = {"_merge" : "zone_merge"}, inplace = True)
assert dict(final_df["zone_merge"].value_counts()) == {'both': 1334, 'left_only': 598, 'right_only': 0}, "incorrect merge of zone_matches_df"

# drop geometry variable
final_df.drop(columns = "geometry", inplace = True)

# rename cousub_name
final_df.rename(columns = {"cousub_name_x": "cousub_name"}, inplace = True)
final_df.drop(columns = "cousub_name_y", inplace = True)

# confirm that prop_id is all integers
final_df["unique_id"] = final_df["unique_id"].astype(int).astype(str)
assert all(final_df["unique_id"].apply(type) == str), "not all values of unique_id are integers"

# confirm length of dataframe excluding nan values
mask = (final_df["ncessch"].notna()
        & final_df["zo_usety"].notna() 
        & final_df["l_r_fid"].notna()
        & final_df["reg_type"].notna())

assert len(final_df[mask]) == 1238, "number of observations excluding missing values is not correct in final_df"

# # confirm the distribution of values are the same
error_check_dct = {'unique_id': {'count': 1932.0, 'mean': 1714.621118, 'std': 1017.035188, 'min': 1.0, '25%': 892.75, '50%': 1616.0, '75%': 2587.25, 'max': 3475.0},
                   'ch40b_id': {'count': 1932.0, 'mean': 4639.414596, 'std': 3784.237095, 'min': 10.0, '25%': 1606.0, '50%': 2804.0, '75%': 9197.0, 'max': 10582.0},
                   'l_r_fid': {'count': 1334.0, 'mean': 5996.107946, 'std': 1685.203846, 'min': 167.0, '25%': 4611.0, '50%': 6184.0, '75%': 7422.0, 'max': 8711.0},
                   'zo_usety': {'count': 1931.0, 'mean': 1.713102, 'std': 0.951426, 'min': 0.0, '25%': 1.0, '50%': 1.0, '75%': 3.0, 'max': 4.0},
                   'reg_type': {'count': 1334.0, 'mean': 226.801349, 'std': 132.274455, 'min': 0.0, '25%': 90.0, '50%': 241.0, '75%': 316.0, 'max': 537.0},
                   'ncessch': {'count': 1261, 'unique': 185, 'top': '250327000020', 'freq': 149}
                  }

sum_stats_dct = {col : dict(round(final_df[final_df[col].notna()][col].astype(int).describe(),6)) 
                 for col in ["unique_id", "ch40b_id", "l_r_fid", "zo_usety", "reg_type"]}

sum_stats_dct["ncessch"] = dict(final_df[final_df["ncessch"].notna()]["ncessch"].describe())

assert sum_stats_dct == error_check_dct, "summary stats for variable list do not match expected values"

print("Done compiling final dataset for export!")


# # Export data and save log

# In[12]:


# set log path
log_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/zone_assignments/zone_assignments_ch40b_log.txt"

# save data paths
save_file = "zone_assignments_ch40b_export.csv"
save_folder = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/zone_assignments"
save_path = os.path.join(save_folder, save_file)

# subdir for old exports
old_saves_folder = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/zone_assignments/old_export_versions"

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
    new_file_name = os.path.splitext(old_file_path)[0] + create_date +".csv"   
    os.rename(old_file_path, new_file_name)
    
# export final_df dataset as .csv
final_df.to_csv(save_path, index = False)

# calcualte total program run time
end_time = datetime.now()
duration = end_time - start_time
duration_in_s = (duration.days * 24 * 60 * 60) + duration.seconds
mins, secs = divmod(duration_in_s, 60)
hours, mins = divmod(mins, 60)
days, hours  = divmod(hours, 24)

# write to log
with open(log_path,'a') as file:
    file.write(f"Last run on {datetime.now().strftime('%D at %I:%M:%S %p')}\n")
    file.write(f"{len(final_df):,} observations written to: {save_path} \n")
    file.write(f"Total run time: {days} days, {hours:02} hours, {mins:02} minutes, {secs:02} seconds \n\n")

# Done!
print(f"Done, {len(final_df):,} observations written!")

