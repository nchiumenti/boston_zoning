clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREStat_rd_robustness_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postQJE_rd_robustness_mtlines.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		post QJE updated rd graphs / coefplots.
* 			residuals analysis - are they correlated with strictness of regulation or distance to boundary
* 			for house prices, rents
*			
*			a: baseline
*			b: control for distance to highway + slope and bedrock for duhe boundaries
*
*			Contents:
*               Part 0: Optimal bandwidth calculation 
* 				
* Inputs:		./mt_orthogonal_dist_100m_07-01-22_v2.dta
*			./soil_quality_matches.dta
*			./final_dataset_10-28-2021.dta
*				
* Outputs:		lots of graphs
*			_both -> overlay w/o and w/ char_vars and exclusions
*
* Created:		11/17/2024
* Updated:		
********************************************************************************
* create a save directory if none exists
global RDPATH "$FIGPATH/`name'_`date_stamp'"

capture confirm file "$RDPATH"

if _rc!=0 {
	di "making directory $RDPATH"
	shell mkdir $RDPATH
}

cd $RDPATH

* Eli: commenting out after running once
********************************************************************************
** load and tempsave the mt lines data
********************************************************************************
//Eli: changed to $DATAPATH
use  "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear    /*NEW POSTRESTAT - CHECK PATH*/


destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load and tempsave the soil data
********************************************************************************
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace

********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


*NEW POSTRESTAT
********************************************************************************
** load and tempsave regulations data
********************************************************************************

use "$DATAPATH/warren_zoning_regulations_match.dta", clear    /*ChECK PATH*/

keep prop_id *_esval      /*keep all esval variables, i.e. imputation flags*/

tempfile regs
save `regs', replace


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
** load final dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************

// run "$DOPATH/postREStat_within_town_setup_07102024.do"  // $DOPATH is set within 00_wp_master.do
use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear 


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
	
	* merge error check
	sum _merge
	assert `r(N)' ==  3642292
	assert `r(sum_w)' ==  3642292
	assert `r(mean)' ==  2.878361207723049
	assert `r(Var)' ==  .1068428258243096
	assert `r(sd)' ==  .3268682086473226
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  10483832

	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)   /*NEW POSTRESTAT - CHECK*/
	
	* merge error check
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

// stop
// tempfile save_point
// save `save_point', replace
*save "$DATAPATH/Eli_data_April_2024_robustness"
*eji
*
/* Start REStat revisions from 03-27-2024 */

********************************************************************************
** merge on imputation flags for regulations
********************************************************************************

*NEW POSTRESTAT  - NC ChECK PLS
merge m:1 prop_id using `regs'
sum _merge

drop if _merge == 2
drop _merge 


********************************************************************************
** merge on ACS characteristics
********************************************************************************
* merge on block data level characteristics
merge m:1 warren_GEOID_full using "$DATAPATH/acs/blocks_2010.dta", update replace
	
	* summarize _merge var and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

* create block group making variable
gen BLKGRP = substr(warren_GEOID_full,1,12)


* merge on ace amenities dataset
merge m:1 year BLKGRP using "$DATAPATH/acs/acs_amenities.dta", keepusing(B19113001 SHARE_BACHELOR_25)

	* summarize merge and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

	* rename median income variable
	rename B19113001 median_inc


/* End REStat revisions from 03-27-2024 */


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
** property characteristic variables
********************************************************************************
gen char1_lotsizeac1 = ln(lot_sizeac) if lot_sizeac != 0			// lot size in acres, excl zero acre --> NOW IN LOGS
gen char2_livingarea1 = ln(livingarea) / num_units1 if livingarea != 0		// living area in XX per unit, excl zero --> NOW IN LOGS
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0		// num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0		// num full bathrooms per unit, atleast 1

gen log_lotacres = ln(lot_acres) if lot_acres!=0
gen log_bldgarea =ln(grossbldg_area) if grossbldg_area!=0

* set control variables
global char_vars dist_road
global char_vars_duhe dist_road soil_avgslope soil_avgrestri

*new amenities controls (for discontinuous amenities)
global char_vars_highway dist_road
global char_vars_highway_walkability dist_road natwalkind
global char_vars_walkability natwalkind
global char_vars_hiway_wlkblty_muni dist_road natwalkind dist_center
 

/*
********************************************************************************
** building characteristic variable setup
********************************************************************************
 * Non-log variables
/*
gen char1_lotsizeac1 = lot_sizeac if lot_sizeac != 0			// lot size in acres, excl zero acre
gen char2_livingarea1 = livingarea / num_units1 if livingarea != 0	// living area in XX per unit, excl zero
*/

global char_vars_1 char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1
*/

*AK: should use these property characteristics variables - same as we did in the main file - commenting out part right above 
********************************************************************************
** property characteristic variables
********************************************************************************
*gen char1_lotsizeac1 = ln(lot_sizeac) if lot_sizeac != 0			// lot size in acres, excl zero acre --> NOW IN LOGS
*gen char2_livingarea1 = ln(livingarea) / num_units1 if livingarea != 0		// living area in XX per unit, excl zero --> NOW IN LOGS
*gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0		// num bedrooms per unit, atleast 1
*gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0		// num full bathrooms per unit, atleast 1

// gen log_lotacres = ln(lot_acres) if lot_acres!=0
// gen log_bldgarea =ln(grossbldg_area) if grossbldg_area!=0

********************************************************************************
**Define distance polynomial trends
********************************************************************************

gen r_dist_relax = relaxed * dist_both
gen r_dist_strict = strict * dist_both

local distance_varlist1 = "r_dist_relax r_dist_strict"


********************************************************************************
*This setup has loaded in the maximum amount of additional data 
*define all necessary globals 
********************************************************************************

*house characteristics 
global char_vars_1 i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num
* define a global set of acs variable controls
global acs_vars frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc
*land variables 
global land_amenities dist_school dist_center dist_road dist_river dist_space transit_dist soil_avgslope soil_slope15 soil_avgrestri soil_avgsand soil_avgclay d2b_e8mixa natwalkind 



*residualize prices on everything including boundary f.e. 

quietly reg log_saleprice i.mf_allowed height dupac i.mf_allowed#c.height i.mf_allowed#c.dupac c.height#c.dupac $char_vars_1 $acs_vars $land_amenities i.lam_seg i.last_saleyr ///
	if (dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg)
	
*predict residuals 
predict residuals_lam if e(sample), residuals 


*residualize rents on everything including boundary f.e. 

quietly reg log_mfrent i.mf_allowed height dupac i.mf_allowed#c.height i.mf_allowed#c.dupac c.height#c.dupac $char_vars_1 $acs_vars $land_amenities i.lam_seg i.year ///
	if (dist <= 0.20 & (year>=2010 & year<=2018) & res_typex != "Condominiums"), vce(cluster lam_seg)
	
*predict residuals 
predict residuals_rent_lam if e(sample), residuals 



*residualize prices on everything except boundary f.e. and distance variables
quietly reg log_saleprice i.mf_allowed height dupac i.mf_allowed#c.height i.mf_allowed#c.dupac c.height#c.dupac $char_vars_1 $acs_vars $land_amenities i.last_saleyr ///
	if (dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg)

*predict residuals 
predict residuals_nolam if e(sample), residuals 


*residualize rents on everything except boundary f.e. and distance variables
quietly reg log_mfrent i.mf_allowed height dupac i.mf_allowed#c.height i.mf_allowed#c.dupac c.height#c.dupac $char_vars_1 $acs_vars $land_amenities i.year ///
	if (dist <= 0.20 & (year>=2010 & year<=2018) & res_typex != "Condominiums"), vce(cluster lam_seg)

*predict residuals 
predict residuals_rent_nolam if e(sample), residuals 


/*
{

	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg distance_varlist1 i.last_saleyr ///
		if (only_mf == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg distance_varlist1 i.last_saleyr ///
		if (only_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg distance_varlist1 i.last_saleyr ///
		if (only_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg distance_varlist1 i.last_saleyr ///
		if (mf_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg)

		eststo D


	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg distance_varlist1 i.last_saleyr ///
		if (mf_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg distance_varlist1 i.last_saleyr ///
		if (du_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(cluster lam_seg)
		
		eststo F


	* combine results
	esttab A B C D E F, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 3d: house prices baseline @ 0.20 miles (linear distance trend)") 
		
	eststo clear 
}

*/


*correlate with strictness of regulation 


*dupac
twoway scatter residuals_lam dupac if  (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_scatter_priceresiduals_dupac.gph", replace
graph export "postrestat_scatter_priceresiduals_dupac.pdf", replace

*binned version
binscatter residuals_lam  dupac if  (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_binscatter_priceresiduals_dupac.gph", replace
graph export "postrestat_binscatter_priceresiduals_dupac.pdf", replace


*height
twoway scatter residuals_lam height if  (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_scatter_priceresiduals_height.gph", replace
graph export "postrestat_scatter_priceresiduals_height.pdf", replace

*binned version
binscatter residuals_lam  height if  (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_binscatter_priceresiduals_height.gph", replace
graph export "postrestat_binscatter_priceresiduals_height.pdf", replace


*mf - ttest for mf = 1 vs mf = 0 
ttest residuals_lam if  (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res", by(mf_allowed)


sum residuals_lam if mf_allowed == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res", d
sum residuals_lam if mf_allowed ==0 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res", d

*rent plots
*dupac
twoway scatter residuals_rent_lam dupac if  (dist_both<=0.21 & dist_both>=-0.2) & (year>=2010 & year<=2018) & res_typex != "Condominiums" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_scatter_rentresiduals_dupac.gph", replace
graph export "postrestat_scatter_rentresiduals_dupac.pdf", replace

*binned version
binscatter residuals_rent_lam  dupac if  (dist_both<=0.21 & dist_both>=-0.2)  & (year>=2010 & year<=2018) & res_typex != "Condominiums" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_binscatter_rentresiduals_dupac.gph", replace
graph export "postrestat_binscatter_rentresiduals_dupac.pdf", replace


*height
twoway scatter residuals_rent_lam height if  (dist_both<=0.21 & dist_both>=-0.2)  & (year>=2010 & year<=2018) & res_typex != "Condominiums" , graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_scatter_rentresiduals_height.gph", replace
graph export "postrestat_scatter_rentresiduals_height.pdf", replace

*binned version
binscatter residuals_rent_lam  height if (dist_both<=0.21 & dist_both>=-0.2)  & (year>=2010 & year<=2018) & res_typex != "Condominiums", graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))
graph save "postrestat_binscatter_rentresiduals_height.gph", replace
graph export "postrestat_binscatter_rentresiduals_height.pdf", replace


*mf - ttest for mf = 1 vs mf = 0 
ttest residuals_rent lam if  (dist_both<=0.21 & dist_both>=-0.2)  & (year>=2010 & year<=2018) & res_typex != "Condominiums", by(mf_allowed)


sum residuals_lam if mf_allowed == 1 & (dist_both<=0.21 & dist_both>=-0.2)  & (year>=2010 & year<=2018) & res_typex != "Condominiums", d
sum residuals_lam if mf_allowed ==0 & (dist_both<=0.21 & dist_both>=-0.2)  & (year>=2010 & year<=2018) & res_typex != "Condominiums", d



*run nonparametric specification on residuals 

*prices
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Residualized Sales Prices") 

*robust s.e.
quietly eststo price_du_robust: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg residuals_nolam ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)

esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Residualized Sales Prices, robust s.e.") 
	
	
** coefplots
* coefplots, sales prices w/o characteristics
{
local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_resid"
local l1_title "Residualized sales prices"
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
		name(`r', replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name(`r'a, replace);
	
	graph save `r'a `suffix'_`str', replace;
	graph close `r'a;
	#delimit cr
}

* combine all
#delimit ;
graph combine price_du price_duhe price_mfdu price_mf price_mfhe price_he,
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


*rents
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo price_du: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Residualized Rents") 

*robust s.e.
quietly eststo price_du_robust: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg residuals_rent_nolam ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)

esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Residualized Rents, robust s.e.") 
	
	
** coefplots
* coefplots, sales prices w/o characteristics
{
local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_rent_resid"
local l1_title "Residualized rents"
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
		name(`r', replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name(`r'a, replace);
	
	graph save `r'a `suffix'_`str', replace;
	graph close `r'a;
	#delimit cr
}

* combine all
#delimit ;
graph combine price_du price_duhe price_mfdu price_mf price_mfhe price_he,
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
** end
********************************************************************************
log close
clear all

** convert gph to pdfs
local files : dir "$RDPATH" files "*.gph"

foreach fin in `files' {	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$RDPATH/`fin'"
	
	graph export "$RDPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 

