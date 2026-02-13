* start here

clear all
log close _all
set linesize 255

local name ="bindingness"  // <--- change when necessry

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
* File name:		bindingness.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		Analyzes bindingness of different regulations and boundaries 
*					with binding regs. Buffered at 20%
*
* Inputs:			mt_orthogonal_dist_100m_07-01-22_moreregs.dta
*					soil_quality_matches.dta
*					warren_zoning_regulations_match.dta
*					within_town_analysis_data.dta
*					blocks_2010.dta
*					acs_amenities.dta
*	
* Outputs:			Table C.11
*
* Created:			09/18/2024
* Updated:			01/31/2026
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
use "$DATAPATH/soil_quality_matches.dta", clear

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


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
	drop if _merge == 2
	drop _merge

* merge on mt lines to keep straight line properties
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)
	
	* merge error check
	sum _merge

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

gen soil_avgslope = avg_slope
gen soil_slope15 = slope_15
gen soil_avgrestri = avg_restri
gen soil_avgsand = avg_sand
gen soil_avgclay = avg_clay


********************************************************************************
** property characteristic variables
********************************************************************************
gen char1_lotsizeac1 = ln(lot_sizeac) if lot_sizeac != 0  // lot size in acres, excl zero acre --> NOW IN LOGS
gen char2_livingarea1 = ln(livingarea) / num_units1 if livingarea != 0  // living area in XX per unit, excl zero --> NOW IN LOGS
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0  // num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0  // num full bathrooms per unit, atleast 1

gen log_lotacres = ln(lot_acres) if lot_acres!=0
gen log_bldgarea =ln(grossbldg_area) if grossbldg_area!=0

* set control variables
global char_vars i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num


********************************************************************************
** per squarefoot prices
********************************************************************************
gen log_land = log(assd_landval)

* per squarefoot price of land 
gen land_per_sqft = assd_landval/lot_sizesqft
gen log_land_per_sqft = log(land_per_sqft)

gen price_per_sqft = def_saleprice/lot_sizesqft
gen log_ppsqft = log(price_per_sqft)

gen rent_per_sqft = comb_rent2/lot_sizesqft  
gen log_rpsqft = log(rent_per_sqft)


********************************************************************************
** Calculate bindingness identifier variables at the lot level
********************************************************************************
local buffer2 = .2
 
** 1. min lot size (mls)
* min lot size actual
gen mls_actual = lot_sizesqft if lot_sizesqft!=0

* mls regulation (only where by-right allowed) minlotsize to home_minlotsize

gen mls_byright = home_minlotsize if mnls_esval == 0 & home_minlotsize != 0  // non-imputed
gen mls_all = mnls_eff if mnls_esval != . & mnls_eff != 0  // includes imputed

count if mls_actual == . 
count if mls_byright == . 
count if mls_all == .

* 20% buffer, non-imputed
gen mls_binding_10 = (mls_actual<=(mls_byright*(1 + `buffer2'))) & (mls_actual>=(mls_byright*(1 - `buffer2'))) & mls_actual!=. & mls_byright!=.
replace mls_binding_10 = . if mls_actual==. | mls_byright==.

gen mls_violate_10 = mls_actual<(mls_byright*(1 -`buffer2')) & mls_actual!=. & mls_byright!=.
replace mls_violate_10 = . if mls_actual==. | mls_byright==.

* 20% buffer, all (including imputed)
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

local buffer2 = .2

* 20% buffer, non-imputed
gen height_binding_10 = (height_actual<=(height_byright*(1 + `buffer2'))) & (height_actual>=(height_byright*(1 - `buffer2'))) & height_actual!=. & height_byright!=. 
replace height_binding_10 = . if height_actual==. | height_byright==. 

gen height_violate_10 = height_actual>(height_byright*(1 +`buffer2')) & height_actual!=. & height_byright!=. 
replace height_violate_10 = . if height_actual==. | height_byright==.

* 20% buffer, all (including imputed)
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

local buffer2 = .2

** 4. maxdu 
* maxdu actual 
gen maxdu_actual = num_units1 if num_units1!=.

* maxdu regulation w/ by-right
gen maxdu_byright = maxdu if mxdu_esval == 0 & maxdu!=0  // non-imputed
gen maxdu_all = mxdu_eff if mxdu_esval!= . & mxdu_eff!=0  // includes imputed

count if maxdu_actual == . 
count if maxdu_byright == . 
count if maxdu_all == . 

* 20% buffer, non-imputed
gen maxdu_binding_10 = (maxdu_actual<=(maxdu_byright*(1 + `buffer2'))) & (maxdu_actual>=(maxdu_byright*(1 - `buffer2'))) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_binding_10 = . if maxdu_actual==. | maxdu_byright==.

gen maxdu_violate_10 = maxdu_actual>(maxdu_byright*(1 +`buffer2')) & maxdu_actual!=. & maxdu_byright!=. 
replace maxdu_violate_10 = . if maxdu_actual==. | maxdu_byright==.

* 20% buffer, all (including imputed)
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
//count if frac_binding_far_10 == .
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


********************************************************************************
* Bandwidth selection
********************************************************************************

*sales prices 
*only du
*binding>15%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. , c(0) all

*with maxdu 
*binding>15%
rdbwselect log_saleprice dist_both if only_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. , c(0) all

*only mf
*binding>15%
rdbwselect log_saleprice dist_both if only_mf == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mf>0.15 & frac_binding_mf!=., c(0) all 

*not enough sample - commenting out
/*
*duhe
*mls
*binding>15%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all
*/

*maxdu
*binding>15%
rdbwselect log_saleprice dist_both if du_he == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all

*mfdu
*mls
*binding>15%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., c(0) all

*maxdu
*binding>15%
rdbwselect log_saleprice dist_both if  mf_du == 1 & res_typex=="Single Family Res" & (last_saleyr>=2010 & last_saleyr<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_mf>0.15 & frac_binding_mf!=., c(0) all


*rents 
*only du 
*mls
*binding>15%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=., c(0) all 

*maxdu
*binding>15%
rdbwselect log_mfrent dist_both if only_du==1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=., c(0) all 

*duhe
*mls
*binding>15%
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all

*maxdu
*binding>15%
rdbwselect log_mfrent dist_both if du_he == 1 & res_typex !="Condominiums" & (year>=2010 & year<=2018) & frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=. & frac_binding_height_10_all>0.15 & frac_binding_height_10_all!=., c(0) all 


********************************************************************************
* Regressions
* Sales prices + rents bindingness
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

** Sales price, bindingness 
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* [PAPER SOURCE]: For Table C.11
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
* [PAPER SOURCE]: For Table C.11
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg) 
	
esttab price_du price_mfdu using "$EXPORTPATH/salesprice_table_bindingness15_maxdumls.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du" "price_mfdu") ///
 	title("Sales Prices >15% binding") 

eststo clear 
	
** Sales prices > 15% , characteristics 
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* [PAPER SOURCE]: For Table C.11
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
* [PAPER SOURCE]: For Table C.11
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) & frac_binding_mf>0.15 & frac_binding_mf!=., vce(cluster lam_seg)

esttab price_du price_mfdu using "$EXPORTPATH/salesprice_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) ///
 	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
 	label mtitles("price_du"  "price_mfdu") ///
 	title("Sales Prices, >15% binding, w/ characteristics")
	
eststo clear	


** Rents > 15% , no characteristics 
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

* [PAPER SOURCE]: For Table C.11
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)), vce(cluster lam_seg)
	
esttab rent_du  using "$EXPORTPATH/rents_table_bindingness15_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du") ///
 	title("Rents, bindingness >15%") 

eststo clear 
	
* [PAPER SOURCE]: For Table C.11
** Rents > 15% , characteristics 	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions' & ((frac_binding_mls_10_all>0.15 & frac_binding_mls_10_all!=.) | (frac_binding_maxdu_10_all>0.15 & frac_binding_maxdu_10_all!=.)) , vce(cluster lam_seg)
	
esttab rent_du using "$EXPORTPATH/rents_table_bindingness15_addcontrols_mlsmaxdu.tex", replace keep(21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) se r2 ///
 	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
 	label mtitles("rent_du"  "rent_duhe1"  ) ///
 	title("Rents, bindingness >15%") 

eststo clear 	


********************************************************************************
** end
********************************************************************************
log close
clear all 

display "finished!" 


cd "${WORKINGDIR}/analysis"

zipfile "${EXPORTPATH}",saving("${WORKINGDIR}/analysis/`name'_`date_stamp'", replace)

