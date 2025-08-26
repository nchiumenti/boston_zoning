* start here
clear all
log close _all
set linesize 255

local name ="table1_replication"  // <--- change when necessry

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
* File name:		table1_replication.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		
* 				
* Inputs:		
*
* Outputs:			n/a
*
* Created:			07/30/2025
* Updated:			07/30/2025
********************************************************************************


********************************************************************************
** load the mt lines data
********************************************************************************
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

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
	
	/* * check merge for errors
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

// use "$DATAPATH/postQJE_data_exports/postQJE_sample_data_2022-10-07/postQJE_testing_full.dta", clear
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

* units prices rents variables
gen units = num_units1 if year_built>=1918 & year==2018 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"
gen rent = comb_rent2 if (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"
gen price = def_saleprice if (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* fam 2-3 4+ and single fam variables
/* note, these are the same definitions used in within_town_setup */
gen fam23_1918 = 0 if res_typex == "Single Family Res" & (year_built >= 1918 & year == 2018)
	replace fam23_1918 = 1 if (res_typex == "Two Family Res" | res_typex == "Three Family Res") & (year_built >= 1918 & year == 2018)

gen fam23_1956 = 0 if res_typex == "Single Family Res" & (year_built >= 1956 & year == 2018)
	replace fam23_1956 = 1 if (res_typex == "Two Family Res" | res_typex == "Three Family Res") & (year_built >= 1956 & year == 2018)

gen fam4plus_1918 = 0 if res_typex == "Single Family Res" & (year_built >= 1918 & year == 2018)
	replace fam4plus_1918 = 1 if (res_typex == "4-8 Unit Res" | res_typex == "9+ Unit Res") & (year_built >= 1918 & year == 2018)

gen fam4plus_1956 = 0 if res_typex == "Single Family Res" & (year_built >= 1956 & year == 2018)
	replace fam4plus_1956 = 1 if (res_typex == "4-8 Unit Res" | res_typex == "9+ Unit Res") & (year_built >= 1956 & year == 2018)
	
gen singlefam = (res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018))
	replace singlefam = . if (last_saleyr < 2010 | last_saleyr > 2018)


********************************************************************************
** calculate means for single, 2-3 unit, 4+ unit for >=1918 and >=1956 at
** property level
********************************************************************************
preserve

* collapse to calc means
collapse (mean) mean_fam23_1918 = fam23_1918 ///
		mean_fam23_1956 = fam23_1956 ///
		mean_fam4plus_1918 = fam4plus_1918 ///
		mean_fam4plus_1956 = fam4plus_1956 ///
		mean_singlefam = singlefam ///
	(sum) n_fam23_1918 = fam23_1918 ///
		n_fam23_1956 = fam23_1956 ///
		n_fam4plus_1918 = fam4plus_1918 ///
		n_fam4plus_1956 = fam4plus_1956 ///
		n_singlefam = singlefam ///
		if (dist_both<=0.21 & dist_both>=-0.2) ///
		, by(boundary_type side)

drop if boundary_type == ""

* label export variables
lab var side "relaxed/strict boundary side"

lab var mean_fam23_1918 "mean share of props 2-3 units >=1918 in 2018"
lab var mean_fam23_1956 "mean share of props 2-3 units >=1956 in 2018"
lab var mean_fam4plus_1918 "mean share of props 4+ units >=1918 in 2018"
lab var mean_fam4plus_1956 "mean share of props 4+ units >=1956 in 2018"
lab var mean_singlefam "mean share of props single fam last sale year 2010 to 2018"

lab var n_fam23_1918 "count of props 2-3 units >=1918 in 2018"
lab var n_fam23_1956 "count of props 2-3 units >=1956 in 2018"
lab var n_fam4plus_1918 "count of props 4+ units >=1918 in 2018"
lab var n_fam4plus_1956 "count of props 4+ units >=1956 in 2018"
lab var n_singlefam "count of props single fam last sale year 2010 to 2018"
	
* save as .dta file
//save "postQJE_means_lpm.dta", replace

* display output in log file
tabdisp boundary_type, cell(mean_*)

restore
	
	
********************************************************************************
** calc property level means for units, prices, rents
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


********************************************************************************
** calc boundary level means for height, dupac, mf allowed
********************************************************************************
preserve

unique lam_seg boundary_side boundary_type height dupac mf_allow

* error check uniuqe vals
/* assert `r(N)' ==  962015
assert `r(sum)' ==  3431
assert `r(unique)' ==  3431 */

bysort lam_seg boundary_side boundary_type: keep if _n==1

* error check
/* assert _N == 3431 */

* collapse to calc means
collapse (mean) mean_height=height mean_dupac=dupac mean_mfallow=mf_allow  ///
	(count) n_height=height n_dupac=dupac n_mfallow=mf_allow ///
	, by(boundary_type side)

drop if boundary_type == ""

* error check
/* assert _N == 14 */

* label export variables
lab var boundary_type "regulation boundary type"
lab var mean_height "avg. height regulation"
lab var mean_dupac "avg dupac regulation"
lab var mean_mfallow "avg share allowing mf"
lab var n_height "count of boundaries used in mean_height"
lab var n_dupac "count of boundaries used in mean_dupac"
lab var n_mfallow "count of boundaries used in mean_mfallow"

//save "postQJE_means_boundary_lvl.dta", replace

* display output in log
di "Boundary level MEANS for height, dupac, mf_allow"
tabdisp boundary_type side, cell(mean_height mean_dupac mean_mfallow)

di "Boundary level COUNTS for height, dupac, mf_allow"
tabdisp boundary_type side, cell(n_height n_dupac n_mfallow)
	
restore

*AK added deltas
*absolute values for deltas
replace mf_delta = abs(mf_delta)
replace he_delta = abs(he_delta)
replace du_delta = abs(du_delta)

* additional code added on 3/9/2023
bysort lam_seg (boundary_dist): gen closest_parcel = 1 if _n == 1 // this will tag the closest property to a bounary (lam_seg)

gen closest_city_lamseg = closest_city_dist if closest_parcel == 1    /*what is the closest city dist of that closest parcel*/

gen transit_dist_lamseg = transit_dist if closest_parcel == 1     /*what is the transit dist to south station of that closest parcel */

* end of additional code from 3/9/2023

*calculate total number of units at different boundary types
by boundary_type, sort: egen total_units = total(num_units1)    /*check with Nick about this*/

tab boundary_type total_units    /*to be added to Table 1*/

sum lot_sizeac, d     /*distribution of land parcel sizes, @ nick do we think this variable is in here? */
sum lot_sizesqft, d


** Table 1 
preserve 

* collapse to calc means (NEW VARIABLES)
collapse (mean) m_closest_city_lamseg=closest_city_lamseg m_transit_dist_lamseg=transit_dist_lamseg m_frac_under18=frac_under18 m_frac_over65=frac_over65 m_frac_mortgage=frac_mortgage m_frac_rented=frac_rented m_frac_female=frac_female m_frac_black=frac_black m_frac_asian=frac_asian m_frac_hispanic=frac_hispanic m_frac_nonhispanicwhite=frac_nonhispanicwhite m_frac_morethan4=frac_morethan4 m_median_inc=median_inc m_total_pop=total_pop m_SHARE_CAR_MBIKE=SHARE_CAR_MBIKE m_SHARE_PUBLICTRANS=SHARE_PUBLICTRANS m_SHARE_INC_OVER200K=SHARE_INC_OVER200K m_SHARE_BACHELOR_25=SHARE_BACHELOR_25 only_du only_mf only_he du_he mf_du mf_he mean_height=height mean_dupac=dupac mean_mfallow=mf_allow mean_deltamf = mf_delta mean_deltahe = he_delta mean_deltadu = du_delta (count) n_height=height n_dupac=dupac n_mfallow=mf_allow, by(lam_seg)

* eststo means (NEW VARIABLES)
eststo only_du: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if only_du == 1
eststo only_mf: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25  if only_mf == 1
eststo only_he: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if only_he == 1
eststo du_he: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if du_he == 1
eststo mf_du: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if mf_du == 1
eststo mf_he: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if mf_he == 1


* eststo ttests (NEW VARIABLES)
*Table 1 Panel C
eststo t_mf: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | only_mf == 1), by(only_du)
eststo t_he: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | only_he == 1), by(only_du)
eststo t_duhe: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | du_he == 1), by(only_du)
eststo t_mfdu: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | mf_du == 1), by(only_du)
eststo t_mfhe: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | mf_he == 1), by(only_du)


*Table 1 Panel B
esttab only_mf only_du t_mf, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_he only_du t_he, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab du_he only_du t_duhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_du only_du t_mfdu, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_he only_du t_mfhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

eststo clear


*Table 1 Panel A
*look at distribution of deltas 
summarize mean_deltamf mean_deltadu mean_deltahe if only_du == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if only_mf == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if only_he == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if du_he == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if mf_du == 1, d 
summarize mean_deltamf mean_deltadu mean_deltahe if mf_he == 1, d


restore

********************************************************************************
** end
********************************************************************************
log close
clear all
