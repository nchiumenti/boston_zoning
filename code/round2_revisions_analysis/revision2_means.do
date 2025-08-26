* start here
clear all
log close _all
set linesize 255

local name ="revision2_means"  // <--- change when necessry

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
* File name:		revision2_meanss.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		
* 				
* Inputs:		
*
* Outputs:		n/a
*
* Created:		07/30/2025
* Updated:		07/30/2025
********************************************************************************


********************************************************************************
** load the mt lines data
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
		assert `r(N)' ==  821248
		assert `r(sum_w)' ==  821248
		assert `r(mean)' ==  2.999986605751247
		assert `r(Var)' ==  .0000133940856566
		assert `r(sd)' ==  .0036597931166456
		assert `r(min)' ==  2
		assert `r(max)' ==  3
		assert `r(sum)' ==  2463733

		drop if _merge == 2
		drop _merge
	
keep prop_id station_id station_name distance_m_* length_m

destring prop_id distance_m_* length_m, replace

gen transit_dist_m = distance_m_man + length_m

tempfile transit
save `transit', replace


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear


********************************************************************************
** merge on transit data
********************************************************************************
merge m:1 prop_id using `transit'
	
	/* merge error check
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
	
	/* merge error check
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


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** define mean variables
********************************************************************************
gen side = ""
replace side = "relaxed" if relaxed == 1
replace side = "strict" if relaxed == 0

* gen boundary type var
gen boundary_type = ""
	replace boundary_type = "only_mf" if only_mf == 1
	replace boundary_type = "only_he" if only_he == 1
	replace boundary_type = "only_du" if only_du == 1
	replace boundary_type = "mf_he" if mf_he == 1
	replace boundary_type = "mf_du" if mf_du == 1
	replace boundary_type = "du_he" if du_he == 1
	replace boundary_type = "mf_he_du" if mf_he_du == 1


********************************************************************************
** calc PROPERTY LEVEL means for property characteristics
********************************************************************************

*AK: merge in ACS data 
*TO DO - CHECK WHICH ID TO USE warren_GEOID_full or orig_GEOID_full <--- confirmed it is warren_GEOID_full
*block data
merge m:1 warren_GEOID_full using "$DATAPATH/blocks_2010.dta"

drop if _merge ==2
drop _merge 

*block group data
gen BLKGRP = substr(warren_GEOID_full,1,12)

merge m:1 year BLKGRP using "$DATAPATH/acs_amenities.dta", keepusing(B19113001 B0100300 SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25)
drop if _merge == 2
drop _merge 

rename B19113001 median_inc
rename B0100300 total_pop

*TABLE 1
*means and t-test (revision 2 adding in unit chars)
*global char_vars char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1
*Revision 2: Charactersitics across boundaries (property level)


// nm_units1 = num_units if num_units !=0  // uncomment is num_units1 is not defined

gen char1_lotsizeac1 = lot_sizeac if lot_sizeac != 0 & lot_sizeac != .			         // lot size in acres, excl zero acre
gen char2_livingarea1 = livingarea / num_units1 if livingarea != 0 & livingarea != .	 // living area in XX per unit, excl zero
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0 & bedroom_num != .	 // num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0 & bathfull_num != . // num full bathrooms per unit, atleast 1

*relaxed
eststo only_du_chars_r: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if only_du == 1 & relaxed == 1
eststo only_mf_chars_r: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if only_mf == 1 & relaxed == 1
eststo only_he_chars_r: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if only_he == 1 & relaxed == 1
eststo du_he_chars_r: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if du_he == 1 & relaxed == 1
eststo mf_du_chars_r: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if mf_du == 1 & relaxed == 1
eststo mf_he_chars_r: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if mf_he == 1 & relaxed == 1

*strict
eststo only_du_chars_s: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if only_du == 1 & relaxed == 0
eststo only_mf_chars_s: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if only_mf == 1 & relaxed == 0
eststo only_he_chars_s: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if only_he == 1 & relaxed == 0
eststo du_he_chars_s: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if du_he == 1 & relaxed == 0
eststo mf_du_chars_s: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if mf_du == 1 & relaxed == 0
eststo mf_he_chars_s: quietly estpost summarize char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if mf_he == 1 & relaxed == 0

*ttests (NEW VARIABLES)
eststo t_du_chars: quietly estpost ttest char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if (only_du==1), by(relaxed)
eststo t_mf_chars: quietly estpost ttest char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if (only_mf == 1), by(relaxed)
eststo t_he_chars: quietly estpost ttest char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if (only_he == 1), by(relaxed)
eststo t_duhe_chars: quietly estpost ttest char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if (du_he == 1), by(relaxed)
eststo t_mfdu_chars: quietly estpost ttest char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if (mf_du == 1), by(relaxed)
eststo t_mfhe_chars: quietly estpost ttest char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1 if (mf_he == 1), by(relaxed)

esttab only_mf_chars_r only_mf_chars_s t_mf_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_he_chars_r only_he_chars_s t_he_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_du_chars_r only_du_chars_s t_du_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab du_he_chars_r du_he_chars_s t_duhe_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_du_chars_r only_du_chars_s t_mfdu_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_he_chars_r only_du_chars_s t_mfhe_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

eststo clear




********************************************************************************
** calc BOUNDARY LEVEL means for property characteristics
********************************************************************************

****char_vars char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1

** Table 1 
preserve 

* collapse to calc means (NEW VARIABLES)
#delimit ;
collapse (mean) m_lotsize_lamseg = char1_lotsizeac1 
			    m_livingarea_lamseg = char2_livingarea1 
				m_bedrooms_lamseg = char3_bedrooms1 
				m_bathrooms_lamseg = char4_bathfull1 
		(count) n_lotsize = char1_lotsizeac1 
				n_living = char2_livingarea1 
				n_bedrooms = char3_bedrooms1 
				n_bathrooms = char4_bathfull1, 
	by(lam_seg relaxed only_du only_mf only_he du_he mf_du mf_he);
#delimit cr

*means
*relaxed
eststo only_du_chars_r: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if only_du == 1 & relaxed == 1
eststo only_mf_chars_r: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if only_mf == 1 & relaxed == 1
eststo only_he_chars_r: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if only_he == 1 & relaxed == 1
eststo du_he_chars_r: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if du_he == 1 & relaxed == 1
eststo mf_du_chars_r: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if mf_du == 1 & relaxed == 1
eststo mf_he_chars_r: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if mf_he == 1 & relaxed == 1

*strict
eststo only_du_chars_s: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if only_du == 1 & relaxed == 0
eststo only_mf_chars_s: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if only_mf == 1 & relaxed == 0
eststo only_he_chars_s: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if only_he == 1 & relaxed == 0
eststo du_he_chars_s: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if du_he == 1 & relaxed == 0
eststo mf_du_chars_s: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if mf_du == 1 & relaxed == 0
eststo mf_he_chars_s: quietly estpost summarize m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg  if mf_he == 1 & relaxed == 0

*ttests (NEW VARIABLES)
eststo t_du_chars: quietly estpost ttest m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if (only_du==1), by(relaxed)
eststo t_mf_chars: quietly estpost ttest m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if (only_mf == 1), by(relaxed)
eststo t_he_chars: quietly estpost ttest m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if (only_he == 1), by(relaxed)
eststo t_duhe_chars: quietly estpost ttest m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if (du_he == 1), by(relaxed)
eststo t_mfdu_chars: quietly estpost ttest m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if (mf_du == 1), by(relaxed)
eststo t_mfhe_chars: quietly estpost ttest m_lotsize_lamseg m_livingarea_lamseg m_bedrooms_lamseg m_bathrooms_lamseg if (mf_he == 1), by(relaxed)

esttab only_mf_chars_r only_mf_chars_s t_mf_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_he_chars_r only_he_chars_s t_he_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_du_chars_r only_du_chars_s t_du_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab du_he_chars_r du_he_chars_s t_duhe_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_du_chars_r only_du_chars_s t_mfdu_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_he_chars_r only_du_chars_s t_mfhe_chars, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

eststo clear



restore

********************************************************************************
** end
********************************************************************************
log close
clear all
