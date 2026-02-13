<a id="top"></a>

# Analysis Files Guide

[🔙 Return to Start Here](./README.md) | [🏠 Go to main repo page](/)

**Contents:**
- [Overview](#overview)
- [Code Structure](#code-structure)
- [File-to-Figures/Tables](#file-to-figure-map)
- [File Descriptions](#file-descriptions)
	- [analysis_master_file.do](#analysis_master_filedo) 
	- [analysis_within_town_setup.do](#analysis_within_town_setupdo) 
	- [analysis_noroads_setup.do](#analysis_noroads_setupdo) 
	- [analysis_town_comparisons_setup.do](#analysis_town_comparison_setupdo) 
	- [amenities_mtlines.do](#amenities_mtlinesdo) 
	- [amenities_muni_boundary.do](#amenities_muni_boundarydo) 
	- [bindingness.do](#bindingnessdo) 
	- [chars_mtlines.do](#chars_mtlinesdo) 
	- [counterfactual_01_spatial_heterogeneity.do](#counterfactual_01_spatial_heterogeneitydo) 
	- [counterfactual_02_train_station_means.do](#counterfactual_02_train_station_meansdo) 
	- [counterfactual_03_means.do](#counterfactual_03_meansdo) 
	- [counterfactual_04_calculations_combined.do](#counterfactual_04_calculations_combineddo) 
	- [existence.do](#existencedo) 
	- [external_effects.do](#external_effectsdo) 
	- [histogram.do](#histogramdo) 
	- [main_mtlines.do](#main_mtlinesdo) 
	- [main_noroads.do](#main_noroadsdo) 
	- [predicted_prices_mtlines.do](#predicted_prices_mtlinesdo) 
	- [residuals.do](#residualsdo) 
	- [robustness_mtlines.do](#robustness_mtlinesdo) 
	- [straight_v_walking_dist.do](#straight_v_walking_distdo) 
	- [table1_replication.do](#table1_replicationdo) 
	- [within_town_mtlines.do](#within_town_mtlinesdo) 
	- [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo) 
	- [assessed_vs_sales.do](#assessed_vs_salesdo)
	- [figure_A6.do](#figure_a6do)
	- [included_excluded_towns.do](#included_excluded_townsdo)
	- [regulations_map.do](#regulations_mapdo)
	- [straight_line_boundary_map.do](#straight_line_boundary_mapdo)
	- [warren_group_property_map.do](#warren_group_property_mapdo)

---

## Overview

[/code/analysis_files](/code/analysis_files/) contains any and all files that conduct analysis or output figures
and tables used in [Under the (Neighbor)Hood: Understanding Interactions Among Zoning Regulations](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4082457). 
 
## Code Structure

> [!NOTE]
> To easily find references to tables and/or figures in code files, search for 
> text tag `[PAPER SOURCE]` using `ctrl/cmd+f`.

All `./analysis_files` files are Stata `.do` files and must be run with a working version of 
Stata. 

Almost all .do files begin with the same preface. Below is an example from `amenities_mtlines.do`:

<details>
<summary>example file preface</summary>

```
* start here
clear all
log close _all
set linesize 255

local name ="amenities_mtlines"  // <--- change when necessry

* create an output directory if none exists
global EXPORTPATH "$WORKINGDIR/analysis/`name'_output"

capture confirm file "$EXPORTPATH"

if _rc != 0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

* start log file
local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

log using "$EXPORTPATH/`name'_log_`date_stamp'.log", replace
```

</details>

All `.do` files will have a header. Again an example from `amenities_mtlines.do`:

<details>
<summary>example file header</summary>

```
********************************************************************************
* File name:		amenities_mtlines.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		Primarily a robustness focused file that tests the model 
*					against various amenities indicators to check if there is 
*					any discontinuity across boundaries.
*
* Inputs:		    mt_orthogonal_dist_100m_07-01-22_v2.dta
*				    dist_south_station_2022_09_29.csv
*                   transit_distance.csv
*                   soil_quality_matches.dta
*                   warren_group_walkability.dta
*                   within_town_analysis_data.dta
*
* Outputs:		    Table 2, Figure C.1 (a-e), Table C.1 means
*
* Date Created:		06/23/2021
*
* Last Updated:		01/09/2026
********************************************************************************
```
</details>

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

## File Descriptions

### `analysis_master_file.do`
**Description**:

Sets global file paths and Stata run options for analysis files. Can be set to 
run through all analysis files automatically, if needed.
			
[:card_index: file link](/code/analysis_files/analysis_master_file.do)

> [!IMPORTANT]
> This file ***must*** be run first as it sets global paths for all analysis 
> files. The most important globals to set are `$DATAPATH`, which needs to point to the `/data` directory, and `$EXPORTPATH`, which will store `.gph`, `.pdf` and `.tex` files.

**Inputs**:
n/a
			
**Outputs**:
n/a

---

### `analysis_within_town_setup.do`

**Description**
This setup file takes the cleaned warren group, costar, etc. data that is the 
result of the `./data_setup` `.do` files and prepares it for use in the analysis 
files. It handles a number of extra setup steps that were added over the life of 
the project. There is still plenty of other setup done within each analysis file,
this merely handles the bulk of the common setup steps.

It creates `within_town_analysis_data.dta`, which is the primary default input 
data for most analysis files.

[:card_index: file link](/code/analysis_files/analysis_within_town_setup.do)

**Inputs**
`final_dataset_10-28-2021.dta`
`warren_MAPC_all_unique_closest_stuff.dta`
`warren_sales_data.dta`
`CPI_2019.dta`
`costar_mf_destring.dta`
`costar_rent_hist.dta`

**Outputs**
`within_town_analysis_data.dta`

---

### `analysis_noroads_setup.do`
**Description**
This setup file is simialr in purpose to `analysis_within_town_setup.do` but
specific for no roads analysis, of which "main_noroads.do" is the only real 
analysis file run currently that uses it.

Its chief difference is that it uses `closest_boundary_matches_noroads.csv`
instead of `closest_boundary_matches.csv`

[:card_index: file link](/code/analysis_files/analysis_noroads_setup.do)

**Inputs**
`closest_boundary_matches_noroads.csv`
`final_dataset_10-28-2021.dta`
`warren_MAPC_all_unique_closest_stuff.dta`

**Outputs**
None, is coded to run as a sub-script of `main_noroads.do` with option to save 
`analysis_noroads_data.dta` in that file to save on repeat runtimes. 

---

### `analysis_town_comparison_setup.do`
**Description**
This setup file is simialr in purpose to `analysis_within_town_setup.do` but
specific for no roads analysis, of which `amenities_muni_boundary.do` is the 
only real analysis file run currently that uses it.

Its chief difference is that it is coded up based on 
`final_dataset_town_comparisons.dta` which uses different identifiers for 
lam_seg variables.

[:card_index: file link](/code/analysis_files/analysis_town_comparisons_setup.do)

**Inputs**
`dist_south_station_2022_09_29.csv`
`transit_distance.csv`
`soil_quality_matches.dta`
`warren_group_walkability.dta`
`final_dataset_town_comparisons.dta`

**Outputs**
None, is coded to run as a sub-script of `amenities_muni_boundary.do`

---

### `amenities_mtlines.do`
**Description**: 
Primarily a robustness check file that tests the model against various 
amenities indicators to check if there is any discontinuity across boundaries.

[:card_index: file link](/code/analysis_files/amenities_mtlines.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `warren_group_walkability.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table 2;
- Figure C.1
- Figure C.2
- Table C.1 means

---

### `amenities_muni_boundary.do`
**Description**
File is similar to amenities_mtlines.do except it compares across town 
boundaries instead of zoning boundaries. Calls [analysis_town_comparisons_setup.do](#analysis_town_comparisons_setupdo).

[:card_index: file link](/code/analysis_files/amenities_muni_boundary.do)

**Inputs**
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `warren_group_walkability.dta`
- `final_dataset_town_comparisons.dta`

**Outputs**
- Table C.2

---

### `bindingness.do`
**Description**
Analyzes bindingness of different regulations and boundaries with binding regs.

[:card_index: file link](/code/analysis_files/bindingness.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_moreregs.dta`
- `soil_quality_matches.dta`
- `warren_zoning_regulations_match.dta`
- `within_town_analysis_data.dta`
- `blocks_2010.dta`
- `acs_amenities.dta`

**Outputs**
- Table C.11

---

### `chars_mtlines.do`
**Description**
Handles all of the analysis on neighborhood characteristics acrsoss zoning 
boundaries.

[:card_index: file link](/code/analysis_files/chars_mtlines.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table C.8
- Figure 2
- Figure C.11(a)
- Table C.9
- Table C.10
- Figure C.11
- Figure C.5

---

### `counterfactual_01_spatial_heterogeneity.do`
**Description**
Runs the spatial heterogeneity file for boston zoning paper.

[:card_index: file link](/code/analysis_files/counterfactual_01_spatial_heterogeneity.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table D.1
- Table D.2 

and inputs for subsequent counterfactual files

---

### `counterfactual_02_train_station_means.do`
**Description**
This file is part 2 of the counterfactual analysis. It calculates means around 
train stations using the finalized set of warren group data.

[:card_index: file link](/code/analysis_files/counterfactual_02_train_station_means.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `within_town_analysis_data.dta`
- `station_boundary_dist.csv`
- `adm3_crs4269.dta`
- `cb_2018_25_cousub_500k_shp.dta`
- `cb_2018_25_cousub_500k.dta`
- `all_stations.csv`

**Outputs**
`train_station_means.dta`, which is an input for counterfactual #3.

---

### `counterfactual_03_means.do`
**Description**
This is part 3 of the counterfactual analysis.This file calcs a bunch of means 
at different levels (property, boundary, etc.). It then creates a town level 
version that also has train station level means attached. If run in order, on 
the same day, counterfactual output should be in the same folder.

[:card_index: file link](/code/analysis_files/counterfactual_03_means.do)

**Inputs**
- `mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `within_town_analysis_data.dta`
- `means_town_lvl.dta`
- `means_town_lvl_tomerge.dta`

**Outputs**
- `means_lpm.dta`
- `means_property_lvl.dta`
- `means_boundary_lvl.dta`
- `means_town_lvl.dta`
- `means_town_lvl_tomerge.dta`
- `means_town_train_stations.dta`

---

### `counterfactual_04_calculations_combined.do`
**Description**
This dofile imports the means calculated in prior counterfactual #3 prior and 
prepares the dataset to be merged with data on coefficients, calculates policy 
numbers and plots them on a  map.

[:card_index: file link](/code/analysis_files/counterfactual_04_calculations_combined.do)

**Inputs**
- `means_lpm.dta`
- `means_property_lvl.dta`
- `means_boundary_lvl.dta`
- `means_town_lvl.dta`
- `means_town_lvl_tomerge.dta`
- `means_town_train_stations.dta`

**Outputs**
- Figure 5

---

### `existence.do`
**Description**
Creates the A.3 scatter plot of number of boundaries per acre relative to various 
soc-econ measures.

[:card_index: file link](/code/analysis_files/existence.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `warren_group_walkability.dta`
- `within_town_analysis_data.dta`
- `blocks_2010.dta`
- `acs_amenities.dta`
- `muni_tax_rates.dta`
- `muni_land_area.dta`

**Outputs**
- Figure A.3

---

### `external_effects.do`

**Description**
Near-far external lot analysis following Turner et al. straight line boundaries 
(matt turner orthogonal lines) for house prices, rents. regression output is 
tables only. Printed w/o characteristics or exclusions (a) and w/ (b).

[:card_index: file link](/code/analysis_files/external_effects.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_moreregs.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table C.13

--- 

### `histogram.do`
**Description**
Makes a bunch of histograms and scatter plots for use in paper. Note the final 
alpha-num sequence may have changed.

[:card_index: file link](/code/analysis_files/histogram.do)

**Inputs**
- `within_town_analysis_data.dta`

**Outputs**
- Figure A.4
- Figure A.5

---

### `main_mtlines.do`
**Description**
Main regression specifications for the paper. Runs through multiple models and 
specifications. Produces almost all headline analysis in the paper.

[:card_index: file link](/code/analysis_files/main_mtlines.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Figure 1
- Figure C.3
- Figure C.4
- Figure 3
- Figure C.6
- Figure 4
- Figure C.7 


---

### `main_noroads.do`
**Description**
Runs a version of the main regression specifications for the paper that uses a 
version of the boundaries which removes all roads, not just the major ones, that
overlap boundaries

[:card_index: file link](/code/analysis_files/main_noroads.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `analysis_noroads_data.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `within_town_analysis_data.dta`
- `blocks_2010.dta`
- `acs_amenities.dta`

**Outputs**
- Figure C.12
- Appendix C.5.1

---

### `predicted_prices_mtlines.do`
**Description**
Calculates predicted prices in Table 2

[:card_index: file link](/code/analysis_files/predicted_prices_mtlines.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `analysis_noroads_data.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `walkability.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table 2 Panel (C)

---

### `residuals.do`
**Description**
Calculates residuals for Table C.3

[:card_index: file link](/code/analysis_files/residuals.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `analysis_noroads_data.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table C.3

---

### `robustness_mtlines.do`
**Description**
This file runs a myriad of robustness checks, not main line specifications. it 
has been trimmed down considerably. As such, the .do file 'part' numbers are not 
consecutive but they should align to prior versions of the file.

[:card_index: file link](/code/analysis_files/robustness_mtlines.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_moreregs.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `soil_quality_matches.dta`
- `warren_group_walkability.dta`
- `within_town_analysis_data.dta`
- `final_addon_regs_intersect.dta`
- `blocks_2010.dta`
- `acs_amenities.dta`

**Outputs**
- Figure C.12
- Figure C.8
- Figure C.9
- Table C.12
- Figure C.10

---

### `straight_v_walking_dist.do`
**Description**
Calculates the straight line (as the crow flies) distance from the closest 
property to a boundary to it's closest neighbor on the other side. Exports a .csv 
file to be used in walking_distances_orsm.ipynb to calculate the walking/effective 
distance between these two properties.

[:card_index: file link](/code/analysis_files/straight_v_walking_dist.do)

> [!NOTE]
> This file depends on the Python program [walking_distances_orsm.ipynb](../data_setup/python_programs/walking_distances/walking_distances_orsm.ipynb). 
> See file for details.
>
> You will need to have a working Python environment to run this file fully, and
> will need to manually move over to running python if running all parts of this
> file.

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_v2.dta`
- `within_town_analysis_data.dta`
- `walking_distance_inputs.csv`
- `walking_distance_outputs.csv`

**Outputs**
- Figure E.6

---

### `table_1_replication.do`
**Description**
Creates Table 1, thats about it.

[:card_index: file link](/code/analysis_files/table1_replication.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_moreregs.dta`
- `dist_south_station_2022_09_29.csv`
- `transit_distance.csv`
- `within_town_analysis_data.dta`
- `blocks_2010.dta`
- `acs_amenities.dta`

**Outputs**
- Table 1

---

### `within_town_mtlines.do`
**Description**
Runs specifications for gentle and high density units as well as some 
endogeneity checks.

[:card_index: file link](/code/analysis_files/within_town_mtlines.do)

**Inputs**
- `mt_orthogonal_dist_100m_07-01-22_moreregs.dta`
- `within_town_analysis_data.dta`

**Outputs**
- Table 3
- Table C.4
- Table C.5
- Table C.7
- Table C.6

---

### `within_town_mtlines_robustse.do`
**Description**
Runs specifications for gentle and high density units as well as some 
endogeneity checks. Similar to the other within town file but **with robust clustering.**

[:card_index: file link](/code/analysis_files/within_town_mtlines_robustse.do)

**Inputs**
`mt_orthogonal_dist_100m_07-01-22_moreregs.dta`
`within_town_analysis_data.dta`

**Outputs**
- Table 3
- Table C.4
- Table C.5
- Table C.7
- Table C.6

---

### `assessed_vs_sales.do`
**Description**
Creates the bin scatter of accessed vs sales price values figure.

[:card_index: file link](/code/analysis_files/miscellaneous_analysis_files/assessed_vs_sales.do)

**Inputs**
- MA_assessor_hist.dta
- CPI_2019.dta
- final_dataset_10-28-2021.dta

**Outputs**
- Figure E.4

---

### `figure_A6.do`

**Description**
Calculates the boundary length data found in the figure. The actual display part 
of the figure is made in ArcGIS.

[:card_index: file link](/code/analysis_files/miscellaneous_analysis_files/figure_A6.do)

**Inputs**
- `polylines_feasible_new.shp`
- `mapc_minus_muni_minus_river_minus_roads_new.shp`
- `mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp`
- `mt_orthogonal_lines.shp`

**Outputs**
select numbers found in Figure A.6

---

### `included_excluded_towns.do`
**Description**
Creates a figure showing which Metropolitan Area Planning Council cities and 
towns are included or excluded in the analysis.

[:card_index: file link](/code/analysis_files/miscellaneous_analysis_files/included_excluded_towns.do)

**Inputs**
- `cb_2018_25_cousub_500k_latlong.dta`
- `cb_2018_25_cousub_500k_latlong_shp.dta`
- `MAPC_town_list.dta`

**Outputs**
- Figure E.5

---

### `regulations_map.do`
**Description**
Shows the three main regulation types used in the paper (dwelling units per acre,
building height, and multifamily permitted) by levels of 'strictness'.

[:card_index: file link](/code/analysis_files/miscellaneous_analysis_files/regulations_map.do)

**Inputs**
- `cb_2018_25_cousub_500k_latlong.dta`
- `cb_2018_25_cousub_500k_latlong_shp.dta`
- `zoning_atlas_latlong.dta`
- `zoning_atlas_latlong_shp.dta`

**Outputs**
- Figure E.1
- Figure E.2
- Figure E.3

---

### `straight_line_boundary_map.do`
**Description**
Shows the actual zoning boundaries, drawn over MAPC city/town borders, by their
final identified type (e.g. only multifamily, only dupac, etc.)

[:card_index: file link](/code/analysis_files/miscellaneous_analysis_files/straight_line_boundary_map.do)

**Inputs**
- `cb_2018_25_cousub_500k_latlong.dta`
- `cb_2018_25_cousub_500k_latlong_shp.dta`
- `MAPC_town_list.dta`
- `mt_orthogonal_lines_4269.dta`
- `regulation_types.dta`

**Outputs**
- Figure A.7, Figure D.1 (color version)

---

### `warren_group_property_map.do`
**Description**
Shows just the vacant (no development but buildable) parcels of land in the 
MAPC region

[:card_index: file link](/code/analysis_files/miscellaneous_analysis_files/warren_group_property_map.do)

**Inputs**
- `cb_2018_25_cousub_500k_latlong.dta`
- `cb_2018_25_cousub_500k_latlong_shp.dta`
- `final_dataset_10-28-2021.dta`

**Outputs**
- Figure E.7


<br>
<br>

<a href="#top">Back to Top</a>