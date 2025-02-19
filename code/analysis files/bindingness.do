clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREStat_bindingness" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
*Bindingness of different regulations and boundaries with binding regs**********
********************************************************************************

** Post REStat Submission Version **

********************************************************************************
* File name:		"postREStat_bindingness.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Last run with MC on 10/21/2024
*					This version was shortened from prior versions by AK 
*					
*					Analyzes bindingness of different regulations and boundaries 
*					with binding regs.

*					Part 0: Calculate bindingness at the lot level
*					Part 1: generate summary statistics tables (currently commented out)
*					Part 5: Regressions sales prices + rents bindingness > 15% + > 25%
*						5A: Sales price, bindingness 
* 						5B: Sales prices > 15% , characteristics 
* 						5E: Rents > 15% , no characteristics 
* 						5F: Rents > 15% , characteristics 	
* Inputs:			from $DATAPATH/
*						./mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_moreregs.dta
*						./soil_quality/soil_quality_matches.dta
*						./warren_zoning_regulations_match.dta
*	
* Outputs:			log output only
*
* Created:			09/18/2024
* Updated:			10/07/2024
********************************************************************************
// * create a save directory if none exists
global RDPATH "$FIGPATH/`name'_`date_stamp'"

capture confirm file "$RDPATH"

if _rc!=0 {
	di "making directory $RDPATH"
	shell mkdir $RDPATH
}

cd $RDPATH


********************************************************************************
** load and tempsave the mt lines data
********************************************************************************
use  "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear  // loads the version with additional regulation variables

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


*NEW POSTRESTAT
********************************************************************************
** load and regulations data to keep only the imputed flag variables
********************************************************************************
use "$DATAPATH/warren_zoning_regulations_match.dta", clear

keep prop_id *_esval mnls_eff mxfl_eff maxheight mxdu_eff maxdu far far_eff

tempfile imputed_flags

save `imputed_flags', replace


********************************************************************************
** create working dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear

* run postREStat within town setup file
// do "$DOPATH/postREStat_within_town_setup.do"  // Note that this set up file may already exist without the data tage

// do "$DOPATH/postREStat_within_town_setup_07102024.do"

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta", clear  // <-- this is the output mike created from running the above within_town_setup_07102024.do file

********************************************************************************
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'
	
	* merge error check
	sum _merge
	/* assert `r(N)' ==  3642292
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
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)   /*NEW POSTRESTAT - CHECK*/
	
	* merge error check
	sum _merge
	/* assert `r(N)' ==  3400297
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
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** merge on imputation flags for regulations
********************************************************************************
merge m:1 prop_id using `imputed_flags'
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
merge m:1 year BLKGRP using "$DATAPATH/acs/acs_amenities.dta", keepusing(B19113001)

	* summarize merge and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

	* rename median income variable
	rename B19113001 median_inc

* define a global set of acs variable controls
global acs_vars frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc


********************************************************************************
** gen amenity variables
********************************************************************************
gen dist_school = closest_school_dist
gen dist_center = closest_city_dist
gen dist_road = closest_road_dist
gen dist_river = closest_river_dist
gen dist_space = closest_green_dist

// gen transit_dist = transit_dist_m/1609

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
global char_vars i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num

*global char_vars dist_road
*global char_vars_duhe dist_road soil_avgslope soil_avgrestri


********************************************************************************
** per squarefoot prices
********************************************************************************
gen log_land = log(assd_landval)

*per squarefoot price of land 
gen land_per_sqft = assd_landval/lot_sizesqft
gen log_land_per_sqft = log(land_per_sqft)

gen price_per_sqft = def_saleprice/lot_sizesqft
gen log_ppsqft = log(price_per_sqft)

gen rent_per_sqft = comb_rent2/lot_sizesqft  
gen log_rpsqft = log(rent_per_sqft)


********************************************************************************
** Calculate bindingness identifier variables at the lot level
*		1. min lot size
*		2. height
*		3. mulfam
*		4. maxdu
********************************************************************************
local buffer1 = .1
local buffer2 = .2
 
** 1. min lot size (mls)
* min lot size actual
gen mls_actual = lot_sizesqft if lot_sizesqft!=0

/* mls regulation (only where by-right allowed) 
minlotsize to home_minlotsize 20240920 */

gen mls_byright = home_minlotsize if mnls_esval == 0 & home_minlotsize != 0  // non-imputed
gen mls_all = mnls_eff if mnls_esval != . & mnls_eff != 0  // includes imputed

count if mls_actual == . 
count if mls_byright == . 
count if mls_all == .

* 10% buffer, non-imputed
gen mls_binding_10 = (mls_actual<=(mls_byright*(1 + `buffer2'))) & (mls_actual>=(mls_byright*(1 - `buffer2'))) & mls_actual!=. & mls_byright!=.
replace mls_binding_10 = . if mls_actual==. | mls_byright==.

gen mls_violate_10 = mls_actual<(mls_byright*(1 -`buffer2')) & mls_actual!=. & mls_byright!=.
replace mls_violate_10 = . if mls_actual==. | mls_byright==.

* 10% buffer, all (including imputed)
gen mls_binding_10_all = (mls_actual<=(mls_all*(1 + `buffer2'))) & (mls_actual>=(mls_all*(1 - `buffer2'))) & mls_actual!=. & mls_all!=.
replace mls_binding_10_all = . if mls_actual==. | mls_all==.

gen mls_violate_10_all = mls_actual<(mls_all*(1 -`buffer2')) & mls_actual!=. & mls_all!=.
replace mls_violate_10_all = . if mls_actual==. | mls_all==.

** 2. height
* height actual 
gen height_actual = num_floors1*10 if num_floors1!=.

replace mxfl_eff = mxfl_eff*10  //mult by 10 - 20240923

* height regulation w/ by-right
gen height_byright = maxheight if mxht_esval == 0 & maxheight!=0  // non-imputed
gen height_all = mxfl_eff if mxht_esval!=. & mxfl_eff!=0  // includes imputed

count if height_actual == . 
count if height_byright == . 
count if height_all == . 

local buffer1 = .1
local buffer2 = .2

* 10% buffer, non-imputed
gen height_binding_10 = (height_actual<=(height_byright*(1 + `buffer2'))) & (height_actual>=(height_byright*(1 - `buffer2'))) & height_actual!=. & height_byright!=. 
replace height_binding_10 = . if height_actual==. | height_byright==. 

gen height_violate_10 = height_actual>(height_byright*(1 +`buffer2')) & height_actual!=. & height_byright!=. 
replace height_violate_10 = . if height_actual==. | height_byright==.

*10% buffer, all (including imputed)
local buffer1 = .1
local buffer2 = .2

gen height_binding_10_all = (height_actual<=(height_all*(1 + `buffer2'))) & (height_actual>=(height_all*(1 - `buffer2'))) & height_actual!=. & height_all!=. 
replace height_binding_10_all = . if height_actual==. | height_all==. 
gen height_violate_10_all = height_actual>(height_all*(1 +`buffer2')) & height_actual!=. & height_all!=. 
replace height_violate_10_all = . if height_actual==. | height_all==.

** 3. mulfam 
* mulfam actual 
gen mf_actual = num_units1 if num_units1!=.

* mulfam by-right regulation 
gen mf_byright = home_mulfam if home_mulfam!=. 

*binding relative to regulation
gen mf_binding = (mf_byright==1 & mf_actual>1)
replace mf_binding = . if mf_byright == . | mf_actual == .

gen mf_violate = (mf_byright==0 & mf_actual>1)  // more than one unit on a lot even though mf not allowed
replace mf_violate = . if mf_byright == . | mf_actual == . 

local buffer1 = .1
local buffer2 = .2

** 4. maxdu 
* maxdu actual 
gen maxdu_actual = num_units1 if num_units1!=.

* maxdu regulation w/ by-right
gen maxdu_byright = maxdu if mxdu_esval == 0 & maxdu!=0           /*non-imputed*/
gen maxdu_all = mxdu_eff if mxdu_esval!= . & mxdu_eff!=0          /*includes imputed*/

count if maxdu_actual == . 
count if maxdu_byright == . 
count if maxdu_all == . 

* 10% buffer, non-imputed
gen maxdu_binding_10 = (maxdu_actual<=(maxdu_byright*(1 + `buffer2'))) & (maxdu_actual>=(maxdu_byright*(1 - `buffer2'))) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_binding_10 = . if maxdu_actual==. | maxdu_byright==.

gen maxdu_violate_10 = maxdu_actual>(maxdu_byright*(1 +`buffer2')) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_violate_10 = . if maxdu_actual==. | maxdu_byright==.

* 10% buffer, all (including imputed)
gen maxdu_binding_10_all = (maxdu_actual<=(maxdu_all*(1 + `buffer2'))) & (maxdu_actual>=(maxdu_all*(1 - `buffer2'))) & maxdu_actual!=. & maxdu_all!=. 
replace maxdu_binding_10_all = . if maxdu_actual==. | maxdu_all==. 

gen maxdu_violate_10_all = maxdu_actual>(maxdu_all*(1 +`buffer2')) & maxdu_actual!=. & maxdu_all!=. 
replace maxdu_violate_10_all = . if maxdu_actual==. | maxdu_all==.


********************************************************************************
** Identifying binding boundaries
********************************************************************************
* non-imputed regulations, based on 5% and 10
* what is missing
count if mls_binding_10 == . 
count if height_binding_10 == . 
count if maxdu_binding_10 == .
count if mf_binding == . 

foreach l in mls height maxdu {
	foreach j in 10{
			by lam_seg, sort: egen frac_binding_`l'_`j' = mean(`l'_binding_`j')
	}
} 

* mf is separate 
by lam_seg, sort: egen frac_binding_mf = mean(mf_binding)

count if frac_binding_mls_10 == . 
count if frac_binding_height_10 == .
count if frac_binding_maxdu_10 == . 
count if frac_binding_far_10 == .
count if frac_binding_mf == . 

* all, based on 10% and 20%, what is missing
count if mls_binding_10_all == . 
count if height_binding_10_all == . 
count if maxdu_binding_10_all == .

foreach l in mls height maxdu {
	foreach j in 10{
			by lam_seg, sort: egen frac_binding_`l'_`j'_all = mean(`l'_binding_`j'_all)
	}
} 

count if frac_binding_mls_10_all == . 
count if frac_binding_height_10_all == .
count if frac_binding_maxdu_10_all == . 

/* AK (1/23/2025) commenting this out for now, but need to double check that we 
don't need maybe one summary statistic from this part
********************************************************************************
** Part 1: generate summary statistics tables
********************************************************************************
gen boundary_reg = .
replace boundary_reg = 1 if only_mf == 1
replace boundary_reg = 2 if only_he == 1
replace boundary_reg = 3 if only_du == 1
replace boundary_reg = 4 if mf_he == 1
replace boundary_reg = 5 if mf_du == 1
replace boundary_reg = 6 if du_he == 1

lab define boundary_reg_lbl ///
1 "only_mf" ///
2 "only_he" ///
3 "only_du" ///
4 "mf_he" ///
5 "mf_du" ///
6 "du_he", replace

lab val boundary_reg boundary_reg_lbl

** binding regulations +- 5% only non-imputed
* no year-built restriction
table boundary_reg , stat(mean mls_binding_05 mls_violate_05 height_binding_05 height_violate_05 far_binding_05 far_violate_05 far_binding_05_2 far_violate_05_2 maxdu_binding_05 maxdu_violate_05 mf_binding mf_violate) nformat(%4.3fc)

* year built >=1918
table boundary_reg if year_built>=1918 , stat(mean mls_binding_05 mls_violate_05 height_binding_05 height_violate_05 far_binding_05 far_violate_05 far_binding_05_2 far_violate_05_2 maxdu_binding_05 maxdu_violate_05 mf_binding mf_violate) nformat(%4.3fc)

//table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6) & year_built>=1918, c(mean mls_binding_05 mean mls_violate_05 mean height_binding_05 mean height_violate_05 mean far_binding_05 mean far_violate_05 mean far_binding_05_2 mean far_violate_05_2 mean maxdu_binding_05 mean maxdu_violate_05 mean mf_binding mean mf_violate) format(%4.3fc)

* year built > = 1956
*table boundary_reg if year_built>=1956 , stat(mean mls_binding_05 mls_violate_05 height_binding_05 height_violate_05 far_binding_05 far_violate_05 far_binding_05_2 far_violate_05_2 maxdu_binding_05 maxdu_violate_05 mf_binding mf_violate) nformat(%4.3fc)

** binding regulations +- 10% only non-imputed
* no year_built restriction 
table boundary_reg, stat(mean mls_binding_10 mls_violate_10 height_binding_10 height_violate_10 far_binding_10 far_violate_10 far_binding_10_2 far_violate_10_2 maxdu_binding_10 maxdu_violate_10  mf_binding mf_violate) nformat(%4.3fc)

//table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6), c(mean mls_binding_10 mean mls_violate_10 mean height_binding_10 mean height_violate_10 mean far_binding_10 mean far_violate_10 mean far_binding_10_2 mean far_violate_10_2 mean maxdu_binding_10 mean maxdu_violate_10 mean mf_binding mean mf_violate) format(%4.3fc)

* year built >=1918
table boundary_reg if year_built>=1918, stat(mean mls_binding_10 mls_violate_10 height_binding_10 height_violate_10 far_binding_10 far_violate_10 far_binding_10_2 far_violate_10_2 maxdu_binding_10 maxdu_violate_10  mf_binding mf_violate) nformat(%4.3fc)

* year built > = 1956
*table boundary_reg if year_built>=1956, stat(mean mls_binding_10 mls_violate_10 height_binding_10 height_violate_10 far_binding_10 far_violate_10 far_binding_10_2 far_violate_10_2 maxdu_binding_10 maxdu_violate_10  mf_binding mf_violate) nformat(%4.3fc)

** binding regulations +- 5% all
* no year_built restriction 
table boundary_reg, stat(mean mls_binding_05_all mls_violate_05_all height_binding_05_all height_violate_05_all far_binding_05_all far_violate_05_all far_binding_05_all_2 far_violate_05_all_2 maxdu_binding_05_all maxdu_violate_05_all mf_binding mf_violate) nformat(%4.3fc)

//table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6), c(mean mls_binding_05_all mean mls_violate_05_all mean height_binding_05_all mean height_violate_05_all mean far_binding_05_all mean far_violate_05_all mean far_binding_05_all_2 mean far_violate_05_all_2 mean maxdu_binding_05_all mean maxdu_violate_05_all mean mf_binding mean mf_violate) format(%4.3fc)

*year built >=1918
table boundary_reg if year_built>=1918, stat(mean mls_binding_05_all mls_violate_05_all height_binding_05_all height_violate_05_all far_binding_05_all far_violate_05_all far_binding_05_all_2 far_violate_05_all_2 maxdu_binding_05_all maxdu_violate_05_all mf_binding mf_violate) nformat(%4.3fc)

*year built > = 1956
*table boundary_reg if year_built>=1956, stat(mean mls_binding_05_all mls_violate_05_all height_binding_05_all height_violate_05_all far_binding_05_all far_violate_05_all far_binding_05_all_2 far_violate_05_all_2 maxdu_binding_05_all maxdu_violate_05_all mf_binding mf_violate) nformat(%4.3fc)



*binding regulations +- 10% all
*no year_built restriction 
table boundary_reg, stat(mean mls_binding_10_all mls_violate_10_all height_binding_10_all height_violate_10_all far_binding_10_all far_violate_10_all far_binding_10_all_2 far_violate_10_all_2 maxdu_binding_10_all maxdu_violate_10_all mf_binding mf_violate) nformat(%4.3fc)

*table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6), c(mean mls_binding_10_all mean mls_violate_10_all mean height_binding_10_all mean height_violate_10_all mean far_binding_10_all mean far_violate_10_all mean far_binding_10_all_2 mean far_violate_10_all_2 mean maxdu_binding_10_all mean maxdu_violate_10_all mean mf_binding mean mf_violate) format(%4.3fc)

*year built >=1918
table boundary_reg if year_built>=1918, stat(mean mls_binding_10_all mls_violate_10_all height_binding_10_all height_violate_10_all far_binding_10_all far_violate_10_all far_binding_10_all_2 far_violate_10_all_2 maxdu_binding_10_all maxdu_violate_10_all mf_binding mf_violate) nformat(%4.3fc)

*year built > = 1956
*table boundary_reg if year_built>=1956, stat(mean mls_binding_10_all mls_violate_10_all height_binding_10_all height_violate_10_all far_binding_10_all far_violate_10_all far_binding_10_all_2 far_violate_10_all_2 maxdu_binding_10_all maxdu_violate_10_all mf_binding mf_violate) nformat(%4.3fc)

*average bindingness and counts at boundary level 
table boundary_reg, stat(mean frac_binding_mls_05 frac_binding_height_05 frac_binding_far_05 frac_binding_far_2_05 frac_binding_maxdu_05 frac_binding_mf) nformat(%4.3fc)
table boundary_reg, stat(count frac_binding_mls_05 frac_binding_height_05 frac_binding_far_05 frac_binding_far_2_05 frac_binding_maxdu_05 frac_binding_mf) nformat(%4.3fc)

table boundary_reg , stat(mean frac_binding_mls_10 frac_binding_height_10 frac_binding_far_10 frac_binding_far_2_10 frac_binding_maxdu_10 frac_binding_mf) nformat(%4.3fc)
table boundary_reg , stat(count frac_binding_mls_10 frac_binding_height_10 frac_binding_far_10 frac_binding_far_2_10 frac_binding_maxdu_10 frac_binding_mf) nformat(%4.3fc)

table boundary_reg, stat(mean frac_binding_mls_05_all frac_binding_height_05_all frac_binding_far_05_all frac_binding_far_2_05_all frac_binding_maxdu_05_all frac_binding_mf) nformat(%4.3fc)
table boundary_reg, stat(count frac_binding_mls_05_all frac_binding_height_05_all frac_binding_far_05_all frac_binding_far_2_05_all frac_binding_maxdu_05_all frac_binding_mf) nformat(%4.3fc)

table boundary_reg, stat(mean frac_binding_mls_10_all frac_binding_height_10_all frac_binding_far_10_all frac_binding_far_2_10_all frac_binding_maxdu_10_all frac_binding_mf) nformat(%4.3fc)
table boundary_reg, stat(count frac_binding_mls_10_all frac_binding_height_10_all frac_binding_far_10_all frac_binding_far_2_10_all frac_binding_maxdu_10_all frac_binding_mf) nformat(%4.3fc)

*/

		
********************************************************************************
** Part 5: Regressions sales prices + rents bindingness > 15% + > 25%
** use maxdu AND mls for density 
********************************************************************************
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* unique boundaries overall
unique lam_seg if `regression_conditions' & only_du == 1 & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1  & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & log_saleprice!=.

* unique boundaries with bindingness 15%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & frac_binding_mf>0.15 & frac_binding_mf!=. & log_saleprice!=.

* unique boundaries with bindingness 25%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & frac_binding_mf>0.25 & frac_binding_mf!=. & log_saleprice!=.

** Part 5A: Sales price, bindingness 
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Prices >15% binding") 
	
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/salesprice_table_bindingness15_maxdumls.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear

** Part 5B: Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions' &  frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/salesprice_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_he"  "price_duhe"  "price_mfdu" "price_mf" ) ///
	title("Sales Prices, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 

** Part 5E: Rents > 15% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* unique boundaries overall (for rents)
unique lam_seg if `regression_conditions' & only_du == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & log_mfrent!=.

* unique boundaries with bindingness 15%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_mfrent!=.


* unique boundaries with bindingness 25%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=. & log_mfrent!=.

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_duhe1  using "$RDPATH/rents_table_bindingness15_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 
	
** Part 5F: Rents > 15% , characteristics 	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) , vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du  rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_duhe1 using "$RDPATH/rents_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 


********************************************************************************
** end
********************************************************************************
log close
clear all 

display "finished!" 
