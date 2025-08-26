* start here
clear all
log close _all
set linesize 255

local name ="revised_bindingness"  // <--- change when necessry

* creates an output directory if none exists
global DATAPATH "${DATAPATH_replication_package}"
global DOPATH "~/rda-projects/clones_dept/boston_zoning/code/analysis_files"

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
* File name:		revised_bindingness.do (formerly reivsion 2 bindingness)
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

********************************************************************************
** load and tempsave the mt lines data
********************************************************************************
use  "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear 

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
use "$DATAPATH/within_town_analysis_data.dta", clear

* merge on soil quality data
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

* merge on mt lines to keep straight line properties
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)
	
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

keep if straight_line == 1  // <-- drops non-straight line properties

* drop out of scope years
keep if (year >= 2010 & year <= 2018)

tab year

* merge on imputation flags for regulations
merge m:1 prop_id using `imputed_flags'
sum _merge

drop if _merge == 2
drop _merge 

** merge on ACS characteristics
* merge on block data level characteristics
merge m:1 warren_GEOID_full using "$DATAPATH/blocks_2010.dta", update replace
	
	* summarize _merge var and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

* create block group making variable
gen BLKGRP = substr(warren_GEOID_full,1,12)

* merge on ace amenities dataset
merge m:1 year BLKGRP using "$DATAPATH/acs_amenities.dta", keepusing(B19113001)

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
** Calculate bindingness at the lot level
* 1. min lot size
* 2. height
* 3. mulfam
* 4. maxdu
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


** 5. DUPAC 

//stop

** at this point we need to work step by step to get this to work correctly

* drop all dupac variables in current dataset
drop dupac*

* add on id to merge new data from zoning atlast
// cd /shared/boston_zoning/working_paper/data/shapefiles/standardized/

 
geoinpoly warren_latitude warren_longitude using "/shared/boston_zoning/working_paper/data/shapefiles/standardized/zoning_atlas_latlong_shp.dta", unique

* now add on the original dupac variables
merge m:1 _ID using "/shared/boston_zoning/working_paper/data/shapefiles/standardized/zoning_atlas_latlong.dta", keep(1 3) keepusing(dupac*) nogen
ren dupac_esva dupac_esval

*#### STOPPED HERE 
* uncomment the correct one

*realized dupac 
gen d1 = num_units / lot_sizeac    /*lot-leveldensity*/
bysort _ID: gen d2 = sum(num_units)/sum(lot_sizeac)      /*area-level density by zone polygon*/

sum d1,d
sum d2,d

*actual dupac regulatoin
gen dupac_byright = dupac if dupac_esval == 0 & dupac_eff != 0  // non-imputed
gen dupac_all = dupac_eff if dupac_esval != . & dupac_eff != 0  		  // includes imputed

local buffer1 = .1
local buffer2 = .2

//diff versions of dupac_actual:
forval actual = 1/2 {
	* 10% buffer, non-imputed
	gen dupac_d`actual'_binding_10 = (d`actual' <= (dupac_byright*(1 + `buffer2'))) & (d`actual'>=(dupac_byright*(1 - `buffer2'))) & d`actual'!=. & dupac_byright!=. 
	replace dupac_d`actual'_binding_10 = . if d`actual'==. | dupac_byright==.

	gen dupac_d`actual'_violate_10 = d`actual'>(dupac_byright*(1 +`buffer2')) & d`actual'!=. & dupac_byright!=. 
	replace dupac_d`actual'_violate_10 = . if d`actual'==. | dupac_byright==.

	* 10% buffer, all (including imputed)
	gen dupac_d`actual'_binding_10_all = (d`actual'<=(dupac_all*(1 + `buffer2'))) & (d`actual'>=(dupac_all*(1 - `buffer2'))) & d`actual'!=. & dupac_all!=. 
	replace dupac_d`actual'_binding_10_all = . if d`actual'==. | dupac_all==. 

	gen dupac_d`actual'_violate_10_all = d`actual'>(dupac_all*(1 +`buffer2')) & d`actual'!=. & dupac_all!=. 
	replace dupac_d`actual'_violate_10_all = . if d`actual'==. | dupac_all==.
}



forval actual = 1/2 {
	* 5% buffer, non-imputed
	gen dupac_d`actual'_binding_05 = (d`actual' <= (dupac_byright*(1 + `buffer1'))) & (d`actual'>=(dupac_byright*(1 - `buffer1'))) & d`actual'!=. & dupac_byright!=. 
	replace dupac_d`actual'_binding_05 = . if d`actual'==. | dupac_byright==.

	gen dupac_d`actual'_violate_05 = d`actual'>(dupac_byright*(1 +`buffer1')) & d`actual'!=. & dupac_byright!=. 
	replace dupac_d`actual'_violate_05 = . if d`actual'==. | dupac_byright==.

	* 5% buffer, all (including imputed)
	gen dupac_d`actual'_binding_05_all = (d`actual'<=(dupac_all*(1 + `buffer1'))) & (d`actual'>=(dupac_all*(1 - `buffer1'))) & d`actual'!=. & dupac_all!=. 
	replace dupac_d`actual'_binding_05_all = . if d`actual'==. | dupac_all==. 

	gen dupac_d`actual'_violate_05_all = d`actual'>(dupac_all*(1 +`buffer1')) & d`actual'!=. & dupac_all!=. 
	replace dupac_d`actual'_violate_05_all = . if d`actual'==. | dupac_all==.
}


ren d1 dupac_actual
ren d2 dupac_actual_zone

sum dupac_actual, d 
sum dupac_actual_zone, d 


count if dupac_actual == . 
count if dupac_actual_zone == . 
count if dupac_byright == . 
count if dupac_all == . 




*describe ,fullnames


*stop

/*
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

*/

********************************************************************************
** Identifying binding boundaries
********************************************************************************
* non-imputed regulations
* based on 5% and 10

*what is missing
count if mls_binding_10 == . 
count if height_binding_10 == . 
count if maxdu_binding_10 == .
count if dupac_d1_binding_10 == . 
count if dupac_d2_binding_10 == . 
count if mf_binding == . 


// drop fbind_* 
// cap drop *boundary_reg


foreach l in mls height maxdu dupac_d1 dupac_d2 {
	foreach j in 05 10{
			by lam_seg, sort: egen fbind_`l'_`j' = mean(`l'_binding_`j')
	}
} 


* mf is separate 
by lam_seg, sort: egen fbind_mf = mean(mf_binding)

count if fbind_mls_10 == . 
count if fbind_height_10 == .
count if fbind_maxdu_10 == . 
count if fbind_dupac_d1_10 == . 
count if fbind_dupac_d2_10 == . 
count if fbind_mf == . 


* all
* based on 10% and 20%
*what is missing
count if mls_binding_10_all == . 
count if height_binding_10_all == . 
count if maxdu_binding_10_all == .
count if dupac_d1_binding_10_all == . 
count if dupac_d2_binding_10_all == . 

foreach l in mls height maxdu dupac_d1 dupac_d2 {
	foreach j in 05 10{
			by lam_seg, sort: egen fbind_`l'_`j'_all = mean(`l'_binding_`j'_all)
	}
} 


count if fbind_mls_10_all == . 
count if fbind_height_10_all == .
count if fbind_maxdu_10_all == . 
count if fbind_dupac_d1_10_all == . 
count if fbind_dupac_d2_10_all == . 



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
table boundary_reg , stat(mean mls_binding_05 mls_violate_05 height_binding_05 height_violate_05 maxdu_binding_05 maxdu_violate_05 mf_binding mf_violate dupac_d1_binding_05  dupac_d1_violate_05 dupac_d2_binding_05 dupac_d2_violate_05) nformat(%4.3fc)

* year built >=1918
table boundary_reg if year_built>=1918 , stat(mean mls_binding_05 mls_violate_05 height_binding_05 height_violate_05 maxdu_binding_05 maxdu_violate_05 mf_binding mf_violate dupac_d1_binding_05 dupac_d1_violate_05 dupac_d2_binding_05 dupac_d2_violate_05) nformat(%4.3fc)

//table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6) & year_built>=1918, c(mean mls_binding_05 mean mls_violate_05 mean height_binding_05 mean height_violate_05 mean far_binding_05 mean far_violate_05 mean far_binding_05_2 mean far_violate_05_2 mean maxdu_binding_05 mean maxdu_violate_05 mean mf_binding mean mf_violate) format(%4.3fc)

* year built > = 1956
*table boundary_reg if year_built>=1956 , stat(mean mls_binding_05 mls_violate_05 height_binding_05 height_violate_05 far_binding_05 far_violate_05 far_binding_05_2 far_violate_05_2 maxdu_binding_05 maxdu_violate_05 mf_binding mf_violate) nformat(%4.3fc)

** binding regulations +- 10% only non-imputed
* no year_built restriction 
table boundary_reg, stat(mean mls_binding_10 mls_violate_10 height_binding_10 height_violate_10 maxdu_binding_10 maxdu_violate_10  mf_binding mf_violate dupac_d1_binding_10 dupac_d1_violate_10 dupac_d2_binding_10 dupac_d2_violate_10) nformat(%4.3fc)

//table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6), c(mean mls_binding_10 mean mls_violate_10 mean height_binding_10 mean height_violate_10 mean far_binding_10 mean far_violate_10 mean far_binding_10_2 mean far_violate_10_2 mean maxdu_binding_10 mean maxdu_violate_10 mean mf_binding mean mf_violate) format(%4.3fc)

* year built >=1918
table boundary_reg if year_built>=1918, stat(mean mls_binding_10 mls_violate_10 height_binding_10 height_violate_10 maxdu_binding_10 maxdu_violate_10  mf_binding mf_violate dupac_d1_binding_10 dupac_d1_violate_10 dupac_d2_binding_10 dupac_d2_violate_10) nformat(%4.3fc)

* year built > = 1956
*table boundary_reg if year_built>=1956, stat(mean mls_binding_10 mls_violate_10 height_binding_10 height_violate_10 far_binding_10 far_violate_10 far_binding_10_2 far_violate_10_2 maxdu_binding_10 maxdu_violate_10  mf_binding mf_violate) nformat(%4.3fc)

** binding regulations +- 5% all
* no year_built restriction 
table boundary_reg, stat(mean mls_binding_05_all mls_violate_05_all height_binding_05_all height_violate_05_all maxdu_binding_05_all maxdu_violate_05_all mf_binding mf_violate dupac_d1_binding_05_all dupac_d1_violate_05_all dupac_d2_binding_05_all dupac_d2_violate_05_all) nformat(%4.3fc)

//table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6), c(mean mls_binding_05_all mean mls_violate_05_all mean height_binding_05_all mean height_violate_05_all mean far_binding_05_all mean far_violate_05_all mean far_binding_05_all_2 mean far_violate_05_all_2 mean maxdu_binding_05_all mean maxdu_violate_05_all mean mf_binding mean mf_violate) format(%4.3fc)

*year built >=1918
table boundary_reg if year_built>=1918, stat(mean mls_binding_05_all mls_violate_05_all height_binding_05_all height_violate_05_all maxdu_binding_05_all maxdu_violate_05_all mf_binding mf_violate dupac_d1_binding_05_all dupac_d1_violate_05_all dupac_d2_binding_05_all dupac_d2_violate_05_all ) nformat(%4.3fc)

*year built > = 1956
*table boundary_reg if year_built>=1956, stat(mean mls_binding_05_all mls_violate_05_all height_binding_05_all height_violate_05_all far_binding_05_all far_violate_05_all far_binding_05_all_2 far_violate_05_all_2 maxdu_binding_05_all maxdu_violate_05_all mf_binding mf_violate) nformat(%4.3fc)



*binding regulations +- 10% all
*no year_built restriction 
table boundary_reg, stat(mean mls_binding_10_all mls_violate_10_all height_binding_10_all height_violate_10_all maxdu_binding_10_all maxdu_violate_10_all mf_binding mf_violate dupac_d1_binding_10_all dupac_d1_violate_10_all dupac_d2_binding_10_all dupac_d2_violate_10_all) nformat(%4.3fc)

*table boundary_reg if inlist(boundary_reg,1, 2, 3, 4, 5, 6), c(mean mls_binding_10_all mean mls_violate_10_all mean height_binding_10_all mean height_violate_10_all mean far_binding_10_all mean far_violate_10_all mean far_binding_10_all_2 mean far_violate_10_all_2 mean maxdu_binding_10_all mean maxdu_violate_10_all mean mf_binding mean mf_violate) format(%4.3fc)

*year built >=1918
table boundary_reg if year_built>=1918, stat(mean mls_binding_10_all mls_violate_10_all height_binding_10_all height_violate_10_all maxdu_binding_10_all maxdu_violate_10_all mf_binding mf_violate dupac_d1_binding_10_all dupac_d1_violate_10_all dupac_d2_binding_10_all dupac_d2_violate_10_all) nformat(%4.3fc)

*year built > = 1956
*table boundary_reg if year_built>=1956, stat(mean mls_binding_10_all mls_violate_10_all height_binding_10_all height_violate_10_all far_binding_10_all far_violate_10_all far_binding_10_all_2 far_violate_10_all_2 maxdu_binding_10_all maxdu_violate_10_all mf_binding mf_violate) nformat(%4.3fc)

*average bindingness and counts at boundary level 
table boundary_reg, stat(mean fbind_mls_05 fbind_height_05 fbind_maxdu_05 fbind_mf fbind_dupac_d1_05 fbind_dupac_d2_05) nformat(%4.3fc)
table boundary_reg, stat(count fbind_mls_05 fbind_height_05 fbind_maxdu_05 fbind_mf fbind_dupac_d1_05 fbind_dupac_d2_05) nformat(%4.3fc)

table boundary_reg , stat(mean fbind_mls_10 fbind_height_10 fbind_maxdu_10 fbind_mf fbind_dupac_d1_10 fbind_dupac_d2_10) nformat(%4.3fc)
table boundary_reg , stat(count fbind_mls_10 fbind_height_10 fbind_maxdu_10 fbind_mf fbind_dupac_d1_10 fbind_dupac_d2_10) nformat(%4.3fc)

table boundary_reg, stat(mean fbind_mls_05_all fbind_height_05_all fbind_maxdu_05_all fbind_mf fbind_dupac_d1_05_all fbind_dupac_d2_05_all) nformat(%4.3fc)
table boundary_reg, stat(count fbind_mls_05_all fbind_height_05_all fbind_maxdu_05_all fbind_mf fbind_dupac_d1_05_all fbind_dupac_d2_05_all) nformat(%4.3fc)

table boundary_reg, stat(mean fbind_mls_10_all fbind_height_10_all fbind_maxdu_10_all fbind_mf fbind_dupac_d1_10_all fbind_dupac_d2_10_all) nformat(%4.3fc)

table boundary_reg, stat(count fbind_mls_10_all fbind_height_10_all fbind_maxdu_10_all fbind_mf fbind_dupac_d1_10_all fbind_dupac_d2_10_all) nformat(%4.3fc)


********************************************************************************
* REVISION 2: Bindingness over time and across regulation strictness
********************************************************************************
*use 20% buffer values (*_10_*) to calculate bindingness 
*use dupac, height, mls, mf (no far and maxdu)
*can be overall, doesn't have to be at boundary level

local buffer2 = .2

****1. RESTRICT TO 2010 - 2018
* non-imputed regulations

foreach l in mls height dupac_d1 dupac_d2 {
	egen fbind_`l'_10_2010 = mean(`l'_binding_10) if year_built>=2010 & year_built!=.
} 

* mf is separate 
by lam_seg, sort: egen fbind_mf_2010 = mean(mf_binding) if year_built>=2010 & year_built!=.

* all
* based on 20% buffer

foreach l in mls height dupac_d1 dupac_d2 {
	egen fbind_`l'_10_all_2010 = mean(`l'_binding_10_all) if year_built>=2010 & year_built!=.
} 


sum fbind_mls_10_2010, d
sum fbind_mls_10_all_2010, d

sum fbind_height_10_2010, d 
sum fbind_height_10_all_2010, d

sum fbind_dupac_d1_10_2010, d
sum fbind_dupac_d1_10_all_2010, d

sum fbind_dupac_d2_10_2010, d
sum fbind_dupac_d2_10_all_2010, d



****2a. VARIATION OVER TIME 
*distance 0.5 miles away from boundary
*generate year_built groups 
gen yb_group = . 
replace yb_group = 1 if year_built>=1960 & year_built<1980
replace yb_group = 2 if year_built>=1980 & year_built<2000
replace yb_group = 3 if year_built>=2000 & year_built<2020

label define yb_g 1 "1960-1979" 2 "1980-1999" 3 ">2000"
label values yb_group yb_g


foreach l in mls height dupac_d1 dupac_d2 {
	by yb_group, sort: egen fbind_`l'_10_yb = mean(`l'_binding_10)
} 

* mf is separate 
by yb_group, sort: egen fbind_mf_yb = mean(mf_binding)

* all
* based on 20% buffer

foreach l in mls height dupac_d1 dupac_d2 {
	by yb_group, sort: egen fbind_`l'_10_all_yb = mean(`l'_binding_10_all)
} 




graph bar fbind_mls_10_all_yb fbind_height_10_all_yb fbind_mf_yb fbind_dupac_d1_10_all_yb fbind_dupac_d2_10_all_yb, over(yb_group)
graph save "bindingness_over_time.gph", replace

*no mls
graph bar fbind_height_10_all_yb fbind_mf_yb fbind_dupac_d1_10_all_yb fbind_dupac_d2_10_all_yb, over(yb_group)
graph save "bindingness_over_time_nomls.gph", replace

*dupac 1
graph bar fbind_height_10_all_yb fbind_mf_yb fbind_dupac_d1_10_all_yb, over(yb_group)
graph save "bindingness_over_time_du1.gph", replace


*dupac 2
graph bar fbind_height_10_all_yb fbind_mf_yb fbind_dupac_d2_10_all_yb, over(yb_group)
graph save "bindingness_over_time_du2.gph", replace





****2b. VARIATION OVER TIME 
*restrict distance to 0.2 miles from boundary
*generate year_built groups 

preserve 

keep if dist_both<=0.21 & dist_both>=-0.2


* mf is separate 
by yb_group, sort: egen fbind_mf_yb_02 = mean(mf_binding)

* all
* based on 20% buffer

foreach l in mls height dupac_d1 dupac_d2 {
	by yb_group, sort: egen fbind_`l'_10_all_yb_02 = mean(`l'_binding_10_all)
} 




graph bar fbind_mls_10_all_yb_02 fbind_height_10_all_yb_02 fbind_mf_yb_02 fbind_dupac_d1_10_all_yb_02 fbind_dupac_d2_10_all_yb_02, over(yb_group)
graph save "bindingness_over_time_02.gph", replace

*no mls
graph bar fbind_height_10_all_yb_02 fbind_mf_yb_02 fbind_dupac_d1_10_all_yb_02 fbind_dupac_d2_10_all_yb_02, over(yb_group)
graph save "bindingness_over_time_02_nomls.gph", replace

*dupac1
graph bar fbind_height_10_all_yb_02 fbind_mf_yb_02 fbind_dupac_d1_10_all_yb_02 , over(yb_group)
graph save "bindingness_over_time_02_du1.gph", replace

*dupac2
graph bar fbind_height_10_all_yb_02 fbind_mf_yb_02 fbind_dupac_d2_10_all_yb_02, over(yb_group)
graph save "bindingness_over_time_02_du2.gph", replace



restore 




****2c. VARIATION OVER TIME 
*restrict distance to 0.1 miles from boundary
*generate year_built groups 

preserve 

keep if dist_both<=0.11 & dist_both>=-0.1


* mf is separate 
by yb_group, sort: egen fbind_mf_yb_01 = mean(mf_binding)

* all
* based on 20% buffer

foreach l in mls height dupac_d1 dupac_d2 {
	by yb_group, sort: egen fbind_`l'_10_all_yb_01 = mean(`l'_binding_10_all)
} 




graph bar fbind_mls_10_all_yb_01 fbind_height_10_all_yb_01 fbind_mf_yb_01 fbind_dupac_d1_10_all_yb_01 fbind_dupac_d2_10_all_yb_01, over(yb_group)
graph save "bindingness_over_time_01.gph", replace

*no mls
graph bar fbind_height_10_all_yb_01 fbind_mf_yb_01 fbind_dupac_d1_10_all_yb_01 fbind_dupac_d2_10_all_yb_01, over(yb_group)
graph save "bindingness_over_time_01_nomls.gph", replace

*dupac1
graph bar fbind_height_10_all_yb_01 fbind_mf_yb_01 fbind_dupac_d1_10_all_yb_01, over(yb_group)
graph save "bindingness_over_time_01_du1.gph", replace

*dupac2
graph bar fbind_height_10_all_yb_01 fbind_mf_yb_01 fbind_dupac_d2_10_all_yb_01, over(yb_group)
graph save "bindingness_over_time_01_du2.gph", replace



restore 





****3. VARIATION BY REGULATION STRICTNESS 
*run with Mike   - then divide up into groups and plot

** 1. MLS
tab mls_byright
tab mls_all

sum mls_byright, d
sum mls_all, d


** 2. height
tab height_byright
tab height_all 

sum height_byright, d
sum height_all, d

** 3. Mulfam
tab mf_byright 


** 4. DUPAC
sum dupac_byright, d
sum dupac_all, d


*groups 
*mls 
gen mls_group = . 
replace mls_group = 1 if mls_all<8000
replace mls_group = 2 if mls_all>=8000 & mls_all<10000
replace mls_group = 3 if mls_all>=10000 & mls_all<20000
replace mls_group = 4 if mls_all>=20000 & mls_all<30000
replace mls_group = 5 if mls_all>=30000 & mls_all<40000
replace mls_group = 6 if mls_all>=40000 & mls_all<45000
replace mls_group = 7 if mls_all>=45000 & mls_all!=.

label define mls_labels 1 "<8k sqft" 2 "8k-10k sqft" 3 "10k-20k sqft" 4 "20k-30k sqft" 5 "30k-40k sqft" 6 "40k-45k sqft" 7 ">45k sqft"

label values mls_group mls_labels


*dupac
gen dupac_group = . 
replace dupac_group = 1 if dupac_all == 0
replace dupac_group = 2 if dupac_all == 1
replace dupac_group = 3 if dupac_all == 2
replace dupac_group = 4 if dupac_all>=3 & dupac_all <10
replace dupac_group = 5 if dupac_all>=10 & dupac_all <25
replace dupac_group = 6 if dupac_all >= 25 & dupac_all < 50 
replace dupac_group = 7 if dupac_all >=50 & dupac_all <100
replace dupac_group = 8 if dupac_all >= 100 & dupac_all !=.

label define dupac_labels 1 "no by-right" 2 "1 dupac" 3 "2 dupac" 4 "3-10 dupac" 5 "10-25 dupac" 6 "25-50 dupac" 7 "50-100 dupac" 8 ">100 dupac"

label values dupac_group dupac_labels


*height 
gen height_group = . 
replace height_group = 1 if height_all <20
replace height_group = 2 if height_all>=20 & height_all<30
replace height_group = 3 if height_all>=30 & height_all<40
replace height_group = 4 if height_all>=40 & height_all<50
replace height_group = 5 if height_all>=50 & height_all<60
replace height_group = 6 if height_all>=60 & height_all<70
replace height_group = 7 if height_all>=70 & height_all<80
replace height_group = 8 if height_all>=80 & height_all!=.

label define height_labels 1 "<20ft" 2 "20-29 ft" 3 "30-39 ft" 4 "40-49 ft" 5 "50-59 ft" 6 "60-69 ft" 7 "70-79 ft" 8 ">80 ft"

label values height_group height_labels


by height_group, sort: egen fbind_height_10_strictness = mean(height_binding_10)

by mls_group, sort: egen fbind_mls_10_strictness = mean(mls_binding_10) 

by mf_byright, sort: egen fbind_mf_strictness = mean(mf_binding)

by dupac_group, sort: egen fbind_dupac_d1_10_strictness = mean(dupac_d1_binding_10)
by dupac_group, sort: egen fbind_dupac_d2_10_strictness = mean(dupac_d2_binding_10)


* all
* based on 20% buffer


by height_group, sort: egen fbind_height_10_all_strictness = mean(height_binding_10_all)
 
by mls_group, sort: egen fbind_mls_10_all_strictness = mean(mls_binding_10_all)

by dupac_group, sort: egen fbind_dupac_d1_10_all_strictness = mean(dupac_d1_binding_10_all)
by dupac_group, sort: egen fbind_dupac_d2_10_all_strictness = mean(dupac_d2_binding_10_all)


local sort_var height_group
sort `sort_var'

twoway connected fbind_height_10_all_strictness `sort_var', xlabel(,valuelabel) ytitle("Average bindingness by group") name("avg_group_binding_height", replace)
graph save "avg_group_binding_height" "avg_group_binding_height.gph", replace

local sort_var mls_group
sort `sort_var'
twoway connected fbind_mls_10_all_strictness `sort_var', xlabel(,valuelabel) ytitle("Average bindingness by group") name("avg_group_binding_mls", replace)
graph save "avg_group_binding_mls" "avg_group_binding_mls.gph", replace


local sort_var mf_byright
sort `sort_var'
twoway connected fbind_mf_strictness `sort_var', xlabel(,valuelabel) ytitle("Average bindingness by group") name("avg_group_binding_mf", replace)
graph save "avg_group_binding_mf" "avg_group_binding_mf.gph", replace

local sort_var dupac_group
sort `sort_var'
twoway connected fbind_dupac_d1_10_strictness `sort_var', xlabel(,valuelabel) ytitle("Average bindingess by group") name("avg_group_binding_du1", replace)
graph save "avg_group_binding_du1" "avg_group_binding_du1.gph", replace

twoway connected fbind_dupac_d2_10_strictness `sort_var', xlabel(,valuelabel) ytitle("Average bindingness by group") name("avg_group_binding_du2", replace)
graph save "avg_group_binding_du2" "avg_group_binding_du2.gph", replace


****4. STANDARD DEVIATION OF REALIZED LOT SIZES 
*4a: MLS
by mls_group, sort: sum mls_actual, d


*4b: height
by height_group, sort: sum height_actual, d


*4c: du1
by dupac_group, sort: sum dupac_actual, d


*4d: du2
by dupac_group, sort: sum dupac_actual_zone

*should see here that standard deviation is larger for more relaxed levels of height/mls


********************************************************************************
*For Revision 2: option value regressions at different bindingness levels
********************************************************************************

*generate land value variables 
gen log_land = log(assd_landval)

*per squarefoot price of land 
gen land_per_sqft = assd_landval/lot_sizesqft
gen log_land_per_sqft = log(land_per_sqft)



* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0


quietly eststo land_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.))
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.))

quietly eststo land_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=.
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=.

quietly eststo land_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg) 
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=.
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=.

quietly eststo land_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg)
sum land_per_sqft if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & fbind_mf>0.15 & fbind_mf!=.
sum land_per_sqft if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & fbind_mf>0.15 & fbind_mf!=.

quietly eststo land_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)

esttab land_du land_duhe land_mfdu land_mf land_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_he") ///
	title("Assessed Land Value Per Squarefoot") 
	
* export table version 	
esttab and_du land_duhe land_mfdu land_mf land_he using "$EXPORTPATH/land_price_table_bindingness_15.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_he") ///
	title("Assessed Land Value Per Squarefoot")	
	
*robust s.e.
quietly eststo land_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(robust)

quietly eststo land_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

quietly eststo land_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust) 

quietly eststo land_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & fbind_mf>0.15 & fbind_mf!=., vce(robust)

quietly eststo land_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

esttab land_du_robust land_duhe_robust land_mfdu_robust land_mf_robust land_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_he") ///
	title("Assessed Land Value Per Squarefoot, robust s.e.") 	
	
eststo clear



*use dupac for density
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

* Part a: bindingness 15%
*du1
quietly eststo land_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)), vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) )
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.))

quietly eststo land_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=.
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=.

quietly eststo land_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg) 
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=.
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=.

*du2
quietly eststo land_du2: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)), vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) )
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.))

quietly eststo land_du2he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=.
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=.

quietly eststo land_mfdu2: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg) 
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=.
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=.
	
esttab land_du land_duhe land_mfdu land_du2 land_du2he land_mfdu2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_du2" "land_du2he" "land_mfdu2") ///
	title("Assessed Land Value Per Squarefoot") 
	
* export table version 	
esttab land_du land_duhe land_mfdu land_du2 land_du2he land_mfdu2 using "$EXPORTPATH/land_price_table_bindingness_15_dupac.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_du2" "land_du2he" "land_mfdu2") ///
	title("Assessed Land Value Per Squarefoot")	
	
*du1
quietly eststo land_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)), vce(robust)

quietly eststo land_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

quietly eststo land_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust) 

*du2
quietly eststo land_du2_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)), vce(robust)

quietly eststo land_du2he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

quietly eststo land_mfdu2_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust) 

esttab land_du_robust land_duhe_robust land_mfdu_robust land_du2_robust land_du2he_robust land_mfdu2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_du2" "land_du2he" "land_mfdu2") ///
	title("Assessed Land Value Per Squarefoot, robust s.e.") 
	
eststo clear







	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

* Part b: bindingness 25%
quietly eststo land_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)), vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.))
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.))

quietly eststo land_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=.
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=.

quietly eststo land_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=., vce(cluster lam_seg) 
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=.
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=.

quietly eststo land_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & fbind_mf>0.25 & fbind_mf!=., vce(cluster lam_seg)
sum land_per_sqft if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & fbind_mf>0.25 & fbind_mf!=.
sum land_per_sqft if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & fbind_mf>0.25 & fbind_mf!=.

quietly eststo land_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(cluster lam_seg)

esttab land_du land_duhe land_mfdu land_mf land_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_he") ///
	title("Assessed Land Value Per Squarefoot") 
	
* export table version 	
esttab and_du land_duhe land_mfdu land_mf land_he using "$EXPORTPATH/land_price_table_bindingness_25.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_he") ///
	title("Assessed Land Value Per Squarefoot")	
	
*robust s.e.
quietly eststo land_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)), vce(robust)

quietly eststo land_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(robust)

quietly eststo land_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=., vce(robust) 

quietly eststo land_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & fbind_mf>0.25 & fbind_mf!=., vce(robust)

quietly eststo land_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(robust)

esttab land_du_robust land_duhe_robust land_mfdu_robust land_mf_robust land_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_he") ///
	title("Assessed Land Value Per Squarefoot, robust s.e.") 	
	
eststo clear



*use dupac for density
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

* Part b: bindingness 25%
*du1
quietly eststo land_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.)), vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.) )
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.))

quietly eststo land_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=.
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.25 & fbind_height_10_all!=.

quietly eststo land_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=., vce(cluster lam_seg) 
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.) ) & fbind_mf>0.25 & fbind_mf!=.
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.) ) & fbind_mf>0.25 & fbind_mf!=.

*du2
quietly eststo land_du2: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.)), vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.) )
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.))

quietly eststo land_du2he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=.
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.25 & fbind_height_10_all!=.

quietly eststo land_mfdu2: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=., vce(cluster lam_seg) 
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.) ) & fbind_mf>0.25 & fbind_mf!=.
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0 & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.) ) & fbind_mf>0.25 & fbind_mf!=.
	
esttab land_du land_duhe land_mfdu land_du2 land_du2he land_mfdu2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_du2" "land_du2he" "land_mfdu2") ///
	title("Assessed Land Value Per Squarefoot") 
	
* export table version 	
esttab land_du land_duhe land_mfdu land_du2 land_du2he land_mfdu2 using "$EXPORTPATH/land_price_table_bindingness_25_dupac.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_du2" "land_du2he" "land_mfdu2") ///
	title("Assessed Land Value Per Squarefoot")	
	
*du1
quietly eststo land_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.)), vce(robust)

quietly eststo land_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(robust)

quietly eststo land_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.25 & fbind_dupac_d1_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=., vce(robust) 

*du2
quietly eststo land_du2_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.)), vce(robust)

quietly eststo land_du2he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.25 & fbind_height_10_all!=., vce(robust)

quietly eststo land_mfdu2_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.25 & fbind_dupac_d2_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=., vce(robust) 

esttab land_du_robust land_duhe_robust land_mfdu_robust land_du2_robust land_du2he_robust land_mfdu2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_du2" "land_du2he" "land_mfdu2") ///
	title("Assessed Land Value Per Squarefoot, robust s.e.") 
	
eststo clear

		
	


********************************************************************************
* Part 0
* Bandwidth selection
********************************************************************************

*sales prices 
*only du
*binding>25%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mls_10_all>0.25 & fbind_mls_10_all!=. , c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mls_10_all>0.15 & fbind_mls_10_all!=. , c(0) all

*with maxdu 
*binding>25%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=. , c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=. , c(0) all

*only mf
*binding>25%
rdbwselect log_saleprice dist_both if only_mf == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mf>0.25 & fbind_mf!=., c(0) all 
*binding>15%
rdbwselect log_saleprice dist_both if only_mf == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mf>0.15 & fbind_mf!=., c(0) all 

*not enough sample - commenting out
/*
*duhe
*mls
*binding>25%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mls_10_all>0.25 & fbind_mls_10_all!=. & fbind_height_10_all>0.25 & fbind_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mls_10_all>0.15 & fbind_mls_10_all!=. & fbind_height_10_all>0.15 & fbind_height_10_all!=., c(0) all
*/

*maxdu
*binding>25%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=. & fbind_height_10_all>0.25 & fbind_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=. & fbind_height_10_all>0.15 & fbind_height_10_all!=., c(0) all

*mfdu
*mls
*binding>25%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mls_10_all>0.25 & fbind_mls_10_all!=. & fbind_mf>0.25 & fbind_mf!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_mls_10_all>0.15 & fbind_mls_10_all!=. & fbind_mf>0.15 & fbind_mf!=., c(0) all

*maxdu
*binding>25%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=. & fbind_mf>0.25 & fbind_mf!=., c(0) all
*binding>15%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=. & fbind_mf>0.15 & fbind_mf!=., c(0) all


*rents 
*only du 
*mls
*binding>25%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_mls_10_all>0.25 & fbind_mls_10_all!=., c(0) all 
*binding>15%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_mls_10_all>0.15 & fbind_mls_10_all!=., c(0) all 

*maxdu
*binding>25%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=., c(0) all 
*binding>15%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=., c(0) all 

*duhe
*mls
*binding>25% 
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_mls_10_all>0.25 & fbind_mls_10_all!=. & fbind_height_10_all>0.25 & fbind_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_mls_10_all>0.15 & fbind_mls_10_all!=. & fbind_height_10_all>0.15 & fbind_height_10_all!=., c(0) all

*maxdu
*binding>25% 
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=. & fbind_height_10_all>0.25 & fbind_height_10_all!=., c(0) all
*binding>15%
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=. & fbind_height_10_all>0.15 & fbind_height_10_all!=., c(0) allfbind_mf_2010_yb




		
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
unique lam_seg if `regression_conditions' & only_du == 1 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1 & fbind_height_10_all>0.15 & fbind_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & fbind_mf>0.15 & fbind_mf!=. & log_saleprice!=.

*unique boundaries with bindingness 25%
unique lam_seg if `regression_conditions' & only_du == 1 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_he == 1 & fbind_height_10_all>0.25 & fbind_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=. & log_saleprice!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & fbind_mf>0.25 & fbind_mf!=. & log_saleprice!=.

** Part 5A: Sales price, bindingness 
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg) 
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg)

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
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he==1 & `regression_conditions' & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions' & fbind_mf>0.15 & fbind_mf!=., vce(robust)
	
esttab price_du_robust price_he_robust price_duhe_robust price_mfdu_robust price_mf_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_he" "price_duhe" "price_mfdu" "price_mf" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear


** Part 5B: Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions' &  fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg)
quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg)

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
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(robust)
quietly eststo price_he_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he==1 & `regression_conditions' & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust)
quietly eststo price_mf_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions' & fbind_mf>0.15 & fbind_mf!=., vce(robust)

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
unique lam_seg if `regression_conditions' & mf_du == 1 & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & log_mfrent!=.

* unique boundaries with bindingness 15%
unique lam_seg if `regression_conditions' & only_du == 1 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & fbind_height_10_all>0.15 & fbind_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & fbind_mf>0.15 & fbind_mf!=. & log_mfrent!=.

* unique boundaries with bindingness 25%
unique lam_seg if `regression_conditions' & only_du == 1 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_he == 1 & fbind_height_10_all>0.25 & fbind_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & du_he == 1 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.25 & fbind_height_10_all!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & mf_du == 1 & ((fbind_mls_10_all>0.25 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.25 & fbind_maxdu_10_all!=.)) & fbind_mf>0.25 & fbind_mf!=. & log_mfrent!=.
unique lam_seg if `regression_conditions' & only_mf == 1 & fbind_mf>0.25 & fbind_mf!=. & log_mfrent!=.

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
	
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

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 
	
	
** Part 5F: Rents > 15% , characteristics 	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) , vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
	
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

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((fbind_mls_10_all>0.15 & fbind_mls_10_all!=.) | (fbind_maxdu_10_all>0.15 & fbind_maxdu_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 


********************************************************************************
* Part 6 
* Regressions
* Sales prices + rents
* bindingness > 15% + > 25%
* use DUPAC for density
********************************************************************************
************
*dupac 1****
************

** Part 6A: Sales price, bindingness 
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"


quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg) 

esttab price_du price_duhe price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu") ///
	title("Sales Prices >15% binding") 
	
	
esttab price_du  price_duhe price_mfdu   using "$RDPATH/salesprice_table_bindingness15_dupac1.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_duhe" "price_mfdu" ) ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ), vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust)
	
esttab price_du_robust price_duhe_robust price_mfdu_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear


** Part 6B: Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg)

esttab price_du price_duhe price_mfdu , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_duhe" "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
esttab price_du price_duhe price_mfdu using "$RDPATH/salesprice_table_bindingness15_addcontrols_dupac1.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_duhe" "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ), vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=., vce(robust)

esttab price_du_robust price_duhe_robust price_mfdu_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_duhe"  "price_mfdu") ///
	title("Sales Prices, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 




** Part 6E: Rents > 15% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"


quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)), vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_duhe1  using "$RDPATH/rents_table_bindingness15_dupac1.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 
	
	
** Part 6F: Rents > 15% , characteristics 	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ) , vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) |) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du  rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_duhe1 using "$RDPATH/rents_table_bindingness15_addcontrols_dupac1.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.) ), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((fbind_dupac_d1_10_all>0.15 & fbind_dupac_d1_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 

************
*dupac 2****
************

** Part 6A2: Sales price, bindingness 
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"


quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg) 

esttab price_du price_duhe price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu") ///
	title("Sales Prices >15% binding") 
	
	
esttab price_du  price_duhe price_mfdu   using "$RDPATH/salesprice_table_bindingness15_dupac2.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_duhe" "price_mfdu" ) ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ), vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(robust)
	
esttab price_du_robust price_duhe_robust price_mfdu_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" ) ///
	title("Sales Prices >15% binding, robust s.e.") 
	
eststo clear


** Part 6B2: Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)), vce(cluster lam_seg)
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_mf>0.15 & fbind_mf!=., vce(cluster lam_seg)

esttab price_du price_duhe price_mfdu , ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_duhe" "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
esttab price_du price_duhe price_mfdu using "$RDPATH/salesprice_table_bindingness15_addcontrols_dupac2.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_duhe" "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	
	
* robust s.e.
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ), vce(robust)
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_mf>0.15 & fbind_mf!=., vce(robust)

esttab price_du_robust price_duhe_robust price_mfdu_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_duhe"  "price_mfdu") ///
	title("Sales Prices, >15% binding, w/ characteristics, robust s.e.") 	
	
eststo clear 




** Part 6E2: Rents > 15% , no characteristics 
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"


quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)), vce(cluster lam_seg)

* using maxdu 
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_duhe1  using "$RDPATH/rents_table_bindingness15_dupac2.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)
	
esttab rent_du_robust  rent_duhe1_robust , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	

eststo clear 
	
	
** Part 6F2: Rents > 15% , characteristics 	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ) , vce(cluster lam_seg)
quietly eststo rent_duhe1: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) |) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(cluster lam_seg)
	
esttab rent_du  rent_duhe1 , se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du" "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 	
	
esttab rent_du rent_duhe1 using "$RDPATH/rents_table_bindingness15_addcontrols_dupac2.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	

* robust s.e.
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.) ), vce(robust)
quietly eststo rent_duhe1_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he==1 & `regression_conditions' & ((fbind_dupac_d2_10_all>0.15 & fbind_dupac_d2_10_all!=.)) & fbind_height_10_all>0.15 & fbind_height_10_all!=., vce(robust)

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
