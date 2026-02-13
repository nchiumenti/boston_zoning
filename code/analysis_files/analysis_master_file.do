********************************************************************************
* File name:		analysis_master_file.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:      Sets global file paths and Stata run options for analysis 
*					files. Can be set to run through all analysis files 
*					automatically, if needed.
* 				
* Inputs:           none
*				
* Outputs:          none
*
* Last updated:     01/09/2026
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
** Global Paths
********************************************************************************
/* 
Description of global file paths:

WORKINGDIR -- This should be the main working directory of the project, with 
any and all subsequent filepaths found within this directory.

DATAPATH -- This should be the main folder storing input data.

EXPORTPATH -- This path will be unique to the .do file and will take the form of 
"./<.do file name>" and will store any output including, logs, figures, 
tables, datasets, etc.

DOPATH -- This is the directory containing all of the analysis .do files.

ANALYSIS_PATH -- Is the same as EXPORTPATH but can be used to zip all output
into single folder for sharing and/or easy upload.

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
global EXPORTPATH "/shared/boston_zoning/working_paper/replication_package/analysis"
global DOPATH "/shared/boston_zoning/working_paper/replication_package/code"
global ANALYSIS_PATH "/shared/boston_zoning/working_paper/replication_package/analysis"

 
********************************************************************************
** Run analysis .do files
********************************************************************************
/* the below code should run all of the analysis .do files instead of running 
them individually. It is not recommended to use this method unless you are absolutely
sure all data dependencies are present. */

cd $DOPATH

scalar UPDATE_wInTownSetup_DATA=0  // set to 1 if updating the within_town_setup.dta file
scalar RUN_COUNTERFACTUALS=1  // set to 1 if running the counterfactual files (these must be run in order)


** make lists of do files in DOPATH
local all_do_files : dir . files "*.do"

** remove setup files from main list
local setup_do_files : dir . files "*setup.do"  // store setup files into list
local setup_do_files "`setup_do_files' analysis_master_file.do"  // add current master file
local do_files_to_run : list all_do_files - setup_do_files  // remove setup list to get all other dos
local do_files_to_run : list sort  do_files_to_run

/* 
Description of .do file order:

Generally the analysis .do files can be run in any order...
There are two (2) exceptions, however...
*/

/* 
Exception (1)

analysis_within_town_setup.do MUST be run first as it creates a .dta file 
that is used throughout the analysis files. Once file is created, this can be turned off. 
*/

if UPDATE_wInTownSetup_DATA {
	do "analysis_within_town_setup.do"
}

/* 
Exception (2)

The counterfactual files must be run in the order noted by their numerical 
infix, i.e. counterfactual_01.. is run first, then counterfactual_02.., etc.
*/

* define list of counterfactual .do files
#delimit ;
local counterfactuals 
	counterfactual_01_spatial_heterogeneity.do
	counterfactual_02_train_station_means.do 
	counterfactual_03_means.do
;
#delimit cr

* remove counterfactual files from overall list of .do files
local not_counterfactuals : list do_files_to_run - counterfactuals
foreach ncf of local not_counterfactuals {
	di "`ncf'"
}

* run counterfactual files
if RUN_COUNTERFACTUALS {
	foreach cfact of local counterfactuals {
		do `cfact'
	}
}

********************************************************************************
** Run all other analysis .do files
** Note: All other analysis .do files can be run in any order.
********************************************************************************
* define a list of skipped files (only used when error testing)
#delimit ;
local skip_success
;
local skip_fail
;
local skip_list `skip_success' `skip_fail';
#delimit cr

* if not in skip list and not a 
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






