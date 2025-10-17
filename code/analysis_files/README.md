# Analysis Files Guide and Walkthrough

## Introduction
All of the Stata .do files located in this folder create output found in the current 
submitted ReStat version of the paper. This folder is *just* analaysis files and 
minor setup files related to that analysis. It does not contain any files 
pertaining to overall data setup for the paper. Those files can be found under 
./data_setup.

All output will be saved in a created directory called "./analysis" with 
sub-directories created for each .do file to store the specific output from that 
file. 

## Order of Files
The file *analysis_master_file.do* will run all of the .do files automatically.

The analysis files can be run individually in essentially any order. The **exceptions
are "analysis_within_town_setup.do" and the counterfactual files**. 
"analysis_within_town_setup.do" must be run only <ins>**once**</ins> in order to 
setup the data for use in the analysis (prior versions ran this file within each
analysis file which takes prolongs runtimes). The counterfactual files that must 
be run in the specific order they are named based on their numbering.

## Files in this Directory
- [analysis_master_file.do](#analysis_master_filedo)
- [analysis_within_town_setup.do](#analysis_within_town_setupdo)
- [analysis_noroads_setup.do](#analysis_noroads_setupdo)
- [analysis_town_comparison_setup.do](#analysis_town_comparison_setupdo)
- [amenities_mtlines.do](#amenities_mtlinesdo)
- [amenities_muni_boundary.do](#amenities_muni_boundarydo)
- [bindingness.do](#bindingnessdo)
- [chars_mtlines.do](#chars_mtlinesdo)
- [counterfactual_01_spatial_heterogeneity.do](#counterfactual_01_spatial_heterogeneitydo)
- [counterfactual_02_train_station_means.do](#counterfactual_02_train_station_meansdo)
- [counterfactual_03_means.do](#counterfactual_03_meansdo)
- [external_effects.do](#external_effectsdo)
- [histogram.do](#histogramdo)
- [main_mtlines.do](#main_mtlinesdo)
- [main_noroads.do](#main_noroadsdo)
- [predicted_prices_mtlines.do](#predicted_prices_mtlinesdo)
- [residuals.do](#esidualsdo)
- [robustness_mtlines.do](#robustness_mtlinesdo)
- [straight_v_walking_dist.do](#straight_v_walking_distdo)
- [within_town_mtlines_robustse.do](#within_town_mtlines_robustsedo)
- [within_town_mtlines.do](#within_town_mtlinesdo)

## Replication File Status
| File Name| Checked/Cleaned | Run Successfully by Mike | Replicates Results|
|----------|:------------:|:----------------:|:----------------:|
| amentities_mtlines.do | ✅ | ✅ |✅ |
| amenities_muni_boundary.do | ✅ | ✅ | ✅ |
| analysis_master_file.do | ✅ | ✅ | ✅ |
| analysis_noroads_setup.do | ✅ | ✅ | ✅ |
| analysis_town_comparisons_setup.do | ✅ | ✅ | ✅ |
| analysis_within_town_setup.do | ✅ | ✅ | ✅ |
| bindingness.do | ✅ | ✅ |✅ |
| chars_mtlines.do | ✅ | ✅ |✅ |
| counterfactual_01_spatial_heterogeneity.do | ✅ | ✅ | ✅ |
| counterfactual_02_train_station_means.do | ✅ | ✅ | ✅ |
| counterfactual_03_means.do (formerly means.do) | ✅ | ✅ | ✅ |
| counterfactual_04_calculations_combined.do | ✅ | run by AK ✅ | ✅ |
| external_effects.do | ✅ | ✅ | ✅ |
| histogram.do | ✅ | ✅ | ✅ |
| main_mtlines.do | ✅ | ✅ | ✅|
| main_noroads.do | ✅ | ✅ | ✅ |
| predicted_prices_mtlines.do | ✅ | ✅ | ✅|
| residuals.do | ✅ | ✅ | ✅ |
| robustness_mtlines.do | ✅ | ✅ | ✅ |
| straight_line_v_walking.do[^1] | ✅ | ✅ |✅ |
| within_town_mtlines.do | ✅ | ✅ | ✅ |
| within_town_mtlines_robustse.do | ✅ | ✅ |  ✅ |

## File descriptions

### analysis_master_file.do
Sets all file paths and can run all ./analysis_files .do files automatically.

### analysis_within_town_setup.do
This setup file takes the cleaned warren group, costar, etc. data that is the 
result of the ./data_setup .do files and prepares it for use in the analysis files.

### analysis_noroads_setup.do
This setup file is specific for no roads analysis, of which "main_noroads.do" 
is the only real analysis file run currently.

### analysis_town_comparison_setup.do
Similar to noroads_setup but for "amenities_muni_boundary.do",

### amenities_mtlines.do
This is primarily a robustness focused file that tests the model against various 
amenities indicators to check if there is any discontinuity across boundaries.

### amenities_muni_boundary.do
Is the same as amenities except comparing across town boundaries instead of 
zoning boundaries.

### bindingness.do
Analyzes bindingness of different regulations and boundaries with binding regs.

### chars_mtlines.do
Examines charactistic variables across zoning boundaries. Exports a bunch of 
tables and graphs.

### counterfactual_01_spatial_heterogeneity.do
Runs the spatial heterogeneity file for boston zoning paper.
Regression 1: linear probability rents and prices
Regression 2: units spatial heterogeneity

### counterfactual_02_train_station_means.do
This file is part 2 of the counterfactual analysis. It calculated means around 
train stations using the finalized set of warren group data.

### counterfactual_03_means.do
This is part 3 of the counterfactual analysis. Some analysis might be used in 
other parts of the paper.					

This file calcs a bunch of means at different levels (property, boundary, etc.). 
It then creates a town level version that also has train station level means 
attached. If run in order, on the same day, counterfactual output should be in 
the same folder.


### external_effects.do
A shortened and cleaned version of the external effects file, last run by MC on 2/3/2025. 

Near-far external lot analysis following Turner et al. striaght line boundaries 
(matt turner orthogonal lines method) for house prices, rents. regression output 
is tables only. Printed w/o characteristics or exclusions (a) and w/ (b).


### histogram.do
Makes a bunch of histograms and scatter plots.

### main_mtlines.do
Main regression specifications for the paper. Runs through multiple models and 
specifications. Has been cut down to just include versions used in the paper.

### main_noroads.do
Basically the same as main_mtlines but for boundaries w/ no road overlaps.

### predicted_prices_mtlines.do
This is a shortened version of older predicted prices files, only the relevant 
bits found in the final analysis were kept.

It otherwise has not been changed so the updated date is the same as the longer 
version last run with MC on 10/18/2024.

### residuals.do
Does something with residuals, IDK it is confusing to me.

### robustness_mtlines.do
This file runs a myriad of robustness checks, not main line specifications. 
it has been trimmed down considerably. As such, the .do file 'part' numbers are not consecutive but 
they should align to prior versions of the file.

### straight_v_walking_dist.do
Calculates the straight line (as the crow flies) distance from the closest 
property to a boundary to it's closest neighor on the other side. Exports a 
.csv file to be used in <python program> to calculate the walking/effective
distance between these two properties.

### within_town_mtlines_robustse.do
Runs specifications for gentle and high density units as well as some endogeneity 
checks. Similar to the other within  town file but now with robust standard errors. 
Section part numbers are based on older versions and so are not consecutive but 
are preserved for references across files.

### within_town_mtlines.do
Runs specifications for gentle and high density units as well as some endogeneity 
checks. Section part numbers are based on older versions and so are not 
consecutive but are	preserved for references across files.

