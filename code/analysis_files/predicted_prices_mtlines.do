* start here
clear all
log close _all
set linesize 255

local name = "predicted_prices_mtlines"  // <--- change when necessry

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
* File name:		predicted_prices_mtlines.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		Calculates predicted prices in Table 2
*				
* Inputs:			mt_orthogonal_dist_100m_07-01-22_v2.dta
*					transit_distance.csv
*					soil_quality_matches.dta
*					warren_group_walkability.dta
*
* Outputs:			Table 2 panel C
*
* Created:			06/10/2024
* Updated:			01/31/2026
********************************************************************************


********************************************************************************
** load and tempsave the mt lines flag data
********************************************************************************
use "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load and tempsave the transit data
********************************************************************************
import delimited "$DATAPATH/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/transit_distance.csv", clear stringcols(_all)

merge m:1 station_id using `dist_south_station'
		
		* merge error check
		sum _merge
		drop if _merge == 2
		drop _merge
	
keep prop_id station_id station_name distance_m_* length_m

destring prop_id distance_m_* length_m, replace

gen transit_dist_m = distance_m_man + length_m

tempfile transit
save `transit', replace


********************************************************************************
** load and tempsave the soil data
********************************************************************************
use "$DATAPATH/soil_quality_matches.dta", clear  // bringing back the old soil data

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace

********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear

* merge on transit data
merge m:1 prop_id using `transit'
	
	/* * merge error check
	sum _merge
	assert `r(N)' ==  3642292
	assert `r(sum_w)' ==  3642292
	assert `r(mean)' ==  2.878361207723049
	assert `r(Var)' ==  .1068428258243096
	assert `r(sd)' ==  .3268682086473226
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  10483832 */
	
	drop if _merge == 2
	drop _merge

* merge on soil quality data
merge m:1 prop_id using `soil'
	
	/* * merge error check
	sum _merge
	assert `r(N)' ==  3642292
	assert `r(sum_w)' ==  3642292
	assert `r(mean)' ==  2.878361207723049
	assert `r(Var)' ==  .1068428258243096
	assert `r(sd)' ==  .3268682086473226
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  10483832 */

	drop if _merge == 2
	drop _merge

* merge on mt lines to keep straight line properties
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	/* * merge error check
	sum _merge
	assert `r(N)' ==  3400297
	assert `r(sum_w)' ==  3400297
	assert `r(mean)' ==  2.940873106084557
	assert `r(Var)' ==  .0556309206919615
	assert `r(sd)' ==  .235862079809285
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9999842 */

	drop if _merge == 2
	drop _merge

keep if straight_line == 1  // <-- drops non-straight line properties

* merge on walkscore variables 
merge m:1 prop_id using `walkscore', 
    sum _merge
    drop if _merge == 2
    drop _merge 

* drop out of scope years
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** gen amenity variables
********************************************************************************
gen dist_school = closest_school_dist
gen dist_center = closest_city_dist
gen dist_road = closest_road_dist
gen dist_river = closest_river_dist
gen dist_space = closest_green_dist

gen transit_dist = transit_dist_m/1609

gen soil_avgslope = avg_slope
gen soil_slope15 = slope_15
gen soil_avgrestri = avg_restri
gen soil_avgsand = avg_sand
gen soil_avgclay = avg_clay


********************************************************************************
** placebo check - predict outcomes at boundaries
********************************************************************************
* define dist vars macro 
global dist_vars dist_school dist_center dist_road dist_river dist_space transit_dist

* soil macro
global soil_vars soil_avgslope soil_slope15 soil_avgrestri soil_avgsand soil_avgclay

* define new macro for walkscore vars
global walk_vars_0 d2b_e8mixa natwalkind 

** sales price
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_0: reg log_saleprice $dist_vars $walk_vars_0 $soil_vars i.lam_seg i.last_saleyr if `regression_conditions'
predict amenity_price_0 if e(sample), xb

* predict prices, amenity vars w/o walkability
quietly eststo price_1: reg log_saleprice $dist_vars d2b_e8mixa $soil_vars i.lam_seg i.last_saleyr if `regression_conditions'

predict amenity_price_1 if e(sample), xb

** rents
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* NEW
quietly eststo rent_0: reg log_mfrent $dist_vars $walk_vars_0 $soil_vars i.lam_seg i.year if `regression_conditions'
predict amenity_rent_0 if e(sample), xb

local i = 0

esttab price_`i' rent_`i', ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Sale Year f.e.=*last_saleyr" "Year f.e.=*year") interaction(" X ") ///
label mtitles("price" "rent") ///
title("Predicted price/rent coefficients") 


********************************************************************************
* predicted sales prices, all amenties + w/o walkscore
********************************************************************************
* regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

*[PAPER SOURCE]: For Table 2 Panel (C)
local j = 0
	quietly eststo price_du_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_duhe_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_mfdu_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_mf_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_mfhe_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_he_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)


*[PAPER SOURCE]: For Table 2 Panel (C)

* clustered
local i = 0
	esttab price_du_`i' price_duhe_`i' price_mfdu_`i' price_mf_`i' price_mfhe_`i' price_he_`i' using "$EXPORTPATH/predicted_prices_table_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Amenity sales prices, new amenity list") 
				

********************************************************************************
** predicted rents, all amenities + w/o walkscore
********************************************************************************
* regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

*[PAPER SOURCE]: For Table 2 Panel (C)
local j = 0
	quietly eststo rent_du_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_duhe_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_he_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

	
*[PAPER SOURCE]: For Table 2 Panel (C)
* (rent), clustered
local i = 0
	esttab rent_du_`i' rent_duhe_`i' rent_he_`i' using "$EXPORTPATH/predicted_rents_table_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Amenity rents prices, new amenity list") 
					

********************************************************************************
** end
********************************************************************************
display "finished!" 
log close
clear all 
