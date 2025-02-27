********************************************************************************
* File name:		"00_wp_master.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Current working directories are S drive for working paper folders
* 				
* Inputs:		n/a
*				
* Outputs:		n/a
*
* Created:		12/08/2020
* Last updated:		12/22/2022
********************************************************************************

clear all

log close _all

set more off, perm

set type double

set seed 123456

set linesize 255

pause off

set graphics on

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








