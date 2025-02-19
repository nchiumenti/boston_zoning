clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="straight_v_walking_dist" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace



** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES SETUP VERSION **


********************************************************************************
* File name:		"straight_v_walking_dist.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Calculates the straight line (as the crow flies) distance
*			from the closest property to a boundary to it's closest 
*			neighor on the other side. Exports a .csv file to be used
*			in <python program> to calculate the walking/effective
*			distance between these two properties.
* 				
* Inputs:		./mt_orthogonal_dist_100m_07-01-22_v2.dta
*			./final_dataset_10-28-2021.dta
*				
* Outputs:		
*
* Created:		03/24/2022
* Updated:		10/17/2022
********************************************************************************


********************************************************************************
** load the mt lines data
********************************************************************************
use "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load final dataset
********************************************************************************
use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
run "$DOPATH/postQJE_within_town_setup.do"


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* checks for errors in merge
	sum _merge
	assert `r(N)' ==  3400297
	assert `r(sum_w)' ==  3400297
	assert `r(mean)' ==  2.940873106084557
	assert `r(Var)' ==  .0556309206919615
	assert `r(sd)' ==  .235862079809285
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9999842

	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties

stop
tempfile save_point
save `save_point', replace


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
assert `r(N)' ==  12042
assert `r(sum_w)' ==  12042
assert `r(mean)' ==  2014.035293140674
assert `r(Var)' ==  6.630844648717998
assert `r(sd)' ==  2.575042649883298
assert `r(min)' ==  2010
assert `r(max)' ==  2018
assert `r(sum)' ==  24253013

sum crow_dist
assert `r(N)' ==  12042
assert `r(sum_w)' ==  12042
assert `r(mean)' ==  .1084696652930108
assert `r(Var)' ==  .0308764188208655
assert `r(sd)' ==  .1757168711901778
assert `r(min)' ==  .000390443351853
assert `r(max)' ==  2.186940493159569
assert `r(sum)' ==  1306.191709458436
		
* keep 2018 data only
keep if year == 2018

* export data for use in <python program>
export delimited using "$DATAPATH/walking_distance_inputs.csv", replace


********************************************************************************
** after time passes with the python program
********************************************************************************


********************************************************************************
** import the effective distance python output
********************************************************************************
import delimited "$DATAPATH/walking_distance_outputs.csv", clear stringcols(_all)

destring distance_m crow_dist, replace

gen walking_dist_mi = distance_m * 0.000621 // <-- convert meters to miles

summarize walking_dist_mi, detail

keep if inrange(walking_dist_mi, 0, r(p99))


binscatter walking_dist_mi crow_dist , n(20) ///
	xlabel(0(.1).8, gmin gmax) ///
	ylabel(0(.1)1.2, gmin gmax) ///
	xtitle("{bf:Striaght Line Distance (miles)}") ///
	ytitle("{bf:Walking Route Distance (miles)}")
	
	graph save "$FIGPATH/straight_v_walking_dist.gph", replace
	graph export "$FIGPATH/straight_v_walking_dist.pdf", replace
