********************************************************************************
* File name:		analysis_master_file.do
*
* Project title:	Boston Zoning Project
*
* Description:
* 				
* Inputs:
*				
* Outputs:
*
* Created:
* Last updated:
********************************************************************************

********************************************************************************
** Clear data, define settings
********************************************************************************
clear all
log close _all

set more off, perm
set type double
set seed 123456
set linesize 255
set graphics on

pause off

********************************************************************************
** Define paths
********************************************************************************
/* Description of file paths:

WORKINGDIR - This should be the main working directory of the project, with 
any and all subsequent filepaths found within this directory.

DATAPATH - This should be the main folder storing input data. For the analysis
.do files this will encompass the following:
    - within_town_analysis.dta
    - 2
    - 3
    - n

EXPORTPATH - This path will vary and is defined seperately within each .do file. 
The will be unique to the .do file and will take the form of "./<.do file name>" 
and will store any output including, logs, figures, tables, datasets, etc.


The follwing is the recommended folder structure:
|-- ./project folder (this will be WORKINGDIR)
     |-- ./analysis (subdirectories will be created and defined as EXPORTPATH within corresponding .do files)
     |--  |-- ./analysis_within_town_setup_output
     |    |-- ./bindingness_output
     |    |-- ./counterfactual_output     
     |    |-- ./external_effects_output
     |    |-- ./predicted_prices_mtlines_output
     |    |-- 
     |    |-- 
     |    |-- 
     |-- ./code (this will be $DOPATH)
     |    |-- analysis_master_file.do
     |    |-- analysis_within_town_setup.do
     |-- ./data (this will be DATAPATH)

*/

global WORKINGDIR "/shared/boston_zoning/working_paper/replication_package"

global DATAPATH "/shared/boston_zoning/working_paper/replication_package/data"

global DOPATH "/shared/boston_zoning/working_paper/replication_package/code"

global EXPORTPATH "/shared/boston_zoning/working_paper/replication_package/analysis"

cd $WORKINGDIR


********************************************************************************
** Run analysis .do files
********************************************************************************
/* Description of .do file order:
Generally the analysis .do files can be run in any order. There are two (2) 
exceptions, however. 

1) analysis_within_town_setup.do MUST be run first as it creates a .dta file 
that is used throughout the analysis files.

2) the counterfactual files must be run in the order noted by their numerical 
infix, i.e. counterfactual_01.. is run first, then counterfactual_02.., etc.

All other analysis .do files can be run in any order.
*/

do "counterfactual_01_spatial_hetergeneity.do"

do "counterfactual_02_train_station_means.do"

do "counterfactual_03_means.do"








