********************************************************************************
*Bindingness of different regulations and boundaries with binding regs**********
********************************************************************************

clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREStat_rd_bindingness" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postREStat_bindingness.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		analyzes the bindingness of regulations
*
*					Part 0: Optimal bandwidths
*					Part 1A: Sales price, bindingness w/o characteristics
*					Part 1B: Sales price bindingness > 50% w/o characteristics
* 					Part 1C: With characteristic controls bindingness > 25%
*					Part 1D: With characteristic controls bindingness > 50%
*					Part 1E: Sales price, bindingness > 15% w/o charactersitics
*					Part 1F: With characteristic controls bindingness > 15%
*					Part 2A: Rent bindingness > 25% w/o characteristics
*					Part 2B: Rent bindingness > 50% w/o characteristics
*					Part 2C: Rent With characteristic controls bindingness > 25%
*					Part 2D: Rent With characteristic controls bindingness > 50%
*					Part 2E: Rent bindingness > 15% w/o characteristics
*					Part 2F: Rent with characteristic controls bindingness > 15%  
*					Part 3: No year f.e. 
*					Part 4: Sales prices, using maxdu 
*					Part 5A-H: Repeats 1A,C,E,F and 2A,C,E,F considering mls AND maxdu
*					Part 6A-H: Repeats 1A,C,E,F and 2A,C,E,F with price and rent per sqft as DV
*					Part 7: Repeats 1A,C,E,F with land price per sqft
* 				
* Inputs:			"$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_moreregs.dta"
*					"$SHAPEPATH/soil_quality/soil_quality_matches.dta"
*					"$DATAPATH/warren_zoning_regulations_match.dta"
*					"$DATAPATH/final_dataset_10-28-2021.dta"
*				
* Outputs:			various .tex tables and a log file
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
** load final dataset
********************************************************************************
//use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postREStat within town setup file
********************************************************************************
//run "$DOPATH/postREStat_within_town_setup_07102024.do"
// do "$DOPATH/postREStat_within_town_setup.do"  // Note that this set up file may already exist without the data tage

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear

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

/* End REStat revisions from 03-27-2024 */


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
** Calculate bindingness at the lot level
* 1. min lot size
* 2. height
* 3. mulfam
* 4. maxdu
* 5. FAR using gross building area
* 6. FAR living area
********************************************************************************
local buffer1 = .1
local buffer2 = .2
 
** 1. min lot size (mls)
* mls actual
gen mls_actual = lot_sizesqft if lot_sizesqft!=0

* mls regulation (only where by-right allowed) -- minlotsize to home_minlotsize 20240920
gen mls_byright = home_minlotsize if mnls_esval == 0 & home_minlotsize != 0      /*non-imputed*/
gen mls_all = mnls_eff if mnls_esval != . & mnls_eff != 0              /*includes imputed*/

count if mls_actual == . 
count if mls_byright == . 
count if mls_all == .

** binding/violation relative to regulation
* 5% buffer
* non-imputed
gen mls_binding_05 = (mls_actual<=(mls_byright*(1 + `buffer1'))) & (mls_actual>=(mls_byright*(1 - `buffer1'))) & mls_actual!=. & mls_byright!=.
replace mls_binding_05 = . if mls_actual==. | mls_byright==.
gen mls_violate_05 = mls_actual<(mls_byright*(1 -`buffer1')) & mls_actual!=. & mls_byright!=.
replace mls_violate_05 = . if mls_actual==. | mls_byright==.

* 5% buffer
* all (including imputed)
gen mls_binding_05_all = (mls_actual<=(mls_all*(1 + `buffer1'))) & (mls_actual>=(mls_all*(1 - `buffer1'))) & mls_actual!=. & mls_all!=.
replace mls_binding_05_all = . if mls_actual==. | mls_all==.
gen mls_violate_05_all = mls_actual<(mls_all*(1 -`buffer1')) & mls_actual!=. & mls_all!=. 
replace mls_violate_05_all = . if mls_actual==. | mls_all==.

* 10% buffer
* non-imputed
gen mls_binding_10 = (mls_actual<=(mls_byright*(1 + `buffer2'))) & (mls_actual>=(mls_byright*(1 - `buffer2'))) & mls_actual!=. & mls_byright!=.
replace mls_binding_10 = . if mls_actual==. | mls_byright==.
gen mls_violate_10 = mls_actual<(mls_byright*(1 -`buffer2')) & mls_actual!=. & mls_byright!=.
replace mls_violate_10 = . if mls_actual==. | mls_byright==.

* 10% buffer
* all (including imputed)
gen mls_binding_10_all = (mls_actual<=(mls_all*(1 + `buffer2'))) & (mls_actual>=(mls_all*(1 - `buffer2'))) & mls_actual!=. & mls_all!=.
replace mls_binding_10_all = . if mls_actual==. | mls_all==.
gen mls_violate_10_all = mls_actual<(mls_all*(1 -`buffer2')) & mls_actual!=. & mls_all!=.
replace mls_violate_10_all = . if mls_actual==. | mls_all==.

** 2. height
* height actual 
gen height_actual = num_floors1*10 if num_floors1!=.

replace mxfl_eff = mxfl_eff*10 //mult by 10 - 20240923


* height regulation w/ by-right
gen height_byright = maxheight if mxht_esval == 0 & maxheight!=0  /*non-imputed*/
gen height_all = mxfl_eff if mxht_esval!=. & mxfl_eff!=0          /*includes imputed*/

count if height_actual == . 
count if height_byright == . 
count if height_all == . 

local buffer1 = .1
local buffer2 = .2

** binding/violation relative to regulation
* 5% buffer
* non-imputed
gen height_binding_05 = (height_actual<=(height_byright*(1 + `buffer1'))) & (height_actual>=(height_byright*(1 - `buffer1'))) & height_actual!=. & height_byright!=. 
replace height_binding_05 = . if height_actual==. | height_byright==.
gen height_violate_05 = height_actual>(height_byright*(1 +`buffer1')) & height_actual!=. & height_byright!=. 
replace height_violate_05 = . if height_actual==. | height_byright==.

* 5% buffer
* all (including imputed)
gen height_binding_05_all = (height_actual<=(height_all*(1 + `buffer1'))) & (height_actual>=(height_all*(1 - `buffer1'))) & height_actual!=. & height_all!=. 
replace height_binding_05_all = . if height_actual==. | height_all==.
gen height_violate_05_all = height_actual>(height_all*(1 +`buffer1')) & height_actual!=. & height_all!=. 
replace height_violate_05_all = . if height_actual==. | height_all==.

*10% buffer
*non-imputed
gen height_binding_10 = (height_actual<=(height_byright*(1 + `buffer2'))) & (height_actual>=(height_byright*(1 - `buffer2'))) & height_actual!=. & height_byright!=. 
replace height_binding_10 = . if height_actual==. | height_byright==. 
gen height_violate_10 = height_actual>(height_byright*(1 +`buffer2')) & height_actual!=. & height_byright!=. 
replace height_violate_10 = . if height_actual==. | height_byright==.

*10% buffer
*all (including imputed)

local buffer1 = .1
local buffer2 = .2

gen height_binding_10_all = (height_actual<=(height_all*(1 + `buffer2'))) & (height_actual>=(height_all*(1 - `buffer2'))) & height_actual!=. & height_all!=. 
replace height_binding_10_all = . if height_actual==. | height_all==. 
gen height_violate_10_all = height_actual>(height_all*(1 +`buffer2')) & height_actual!=. & height_all!=. 
replace height_violate_10_all = . if height_actual==. | height_all==.


***********************************************************
** 3. mulfam 
* mulfam actual 
gen mf_actual = num_units1 if num_units1!=.

* mulfam by-right regulation 
gen mf_byright = home_mulfam if home_mulfam!=. 

*binding relative to regulation
gen mf_binding = (mf_byright==1 & mf_actual>1)
replace mf_binding = . if mf_byright == . | mf_actual == .
gen mf_violate = (mf_byright==0 & mf_actual>1)    /*more than one unit on a lot even though mf not allowed*/
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

** binding relative to regulation
* 5% buffer
* non-imputed
gen maxdu_binding_05 = (maxdu_actual<=(maxdu_byright*(1 + `buffer1'))) & (maxdu_actual>=(maxdu_byright*(1 - `buffer1'))) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_binding_05 = . if maxdu_actual==. | maxdu_byright==.
gen maxdu_violate_05 = maxdu_actual>(maxdu_byright*(1 +`buffer1')) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_violate_05 = . if maxdu_actual==. | maxdu_byright==.

* 5% buffer
* all (including imputed)
gen maxdu_binding_05_all = (maxdu_actual<=(maxdu_all*(1 + `buffer1'))) & (maxdu_actual>=(maxdu_all*(1 - `buffer1'))) & maxdu_actual!=. & maxdu_all!=. 
replace maxdu_binding_05_all = . if maxdu_actual==. | maxdu_all==.
gen maxdu_violate_05_all = maxdu_actual>(maxdu_all*(1 +`buffer1')) & maxdu_actual!=. & maxdu_all!=. 
replace maxdu_violate_05_all = . if maxdu_actual==. | maxdu_all==.

* 10% buffer
* non-imputed
gen maxdu_binding_10 = (maxdu_actual<=(maxdu_byright*(1 + `buffer2'))) & (maxdu_actual>=(maxdu_byright*(1 - `buffer2'))) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_binding_10 = . if maxdu_actual==. | maxdu_byright==.
gen maxdu_violate_10 = maxdu_actual>(maxdu_byright*(1 +`buffer2')) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_violate_10 = . if maxdu_actual==. | maxdu_byright==.

* 10% buffer
* all (including imputed)
gen maxdu_binding_10_all = (maxdu_actual<=(maxdu_all*(1 + `buffer2'))) & (maxdu_actual>=(maxdu_all*(1 - `buffer2'))) & maxdu_actual!=. & maxdu_all!=. 
replace maxdu_binding_10_all = . if maxdu_actual==. | maxdu_all==. 
gen maxdu_violate_10_all = maxdu_actual>(maxdu_all*(1 +`buffer2')) & maxdu_actual!=. & maxdu_all!=. 
replace maxdu_violate_10_all = . if maxdu_actual==. | maxdu_all==.

** 5. FAR using grossbldg aea
* FAR using grossbldg area actual 
gen far_actual = grossbldg_area/lot_sizesqft if grossbldg_area!=0 & lot_sizesqft!=0
sum far_actual,d


* FAR using grossbldg area regulation w/ by-right
gen far_byright = far if far_esval == 0 &far!=0                   /*non-imputed*/
gen far_all = far_eff if far_esval!=. & far_eff!=0                /*includes imputed*/
sum far far_eff,d

count if far_actual == . 
count if far_byright == . 
count if far_all == . 

* binding relative to regulation 
* 5% buffer
* non-imputed
gen far_binding_05 = (far_actual<=(far_byright*(1 + `buffer1'))) & (far_actual>=(far_byright*(1 - `buffer1'))) & far_actual!=. & far_byright!=. 
replace far_binding_05= . if far_actual==. | far_byright==. 
gen far_violate_05 = far_actual>(far_byright*(1 +`buffer1')) & far_actual!=. & far_byright!=. 
replace far_violate_05 = . if far_actual==. | far_byright==. 

* 5% buffer
* all (including imputed)
gen far_binding_05_all = (far_actual<=(far_all*(1 + `buffer1'))) & (far_actual>=(far_all*(1 - `buffer1'))) & far_actual!=. & far_all!=. 
replace far_binding_05_all =. if far_actual==. | far_all==. 
gen far_violate_05_all = far_actual>(far_all*(1 +`buffer1')) & far_actual!=. & far_all!=. 
replace far_violate_05_all = . if far_actual==. | far_all==.

* 10% buffer
* non-imputed
gen far_binding_10 = (far_actual<=(far_byright*(1 + `buffer2'))) & (far_actual>=(far_byright*(1 - `buffer2'))) & far_actual!=. & far_byright!=. 
replace far_binding_10 = . if far_actual==. | far_byright==.
gen far_violate_10 = far_actual>(far_byright*(1 +`buffer2')) & far_actual!=. & far_byright!=. 
replace far_violate_10 = . if far_actual==. | far_byright==.

* 10% buffer
* all (including imputed)
gen far_binding_10_all = (far_actual<=(far_all*(1 + `buffer2'))) & (far_actual>=(far_all*(1 - `buffer2'))) & far_actual!=. & far_all!=. 
replace far_binding_10_all = . if  far_actual==. | far_all==. 
gen far_violate_10_all = far_actual>(far_all*(1 +`buffer2')) & far_actual!=. & far_all!=. 
replace far_violate_10_all= . if  far_actual==. | far_all==. 

** 6. FAR using living area
* FAR using living area actual 
gen far_actual_2 = livingarea/lot_sizesqft if livingarea!=0 & lot_sizesqft!=0

* binding relative to regulation 
* 5% buffer
* non-imputed
gen far_binding_05_2 = (far_actual_2<=(far_byright*(1 + `buffer1'))) & (far_actual_2>=(far_byright*(1 - `buffer1'))) & far_actual_2!=. & far_byright!=. 
replace far_binding_05_2 = . if far_actual_2==. | far_byright==. 
gen far_violate_05_2 = far_actual_2>(far_byright*(1 +`buffer1')) & far_actual_2!=. & far_byright!=. 
replace far_violate_05_2 = . if far_actual_2==. | far_byright==. 

* 5% buffer
* all (including imputed)
gen far_binding_05_all_2 = (far_actual_2<=(far_all*(1 + `buffer1'))) & (far_actual_2>=(far_all*(1 - `buffer1'))) & far_actual_2!=. & far_all!=. 
replace far_binding_05_all_2 = . if  far_actual_2==. | far_all==.
gen far_violate_05_all_2 = far_actual_2>(far_all*(1 +`buffer1')) & far_actual_2!=. & far_all!=.
replace far_violate_05_all_2=. if far_actual_2==. | far_all==. 

* 10% buffer
* non-imputed
gen far_binding_10_2 = (far_actual_2<=(far_byright*(1 + `buffer2'))) & (far_actual_2>=(far_byright*(1 - `buffer2'))) & far_actual_2!=. & far_byright!=. 
replace far_binding_10_2 = . if far_actual_2==. | far_byright==.
gen far_violate_10_2 = far_actual_2>(far_byright*(1 +`buffer2')) & far_actual_2!=. & far_byright!=. 
replace far_violate_10_2 = . if far_actual_2==. | far_byright==. 

* 10% buffer
* all (including imputed)
gen far_binding_10_all_2 = (far_actual_2<=(far_all*(1 + `buffer2'))) & (far_actual_2>=(far_all*(1 - `buffer2'))) & far_actual_2!=. & far_all!=. 
replace far_binding_10_all_2 = . if far_actual_2==. | far_all==. 
gen far_violate_10_all_2 = far_actual_2>(far_all*(1 +`buffer2')) & far_actual_2!=. & far_all!=. 
replace far_violate_10_all_2 = . if far_actual_2==. | far_all==. 


********************************************************************************
** Identifying binding boundaries
********************************************************************************
* non-imputed regulations
* based on 5% and 10

*what is missing
count if mls_binding_10 == . 
count if height_binding_10 == . 
count if maxdu_binding_10 == .
count if far_binding_10 == . 
count if mf_binding == . 

foreach l in mls height maxdu far{
	foreach j in 05 10{
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


* all
* based on 10% and 20%
*what is missing
count if mls_binding_10_all == . 
count if height_binding_10_all == . 
count if maxdu_binding_10_all == .
count if far_binding_10_all == . 

foreach l in mls height maxdu far{
	foreach j in 05 10{
			by lam_seg, sort: egen frac_binding_`l'_`j'_all = mean(`l'_binding_`j'_all)
	}
} 


count if frac_binding_mls_10_all == . 
count if frac_binding_height_10_all == .
count if frac_binding_maxdu_10_all == . 
count if frac_binding_far_10_all == .


* far2
by lam_seg, sort: egen frac_binding_far_2_05 = mean(far_binding_05_2)
by lam_seg, sort: egen frac_binding_far_2_10 = mean(far_binding_10_2)
by lam_seg, sort: egen frac_binding_far_2_05_all = mean(far_binding_05_all_2)
by lam_seg, sort: egen frac_binding_far_2_10_all = mean(far_binding_10_all_2)


********************************************************************************
** generate summary statistics tables
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



********************************************************************************
* Part 0
* Bandwidth selection
********************************************************************************

*sales prices 
*only du
*binding>25%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. , c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. , c(0) all

*with maxdu 
*binding>25%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. , c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , c(0) all

*only mf
*binding>25%
rdbwselect log_saleprice dist_both if only_mf == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mf>0.25 & frac_binding_mf!=., c(0) all 
*binding>15%
rdbwselect log_saleprice dist_both if only_mf == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mf>0.15 & frac_binding_mf!=., c(0) all 

*not enough sample - commenting out
/*
*duhe
*mls
*binding>25%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all
*/

*maxdu
*binding>25%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all

*mfdu
*mls
*binding>25%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_mf>0.25 & frac_binding_mf!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., c(0) all

*maxdu
*binding>25%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.25 & frac_binding_mf!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., c(0) all


*rents 
*only du 
*mls
*binding>25%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., c(0) all 
*binding>15%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., c(0) all 

*maxdu
*binding>25%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=., c(0) all 
*binding>15%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., c(0) all 

*duhe
*mls
*binding>25% 
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all

*maxdu
*binding>25% 
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all




********************************************************************************
* Part 1
* Regressions
* Sales Prices
********************************************************************************
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

** Part 1A: Sales price, bindingness 
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

*only take density as binding
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 

*only mf binding
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

* older esttab version, pre REStat
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
	title("Sales Prices >25% binding") 
	
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness25.tex", ///
	replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
	title("Sales Prices >25% binding") 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)

* only take density as binding
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 

* only mf binding
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_duhe2_robust price_mfdu_robust price_mfdu2_robust price_mf_robust , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices >25% binding, robust s.e.") 

eststo clear


** Part 1B: Sales price bindingness > 50%
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* only take density as binding
*quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_mf>0.5 & frac_binding_mf!=., vce(cluster lam_seg) 

*only mf binding
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(cluster lam_seg) 

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(cluster lam_seg)

* older esttab version, pre REStat
esttab price_du price_he price_mfdu price_mfdu2 price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices >50% binding") 
	
esttab price_du price_he price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness50.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices >50% binding") 


* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)
*quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

* only take density as binding
*quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_mf>0.5 & frac_binding_mf!=., vce(robust) 

* only mf binding
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust  price_mfdu_robust price_mfdu2_robust price_mf_robust, ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
label mtitles("price_du" "price_he"  "price_mfdu" "price_mfdu2" "price_mf") ///
title("Sales Prices >50% binding, robust s.e.")

eststo clear	

** Part 1C With characteristic controls bindingness > 25%	
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* only take density as binding
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

* only mf binding
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >25% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness25_addcontrols.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >25% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)

* only take density as binding
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

* only mf binding
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_duhe2_robust price_mfdu_robust price_mfdu2_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
	title("Sales Prices, >25% binding, w/ characteristics, robust s.e.") 
	
eststo clear 

** Part 1D: With characteristic controls bindingness > 50%
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions'  & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)
*quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* only take density as binding
*quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_mf>0.5 & frac_binding_mf!=., vce(cluster lam_seg)

* only mf binding
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(cluster lam_seg)
	
esttab price_du price_he  price_mfdu price_mfdu2 price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he"  "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >50% binding, w/ characteristics") 	
	
esttab price_du price_he  price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness50_addcontrols.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he"  "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >50% binding, w/ characteristics") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions'  & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)
*quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

* only take density as binding
*quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_mf>0.5 & frac_binding_mf!=., vce(robust)

* only mf binding
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.5 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust  price_mfdu_robust price_mfdu2_robust price_mf2_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he"  "price_mfdu" "price_mfdu2" "price_mf" ) ///
	title("Sales Prices, >50% binding, w/ characteristics, robust s.e.") 
eststo clear 


********************************************************************************
* Part 1 (E-F)
* Regressions
* Sales Prices
* 15% bindingness
********************************************************************************
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

** Part 1E: Sales price, bindingness 
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* only take density as binding
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. , vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 

* only mf binding
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
	title("Sales Prices >15% binding") 
	
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness15.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* only du binding
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

* only mf binding
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' &  frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_duhe2_robust price_mfdu_robust price_mfdu2_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2"  "price_mfdu"  "price_mfdu2" "price_mf" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear

** Part 1F With characteristic controls bindingness > 15%
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions' &  frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' &  frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' &  frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness15_addcontrols.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)

quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_duhe2_robust price_mfdu_robust price_mfdu2_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_he"  "price_duhe"  "price_duhe2"  "price_mfdu" "price_mfdu2" "price_mf" ) ///
	title("Sales Prices, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 


********************************************************************************
* Part 2 (A-B)
* Regressions
* Rents
* w/o characteristics
********************************************************************************
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

** Part 2A: bindingness > 25%
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >25%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness25.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >25%") 

eststo clear	
	
* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. , vce(robust)
	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >25%") 	

	
eststo clear 	

** Part 2B: bindingness > 50% w/o characteristics
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

** Part 2A: bindingness > 25%
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)
* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)
* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)
* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3,se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >50%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness50.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >50%") 

eststo clear	
	
* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. , vce(robust)
	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >50%") 	

	
********************************************************************************
* Part 2 (C-D)
* Regressions
* Rents
* With characteristic controls
********************************************************************************
** Part 2C: With characteristic controls bindingness > 25%
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3,  se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >25%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness25_addcontrols.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >25%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=. , vce(robust)

noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >25%") 	

eststo clear 
	
** Part 2D: With characteristic controls bindingness > 50%
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >50%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness50_addcontrols.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >50%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.5 & frac_binding_maxdu_10_all!=. , vce(robust)
	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.5 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.5 & frac_binding_height_10_all!=., vce(robust)

esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >50%") 	

eststo clear 

	
********************************************************************************
* Part 2 (E-F)
* Regressions
* Rents
* bindingness > 15%
********************************************************************************
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

** Part 2E: bindingness > 15%
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness15.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(robust)
	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 

** Part 2F: bindingness>15, with characteristics 
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness15_addcontrols.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(robust)
	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 


********************************************************************************
* Part 3 
* Regressions
* Sales prices + rents 
* bindingness > 15%
* no year f.e. 
********************************************************************************
** Part 3a: sales prices 	
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

** Part 6A: Sales price, bindingness 
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg  if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg  if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* only take density as binding
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg  if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. , vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 

* only mf binding
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg  if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg  if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
	title("Sales Prices >15% binding") 
	
	
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness15_noyear.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg  if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg  if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg  if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* only du binding
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg  if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg  if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

* only mf binding
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg if  mf_du == 1 & `regression_conditions' &  frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_duhe2_robust price_mfdu_robust price_mfdu2_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_duhe2"  "price_mfdu"  "price_mfdu2" "price_mf" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear

** With characteristic controls bindingness > 15%
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if only_he == 1 & `regression_conditions' &  frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if du_he == 1 & `regression_conditions' &  frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg $char_vars if du_he == 1 & `regression_conditions' &  frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_duhe2 price_mfdu price_mfdu2 price_mf  using "$RDPATH/salesprice_table_bindingness15_addcontrols_noyear.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_duhe2" "price_mfdu" "price_mfdu2" "price_mf") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg  $char_vars if du_he == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
 
esttab price_du_robust price_he_robust price_duhe_robust price_duhe2_robust price_mfdu_robust price_mfdu2_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
	label mtitles("price_du"  "price_he"  "price_duhe"  "price_duhe2"  "price_mfdu" "price_mfdu2" "price_mf" ) ///
	title("Sales Prices, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 

** Part 3b: rents 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness15_noyear.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg  if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg  if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg  if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg  if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(robust)
	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg  if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 

* with characteristics 
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(cluster lam_seg)

* use maxdu instead
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)
  
* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* height binding
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* maxdu binding
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
	
noi cap eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_du2 rent_duhe1 rent_duhe2 rent_duhe3 using "$RDPATH/rents_table_bindingness15_addcontrols_noyear.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" ) interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if only_du==1 & `regression_conditions' & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., vce(robust)

* use maxdu instead
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)

* using maxdu 
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* height binding
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* maxdu binding
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(robust)

	
noi cap eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg  $char_vars if du_he == 1 & `regression_conditions'  & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_du2_robust rent_duhe1_robust rent_duhe2_robust rent_duhe3_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
 	label mtitles("rent_du" "rent_du2" "rent_duhe1" "rent_duhe2" "rent_duhe3" ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 

	
********************************************************************************
* Part 4 
* Regressions
* Sales prices 
* bindingness > 15%
* use maxdu for density 
********************************************************************************
** Part 4A: max du instead of mls
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if du_he == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)

* only take density as binding
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if du_he == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if  mf_du == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 

esttab price_du price_duhe price_duhe2 price_mfdu , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_duhe2" "price_mfdu") ///
	title("Sales Prices >15% binding") 
	
	
esttab price_du price_duhe price_duhe2 price_mfdu   using "$RDPATH/salesprice_table_bindingness15_maxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr" ) interaction(" X ") ///
 	label mtitles("price_du" "price_duhe" "price_duhe2" "price_mfdu") ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if du_he == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)

* only du binding
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if du_he == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  if  mf_du == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust  price_duhe_robust price_duhe2_robust price_mfdu_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_duhe2"  "price_mfdu" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear

** Part 4B: With characteristic controls bindingness > 15%
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if du_he == 1 & `regression_conditions' &  frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if du_he == 1 & `regression_conditions' &  frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_duhe price_duhe2 price_mfdu , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_duhe" "price_duhe2" "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
esttab price_du price_duhe price_duhe2 price_mfdu  using "$RDPATH/salesprice_table_bindingness15_addcontrols_maxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_duhe" "price_duhe2" "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if only_du==1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if du_he == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if du_he == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr  $char_vars if  mf_du == 1 & `regression_conditions' & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_duhe_robust price_duhe2_robust price_mfdu_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_duhe"  "price_duhe2"  "price_mfdu" ) ///
	title("Sales Prices, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 

		
********************************************************************************
* Part 5 
* Regressions
* Sales prices + rents
* bindingness > 15% + > 25%
* use maxdu AND mls for density 
********************************************************************************
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

*unique boundaries overall
unique lam_seg if `regression_conditions' & only_du == 1 & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1  & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & log_saleprice!=.

*unique boundaries with bindingness 15%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & frac_binding_mf>0.15 & frac_binding_mf!=. & log_saleprice!=.

*unique boundaries with bindingness 25%
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


** Part 5C: Sales prices > 25% , no characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

* older esttab version, pre REStat
esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Prices >25% binding") 
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/salesprice_table_bindingness25_mlsmaxdu.tex", ///
	replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Prices >25% binding") 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices >25% binding, robust s.e.") 

eststo clear


** Part 5D: Sales prices > 25% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices, >25% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/salesprice_table_bindingness25_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices, >25% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Prices, >25% binding, w/ characteristics, robust s.e.") 
	
eststo clear 


** Part 5E: Rents > 15% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* unique boundaries overall (for rents)
unique lam_seg if `regression_conditions' & only_du == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & log_mfrent!=.

* unique boundaries with bindingness 15%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & frac_binding_mf>0.15 & frac_binding_mf!=. & log_mfrent!=.

* unique boundaries with bindingness 25%
unique lam_seg if `regression_conditions' & only_du == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & frac_binding_mf>0.25 & frac_binding_mf!=. & log_mfrent!=.

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

	
** Part 5G: Rents > 25% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >25%") 	
	
esttab rent_du rent_duhe1 using "$RDPATH/rents_table_bindingness25_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >25%") 

eststo clear	
	
* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_duhe1_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >25%") 	

eststo clear 	

** Part 5H: Rents > 25% , characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1 ,  se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1" ) ///
 	title("Rents, bindingness >25%") 	
	
esttab rent_du rent_duhe1  using "$RDPATH/rents_table_bindingness25_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >25%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1" ) ///
 	title("Rents, bindingness >25%") 	

eststo clear 
	

********************************************************************************
* Part 6 
* Regressions
* Sales prices + rents per sqft
* bindingness > 15% + > 25%
* use maxdu AND mls for density 
********************************************************************************
** Part 6A: Sales prices > 15% , no characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Price per sqft >15% binding") 
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/ppsqft_table_bindingness15_maxdumls.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Price per sqft >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf" ) ///
	title("Sales Price per sqft >15% binding, robust s.e.") 
	
eststo clear


** Part 6B: Sales prices > 15% , characteristics 	
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions' &  frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Price per sqft, >15% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/ppsqft_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Prices per sqft, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_he"  "price_duhe"  "price_mfdu" "price_mf" ) ///
	title("Sales Price per sqft, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 


** Part 6C: Sales prices > 25% , no characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

* older esttab version, pre REStat
esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Price per sqft >25% binding") 
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/ppsqft_table_bindingness25_mlsmaxdu.tex", ///
	replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Price per sqft >25% binding") 
	
* robust s.e.
quietly eststo price_du_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Price per sqft >25% binding, robust s.e.") 

eststo clear

** Part 6D: Sales prices > 25% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Price per sqft, >25% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/ppsqft_table_bindingness25_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Sales Price per sqft, >25% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_ppsqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Sales Price pre sqft, >25% binding, w/ characteristics, robust s.e.") 
	
eststo clear 


** Part 6E: Rents > 15% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_rpsqft ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_rpsqft ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >15%") 	
	
esttab rent_du rent_duhe1  using "$RDPATH/rpsqft_table_bindingness15_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >15%") 

eststo clear 	

* robust s.e.
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >15%") 	

eststo clear 

	
** Part 6F: Rents > 15% , characteristics 	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) , vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du  rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >15%") 	
	
esttab rent_du rent_duhe1 using "$RDPATH/rpsqft_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >15%") 

eststo clear 	

*robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)


esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >15%") 	

eststo clear 


** Part 6G: Rents > 25% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_rpsqft ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_rpsqft ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >25%") 	
	
esttab rent_du rent_duhe1 using "$RDPATH/rpsqft_table_bindingness25_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >25%") 

eststo clear	
	
* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust rent_duhe1_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >25%") 	

	
eststo clear 	


** Part 6H: Rents > 25% , characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)

esttab rent_du rent_duhe1 ,  se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1" ) ///
 	title("Rent per sqft, bindingness >25%") 	
	
esttab rent_du rent_duhe1  using "$RDPATH/rpsqft_table_bindingness25_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rent per sqft, bindingness >25%") 

eststo clear 	

* robust s.e.
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_rpsqft ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust, se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1" ) ///
 	title("Rent per sqft, bindingness >25%") 	

eststo clear 


********************************************************************************
* Part 7 
* Regressions
* Land price per sqft
* bindingness > 15% + > 25%
* use maxdu AND mls for density 
********************************************************************************
** Part 7A: Sales prices > 15% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

** Part 7A: land price, bindingness 
quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price per sqft >15% binding") 
		
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness15_maxdumls.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf" ) ///
	title("Land price per sqft >15% binding, robust s.e.") 
	
eststo clear

** Part 7B: Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0
	
quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions' &  frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft, >15% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land prices per sqft, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_he"  "price_duhe"  "price_mfdu" "price_mf" ) ///
	title("Land price per sqft, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 

** Part 7C: Sales prices > 25% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)


* older esttab version, pre REStat
esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price per sqft >25% binding") 
	
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness25_mlsmaxdu.tex", ///
	replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price per sqft >25% binding") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)


esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft >25% binding, robust s.e.") 

eststo clear


** Part 7D: Sales prices > 25% , characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft, >25% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness25_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft, >25% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)


esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price pre sqft, >25% binding, w/ characteristics, robust s.e.") 
	
eststo clear 


********************************************************************************
* Part 8
* Regressions
* THIS IS THE SAME AS Part 8 EXCEPT IT HAD A DIFFERENT REGRESSION CONDITION
********************************************************************************
** Part 8A: Sales prices > 15% , no characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & assd_landval !=0

** Part 8A: land price, bindingness 
quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price per sqft >15% binding") 
		
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness15_maxdumls_part8_difregcon.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf" ) ///
	title("Land price per sqft >15% binding, robust s.e.") 
	
eststo clear

** Part 8B: Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & assd_landval !=0
	
quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions' &  frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft, >15% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness15_addcontrols_mlsmaxdu_part8_difregcon.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land prices per sqft, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.15 & frac_binding_mf!=., vce(robust)

esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_he"  "price_duhe"  "price_mfdu" "price_mf" ) ///
	title("Land price per sqft, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 

** Part 8C: Sales prices > 25% , no characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & assd_landval !=0

quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)


* older esttab version, pre REStat
esttab price_du price_he price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price per sqft >25% binding") 
	
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness25_mlsmaxdu_part8_difregcon.tex", ///
	replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price per sqft >25% binding") 
	
*robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust) 
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)


esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft >25% binding, robust s.e.") 

eststo clear


** Part 8D: Sales prices > 25% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & assd_landval !=0

quietly eststo price_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_he price_duhe price_mfdu price_mf, ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft, >25% binding, w/ characteristics")
	
esttab price_du price_he price_duhe price_mfdu price_mf  using "$RDPATH/lpsqft_table_bindingness25_addcontrols_mlsmaxdu_part8_difregcon.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
 	title("Land price per sqft, >25% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.))& frac_binding_height_10_all>0.25 & frac_binding_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.25 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.25 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & frac_binding_mf>0.25 & frac_binding_mf!=., vce(robust)


esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf") ///
	title("Land price pre sqft, >25% binding, w/ characteristics, robust s.e.") 
	
eststo clear 


********************************************************************************
** end
********************************************************************************
log close
clear all 

display "finished!" 
