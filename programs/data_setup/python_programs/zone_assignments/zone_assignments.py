#!/usr/bin/env python
# coding: utf-8

# In[1]:


################################################################################
# File name:    "zone_assignment.ipynb"
#
# Project title:    Boston Affordable Housing project (visting scholar porject)
#
# Description:    This program takes the unique set of all warren group property
#                 tax records in the MAPC region and assigns them to (1) a
#                 schools attendance area <ncessch>, (2) a zone use type area
#                 <zo_usety>, and (3) a left/right boundary id and regulation 
#                 type area <l_r_fid> and <reg_type>. The exported .csv file
#                 is used in the closest_boundary_matches.py program.
#
# Inputs:    ./warren_MAPC_all_unique.dta
#            ./sabs_unique_latlong.shp
#            ./roads_mapc_union_sd_dissolved.shp
#            ./zoning_atlas_latlong.shp
#
# Outputs:    ./zone_assignments_export.csv
#             ./zone_assignments_log.txt
#
# Created:    10/18/2022
# Updated:    10/21/2022
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
data_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/data/warren/warren_MAPC_all_unique.dta"

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
data_df = data_df[["prop_id", "cousub_name", "warren_latitude", "warren_longitude"]]

data_gdf = gpd.GeoDataFrame(data_df, geometry = gpd.points_from_xy(data_df["warren_longitude"], data_df["warren_latitude"]),
                            crs = "EPSG:4269")

# convert zone gdf to crs 4269
zones_gdf.to_crs("EPSG:4269", inplace = True)

# error checks
assert len(data_gdf) == 821237, "incorrect observation count for data_gdf"
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
merge_gdf1.drop_duplicates(subset="prop_id", keep=False, inplace=True)
assert len(merge_gdf1) == 811642, "incorrect number of observatins in merge1_gdf, post dup drop"

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

assert len(merge_gdf1[merge_gdf1["ncessch"].isna()]) == 179256, "incorrect number of missing ncessch observations"

# drop missing <ncessch> observations
merge_gdf1 = merge_gdf1[merge_gdf1['ncessch'].notna()]

# convert <ncessch> to string
merge_gdf1["ncessch"] = merge_gdf1["ncessch"].astype(str)

# trim dataset variables, save as school_matches_df
school_matches_df = merge_gdf1[["prop_id", "ncessch"]].copy()

# final error checks
assert len(school_matches_df) == 632386, "incorrect number of observations in merge_gdf1"
assert school_matches_df["prop_id"].nunique() == 632386, "incorrect number of unique prop_ids"
assert school_matches_df["prop_id"].nunique() == len(school_matches_df), "number of observations in merge_gdf1 does not equal number of unique prop_ds"
assert school_matches_df["ncessch"].nunique() == 233, "incorrect number of unique ncessch ids"
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
merge_gdf2.drop_duplicates(subset = "prop_id", keep = False, inplace = True)
assert len(merge_gdf2) == 821062, "incorrect nubmer of observations in merge_gdf2 after duplicates drop"

# check the number of observations with missing zone use types
missing_no = merge_gdf2['zo_usety'].isna().sum()
assert missing_no == 42800, "incorrect number of observations with missing zone use types"

## fill in missing zone use types based on closest zone use area
# create dataframe of obs with missing zone use types
missing_zuse = merge_gdf2.loc[merge_gdf2['zo_usety'].isna()]

# merge missings dataframe with zuse_gdf based on city/town name
missing_zuse = missing_zuse[["prop_id", "cousub_name", "warren_latitude", "warren_longitude", "geometry"]]

closest_zuse = missing_zuse.merge(zuse_gdf, 
                               how = "left",
                               left_on = "cousub_name",
                               right_on = "muni",
                               suffixes = ("_left", "_zuse"))

# calculate the dist between point (property) and polygon (zuse type area)
closest_zuse.loc[:,"dist"] = gpd.GeoSeries(closest_zuse["geometry_left"], crs = "EPSG:4269").distance(gpd.GeoSeries(closest_zuse["geometry_zuse"], crs = "EPSG:4269"))

# sort by prop_id and distance, keep 1st closest match
closest_zuse.sort_values(by = ["prop_id", "dist"], ascending = True, inplace = True)
closest_zuse = closest_zuse.groupby("prop_id").head(1).reset_index(drop = True)
assert len(closest_zuse) == 42800, "incorrect number of observations in closest_zuse"

# flag the observations using closest match
closest_zuse.loc[:, "nan_change"] = 1

# merge closest matches back to main matches gdf
merge_gdf2 = merge_gdf2.merge(closest_zuse, how = "left", on = "prop_id", suffixes = ("", "_r"))

# set nan_change equal to zero if not 1
merge_gdf2['nan_change'] = merge_gdf2['nan_change'].fillna(0)
assert dict(merge_gdf2['nan_change'].value_counts()) == {0.0: 778262, 1.0: 42800}, "incorrect value counts for nan_change"

# fill in zone use type if missing (nan_chane==1)
merge_gdf2.loc[merge_gdf2["nan_change"] == 1, "zo_usety"] = merge_gdf2["zo_usety_r"]
assert merge_gdf2["zo_usety"].isna().sum() == 0, "there are still missing zone use types in merge_gdf2"

# convert <zo_usety> to integer and then string
merge_gdf2["zo_usety"] = merge_gdf2["zo_usety"].astype(int)
merge_gdf2["zo_usety"] = merge_gdf2["zo_usety"].astype(str)

# trim dataset variables, save as zuse_matches_df
zuse_matches_df = merge_gdf2[["prop_id", "zo_usety"]].copy()

# final error checks
assert len(zuse_matches_df) == 821062, "incorrect number of observations in zuse_matches_df"
assert zuse_matches_df["prop_id"].nunique() == 821062, "incorrect number of unique prop_ids in zuse_matches_df"
assert zuse_matches_df["prop_id"].nunique() == len(zuse_matches_df), "number of observations and number of unique prop_ids does not match in zuse_matches_df"
assert zuse_matches_df["zo_usety"].nunique() == 5, "incorrect number of unique zo_usety ids in zuse_matches_df"
assert dict(zuse_matches_df["zo_usety"].value_counts()) == {"1": 731070, "3": 62284, "2": 18075, "0": 5159, "4": 4474}, "incorrect value counts for zo_usety"
assert all(zuse_matches_df["zo_usety"].apply(type) == str), "not all values of zo_usety are strings"
                       
print("Done assigning zone use types!")


# # Assign zoning regulatin area (l_r_fid)

# In[8]:


# define l_r_fid as the index
zones_gdf.loc[:,'l_r_fid'] = zones_gdf.index

# spatial join with address points
merge_gdf3 = gpd.sjoin(data_gdf, zones_gdf, how = "left", op = "within")

# drop duplicated observations including originals
merge_gdf3.drop_duplicates(subset = "prop_id", keep = False, inplace = True)
assert len(merge_gdf3) == 821187, "incorrect observation count for merge_gdf3 after duplicates drop"

# missing value error checks
assert merge_gdf3["l_r_fid"].isna().sum() == 187515, "incorrect number of observations with missing l_r_fid in merge_gdf3"
assert merge_gdf3["reg_type"].isna().sum() == 187515, "incorrect number of observations with missing reg_type in merge_gdf3"
assert merge_gdf3["l_r_fid"].isna().sum() == merge_gdf3["reg_type"].isna().sum(), "number of missing l_r_fid and reg_type do not match"

# drop observations with missing l_r_fid values
merge_gdf3 = merge_gdf3[merge_gdf3["l_r_fid"].notna()]

# convert l_r_fid and reg_type to interger and then string
merge_gdf3[["l_r_fid", "reg_type"]] = merge_gdf3[["l_r_fid", "reg_type"]].astype(int)
merge_gdf3[["l_r_fid", "reg_type"]] = merge_gdf3[["l_r_fid", "reg_type"]].astype(str)

# trim dataset variables, save as zone_matches_df
zone_matches_df = merge_gdf3[["prop_id", "reg_type", "l_r_fid"]].copy()

# final error checks
assert len(zone_matches_df) == 633672, "incorrect number of observations in zone_matches_df"
assert zone_matches_df["prop_id"].nunique() == 633672, "incorrect number of unique prop_ids in zone_matches_df"
assert zone_matches_df["prop_id"].nunique() == len(zone_matches_df), "number of observations and number of unique prop_ids does not match in zone_matches_df"
assert zone_matches_df["l_r_fid"].nunique() == 5963, "incorrect number of unique l_r_fid ids in zone_matches_df"
assert zone_matches_df["reg_type"].nunique() == 451, "incorrect number of unique reg_type ids in zone_matches_df"
assert all(zone_matches_df["l_r_fid"].apply(type) == str), "not all values of l_r_fids are strings"
assert all(zone_matches_df["reg_type"].apply(type) == str), "not all values of reg_types are strings"

print("Done assigning zone regulation types and l_r_fid!")


# # Combine assigments with base data

# In[9]:


# copy data_df to final_df
final_df = data_df.copy()

# merge with school attendance area matches
final_df = final_df.merge(school_matches_df, how = "outer", on = "prop_id", indicator = True, validate="1:1")
final_df.rename(columns = {"_merge" : "school_merge"}, inplace = True)
assert dict(final_df["school_merge"].value_counts()) == {'both': 632386, 'left_only': 188851, 'right_only': 0}, "incorrect merge of school_matches_df"
                                                         
# merge with zone use type area matches
final_df = final_df.merge(zuse_matches_df, how = "outer", on = "prop_id", indicator = True, validate = "1:1")
final_df.rename(columns = {"_merge" : "zuse_merge"}, inplace = True)
assert dict(final_df["zuse_merge"].value_counts()) == {'both': 821062, 'left_only': 175, 'right_only': 0}, "incorrect merge of school_matches_df"
                                                         
# merge with zoning area id matches
final_df = final_df.merge(zone_matches_df, how = "outer", on = "prop_id", indicator = True, validate = "1:1")
final_df.rename(columns = {"_merge" : "zone_merge"}, inplace = True)
assert dict(final_df["zone_merge"].value_counts()) == {'both': 633672, 'left_only': 187565, 'right_only': 0}, "incorrect merge of school_matches_df"

# drop geometry variable
final_df.drop(columns = "geometry", inplace = True)

# confirm that prop_id is all integers
assert all(final_df["prop_id"].apply(type) == int), "not all values of prop_id are integers"

# confirm length of dataframe excluding nan values
mask = (final_df["ncessch"].notna()
        & final_df["zo_usety"].notna() 
        & final_df["l_r_fid"].notna()
        & final_df["reg_type"].notna())

assert len(final_df[mask]) == 618643, "number of observations excluding missing values is not correct in final_df"

# confirm the distribution of values are the same
error_check_dct = {'prop_id': 
                      {'count': 821237.0,
                       'mean': 1452949.4701212926,
                       'std': 1435185.2396116636,
                       'min': 264.0,
                       '25%': 414528.0,
                       '50%': 884816.0,
                       '75%': 1990482.0,
                       'max': 5068039.0},
                    'ncessch': 
                       {'count': 632386, 
                        'unique': 233, 
                        'top': 'BOSTON', 
                        'freq': 103463},
                    'l_r_fid': 
                       {'count': 633672.0,
                        'mean': 5198.722362673434,
                        'std': 1565.8300020628192,
                        'min': 0.0,
                        '25%': 3844.0,
                        '50%': 5299.0,
                        '75%': 6293.0,
                        'max': 8718.0},
                    'zo_usety': 
                       {'count': 821062.0,
                        'mean': 1.183793672097844,
                        'std': 0.5890590627534994,
                        'min': 0.0,
                        '25%': 1.0,
                        '50%': 1.0,
                        '75%': 1.0,
                        'max': 4.0},
                   'reg_type': 
                       {'count': 633672.0,
                        'mean': 163.150656806676,
                        'std': 119.46259382918376,
                        'min': 0.0,
                        '25%': 45.0,
                        '50%': 185.0,
                        '75%': 245.0,
                        'max': 542.0}}

sum_stats_dct = {col : dict(final_df[final_df[col].notna()][col].astype(int).describe()) 
                 for col in ["prop_id", "l_r_fid", "zo_usety", "reg_type"]}

sum_stats_dct["ncessch"] = dict(final_df[final_df["ncessch"].notna()]["ncessch"].describe())

assert sum_stats_dct == error_check_dct, "summary stats for variable list do not match expected values"

print("Done compiling final dataset for export!")


# # Export data and save log

# In[10]:


# set log path
log_path = "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/zone_assignments/zone_assignments_log.txt"

# save data paths
save_file = "zone_assignments_export.csv"
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


# In[ ]:




