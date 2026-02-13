* start here
clear all
log close _all
set linesize 255

local name ="straight_v_walking_dist"  // <--- change when necessry

* creates an output directory if none exists
global EXPORTPATH "$WORKINGDIR/analysis/`name'_output"

capture confirm file "$EXPORTPATH"

if _rc != 0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

* start log file
local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

log using "$EXPORTPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
* File name:		straight_v_walking_dist.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		Calculates the straight line (as the crow flies) distance
*					from the closest property to a boundary to it's closest 
*					neighor on the other side. Exports a .csv file to be used
*					in walking_distances_orsm.ipynb to calculate the 
*					walking/effective distance between these two properties.

* Inputs:			mt_orthogonal_dist_100m_07-01-22_v2.dta
*					within_town_analysis_data.dta
*					walking_distance_inputs.csv
*					walking_distance_outputs.csv
*				
* Outputs:			Figure E.6
*
* Created:			03/24/2022
* Updated:			01/13/2026
********************************************************************************


********************************************************************************
** load the mt lines data
********************************************************************************
use "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear

* merge on mt lines to keep straight line properties
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* checks for errors in merge
	sum _merge
	drop if _merge == 2
	drop _merge

keep if straight_line == 1  // <-- drops non-straight line properties


********************************************************************************
** calculate straight line distance
********************************************************************************
* gen propert address
gen address = string(st_num) + " " + street + " " + city + " " + strofreal(zipcode, "%05.0f")

* trim dataset
keep year prop_id address boundary_using_id boundary_dist boundary_side warren_longitude warren_latitude

* keep the closest property to each boundary on either side
bysort year boundary_using_id boundary_side (boundary_dist): keep if _n == 1

* reshape file at the boundary id level
reshape wide prop_id address boundary_dist warren_longitude warren_latitude, i(year boundary_using_id) j(boundary_side) string

* drop observations with no left/right comparison
drop if prop_idLEFT == . | prop_idRIGHT == .

* calculate straight line distance
geodist warren_latitudeLEFT warren_longitudeLEFT warren_latitudeRIGHT warren_longitudeRIGHT, gen(crow_dist) miles

* error check
sum year

sum crow_dis
		
* keep 2018 data only
keep if year == 2018

* export data for use in <python program>
export delimited using "$DATAPATH/walking_distance_inputs.csv", replace


********************************************************************************
** after time passes with the python program
********************************************************************************
/* This will require running the walking_distances_orsm.ipynb python program to 
find the closest distance between a property and it's closest neighbor on the 
other side of the boundary it is assigned to*/


********************************************************************************
** import the effective distance python output
********************************************************************************
import delimited "$DATAPATH/walking_distance_outputs.csv", clear stringcols(_all)

destring distance_m crow_dist, replace

gen walking_dist_mi = distance_m * 0.000621  // <-- convert meters to miles

summarize walking_dist_mi, detail

keep if inrange(walking_dist_mi, 0, r(p99))


********************************************************************************
** Create a bin scatter plot for use in the paper
********************************************************************************
* [PAPER SOURCE] Figure E.6
binscatter walking_dist_mi crow_dist , n(20) ///
	xlabel(0(.1).8, gmin gmax) ///
	ylabel(0(.1)1.2, gmin gmax) ///
	xtitle("{bf:Striaght Line Distance (miles)}") ///
	ytitle("{bf:Walking Route Distance (miles)}")
	
	graph save "$EXPORTPATH/straight_v_walking_dist.gph", replace


********************************************************************************
** end
********************************************************************************
log off
log close
clear all

** convert gph to pdfs
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files' {	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 
