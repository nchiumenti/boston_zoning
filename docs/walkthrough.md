<a id="top"></a>

# Walkthrough

[🔙 Return to Start Here](./README.md) | [🏠 Go to main repo page](/)

This walkthrough provides the steps involved with reproducing the data used in 
[*Under the (Neighbor)Hood: Understanding Interactions Among Zoning Regulations*](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4082457). 
It is assumed the users has access to the input data files, including those not 
shared in this repository. 

> [!NOTE] 
> **Program Requirements**
> - Stata 16, or later version
> - Python 3.9, or later version
> - ArcPro v3.6, or later version, or comparable GIS software
>
> It is recommended the user have Jupyter Notebook installed for
> viewing and running the `.ipynb` files. Alternatively most modern IDEs have
> `.ipynb` file compatibility.

## Walkthrough Table of Contents:
- [1. Boundary Selection](#1-boundary-selection)
    - [Step 1.1: Run `new_mf_definitions.do`](#step-1.1)
    - [Step 1.2: Run `create_admissible_boundaries.py`](#step-1.1)
- [2. Data Setup](#2-data-setup)
    - [Step 2.1: Run the master setup file.](#step-2.1)
    - [Step 2.2: Compile the warren group data](#step-2.2)
    - [Step 2.3: Run `zone_assignments.ipynb`](#step-2.3)
    - [Step 2.4: Run `closest_boundary_matches.ipynb`](#step-2.4)
    - [Step 2.5: Run `20_boundary_matches.do`](#step-2.5)
    - [Step 2.6: Calculate density measures](#step-2.6)
    - [Step 2.7: Compile the CoStar data](#step-2.7)
    - [Step 2.8: NHPD data, clean, compile, and match to warren](#step-2.8)
    - [Step 2.9: Chapter 40B data, clean, compile, and match to warren](#step-2.9)
    - [Step 2.10: Compile the final dataset](#step-2.10)
    - [Step 2.11: Run `80_amenity_datasets.do`](#step-2.11)
    - [Step 2.12: Create the straight line boundary files](#step-2.12)
    - [Step 2.13: Create the no roads boundary files](#step-2.13)
    - [Step 2.14: Calculate transit distances](#step-2.14)
    - [Step 2.15: Assign soil quality data](#step-2.15)
    - [Step 2.16: Create walkability data](#step-2.16)
    - [Step 2.17: Create `final_dataset_town_comparisons.dta`](#step-2.17)
- [3. Analysis](#3-analysis)
    - [Step 3.1: Run the master analysis file](#step-3.1)
    - [Step 3.2: Run `analysis_within_town_setup.do`](#step-3.2)
    - [Step 3.3 (optional): Run the remaining analysis setup files](#step-3.3)
    - [Step 3.$n$: Run the remaining analysis files](#step-3.n)
- [File-to-Figure](#file-to-figure-map)
    - [Tables-to-Files](#tables-to-files)
    - [Figures-to-Files](#figures-to-files)

---

## 1. Boundary Selection
A core component of this paper are the zoning boundaries that get matched to 
every residential property in Greater Boston. The steps below detail how the
initial set of boundaries are created. 

<a id=step-1.1></a>

### Step 1.1: Run `new_mf_definitions.do`
In Stata, run `new_mf_definitions.do`. This file can be found under 
`code/data_setup/miscellaneous_setup_files`. Either the global `$DATAPATH`
variable to point to the local path of `/data`.

<a id=step-1.2></a>

### Step 1.2: Run `create_admissible_boundaries.py`
Note that this file is coded as a Python `.py` file, but can be run in Jupyter 
Notebooks. Run all parts of `create_admissible_boundaries.py`. 

This file is coded to run out of the directory `/data/boundary_selection`, so 
the `.py` file first copies over multiple input `.zip` files that contain the 
polygon data. However you can comment-out this code and simply direct the paths
to their source files in the corresponding `/data` folder. 

The result of this step is the creation of `amd3.shp`. This is the final
admissible boundaries file that contains the individual zoning boundaries where
Warren Group properties will be assigned to one of two sides (left or right) for
comparison. 


## 2. Data Setup
The steps below are in a kind of chronological order. That is, **steps are in 
the order that the code was written** for this project. The result is that some
steps may have duplicative components, or be superseded by later steps. 
Ultimately we decided not to consolidate code and remove vestigial parts of the 
repository because we felt that would conflict with the goal of transparency.

<a id=step-2.1></a>

### Step 2.1: Run the master data setup file.
In Stata, run `00_data_setup_master_file.do`. This file sets all necessary 
global path variables that will be used throughout the setup process. Any 
changes to the global path variables to match a user's local directory structure
should be made here. The most important global variable to set correctly is 
`$DATAPATH`, as this will point to (almost) all subsequent data files and their 
assumed sub-directories.

Note that this file does set the current working directory to `$DOPATH`, which 
is not strictly necessary.

<a id=step-2.2></a>

### Step 2.2: Compile the warren group data
In Stata, run `10_warren_data_compile.do`. This creates several base Warren 
Group property-level data files. It requires a access to 
`MA_assessor_annual_expanded.dta`, which is the raw Warren Group data 
extracted for the purposes of this paper.

This step calls three (3) sub-scripts, which handle geocoding tasks 
(`11_geocoding.do`), identify residential properties and remove non-residential 
property records (`12_res_types.do`), and clean and aggregate condominium 
records for use later on (`13_condo_collapse.do`). Note that in the end
condominium properties were excluded form the analysis.

After completing this step the following files should have been created:
- `warren_MA_all_annual.dta` - All *residential* property records in 
Massachusetts, by year.
- `warren_MA_all_unique.dta` - A unique set of all *residential* property 
records in Massachusetts (across years).
- `warren_MAPC_all_annual.dta` - All *residential* property records in MAPC 
region, by year.<sup>1</sup>
- `warren_MAPC_all_unique.dta` - A unique set of all *residential* property 
records in MAPC region (across years).

#### Step 2.2.a. (optional)
If necessary, within `11_geocoding.do`, you may wish to uncomment and run
`warren_geocode_fixes.do`. This sub-process handles output from 
`BatchAddressMatch_final.ipynb`, which in turn uploads structured addresses to 
the [Census Geocoder API](#https://geocoding.geo.census.gov/geocoder/) in order 
to identify and correct lat/lon coordinates for a handful of records. This step 
only needs to be done once and is very time consuming as you are rate limited in 
the use of the API. 

1. stop the process at line 137 of `11_gecoding.do`
2. uncomment line 138, 
3. run `./data/warren/geocode_fixes/warren_geocode_fixes.do` up to line 102.
4. navigate to `./data_setup/python_programs/census_geocoder_api`
5. edit `BatchAddressMatch_final.ipynb` to point to the `.txt` files created by step 2.2.a.3.
6. ensure the output is saved to `$DATAPATH/warren/geocode_fixes`
7. run `BatchAddressMatch_final.ipynb`, ensure `geocoder_export_`DateStamp'.csv` is created
8. run `warren_geocode_fixes.do` in full, ensure `address_corrections_output.dta` is created
9. comment-out line 138 in `11_gecoding.do`
10. re-start `11_geocoding.do` from the top, or, re-run `10_warren_data_compile.do` in full.

<span style="font-size: 10px;"> <sup>1</sup> MAPC is the Metropolitan Area 
Planning Council, which created the Zoning Atlas data used in this report. 
The towns in MAPC's region are the basis for our definition of Greater Boston.</span>

<a id=step-2.3></a>

### Step 2.3: Run `zone_assignments.ipynb`
In Jupyter Notebook, run all parts of `zone_assignments.ipynb`. This will create 
a dataset which matches Warren Group properties to the correct zoning area, 
zone-use type, and school district. It will allow for the correct assignment of
properties to zoning boundaries within the same city/town, school district, 
zoning area, and zone-use type area.

The result of this step will create the `zone_assignments_export.csv`. Ensure 
that `zone_assignments_export.csv` has been generated 
***in the same directory as `zone_assignments.ipynb`***. This file will contain 
all Warren Group property IDs, and the variables:
- `zo_usety` - the zone use type code
- `l_r_fid` - the unique zoning area ID
- `ncessch` - the unique school attendance area 

Note that `zone_assignments.ipynb` requires correct paths to the following:
- `warren_MAPC_all_unique.dta`
- `sabs_unique_latlong.shp` - a version of `SABS_1516_Primary.shp` with unique, non-overlapping, school district boundaries.
- `roads_mapc_union_sd_dissolved.shp` - a version of zoning_atlas_latlong.shp with unique, non-overlapping, zoning areas.
- `zoning_atlas_latlong.shp` - contains the zone-use type areas.

<a id=step-2.4></a>

### Step 2.4: Run `closest_boundary_matches.ipynb`
In Jupyter Notebook, run all parts of `closest_boundary_matches.ipynb`. This 
will match all of the Warren Group properties to the five (5) closest zoning 
boundary pairs identified in `adm3_crs4269.shp`. It takes the output from 
[Step 2.3](#step-2.3) and iterates over all possible matches, holding school 
attendance area, zoning area, zone-use type, and municipality constant.

The result of this step will create `closest_boundary_matches.csv`. Ensure that 
`closest_boundary_matches.csv` has been generated 
***in the same directory as `closest_boundary_matches.ipynb`***. It should 
include the following variables:
- `unique_id` - the unique identifier of the boundary pair
- `LEFT_FID` - the unique identifier of a zoning area for the 'left' side of the boundary pair
- `RIGHT_FID` - the unique identifier of a zoning area for the 'right' side of the boundary pair
- `boundary_side` - text entry identifying if the property matched with LEFT_FID, RIGHT_FID, or both
- `nearest_point_dist` - the distance of the nearest point on the boundary to the Warren property
- `nearest_point_lat` - the nearest point latitude coordinates
- `nearest_point_lon `- the nearest point longitude coordinates
- `match_num` - the number match indicator (1-5)

<a id=step-2.5></a>

### Step 2.5: Run `20_boundary_matches.do`
In Stata, run `20_boundary_matches.do`. This code file will identify the single 
best match of a warren group property to a zoning boundary, out of the five closest, defined as the 
closest boundary with comparable regulations on both sides of the 
boundary (left and right side). It will also match on the associated zoning
regulations and assign them to the home zoning area of the property (`home_`) 
and the zoning area identified for comparison (`nn_`).

The result of this step will create `closest_boundary_matches_with_regs.dta`.

<a id=step-2.6></a>

### Step 2.6: Calculate density measures
Note that this files handles setup for analysis that is no longer relevant to the 
paper. However, future files reference output from these steps and so may throw 
runtime errors if not present.

In Stata, run `30_density_measures.do`. This file calculates the share of 
properties in a .1 mile radius around every Warren Group property that is a 2-3 
unit (gentle density) and 4+ unit (high density) building. The result will be 
the file `warren_density_measures.dta`, which stores the density data and is 
merged on later.

<a id=step-2.7></a>

### Step 2.7: Compile the CoStar data
In Stata, run `40_costar.do` to compile all of the raw data scraped from the 
costar website. `40_costar.do` also calls two subscripts:

- `41_costar_warren_xwalk.do` - creates a crosswalk that is used to identify 
matching warren group properties and their corresponding costar record, 
if present.
- `42_costar_rent_history.do` - compiles the historic rent data scraped from 
Costar and uses the crosswalk made in `41_costar_warren_xwalk.do` to identify
corresponding warren group properties.

> [!Note]
> Refer to the [_tree_data_dir.txt](/data/_tree_data_dir.txt) file in order to 
> view the structure and contents of the `/data/costar` directory used to 
> complete this step. `costar_props.ipynb` is stored within this directory and 
> is responsible for creating `costar_property_list.xlsx`. This script is run in
> recursively checks the `./property rent history` directory,  loads the scraped 
> data, and adds it to a dataframe that is then exports it to excel. We were 
> unable to include `costar_props.ipynb` in this repository.

The result of this step are three .dta files:

- `costar_mf_all.dta` stores all of the costar information with matched warren
group property ids.
- `costar_mf_destring.dta` is the same as the above, but with all variables 
converted to float.
- `costar_rent_hist.dta` stores the rental history data that was available in 
costar.

<a id=step-2.8></a>

### Step 2.8: NHPD data, clean, compile, and match to Warren Group properties
This is a multi step process that handles the raw NHPD data, cleans it, assigns
it to zoning boundaries, and matches it to warren group properties. All sub-steps
are required if you wish to reproduce this component of the data. Note however,
it is not used in the final analysis. However, future files reference output 
from these steps and so may throw runtime errors if not present.

#### Step 2.8.a.: Run `50_nhpd.do` up until line 459.
In Stata, run `50_nhpd.do`. This will create `nhpd_mapc.dta`, which is a list of 
all subsidized housing properties in the Metropolitan Area Planning Council 
region within Massachusetts.

Ensure that all paths correctly point to the the following files: 
- `All Properties.xlsx`

#### Step 2.8.b.: Run `zone_assignments_nhpd.ipynb`
In Jupyter Notebook, run `zone_assignments.ipynb`. This is an identical process 
to Step 3, above, but instead this file is coded to handle `nhpd_mapc.dta`. It 
will result in the file `zone_assignments_nhpd_export.csv`. All other input files 
are the same as [Step 2.3](#step-3.2).

Ensure that all paths currectly point to the the following file(s): 
- `nhpd_mapc.dta`

The result of this step are the following file(s):
- `zone_assignments_nhpd_export.csv`

#### Step 2.8.c.: Run `closest_boundary_matches_nhpd.ipynb`
In a Python IDE, run `closest_boundary_matches_nhpd.ipynb`. This is an identical
process to Step 4, above, but instead this file is coded to handle 
`zone_assignments_nhpd_export.csv`. All other input files are the same as Step 4.

Ensure that all paths correctly point to the the following file(s): 
- `zone_assignments_nhpd_export.csv`

The result of this step are the following file(s):
- `closest_boundary_matches_nhpd.csv`

#### Step 2.8.d.: In `50_nhpd.do`, run line 467
This will call `51_nhpd_boundary_matches.do`, which is similar process to Step 5,
above. It will identify the closest zoning boundary and assign regulations using
the same criteria at Step 5.

Ensure that all paths correctly point to the the following file(s): 
- `closest_boundary_matches_nhpd.csv`
- `regulation_types.dta`

The result of this step are the following file(s):
- `closest_boundary_matches_nhpd_with_regs.dta`

#### Step 2.8.e.: In `50_nhpd.do`, run line 469
This will call `52_nhpd_warren_xwalk.do`, which will identify the corresponding
warren group property and assign its ID to the NHPD record. It follows a similar
process used in Step 7, above, (specifically in `41_costar_warren_xwalk.do`),
but also uses the assigned zoning boundary as a criteria for matching.

Ensure that all paths correctly point to the the following file(s): 
- `nhpd_mapc.dta`
- `warren_MA_all_unique.dta`
- `closest_boundary_matches_nhpd_with_regs.dta`

The result of this step are the following file(s):
- `nhpd_warren_xwalk.dta`

<a id=step-2.9></a>

### Step 2.9: repeat Step 8 but with the Chapter 40B files 
The process for handling the Chapter 40B data is essentially the same as the
NHPD data in [Step 2.8](#step-2.8). You should follow along in the same way but with the 
differently component files, usually denoted with the '_ch40b' suffix.

Step 2.9.a.: Run `60_ch40b.do` up until line 704.

Step 2.9.b.: Run `zone_assignments_ch40b.ipynb`

Step 2.9.c.: Run `closest_boundary_matches_ch40b.ipynb`

Step 2.9.d.: In `60_ch40b.do`, run line 710

Step 2.9.e.: In `60_ch40b.do`, run line 712

<a id=step-2.10></a>

### Step 2.10: Compile the final dataset
In Stata, run `70_final_dataset.do`. There isn't much to describe for this step
as the file essentially just merges all of the disparate output from Steps 1-9 
into the final (or nearly final) dataset.

> [!NOTE]
One important thing to note is that the output `final_dataset.dta` is a
generic name. In many of the analysis setup files there is reference to 
`final_dataset_10-28-2021.dta`. This is the same file but date-stamped to 
preserve the output at the time. Another variation is 
`final_dataset_town_comparisons.dta`, which differs in that the municipality 
boundaries are not controlled for when zoning boundaries are assigned.

The required input files are: 
- `warren_MAPC_all_annual.dta`
- `closest_boundary_matches_with_regs.dta`
- `warren_density_measures.dta`
- `costar_warren_xwalk.dta`
- `nhpd_warren_xwalk.dta`
- `chapter40b_warren_xwalk.dta`
- `costar_rent_hist.dta`
- `costar_mf_all.dta`
- `nhpd_mapc.dta`
- `chapter40b_mapc.dta`
- `closest_boundary_matches_nhpd_with_regs.dta`

The result of this step is the following:
- `final_dataset.dta`

<a id=step-2.11></a>

### Step 2.11, run `80_amentiy_datasets.do`
In Stata, run `80_amentiy_datasets.do`. This file takes a number of `.shp` files,
converts them for use in Stata (data and corresponding coordinate .dta files),
and calcualtes the distance from a warren property to the 'closest' amenity (i.e.,
nearest road, green space, etc.).

Technically speaking this step can be completed at any point after [Step 2.2](#step-2.2), and 
only requires that `warren_MAPC_all_unique.dta` be present.

As a result of this step, `warren_MAPC_all_unique_closest_stuff.dta` will be 
created which has the ID for every Warren Group property in `final_dataset.dta`,
along with the distance from that property to various amenties.

<a id=step-2.12></a>

### Step 2.12, create the striaght line boundary files
The original zoning boundaries used for analysis were amended to only include 
those which are straight line boundaries. The process is an off-shoot of the 
closest boundary matches and identifies if a Warren Group property falls along a 
straight segment of a zoning boundary, per Turner et al. (2014).<sup>1</sup>

#### Step 2.12.a.
In Jupyter Notebook, run all parts of `closest_boundary_matches_mtlines.ipynb`. 
It will it to create `closest_boundary_matches_mtlines.csv` in the same path. 

#### Step 2.12.b.
In Stata, run `mt_orthogonal_lines.do`, located under 
`/code/data_setup/miscellaneous_setup_files`. Ensure that the correct path is 
specified to the ouput of Step 12.a. above. 

The result of this step will be `mt_orthogonal_dist_100m.dta` file with the 
variable `straight_line`. This variable equals one (1) if the property lies on a 
straight-line segment of the assigned zoning boundary, else equals zero (0). As
with [Step 2.10](#step-2.10) this is a generic file output name and will be 
references as `mt_orthogonal_dist_100m_07-01-22_moreregs.dta`

<span style="font-size: 10px;"> <sup>1</sup> Turner, Matthew A, Andrew Haughwout, and Wilbert VanDer Klaauw, “Land Use Regulation and Welfare,” Econometrica, 2014, 82 (4), 1341–1403. </span>

 <a id=step-2.13></a>

### Step 2.13: Create the no roads files
The 'no roads' boundaries are the orignal zoning boundaries we identified with
all overlapping roadways removed (not just highways and major roads). Unlike
the original zoning boundaries, the entire process of matching to the closest
boundary and assigning regulations is down in the `.ipynb` file.

In Jupyter Notebook, run all parts of `closest_boundary_matches_noroads.ipynb`.
Note that this file uses a number of one-off datasets.
- `adm3_no_roads_crs26986.shp` - is a version of the final zoning boundaris but 
with all overlapping roads removed. This was created in ArcGIS using `adm3.shp` 
and. The complete road network shapefile `EOTROADS.shp`.
- `warren_address_points_assigned.shp` - This is a simple export of the warren
group properties with the latitude/longitude locations. It was made at the time 
to more easily code up the file but any file format can be used so long as the 
unique ID and coordinates variables are present.
- `regulation_types_moreregs.dta` - holds the boundary regulation data. 

The result will be `closest_boundary_matches_noroads.csv`, which contains 
warren group properties matched to zoning boundaries that do not overlap any 
roads.

 <a id=step-2.14></a>

### Step 2.14: Calculate trasit distances
There are two `.ipynb` files that handle public transit distance measures. This
step covers both of them.

#### Step 2.14.a.
In Jupyter Notebook, run `dist_prop_to_station.ipynb`. This script calcualtes the 
distance of a warren property to it's closest public transit train station using
both a manhattan (to approximate walking distance) and euclidean method. 

The result will produce the file `transit_distance.csv`

#### Step 2.14.b. 
In Jupyter Notebook, run `dist_to_south_station.ipynb`. This script calculates 
the distance of warren property to South Station in downtown Boston, used as a 
central reference point for the main business district in the region. 

The result will produce the file `dist_south_station_2022_09_29.csv`

 <a id=step-2.15></a>
 
### Step 2.15: Assign soil quality data
In a Python IDE, run `soil_quality_matching.ipynb`. This script assigns warren
group properties to the corresponding parcel of soil quality data found in
`Soil_Parcel_Data_Shape.shp`

The result will produce `soil_quality_matches.dta`.

<a id=step-2.16></a>

### Step 2.16: Create walkability data
This step does not have a defined file associated with handling the process. It 
was produced in ArcPro in early 2024 and involved spatially matching warren 
group properties to the polygons found in Natl_WI.gbd. The version used to 
complete this step is ArcPro v3.6.

<a id=step-2.17></a>

### Step 2.17: Create `final_dataset_town_comparisons.dta`

This `.dta` is used as input for `amenities_muni_boundary.do` only. You are 
essentially following steps [2.4](#step-2.4), [2.5](#step-2.5) and [2.10](#step-2.10)
but with the following modifications:

- Instead of `closest_boundary_matches.ipynb`, run `closest_town_boundary_matches.ipynb`.

- Instead of `20_boundary_matches.do` run `warren_town_boundary_matches.do`. This will save
`warren_town_closest_matches_with_regs.dta`

- Instead of 70_final_dataset.do, run `final_dataset_town_boundary_comparisons.do`

## 3. Analysis
So long as [Data Setup Steps 1&ndash;16](#data-setup) have been completed 
successfully the required input files for the analysis code files should be 
present in the `/data` directory. 

<a id=step-3.1></a>

### Step 3.1: Run the master analysis file
In Stata, run `analysis_master_file.do`. This file sets all necessary 
global path variables that will be used throughout the analysis process. Any 
changes to the global path variables to match a user's local directory structure
should be made here. The most important global variables to set correctly are
`$DATAPATH`, which should refer to the main directory storing the data files, 
and `$EXPORTPATH`, which should point to the directory where any output will be 
stored.

<a id=step-3.2></a>

### Step 3.2: Run `analysis_within_town_setup.do`
In Stata, run `analysis_within_town_setup.do`. This file will handle a lot of 
intermediate setup that is common throughout most of the analysis files. It will
also create `within_town_analysis_data.dta`, which is a kind of *final* 
`final_dataset.dta`. 

Prior versions of the code called `analysis_within_town_setup.do` from within 
the overall analysis file. However, `analysis_within_town_setup.do` takes a long 
time to run and so it is recommend that the output is stored for repeated use. 

<a id=step-3.3></a>

### Step 3.3 (optional): Run the remaining analysis setup files
In addition to `analysis_within_town_setup.do`, there are two (2) additional 
analysis setup files that handle distince procedures for their corresponding
analysis files. These are: 
- `analysis_noroads_setup.do`, which is used by `main_noroads.do`
- `analysis_town_comparisons_setup.do`, wich is used by `amenities_muni_boundary.do`

Both setup files take a while to run, however since they only relate to one 
analysis file they are not coded to save output at this time. However, you may 
want to save the ouput from these files if you plan to run their corresponding 
analysis files multiple times in order to save time. 

<a id=step-3.n></a>

### Step 3.$n$: Run the remaining analysis files
For details on which tables/figures correspond to which analysis files, refer to
The [File-to-Figure Map](#file-to-figure-map) and the [Analysis Files Guide](/docs/analysis_files.md) section.

The remaining analysis files can be run in any order, with two (2) exceptions:

1. If you plan to run either `main_noroads.do` and/or `amenities_muni_boundary.do`,
but have not saves the output from [Step 3](), you must do so before-hand or 
confirm they are called within their correspond analysis files.

2. The `counterfactual_` files must be run in the order denote by their infix.
Specifically the order should be follows:
    1. `counterfactual_01_spatial_heterogeneity.do` 
    2. `counterfactual_02_train_station_means`
    3. `counterfactual_03_means.do`
    4. `counterfactual_04_calculations_combined.do`


## File-to-Figure Map

Below are the figure/table paper references mapped to the corresponding file
which generates some or all components.

### Tables-to-Files

| Table Ref       | File |
|-----------------|------|
| Table 1         | [table1_replication.do](#table1_replicationdo) |
| Table 2         | [amenities_mtlines.do](#amenities_mtlinesdo) <br> [predicted_prices_mtlines.do](#predicted_prices_mtlinesdo) |
| Table 3         | [within_town_mtlines.do](#within_town_mtlinesdo) <br> [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo) |
| Table C.1       | [amenities_mtlines.do](#amenities_mtlinesdo) |
| Table C.2       | [amenities_muni_boundary.do](#amenities_muni_boundarydo) |
| Table C.3       | [residuals.do](#residualsdo) |
| Table C.4       | [within_town_mtlines.do](#within_town_mtlinesdo) <br> [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo) |
| Table C.5       | [within_town_mtlines.do](#within_town_mtlinesdo) <br> [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo) |
| Table C.6       | [within_town_mtlines.do](#within_town_mtlinesdo) <br> [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo) |
| Table C.7       | [within_town_mtlines.do](#within_town_mtlinesdo) <br> [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo) |
| Table C.8       | [chars_mtlines.do](#chars_mtlinesdo) <br> [robustness_mtlines.do](#robustness_mtlinesdo)  |
| Table C.9       | [chars_mtlines.do](#chars_mtlinesdo) <br> [robustness_mtlines.do](#robustness_mtlinesdo)  |
| Table C.10      | [chars_mtlines.do](#chars_mtlinesdo) <br> [robustness_mtlines.do](#robustness_mtlinesdo)  |
| Table C.11      | [external_effects.do](#external_effectsdo)  |
| Table C.12      | [robustness_mtlines.do](#robustness_mtlinesdo)  | 
| Table C.13      | [external_effects.do](#external_effectsdo) | 
| Table D.1       | [counterfactual_01_spatial_heterogeneity.do](#counterfactual_01_spatial_heterogeneitydo) | 
| Table D.2       | [counterfactual_01_spatial_heterogeneity.do](#counterfactual_01_spatial_heterogeneitydo) |
| Table E.1       | <sup>1</sup> |
| Table E.2       | <sup>2</sup> |

<span style="font-size: 10px;"> <sup>1</sup> Non-exhaustive list meant to illustrate recent reforms, based on various news sources. </span>
<span style="font-size: 10px;"> <sup>2</sup> Constructed based on data from Knauss, Norman L, Zoned Municipalities in the United States, Vol. 374, Division of Build-
ing and Housing, Bureau of Standards, 1933. </span>

### Figures-to-files

| Figure Ref       | File |
|------------------|------|
| Figure 1         | [main_mtlines.do](#main_mtlinesdo) |
| Figure 2         | [chars_mtlines.do](#chars_mtlinesdo) |
| Figure 3         | [main_mtlines.do](#main_mtlinesdo) |
| Figure 4         | [main_mtlines.do](#main_mtlinesdo) |
| Figure 5         | [counterfactual_04_calculations_combined.do](#counterfactual_04_calculations_combineddo) |
| Figure A.1       | <sup>3</sup> |
| Figure A.2       | <sup>4</sup> |
| Figure A.3       | [existence.do](#existencedo) |
| Figure A.4       | [histogram.do](#histogramdo) |
| Figure A.5       | [histogram.do](#histogramdo) |
| Figure A.6       | [figure_A6.do](#figure_a6do) <sup>5</sup> |
| Figure A.7       | [straight_line_boundary_map.do](#straight_line_boundary_mapdo) |
| Figure C.1       | [amenities_mtlines.do](#amenities_mtlinesdo)  |
| Figure C.2       | [amenities_mtlines.do](#amenities_mtlinesdo)   |
| Figure C.3       | [main_mtlines.do](#main_mtlinesdo) |
| Figure C.4       | [main_mtlines.do](#main_mtlinesdo) |
| Figure C.5       | [chars_mtlines.do](#chars_mtlinesdo) <br> [main_noroads.do](#main_noroadsdo) |
| Figure C.6       | [main_mtlines.do](#main_mtlinesdo) |
| Figure C.7       | [main_mtlines.do](#main_mtlinesdo) |
| Figure C.8       | [robustness_mtlines.do](#robustness_mtlinesdo) |
| Figure C.9       | [robustness_mtlines.do](#robustness_mtlinesdo)    |
| Figure C.10      | [robustness_mtlines.do](#robustness_mtlinesdo) | 
| Figure C.11      | [bindingness.do](#bindingnessdo) <br> [chars_mtlines.do](#chars_mtlinesdo) | 
| Figure C.12      | [main_noroads.do](#main_noroadsdo) <br> [robustness_mtlines.do](#robustness_mtlinesdo)  |
| Figure D.1	   | [straight_line_boundary_map.do](#straight_line_boundary_mapdo) <sup>6</sup> |
| Figure E.1       | [regulations_map.do](#regulations_mapdo) |
| Figure E.2       | [regulations_map.do](#regulations_mapdo) |
| Figure E.3       | [regulations_map.do](#regulations_mapdo) |
| Figure E.4       | [assessed_vs_sales.do](#assessed_vs_salesdo) |
| Figure E.5       | [included_excluded_towns.do](#included_excluded_townsdo) |
| Figure E.6       | [straight_v_walking_dist.do](#straight_v_walking_distdo) |
| Figue E.7        | [warren_group_property_map.do](#warren_group_property_mapdo)  |
| Figure E.8       | <sup>7</sup> |

<span style="font-size: 10px;">

<sup>3</sup> Diagram made via MS Paint
<sup>4</sup> Screenshots of online mapping software overlaying historic zoning area raster images with final boundary file.
<sup>5</sup> The main parts of the figure were made in ArcGIS, calculations for the boundary lengths are in [figure_A6.do](#figure_a6do).
<sup>6</sup> A color version of Figure A.7
<sup>7</sup> Screenshot of [MAPC service region](https://www.mapc.org/resource-library/vehicle-miles-traveled-emissions/) cities and towns by community types.

</span>


<br>
<br>

<a href="#top">Back to Top</a>