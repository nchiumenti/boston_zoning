********************************************************************************
* File name:		"replication_package_master_analysis.do"
*
* Project title:	Greater Boston Zoning Project
*
* Description:		This .do file is a master .do file that calls all relevant
*                   analysis files in the order they should be run. It is meant
*                   to unify the disparate analysis files in one place and make 
*                   it easier to run. 
* 				
* Inputs:           None		
*				
* Outputs:		    None
*
* Created:		    01/21/2025
* Updated:		    04/30/2025
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


//global DOPATH "/shared/boston_zoning/working_paper/wp_dofiles"
global DOPATH "~/rda-projects/clones_dept/boston_zoning/code" //m corbett's home dir - June 4, 2025


global SHAPEPATH "/shared/boston_zoning/working_paper/data/shapefiles"

global FIGPATH "/shared/boston_zoning/working_paper/wp_figures"

global EXT "pdf"

cd "$DOPATH" 

********************************************************************************
** Analysis .do files
********************************************************************************

** AMRITA: please copy the names of the .do files you have finished/shortened below here**

*all can be found in analysis_files_short
*postrestat_rd_main_mtlines
*postrestat_rd_chars_mtlines
*postrestat_rd_robustness_mtlines
*postREstat_rd_amenities_mtlines
*postREstat_rd_amenities_muni_boundary 
*postREStat_predicted_prices_mtlines 
*bindingness
*residuals
*postrestat_within_town_mtlines
*postrestat_within_town_mtlines_robustse (same folder as file above) - we have not run this with Mike but it's an exact replica of the other file (with different standard errors), so if that runs, this should
*postrestat_rd_main_noroads  (@nick, the setup here needs some work but I didn't want to delete things we may need. ultimately we can delete everything related to calculating tract weights)

