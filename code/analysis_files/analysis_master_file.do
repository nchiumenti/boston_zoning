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
global ANALYSIS_PATH "/shared/boston_zoning/working_paper/replication_package/analysis"


********************************************************************************
** Run analysis .do files
cd $DOPATH

scalar UPDATE_wInTownSetup_DATA=0
scalar RUN_COUNTERFACTUALS=1


********************************************************************************
*===========================
/*make lists of do files*/

local all_do_files : dir . files "*.do"
/*Remove setup files from main list*/
local setup_do_files : dir . files "*setup.do" //setup files into list
local setup_do_files "`setup_do_files' analysis_master_file.do" //adding current master file
local do_files_to_run : list all_do_files - setup_do_files //remove setup list to get all other dos
local do_files_to_run : list sort  do_files_to_run 

/* 
Description of .do file order
Generally the analysis .do files can be run in any order...

/*===========================
There are two (2) exceptions, however...
1) analysis_within_town_setup.do MUST be run first as it creates a .dta file 
that is used throughout the analysis files. Once file is created, this can be turned off. */
*/

if UPDATE_wInTownSetup_DATA {
	do "analysis_within_town_setup.do"
}
*===========================>

*===========================<
/* 2) the counterfactual files must be run in the order noted by their numerical 
infix, i.e. counterfactual_01.. is run first, then counterfactual_02.., etc. */

#delimit ;
local counterfactuals 
	counterfactual_01_spatial_heterogeneity.do
	counterfactual_02_train_station_means.do 
	counterfactual_03_means.do
;
#delimit cr

local not_counterfactuals : list do_files_to_run - counterfactuals //remove counterfactual dos 
foreach ncf of local not_counterfactuals {
	di "`ncf'"
}
if RUN_COUNTERFACTUALS {
	foreach cfact of local counterfactuals {
		do `cfact'
	}
}

*===========================<
/*3) All other analysis .do files can be run in any order. */

*===========================>
#delimit ;
local skip_success
;
local skip_fail
;
//predicted_prices_mtlines -- success after editing SHAPEPATH, and forval errors - 2025-04-11
local skip_list `skip_success' `skip_fail';
#delimit cr



if !missing("`skip_list'") {
	local not_counterfactuals : list not_counterfactuals - skip_list
}
local i = 1
foreach ncf of local not_counterfactuals {
	di "$$$<"
	di "FindErrorInDoFile_`i'"
	di "Running: `ncf'"
	do "`ncf'"
	local ++i
}
*===========================>

//stop 

cd "${ANALYSIS_PATH}"
local all_output_dirs : dir . dirs "*output"
foreach outd of local all_output_dirs {
		zipfile "${ANALYSIS_PATH}/`outd'",saving("${ANALYSIS_PATH}/`outd'.zip",replace )
}






