clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postQJE_predicted_prices_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_mtlines_`date_stamp'.log", replace

********************************************************************************
* File name:		"postQJE_predicted_prices_mtlines.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Post QJE updates
*			predicted prices remformatted
* 			striaght line boundaries (matt turner orthogona lines)
*			
*			Contents:
*				Part 1: predict prices/rents/units
*				Part 2: predicted sales prices, all amenties
*				Part 3: predicted rents, all amenities
*				Part 4: predicted sales prices, amenities w/o sand + clay   
*				Part 5: predicted rents prices, amenities w/o sand + clay 
*				Part 6: Costar rents only, all amenties
*				
* Inputs:		./mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta
*			./train_stops/dist_south_station_2022_09_29.csv
*			./soil_quality/soil_quality_matches.dta
*			./final_dataset_10-28-2021.dta
*				
* Outputs:		lots of graphs
*
* Created:		06/10/2024
* Updated:		09/23/2024
********************************************************************************

* create a save directory if none exists
global RDPATH "$FIGPATH/`name'_`date_stamp'"

capture confirm file "$RDPATH"

if _rc!=0 {
	di "making directory $RDPATH"
	shell mkdir $RDPATH
}

cd $RDPATH


********************************************************************************
** load and tempsave the mt lines flag data
********************************************************************************
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load and tempsave the transit data
********************************************************************************
import delimited "$DATAPATH/train_stops/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/train_stops/transit_distance.csv", clear stringcols(_all)

merge m:1 station_id using `dist_south_station'
		
		/* * merge error check
		sum _merge
		assert `r(N)' ==  821248
		assert `r(sum_w)' ==  821248
		assert `r(mean)' ==  2.999986605751247
		assert `r(Var)' ==  .0000133940856566
		assert `r(sd)' ==  .0036597931166456
		assert `r(min)' ==  2
		assert `r(max)' ==  3
		assert `r(sum)' ==  2463733 */

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
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear // bringing back the old soil data

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


/* PRESERVE THE CODE FOR THE UPDATED SOIL DATA BUT DONT USE IT
********************************************************************************
** load and tempsave the soil data //new variables added 19.05.2024
********************************************************************************
** first, load the original soil data that is matched to warren group properties
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear      /*POSTRESTAT NEED TO ADD NEW SOIL AMENITIES HERE */

keep prop_id unique_id

* second, merge on the expanded soil variables
merge 1:1 unique_id using "$SHAPEPATH/soil_quality/recoded_final_soil_parcel_data.dta", keep(1 3)

* keep the important soil quality variables
keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay avg_drainclass avg_drainclass_1 avg_drainclass_2 avg_drainclass_3 avg_drainclass_4 avg_dwellwb avg_dwellwb_1 avg_hydrolgrp avg_hydrolgrp_1 avg_hydrolgrp_2 avg_roads avg_roads_1 avg_flooding avg_flooding_1 avg_flooding_2 avg_flooding_3 avg_flooding_4 avg_ponding avg_ponding_1 avg_ponding_2 avg_corconcret avg_corconcret_1 avg_kfactrf avg_kfactws

* destring the soil quality variables
destring  avg_slope slope_15 avg_restri avg_sand avg_clay avg_drainclass avg_drainclass_1 avg_drainclass_2 avg_drainclass_3 avg_drainclass_4 avg_dwellwb avg_dwellwb_1 avg_hydrolgrp avg_hydrolgrp_1 avg_hydrolgrp_2 avg_roads avg_roads_1 avg_flooding avg_flooding_1 avg_flooding_2 avg_flooding_3 avg_flooding_4 avg_ponding avg_ponding_1 avg_ponding_2 avg_corconcret avg_corconcret_1 avg_kfactrf avg_kfactws, replace

* recode soil quality variable missings
replace avg_drainclass= . if avg_drainclass == 1000
replace avg_drainclass_1 = . if avg_drainclass_1 == 1000
replace avg_drainclass_2 = . if avg_drainclass_2 == 1000
replace avg_drainclass_3 = . if avg_drainclass_3 == 1000
replace avg_drainclass_4 = . if avg_drainclass_4 == 1000
replace avg_dwellwb = . if avg_dwellwb == 1000
replace avg_dwellwb_1 = . if avg_dwellwb_1 == 1000
replace avg_hydrolgrp = . if avg_hydrolgrp == 1000
replace avg_hydrolgrp_1 = . if avg_hydrolgrp_1 == 1000
replace avg_hydrolgrp_2 = . if avg_hydrolgrp_2 == 1000
replace avg_roads = . if avg_roads == 1000
replace avg_roads_1 = . if avg_roads_1 == 1000
replace avg_flooding = . if avg_flooding == 1000
replace avg_flooding_1 = . if avg_flooding_1 == 1000
replace avg_flooding_2 = . if avg_flooding_2 == 1000
replace avg_flooding_3 = . if avg_flooding_3 == 1000
replace avg_flooding_4 = . if avg_flooding_4 == 1000
replace avg_ponding = . if avg_ponding == 1000
replace avg_ponding_1 = . if avg_ponding_1 == 1000
replace avg_ponding_2 = . if avg_ponding_2 == 1000
replace avg_corconcret = . if avg_corconcret == 1000
replace avg_corconcret_1 = . if avg_corconcret_1 == 1000
replace avg_kfactrf = . if avg_kfactrf == 1000
replace avg_kfactws = . if avg_kfactws == 1000

* drop if caution flag == 1
drop if caution == 1

tempfile soil
save `soil', replace
*/

********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace

********************************************************************************
** load final dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
// run "$DOPATH/postREStat_within_town_setup.do"

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear //created with "$DOPATH/postREStat_within_town_setup_07102024.do"


********************************************************************************
** merge on transit data
********************************************************************************
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

	
********************************************************************************
** merge on soil quality data
********************************************************************************
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

	
********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
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

keep if straight_line == 1 // <-- drops non-straight line properties


********************************************************************************
** merge on walkscore variables 
********************************************************************************
merge m:1 prop_id using `walkscore', 
    sum _merge
    drop if _merge == 2
    drop _merge 


********************************************************************************
** drop out of scope years
********************************************************************************
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

/*
gen soil_avg_drainclass = avg_drainclass
gen soil_avg_drainclass_1 = avg_drainclass_1
gen soil_avg_drainclass_2 = avg_drainclass_2   
gen soil_avg_drainclass_3 = avg_drainclass_3  
gen soil_avg_drainclass_4 = avg_drainclass_4  
gen soil_avg_dwellwb = avg_dwellwb    
gen soil_avg_dwellwb_1 = avg_dwellwb_1
gen soil_avg_hydrolgrp = avg_hydrolgrp 
gen soil_avg_hydrolgrp_1 = avg_hydrolgrp_1 
gen soil_avg_hydrolgrp_2 = avg_hydrolgrp_2 
gen soil_avg_roads = avg_roads  
gen soil_avg_roads_1 = avg_roads_1
gen soil_avg_flooding = avg_flooding
gen soil_avg_flooding_1 = avg_flooding_1   
gen soil_avg_flooding_2 = avg_flooding_2   
gen soil_avg_flooding_3 = avg_flooding_3
gen soil_avg_flooding_4 = avg_flooding_4
gen soil_avg_ponding = avg_ponding
gen soil_avg_ponding_1 = avg_ponding_1  
gen soil_avg_ponding_2 = avg_ponding_2
gen soil_avg_corconcret = avg_corconcret  
gen soil_avg_corconcret_1 = avg_corconcret_1
gen soil_avg_kfactrf = avg_kfactrf    
gen soil_avg_kfactws = avg_kfactws     
*/


********************************************************************************
** Part 1: placebo check - predict outcomes at boundaries
********************************************************************************

* define dist vars macro 
global dist_vars dist_school dist_center dist_road dist_river dist_space transit_dist

*soil macro
global soil_vars soil_avgslope soil_slope15 soil_avgrestri soil_avgsand soil_avgclay

* define 2 new soil amenity var macros (baseline + MF problems/walkability removed)
*global soil_vars_0 soil_slope15 soil_avgrestri soil_avgsand soil_avgclay soil_avg_drainclass_3 soil_avg_corconcret_1 soil_avg_kfactrf soil_avg_kfactws soil_avg_hydrolgrp_1 soil_avg_dwellwb soil_avg_roads
*global soil_vars_1 soil_slope15 soil_avgrestri soil_avgsand soil_avgclay soil_avg_drainclass_3 soil_avg_kfactrf soil_avg_kfactws

* define new macro for walkscore vars
global walk_vars_0 d2b_e8mixa natwalkind 

** sales price
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* NEW
quietly eststo price_0: reg log_saleprice $dist_vars $walk_vars_0 $soil_vars i.lam_seg i.last_saleyr if `regression_conditions'
predict amenity_price_0 if e(sample), xb

*quietly eststo price_1: reg log_saleprice $dist_vars $soil_vars_1 i.lam_seg i.last_saleyr if `regression_conditions'
*predict amenity_price_1, xb

* predict prices, amenity vars w/o walkability
quietly eststo price_1: reg log_saleprice $dist_vars d2b_e8mixa $soil_vars i.lam_seg i.last_saleyr if `regression_conditions'

predict amenity_price_1 if e(sample), xb

** rents
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* NEW
quietly eststo rent_0: reg log_mfrent $dist_vars $walk_vars_0 $soil_vars i.lam_seg i.year if `regression_conditions'
predict amenity_rent_0 if e(sample), xb

*quietly eststo rent_1: reg log_mfrent $dist_vars $soil_vars_1 i.lam_seg i.year if `regression_conditions'
*predict amenity_rent_1, xb

* predict rents, amenity vars w/o walkability
quietly eststo rent_1: reg log_mfrent $dist_vars d2b_e8mixa $soil_vars i.lam_seg i.year if `regression_conditions'

predict amenity_rent_1 if e(sample), xb

* predict costar only rents, old amenity vars 
gen log_costar_rent_only = ln(costar_rent) if costar_rent!=.

quietly eststo costar_0: reg log_costar_rent_only $dist_vars $walk_vars_0 $soil_vars i.lam_seg i.year if `regression_conditions'
predict amenity_costar_0 if e(sample), xb

*w/o walkability
quietly eststo costar_1: reg log_costar_rent_only $dist_vars d2b_e8mixa $soil_vars i.lam_seg i.year if `regression_conditions'
predict amenity_costar_1 if e(sample), xb

forvalues i = 0/1 {
	esttab price_`i' rent_`i' costar_`i', ///
				se r2 indicate("Boundary f.e.=*lam_seg" "Sale Year f.e.=*last_saleyr" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("price" "rent" "costar") ///
	title("Predicted price/rent coefficients") 
}

********************************************************************************
* Part 2: predicted sales prices, all amenties + w/o walkscore
********************************************************************************
* regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* NEW
forvalues j = 0/1 {
	quietly eststo price_du_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_duhe_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_mfdu_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_mf_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_mfhe_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo price_he_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
}

* NEW 
forvalues j = 0/1 {
	quietly eststo price_du_r_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(robust)
	quietly eststo price_duhe_r_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)
	quietly eststo price_mfdu_r_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(robust)
	quietly eststo price_mf_r_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)
	quietly eststo price_mfhe_r_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)
	quietly eststo price_he_r_`j': reg amenity_price_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)
}

* clustered
forvalues i = 0/1 {
	esttab price_du_`i' price_duhe_`i' price_mfdu_`i' price_mf_`i' price_mfhe_`i' price_he_`i' using "$RDPATH/predicted_prices_table_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Amenity sales prices, new amenity list") 
					
}

* robust
forvalues i = 0/1 {
	esttab price_du_r_`i' price_duhe_r_`i' price_mfdu_r_`i' price_mf_r_`i' price_mfhe_r_`i' price_he_r_`i' using "$RDPATH/predicted_prices_table_r_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Amenity sales prices, new amenity list (robust SE)") 
}

* predicted sales price coefplots
capture noisily {

forvalues i = 0/1 {
	local plot_list_`i' price_du_`i' price_duhe_`i' price_mfdu_`i' price_mf_`i' price_mfhe_`i' price_he_`i' 
}

local suffix "predicted_price_new"
local l1_title "Predicted sales price from amenities"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

forvalues i = 0/1 {
							foreach r in `plot_list_`i'' {
								
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
	}

	if "`str'" == "mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`str'" == "mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`str'" == "mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`str'" == "he" {
		local title "Only Height Changes"
	}
	* coefplots
	#delimit;
	coefplot 
		/* relaxed side graphing variables */
		(`r', keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r', keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

		/* axis titles and labels */		
		ylabel(, labsize(4) gmin gmax) ymtick()	
		
		xlabel(1 "-.20" 2 "-.18" 3 "-.16" 4 "-.14" 5 "-.12" 6 "-.10" 7 "-.08" 8 "-.06" 9 "-.04" 10 "-.02" 10.5 "0"
			11 ".02" 12 ".04" 13 ".06" 14 ".08" 15 ".10" 16 ".12" 17 ".14" 18 ".16" 19 ".18" 20 ".20", labsize(3) angle(45) gmax)
			
		/* legend */
		legend(off position(6) 
			order()
			symy(2) symx(3) 
			rows(1) cols() size(2) 
			nobox fcolor()
			region(fcolor(none) lpattern(blank))
			margin(t=1 b=1 l=0 r=0)span)
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
	}
}

* combine all
forvalues i = 0/1 {
							
#delimit ;
graph combine `plot_list_`i'',
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
		
}
}

eststo clear
graph close _all

********************************************************************************
** Part 3: predicted rents, all amenities + w/o walkscore
********************************************************************************
* regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

* NEW
forvalues j = 0/1 {
	quietly eststo rent_du_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_duhe_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_mfdu_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_mf_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_mfhe_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo rent_he_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
}

* NEW
forvalues j = 0/1 {
	quietly eststo rent_du_r_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(robust)
	quietly eststo rent_duhe_r_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)
	quietly eststo rent_mfdu_r_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(robust)
	quietly eststo rent_mf_r_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)
	quietly eststo rent_mfhe_r_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)
	quietly eststo rent_he_r_`j': reg amenity_rent_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)
}
	
* (rent), clustered
forvalues i = 0/1 {
	esttab rent_du_`i' rent_duhe_`i' rent_mfdu_`i' rent_mf_`i' rent_mfhe_`i' rent_he_`i' using "$RDPATH/predicted_rents_table_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("Amenity rents prices, new amenity list") 
					
}

* (rent), robust
forvalues i = 0/1 {
							esttab rent_du_r_`i' rent_duhe_r_`i' rent_mfdu_r_`i' rent_mf_r_`i' rent_mfhe_r_`i' rent_he_r_`i' using "$RDPATH/predicted_rents_table_r_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("Amenity rents prices, new amenity list (robust SE)") 
}

* predicted amenity rent coefplots
capture noisily {

forvalues i = 0/1 {
	local plot_list_`i' rent_du_`i' rent_duhe_`i' rent_mfdu_`i' rent_mf_`i' rent_mfhe_`i' rent_he_`i' 
					
}

local suffix "predicted_rent_new"
local l1_title "Predicted rent from amenities"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

forvalues i = 0/1 {
							foreach r in `plot_list_`i'' {
								
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
	}

	if "`str'" == "mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`str'" == "mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`str'" == "mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`str'" == "he" {
		local title "Only Height Changes"
	}
	* coefplots
	#delimit;
	coefplot 
		/* relaxed side graphing variables */
		(`r', keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r', keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

		/* axis titles and labels */		
		ylabel(, labsize(4) gmin gmax) ymtick()	
		
		xlabel(1 "-.20" 2 "-.18" 3 "-.16" 4 "-.14" 5 "-.12" 6 "-.10" 7 "-.08" 8 "-.06" 9 "-.04" 10 "-.02" 10.5 "0"
			11 ".02" 12 ".04" 13 ".06" 14 ".08" 15 ".10" 16 ".12" 17 ".14" 18 ".16" 19 ".18" 20 ".20", labsize(3) angle(45) gmax)
			
		/* legend */
		legend(off position(6) 
			order()
			symy(2) symx(3) 
			rows(1) cols() size(2) 
			nobox fcolor()
			region(fcolor(none) lpattern(blank))
			margin(t=1 b=1 l=0 r=0)span)
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
		}
}

* combine all
forvalues i = 0/1 {
							
#delimit ;
graph combine `plot_list_`i'',
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
}

}

eststo clear
graph close _all


/*
********************************************************************************
* Part 4: predicted sales prices, amenities w/o sand + clay
********************************************************************************
* regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* Single-family home prices
quietly eststo price_du_b: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe_b: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu_b: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf_b: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe_b: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he_b: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

* Single-family home prices, robust SEs
quietly eststo price_du_b_r: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', r
	
quietly eststo price_duhe_b_r: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', r

quietly eststo price_mfdu_b_r: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', r

quietly eststo price_mf_b_r: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', r

quietly eststo price_mfhe_b_r: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', r

quietly eststo price_he_b_r: reg amenity_price_b ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', r

*POSTRESTAT - CHECK PATH
esttab price_du_b price_duhe_b price_mfdu_b price_mf_b price_mfhe_b price_he_b using "$RDPATH/predicted_prices_nosandclay_table.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du_b" "price_duhe_b" "price_mfdu_b" "price_mf_b" "price_mfhe_b" "price_he_b") ///
	title("Amenity sales prices, w/o sand + clay")
	
* Robust SE table
esttab price_du_b_r price_duhe_b_r price_mfdu_b_r price_mf_b_r price_mfhe_b_r price_he_b_r using "$RDPATH/predicted_prices_nosandclay_r_table.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du_b_r" "price_duhe_b_r" "price_mfdu_b_r" "price_mf_b_r" "price_mfhe_b_r" "price_he_b_r") ///
	title("Amenity sales prices, w/o sand + clay (robust SEs)")

	
* predicted sales price coefplots
capture noisily {

local plot_list_b price_du_b price_duhe_b price_mfdu_b price_mf_b price_mfhe_b price_he_b
local suffix "predicted_price_b"
local l1_title "Predicted sales price from amenities"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list'{
	
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
	}

	if "`str'" == "mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`str'" == "mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`str'" == "mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`str'" == "he" {
		local title "Only Height Changes"
	}
	
	* coefplots
	#delimit;
	coefplot 
		/* relaxed side graphing variables */
		(`r', keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r', keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

		/* axis titles and labels */		
		ylabel(, labsize(4) gmin gmax) ymtick()	
		
		xlabel(1 "-.20" 2 "-.18" 3 "-.16" 4 "-.14" 5 "-.12" 6 "-.10" 7 "-.08" 8 "-.06" 9 "-.04" 10 "-.02" 10.5 "0"
			11 ".02" 12 ".04" 13 ".06" 14 ".08" 15 ".10" 16 ".12" 17 ".14" 18 ".16" 19 ".18" 20 ".20", labsize(3) angle(45) gmax)
			
		/* legend */
		legend(off position(6) 
			order()
			symy(2) symx(3) 
			rows(1) cols() size(2) 
			nobox fcolor()
			region(fcolor(none) lpattern(blank))
			margin(t=1 b=1 l=0 r=0)span)
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

* combine all
#delimit ;
graph combine `plot_list',
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
}

eststo clear
graph close _all


********************************************************************************
** Part 5: predicted rents, amenities w/o sand + clay
********************************************************************************
* regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

* rent regressions
quietly eststo rent_du_b: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe_b: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if du_he== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_mfdu_b: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_mf_b: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if only_mf == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_mfhe_b: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he_b: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

* rent regressions, robust SEs
quietly eststo rent_du_b_r: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if only_du == 1 & `regression_conditions', r
	
quietly eststo rent_duhe_b_r: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if du_he== 1 & `regression_conditions', r

quietly eststo rent_mfdu_b_r: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if mf_du == 1 & `regression_conditions', r

quietly eststo rent_mf_b_r: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if only_mf == 1 & `regression_conditions', r

quietly eststo rent_mfhe_b_r: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if mf_he == 1 & `regression_conditions', r

quietly eststo rent_he_b_r: reg amenity_rent_b ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', r

	
*POSTRESTAT - CHECK PATH
esttab rent_du_b rent_duhe_b rent_mfdu_b rent_mf_b rent_mfhe_b rent_he_b using "$RDPATH/predicted_rents_nosandclay_table.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("Amenity Rents, amenities w/o sand + clay") 
	
* robust SE table
esttab rent_du_b_r rent_duhe_b_r rent_mfdu_b_r rent_mf_b_r rent_mfhe_b_r rent_he_b_r using "$RDPATH/predicted_rents_nosandclay_r_table.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("Amenity Rents, amenities w/o sand + clay (robust SEs)") 

* coefplots
capture noisily {
local plot_list rent_du_b rent_duhe_b rent_mfdu_b rent_mf_b rent_mfhe_b rent_he_b
local suffix "predicted_rent_b"
local l1_title "Predicted rent from amenities"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list'{
	
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
	}

	if "`str'" == "mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`str'" == "mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`str'" == "mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`str'" == "he" {
		local title "Only Height Changes"
	}
	
	* coefplots
	#delimit;
	coefplot 
		/* relaxed side graphing variables */
		(`r', keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r', keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

		/* axis titles and labels */		
		ylabel(, labsize(4) gmin gmax) ymtick()	
		
		xlabel(1 "-.20" 2 "-.18" 3 "-.16" 4 "-.14" 5 "-.12" 6 "-.10" 7 "-.08" 8 "-.06" 9 "-.04" 10 "-.02" 10.5 "0"
			11 ".02" 12 ".04" 13 ".06" 14 ".08" 15 ".10" 16 ".12" 17 ".14" 18 ".16" 19 ".18" 20 ".20", labsize(3) angle(45) gmax)
			
		/* legend */
		legend(off position(6) 
			order()
			symy(2) symx(3) 
			rows(1) cols() size(2) 
			nobox fcolor()
			region(fcolor(none) lpattern(blank))
			margin(t=1 b=1 l=0 r=0)span)
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

* combine all
#delimit ;
graph combine `plot_list',
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
}

eststo clear
graph close _all
*/
	
********************************************************************************
** Part 6: Costar rents only  NO PLOTS, all amenities + w/o walkscore
********************************************************************************
* regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

* NEW
forvalues j = 0/1 {
	quietly eststo costar_du_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo costar_duhe_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo costar_mfdu_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo costar_mf_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo costar_mfhe_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
	quietly eststo costar_he_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
}

* NEW
forvalues j = 0/1 {
	quietly eststo costar_du_r_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_du == 1 & `regression_conditions', vce(robust)
	quietly eststo costar_duhe_r_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)
	quietly eststo costar_mfdu_r_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_du == 1 & `regression_conditions', vce(robust)
	quietly eststo costar_mf_r_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)
	quietly eststo costar_mfhe_r_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)
	quietly eststo costar_he_r_`j': reg amenity_costar_`j' ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)
}

* NEW (costar), clustered
forvalues i = 0/1 {
	esttab costar_du_`i' costar_duhe_`i' costar_mfdu_`i' costar_mf_`i' costar_mfhe_`i' costar_he_`i' using "$RDPATH/predicted_rents_onlycostar_table_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("costar_du" "costar_duhe" "costar_mfdu" "costar_mf" "costar_mfhe" "costar_he") ///
	title("Amenity CoStar rents, new amenity list") 
					
}

* NEW (costar), robust
forvalues i = 0/1 {
							esttab costar_du_r_`i' costar_duhe_r_`i' costar_mfdu_r_`i' costar_mf_r_`i' costar_mfhe_r_`i' costar_he_r_`i' using "$RDPATH/predicted_rents_onlycostar_table_r_`i'.tex", replace keep(25.dist3)  ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("costar_du" "costar_duhe" "costar_mfdu" "costar_mf" "costar_mfhe" "costar_he") ///
	title("Amenity CoStar rents, new amenity list (robust SE)") 
}

* NEW, predicted rents, costar only coefplots
capture noisily {

forvalues i = 0/1 {
	local plot_list_`i' costar_du_`i' costar_duhe_`i' costar_mfdu_`i' costar_mf_`i' costar_mfhe_`i' costar_he_`i' 
}

local suffix "predicted_costar_new"
local l1_title "Predicted (non-imputed) rent from amenities"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

forvalues i = 0/1 {
							foreach r in `plot_list_`i'' {
								
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
	}

	if "`str'" == "mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`str'" == "mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`str'" == "mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`str'" == "he" {
		local title "Only Height Changes"
	}
	* coefplots
	#delimit;
	coefplot 
		/* relaxed side graphing variables */
		(`r', keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r', keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

		/* axis titles and labels */		
		ylabel(, labsize(4) gmin gmax) ymtick()	
		
		xlabel(1 "-.20" 2 "-.18" 3 "-.16" 4 "-.14" 5 "-.12" 6 "-.10" 7 "-.08" 8 "-.06" 9 "-.04" 10 "-.02" 10.5 "0"
			11 ".02" 12 ".04" 13 ".06" 14 ".08" 15 ".10" 16 ".12" 17 ".14" 18 ".16" 19 ".18" 20 ".20", labsize(3) angle(45) gmax)
			
		/* legend */
		legend(off position(6) 
			order()
			symy(2) symx(3) 
			rows(1) cols() size(2) 
			nobox fcolor()
			region(fcolor(none) lpattern(blank))
			margin(t=1 b=1 l=0 r=0)span)
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
						
		}
}

* combine all
forvalues i = 0/1 {
							
#delimit ;
graph combine `plot_list_`i'',
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
					
}
}

eststo clear
graph close _all
	

********************************************************************************
** end
********************************************************************************
log close
clear all 

** convert pdfs to gph
local files : dir "$RDPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$RDPATH/`fin'"
	
	graph export "$RDPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 

