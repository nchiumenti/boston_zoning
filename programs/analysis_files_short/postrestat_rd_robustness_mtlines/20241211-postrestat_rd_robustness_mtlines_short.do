clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postrestat_rd_robustness_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postQJE_rd_robustness_mtlines.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		post QJE updated rd graphs / coefplots.
* 			striaght line boundaries (matt turner orthogona lines)
* 			for house prices, rents, units. regression output 
*			printed w/o characteristics or exclusions (a) and w/ (b).
*			
*			a: baseline
*			b: control for distance to highway + slope and bedrock for duhe boundaries
*
*			Contents:
*               Part 0: Optimal bandwidth calculation 
*				Part 3(a-b): Rents baseline + excl. $500-$1400 rents
*				Part 4(a-b): Rents baseline + Costar imputation dummy
*				Part 5(a-b): Sales prices baseline + ACS controls 
*				Part 7(a-b): Rents baseline + ACS controls 
*				Part 9(a-d): Sales prices different relaxedness definitions (only tables)
*				Part 10(a-d): Rents different relaxedness definitions (only tables)
*				Part 11(a-c): Sales prices with minlotsize
*				Part 12(a-c): Rents with minlotsize
*				Part 15: Prices + Control for discontinuous amenities
*				Part 16: Rents + Control for discontinuous amenities
* 				
* Inputs:		./mt_orthogonal_dist_100m_07-01-22_v2.dta
*			./soil_quality_matches.dta
*			./final_dataset_10-28-2021.dta
*				
* Outputs:		lots of graphs
*			_both -> overlay w/o and w/ char_vars and exclusions
*
* Created:		10/05/2022
* Updated:		03/27/2024
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

stop  // NFC 12-10-2024: change the path below or make sure it points to the data file "final_addon_regs_intersect.dta"

use "$DATAPATH/final_addon_regs_intersect.dta", clear    /*ChECK PATH*/

rename addon_* *  // should remove the addon_prefix from all variables

keep prop_id *_esval  // keep all esval variables, i.e. imputation flags

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

* define a global set of acs variable controls
global acs_vars frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc

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

global char_vars_1 i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num




sum $char_vars

** means
* means for only_du boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex != "Condominiums")

* means for du_he boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex != "Condominiums")

* means for mf_du boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex != "Condominiums")

* means for only_mf boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf == 1 & res_typex != "Condominiums")

* means for mf_he boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex != "Condominiums")

* means for only_he boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex != "Condominiums")

* count boundaries
unique lam_seg
unique lam_seg if only_du == 1
unique lam_seg if only_he == 1
unique lam_seg if only_mf == 1

unique lam_seg if du_he == 1
unique lam_seg if mf_du == 1
unique lam_seg if mf_he == 1

stop  // NFC 12-10-2024

************************************
*Part 0:
/*Optimal bandwidth calculation*/
************************************
*WITHOUT CONTROLS
*rents
*triangular kernel
rdbwselect log_mfrent dist_both if (only_mf == 1 & res_typex !="Condominiums" ), c(0) all 
rdbwselect log_mfrent dist_both if (only_he == 1 & res_typex !="Condominiums" ), c(0) all 
rdbwselect log_mfrent dist_both if (only_du == 1 & res_typex !="Condominiums" ), c(0) all 
rdbwselect log_mfrent dist_both if (mf_he == 1 & res_typex !="Condominiums" ), c(0) all 
rdbwselect log_mfrent dist_both if (mf_du == 1 & res_typex !="Condominiums" ), c(0) all 
rdbwselect log_mfrent dist_both if (du_he == 1 & res_typex !="Condominiums" ), c(0) all 
rdbwselect log_mfrent dist_both if (mf_he_du == 1 & res_typex !="Condominiums" ), c(0) all 

*uniform kernel
rdbwselect log_mfrent dist_both if (only_mf == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (only_he == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (only_du == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (mf_he == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (mf_du == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (du_he == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (mf_he_du == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)


*house prices
*triangular kernel
rdbwselect log_saleprice dist_both if (only_mf == 1 & res_typex=="Single Family Res" ), c(0) all 
rdbwselect log_saleprice dist_both if (only_he == 1 & res_typex=="Single Family Res"), c(0) all 
rdbwselect log_saleprice dist_both if (only_du == 1 & res_typex=="Single Family Res" ), c(0) all 
rdbwselect log_saleprice dist_both if (mf_he == 1 & res_typex=="Single Family Res" ), c(0) all 
rdbwselect log_saleprice dist_both if (mf_du == 1 & res_typex=="Single Family Res" ), c(0) all 
rdbwselect log_saleprice dist_both if (du_he == 1 & res_typex=="Single Family Res" ), c(0) all 
rdbwselect log_saleprice dist_both if (mf_he_du == 1 & res_typex=="Single Family Res" ), c(0) all 

*uniform kernel
rdbwselect log_saleprice dist_both if (only_mf == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni) 
rdbwselect log_saleprice dist_both if (only_he == 1 & res_typex=="Single Family Res"), c(0) all kernel(uni) 
rdbwselect log_saleprice dist_both if (only_du == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni) 
rdbwselect log_saleprice dist_both if (mf_he == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)
rdbwselect log_saleprice dist_both if (mf_du == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)
rdbwselect log_saleprice dist_both if (du_he == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)
rdbwselect log_saleprice dist_both if (mf_he_du == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)



*WITH CONTROLS 

*MF
foreach l of var only_mf only_he only_du mf_he mf_du du_he mf_he_du {
		
		*uniform kernel
		quietly reg log_mfrent i.lam_seg if (`l' == 1 & res_typex !="Condominiums")
		predict resid_mf_`l', residuals
		rdbwselect resid_mf_`l' dist_both if (`l' == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
		
		*triangular kernel
		rdbwselect resid_mf_`l' dist_both if (`l' == 1 & res_typex !="Condominiums" ), c(0) all

}

*SF
foreach l of var only_mf only_he only_du mf_he mf_du du_he mf_he_du {
		
		*uniform kernel
		quietly reg log_saleprice i.lam_seg if (`l' == 1 & res_typex=="Single Family Res" )
		predict resid_sf_`l', residuals
		rdbwselect resid_sf_`l' dist_both if (`l' == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)
		
		*triangular kernel
		rdbwselect resid_sf_`l' dist_both if (`l' == 1 & res_typex=="Single Family Res" ), c(0) all

}


global char_vars_highway dist_road
global char_vars_highway_walkability dist_road natwalkind
global char_vars_walkability natwalkind
global char_vars_hiway_wlkblty_muni dist_road natwalkind dist_center





********************************************************************************
** Part 3: Rents
* Part 3a: Rents, baseline
* Part 3b: Rents, not between $500 - $1400
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 3a: Rents all
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 

/* AK note: This doesn't need additional table, same as above */	
	
* Part 3b: Rents w/o 500-1400$
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & (comb_rent2<500 | comb_rent2>1400)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & (comb_rent2<500 | comb_rent2>1400)
	
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & (comb_rent2<500 | comb_rent2>1400)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & (comb_rent2<500 | comb_rent2>1400)

quietly eststo rent_he2: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(cluster lam_seg)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & (comb_rent2<500 | comb_rent2>1400)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & (comb_rent2<500 | comb_rent2>1400)
	
esttab rent_du2 rent_duhe2 rent_he2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, not between $500 - $1400") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab rent_du2 rent_duhe2 rent_he2 using "$RDPATH/rents_table_5001400.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, not between $500 - $1400") 
	
*robust s.e.
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(robust)
	
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(robust)

quietly eststo rent_he2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(robust)
	
esttab rent_du2_robust rent_duhe2_robust rent_he2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, not between $500 - $1400, robust s.e.") 
	
		
* coefplots, Rents both

local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_robustness_5001400_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
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
			)
			
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30)
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
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
		name(`r'3, replace) ;
		
	graph combine `r'3,
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
graph combine rent_du3 rent_duhe3 rent_he3,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	


eststo clear
graph close _all


********************************************************************************
*REStat revision 
** Part 4: Rents
* Part 4a: Rents, baseline
* Part 4c: CoStar imputation dummy 
********************************************************************************

** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 4a: Rents all
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
/* AK note from 3/27/2024: doesn't need additional table, same as above */
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 4b: CoStar imputation dummy
* dummy =1 if no rent from costar, else 0
cap drop imputation_dummy
gen imputation_dummy = 0
	replace imputation_dummy = 1 if AvgAskingUnit == .  // NC note: i think the variable is AvgAskingUnit to note costar derived rents

quietly eststo rent_du3: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he3: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du3 rent_duhe3 rent_he3, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab rent_du3 rent_duhe3 rent_mfdu3 rent_mf3 rent_mfhe3 rent_he3 using "$RDPATH/rents_table_costardummy.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
*robust s.e.
quietly eststo rent_du3_robust: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he3_robust: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du3_robust rent_duhe3_robust rent_he3_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline, robust s.e.") 
	

* coefplots, Rents both

local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_robustness_costardummy_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
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
			)
			
		(`r'3, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'3, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30)
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
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
		name(`r'3, replace) ;
		
	graph combine `r'3,
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
graph combine rent_du3 rent_duhe3 rent_he3,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	


eststo clear
graph close _all


********************************************************************************
** Part 5: Sales prices
* Part 5a: Sales prices, baseline
* Part 5b: Sales prices with ACS controls
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* Part 5a: Sales price w/ ACS controls
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 

	
* Part 5b: Sales price w/ ACS and house controls
quietly eststo price_du2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars  if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ characteristics") 
	
*POSTRESTAT ADDED	
esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2 using "$RDPATH/salesprice_table_onlyACScontrols.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ characteristics") 	
	
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"
	
*robust s.e.
quietly eststo price_du2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_du==1 & `regression_conditions', vce(robust)

quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars  if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_he == 1 & `regression_conditions', vce(robust)
	
esttab price_du2_robust price_duhe2_robust price_mfdu2_robust price_mf2_robust price_mfhe2_robust price_he2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ characteristics, robust s.e.") 
	

* coefplots, sales prices both

local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_robustness_acs_both"
local l1_title "Log Sales Price"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
			)
			
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30)
			ciopts(recast(rarea) color(gs5%30) lwidth(1))
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
		name(`r'3, replace) ;
		
	graph combine `r'3,
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
graph combine price_du3 price_duhe3 price_mfdu3 price_mf3 price_mfhe3 price_he3,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	


eststo clear
graph close _all





********************************************************************************
** Part 7: Rents
* Part 7a: Rents, baseline
* Part 7b: Rents, w/ ACS controls 
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 7a: Rents w/ ACS controls
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
* Part 7b: Rents w/ ACS and house controls
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he2: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du2 rent_duhe2 rent_he2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ characteristics") 
	
*POSTRESTAT ADDED	
esttab rent_du2 rent_duhe2 rent_he2 using "$RDPATH/rents_table_onlyACScontrols.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ characteristics") 	

	
*robust s.e.
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du2_robust rent_duhe2_robust rent_he2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ characteristics, robust s.e.") 
	
	
* coefplots, Rents both

local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_robustness_acs_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
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
			)
			
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30)
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
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
		name(`r'3, replace) ;
		
	graph combine `r'3,
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
graph combine rent_du3 rent_duhe3 rent_he3,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	


eststo clear
graph close _all


********************************************************************************
** Part 9: Sales prices (baseline is salesprice_table_baseline.tex from point 1)
* Part 9a: Sales prices, relaxed2 definition 
* Part 9b: Sales prices, relaxed3 definition
* Part 9c: Sales prices, relaxed4 definition
* Part 9d: Sales prices, only clear boundaries
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.21 & dist_both2>=-0.2) & res_typex=="Single Family Res"

* Part 9a: Sales price (relaxed 2 definition)
quietly eststo price_du: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_duhe: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfdu: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mf: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfhe: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_he: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex=="Single Family Res" & last_salepr > 0
	
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 
	  
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he using "$RDPATH/salesprice_table_relaxed2.tex", replace keep(25.dist3_2) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)

quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)
	
esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline, robust s.e.") 

eststo clear	
	
* Part 9b: Sales price (relaxed 3 definition)
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.21 & dist_both3>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex=="Single Family Res" & last_salepr > 0
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfdu: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mf: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfhe: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_he: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices, relaxed 3") 
	  
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he using "$RDPATH/salesprice_table_relaxed3.tex", replace keep(25.dist3_3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices, relaxed 3") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)
	
esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline, robust s.e.") 

eststo clear	


* Part 9c: Sales price (relaxed 4 definition)
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.21 & dist_both4>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex=="Single Family Res" & last_salepr > 0
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfdu: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mf: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfhe: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_he: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices, relaxed 4") 
	  
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he using "$RDPATH/salesprice_table_relaxed4.tex", replace keep(25.dist3_4) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices, relaxed 4") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)
	
esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices, relaxed 4, robust s.e.") 

eststo clear	




	
* Part 9d: Sales price (only clear boundaries)
/* Note: the first 3 shouldn't be different because these are automatically clear */
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam == 1 & only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1

quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam ==1
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1

quietly eststo price_mfhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam ==1 & mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1

quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam== 1
	
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 
	  
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he using "$RDPATH/salesprice_table_clear_boundaries.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & only_he == 1 & `regression_conditions', vce(robust)
	
esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline, robust s.e.") 
	

eststo clear	

********************************************************************************
** Part 10: Rents (baseline is rents_table_baseline.tex from point 2)
* Part 10a: Rents, relaxed2 definition 
* Part 10b: Rents, relaxed3 definition
* Part 10c: Rents, relaxed4 definition
* Part 10d: Rents, only clear boundaries
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both2<=0.21 & dist_both2>=-0.2) & res_typex != "Condominiums"

* Part 10a: Rents, relaxed 2
quietly eststo rent_du: reg log_mfrent ib26.dist3_2 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex != "Condominiums" & comb_rent2>0

quietly eststo rent_duhe: reg log_mfrent ib26.dist3_2 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex != "Condominiums" & comb_rent2>0

quietly eststo rent_he: reg log_mfrent ib26.dist3_2 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both2<=0.02 & dist_both2>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both2<=0 & dist_both2>-0.02) & res_typex != "Condominiums" & comb_rent2>0

esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 

esttab rent_du rent_duhe rent_he using "$RDPATH/rents_table_relaxed2.tex", replace keep(25.dist3_2) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
*robust s.e.
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3_2 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)

quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3_2 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he_robust: reg log_mfrent ib26.dist3_2 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du_robust rent_duhe_robust rent_he_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline, robust s.e.") 
	
eststo clear

* Part 10b: Rents relaxed3	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both3<=0.21 & dist_both3>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex != "Condominiums" & comb_rent2>0
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex != "Condominiums" & comb_rent2>0

quietly eststo rent_he: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both3<=0.02 & dist_both3>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both3<=0 & dist_both3>-0.02) & res_typex != "Condominiums" & comb_rent2>0
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	  
esttab rent_du rent_duhe rent_he using "$RDPATH/rents_table_relaxed3.tex", replace keep(25.dist3_3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
*robust s.e. 
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he_robust: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du_robust rent_duhe_robust rent_mfdu_robust rent_mf_robust rent_mfhe_robust rent_he_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("Rents, baseline, robust s.e.") 

eststo clear


* Part 10c: Rents relaxed4	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both4<=0.21 & dist_both4>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex != "Condominiums" & comb_rent2>0
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex != "Condominiums" & comb_rent2>0

quietly eststo rent_he: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both4<=0.02 & dist_both4>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both4<=0 & dist_both4>-0.02) & res_typex != "Condominiums" & comb_rent2>0
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, relaxed 4") 
	  
esttab rent_du rent_duhe rent_he using "$RDPATH/rents_table_relaxed3.tex", replace keep(25.dist3_4) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, relaxed 4") 
	
*robust s.e. 
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he_robust: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du_robust rent_duhe_robust rent_he_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, relaxed 4, robust s.e.") 

eststo clear

	
* Part 10d: Rents, only clear boundaries
* set regression conditions - first 3 regs should not differ from baseline
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0 & clear_relaxed_strict_lam== 1
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & clear_relaxed_strict_lam== 1
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0 & clear_relaxed_strict_lam== 1
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & clear_relaxed_strict_lam== 1

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0 & clear_relaxed_strict_lam== 1
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & clear_relaxed_strict_lam== 1

esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 

esttab rent_du rent_duhe rent_he using "$RDPATH/rents_table_clear_boundaries.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
*robust s.e.
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du_robust rent_duhe_robust rent_he_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline, robust s.e.") 


********************************************************************************
* RESTAT REVISION
** Part 11: Sales prices
* Part 11a: Sales prices, minlotsize by-right boundaries
********************************************************************************
** regressions
* set regression conditions
* minlotsize_esval = 0 means mnls is in the bylaws (notimputed) (POSTRESTAT CHECK)
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & mnls_esval==0

*only need boundary types involving density
* Part 11a: Sales price baseline
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr & mnls_esval==0
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr& mnls_esval==0
*number of boundaries
unique lam_seg if only_du==1 & `regression_conditions'

quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr & mnls_esval==0
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr& mnls_esval==0
*number of boundaries
unique lam_seg if du_he==1 & `regression_conditions'


quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0& mnls_esval==0
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & mnls_esval==0
*number of boundaries
unique lam_seg if mf_du==1 & `regression_conditions'

* older esttab version, pre REStat
esttab price_du price_duhe price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu") ///
	title("Sales Prices minimum lot size in bylaws, clustered s.e.") 
	
/* REStat Revision - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab price_du price_duhe price_mfdu  using "$RDPATH/salesprice_table_minlotsize.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu") ///
	title("Sales Prices minimum lot size in bylaws, clustered s.e.") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)


* older esttab version, pre REStat
esttab price_du_robust price_duhe_robust price_mfdu_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" ) ///
	title("Sales Prices minimum lot size in bylaws, robust s.e.") 
		
* coefplots, sales prices w/o characteristics

local plot_list price_du price_duhe price_mfdu 
local suffix "coef_price_minlotsize_clustered"
local l1_title "Log Sales Price"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
graph combine price_du price_duhe price_mfdu ,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph_clustered", replace);
	
	graph save "final_graph_clustered" "`suffix'_all", replace;
#delimit cr	

	
eststo clear
graph close _all



********************************************************************************
** Part 12: Rents
* Part 12a: Rents, baseline
********************************************************************************
** regressions
* set regression conditions
* POSTRESTAT NEW CHECK, adding minlotsize condition here 
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & mnls_esval==0
	
* Part 12a: Rents w/o characteristics
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0
*number of boundaries
unique lam_seg if only_du==1 & `regression_conditions' 

quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0
*number of boundaries
unique lam_seg if du_he==1 & `regression_conditions' 

quietly eststo rent_mfdu: reg log_mfrent ib26.dist3 i.lam_seg i.year if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0
sum comb_rent2 if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0
*number of boundaries
unique lam_seg if mf_du==1 & `regression_conditions' 


esttab rent_du rent_duhe rent_mfdu, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu") ///
	title("Rents, minimum lot size in bylaws, clustered s.e.") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab rent_du rent_duhe rent_mfdu using "$RDPATH/rents_table_minlotsize.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" ) ///
	title("Rents, minimum lot size in bylaws, clustered s.e.") 
	
*robust s.e.
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_mfdu_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if mf_du == 1 & `regression_conditions', vce(robust)

esttab rent_du_robust rent_duhe_robust rent_mfdu_robust , se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu") ///
	title("Rents, minimum lot size in bylaws, robust s.e.") 
	
** coefplots

local plot_list rent_du rent_duhe rent_mfdu
local suffix "coef_rent_minlotsize_clustered"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
graph combine rent_du rent_duhe rent_mfdu,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph_clustered", replace);
	
	graph save "final_graph_clustered" "`suffix'_all", replace;
#delimit cr	
	

eststo clear
graph close _all


********************************************************************************
** Part 15: Sales prices
* Part 1a: Sales prices, baseline
* Part 1b: Sales prices, w/ control discontinuous amenities 
********************************************************************************


** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* Part 1a: Sales price baseline
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

* older esttab version, pre REStat
esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 

	
*robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)

* older esttab version, pre REStat
esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline, robust s.e.") 
	
	
		
* Part 15b: Sales prices, w/ control for amenities
quietly eststo price_du2: reg log_saleprice dist_center dist_road ib26.dist3 i.lam_seg i.last_saleyr   if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe2: reg log_saleprice dist_road ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 transit_dist dist_road natwalkind i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf2: reg log_saleprice ib26.dist3 dist_center dist_road natwalkind i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe2: reg log_saleprice ib26.dist3 soil_avgslope dist_road i.lam_seg i.last_saleyr  if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he2: reg log_saleprice ib26.dist3 soil_slope15 dist_space dist_road i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

* older esttab version, pre REStat
esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ amenities") 

	  
esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2 using "$RDPATH/salesprice_table_amenities_control_new.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ amenities") 
	
*robust s.e.
quietly eststo price_du2_robust: reg log_saleprice dist_center dist_road  ib26.dist3 i.lam_seg i.last_saleyr  if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe2_robust: reg log_saleprice dist_road ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu2_robust: reg log_saleprice transit_dist dist_road natwalkind  ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf2_robust: reg log_saleprice dist_center dist_road natwalkind ib26.dist3 i.lam_seg i.last_saleyr  if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe2_robust: reg log_saleprice soil_avgslope dist_road ib26.dist3 i.lam_seg i.last_saleyr  if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he2_robust: reg log_saleprice soil_slope15 dist_space dist_road ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(robust)

* older esttab version, pre REStat
esttab price_du2_robust price_duhe2_robust price_mfdu2_robust price_mf2_robust price_mfhe2_robust price_he2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ amenities, robust s.e.") 
	
	
* coefplots, sales prices both

local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_robustness_amenitiesnew_both"
local l1_title "Log Sales Price"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
			)
			
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30)
			ciopts(recast(rarea) color(gs5%30) lwidth(1))
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
		name(`r'3, replace) ;
		
	graph combine `r'3,
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
graph combine price_du3 price_duhe3 price_mfdu3 price_mf3 price_mfhe3 price_he3,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	


eststo clear
graph close _all



********************************************************************************
** Part 16: Sales prices
* Part 16a: Sales prices, baseline
* Part 16b: Sales prices, w/ control discontinuous amenities 
********************************************************************************

** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 16a: Rents w/ ACS controls
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
* Part 16b: Rents w/ control for amenities 
quietly eststo rent_du2: reg log_mfrent dist_center dist_road ib26.dist3 i.lam_seg i.year  if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe2: reg log_mfrent dist_road ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he2: reg log_mfrent soil_slope15 dist_space dist_road ib26.dist3 i.lam_seg i.year  if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du2 rent_duhe2 rent_he2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ amenities") 
	
*POSTRESTAT ADDED	
esttab rent_du2 rent_duhe2 rent_he2 using "$RDPATH/rents_table_amenities_control_new.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ amenities") 	

	
*robust s.e.
quietly eststo rent_du2_robust: reg log_mfrent dist_center dist_road ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe2_robust: reg log_mfrent dist_road ib26.dist3 i.lam_seg i.year  if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he2_robust: reg log_mfrent soil_slope15 dist_space dist_road ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du2_robust rent_duhe2_robust rent_he2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ amenities, robust s.e.") 
	
	
* coefplots, Rents both

local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_robustness_amenitiesnew_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
	local pos = ustrpos("`r'", "_") + 1
	local str = substr("`r'", `pos', .)

	if "`str'" == "du" {
		local title "Only DUPAC Changes"
	}
	
	if "`str'" == "duhe" {
		local title "DUPAC and Height Change"
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
			)
			
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30)
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
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
		name(`r'3, replace) ;
		
	graph combine `r'3,
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
graph combine rent_du3 rent_duhe3 rent_he3,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	


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



