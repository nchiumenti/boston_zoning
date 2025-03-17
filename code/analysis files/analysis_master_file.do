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

do ""

do ""









/* old code below this point






* set paths, passed to called .do files
global DATAPATH "/shared/boston_zoning/working_paper/data"

global LOGPATH = "/shared/boston_zoning/working_paper/wp_logs"

global DOPATH "/shared/boston_zoning/working_paper/wp_dofiles"

global SHAPEPATH "/shared/boston_zoning/working_paper/data/shapefiles"

global FIGPATH "/shared/boston_zoning/working_paper/wp_figures"

global EXT "pdf"

cd "$DOPATH"

// copy "/shared/warren/assessor/data/MA_assessor_annual.dta" "$DATAPATH/warren/originals/MA_assessor_annual.dta", replace
// copy "/shared/warren/data/dta/MA/MA_prop_merged.dta" "$DATAPATH/warren/originals/MA_prop_merged.dta", replace

stop




********************************************************************************
** do file order
********************************************************************************
* under ./data setup

do "$DOPATH/data_setup/town_lists_export.do"

// do "$DOPATH/data_setup/warren_geocode_fixes.do" // <-- only run this if absolutely necessary

do "$DOPATH/data_setup/10_warren_data_compile.do"

do "$DOPATH/data_setup/20_boundary_matches.do"

do "$DOPATH/data_setup/30_density_measures.do"

do "$DOPATH/data_setup/40_costar.do"

do "$DOPATH/data_setup/50_nhpd.do"

do "$DOPATH/data_setup/60_ch40b.do"

do "$DOPATH/data_setup/70_final_dataset.do"

do "$DOPATH/data_setup/80_amenity_datasets.do"




do "$DOPATH/12_chapter40b.do" 		// compiles the Chapter 40B property data, calls sub dofile 12a

do "$DOPATH/13_costar.do"		// compiles CoStar property data

* main data set up files
do "$DOPATH/15_main_dataset.do" 	// compiles main warren data set, calls 15a 15b 15c

do "$DOPATH/16_boundary_matches.do"	// matched warren properties to zoning reg data

do "$DOPATH/17_density_measures.do"	// calcs unit density measures

* crosswalk files
do "$DOPATH/18a_ch40b_to_warren_xwalk.do"	// crosswalk for ch40b properties

do "$DOPATH/18b_costar_to_warren_xwalk.do" 	// crosswalk for costar properties

// do "$DOPATH/18c_nhpd_to_warren_xwalk.do"	// NO LONG USED, crosswalk for nhpd properties

do "DOPath/18d_costar_rent_history.do"		// costar historic rent data

* final data set
do "$DOPATH/19_final_dataset.do"	// compiles everyhting together to make the final working dataset

** in text analysis

** final figures and tables

do "30_figure1_allregs_map.do" // fig 1

do "36_figure_2.do" // figure 2

do "32_figure3_props_map.do" // figure 3

do "33_rd_graphs.do" // figs 4 and 5

do "35_map_appendix1.do"








