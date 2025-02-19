clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name = "postrestat_means" 

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES SETUP VERSION **


********************************************************************************
* File name:		"postQJE_means.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		calculates means for units/rents/prices and height/dupac/mf
*					at the property, boundary, and town level. regulation
*					means only calculated for the boundary file. all means
*					exported as .dta files
* 				
* Inputs:		./mt_orthogonal_dist_100m_07-01-22_v2.dta
*				./final_dataset_10-28-2021.dta"
* 				./dist_south_station_2022_09_29.csv
*				./transit_distance.csv
*
* Outputs:		n/a
*
* Created:		11/10/2021
* Updated:		03/09/2023
********************************************************************************

* create a save directory if none exists
global EXPORTPATH "$DATAPATH/postQJE_data_exports/`name'_`date_stamp'"

capture confirm file "$EXPORTPATH"

if _rc!=0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

cd $EXPORTPATH


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

gen transit_dist = transit_dist_m/1609 // this is the transit distance to south station but in miles, not meters

tempfile transit
save `transit', replace

********************************************************************************
** load final dataset
********************************************************************************
*use "$DATAPATH/final_dataset_10-28-2021.dta", clear

********************************************************************************
** run postQJE within town setup file
********************************************************************************
*run "$DOPATH/postQJE_within_town_setup.do"
// use "$DATAPATH/postQJE_Within_Town_setup_data.dta",clear
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

// stop
// tempfile save_point
// save `save_point', replace
** end of extended setup **

** code for testing added 3/9/2023 by NFC
//use "C:\Users\nicholas.chiumenti\Documents\boston_zoning\postQJE_sample_50k_12292022.dta", clear
//gen transit_dist = runiform(1,100)

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

* error check
/* sum units
	assert `r(N)' ==  53926
	assert `r(sum_w)' ==  53926
	assert `r(mean)' ==  1.466917627860401
	assert `r(Var)' ==  41.80136265272328
	assert `r(sd)' ==  6.465397331388325
	assert `r(min)' ==  1
	assert `r(max)' ==  601
	assert `r(sum)' ==  79105

sum rent
	assert `r(N)' ==  149042
	assert `r(sum_w)' ==  149042
	assert `r(mean)' ==  1190.58200293449
	assert `r(Var)' ==  442463.4875743266
	assert `r(sd)' ==  665.179289796613
	assert `r(min)' ==  0
	assert `r(max)' ==  4995.37758772267
	assert `r(sum)' ==  177446722.8813623

sum price
	assert `r(N)' ==  88425
	assert `r(sum_w)' ==  88425
	assert `r(mean)' ==  586028.3923129035
	assert `r(Var)' ==  113294638707.3995
	assert `r(sd)' ==  336592.689622635
	assert `r(min)' ==  2731.73488174657
	assert `r(max)' ==  2099133.386838418
	assert `r(sum)' ==  51819560590.26849
	
sum fam23_1918 
	assert `r(N)' ==  72535
	assert `r(sum_w)' ==  72535
	assert `r(mean)' ==  .0770800303301854
	assert `r(Var)' ==  .0711396800179769
	assert `r(sd)' ==  .2667202279880115
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  5591

sum fam23_1956 
	assert `r(N)' ==  44671
	assert `r(sum_w)' ==  44671
	assert `r(mean)' ==  .0289449531015648
	assert `r(Var)' ==  .0281077720089473
	assert `r(sd)' ==  .1676537264988384
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  1293

sum fam4plus_1918 
	assert `r(N)' ==  67678
	assert `r(sum_w)' ==  67678
	assert `r(mean)' ==  .0108454741570377
	assert `r(Var)' ==  .0107280083627929
	assert `r(sd)' ==  .1035760993800833
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  734

sum fam4plus_1956 
	assert `r(N)' ==  43712
	assert `r(sum_w)' ==  43712
	assert `r(mean)' ==  .0076409224011713
	assert `r(Var)' ==  .0075827121758369
	assert `r(sd)' ==  .0870787699490349
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  334

sum singlefam
	assert `r(N)' ==  171104
	assert `r(sum_w)' ==  171104
	assert `r(mean)' ==  .7039110716289508
	assert `r(Var)' ==  .2084214929654413
	assert `r(sd)' ==  .4565320284114153
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  120442

sum height
	assert `r(N)' ==  962015
	assert `r(sum_w)' ==  962015
	assert `r(mean)' ==  3.449134576903687
	assert `r(Var)' ==  .6153669665846871
	assert `r(sd)' ==  .7844532915251788
	assert `r(min)' ==  0
	assert `r(max)' ==  35.6
	assert `r(sum)' ==  3318119.2

sum dupac
	assert `r(N)' ==  962015
	assert `r(sum_w)' ==  962015
	assert `r(mean)' ==  9.719478386511645
	assert `r(Var)' ==  217.705447898112
	assert `r(sd)' ==  14.754844895766
	assert `r(min)' ==  0
	assert `r(max)' ==  349
	assert `r(sum)' ==  9350284

sum mf_allow
	assert `r(N)' ==  962015
	assert `r(sum_w)' ==  962015
	assert `r(mean)' ==  .5402472934413705
	assert `r(Var)' ==  .2483804135583165
	assert `r(sd)' ==  .4983777819669698
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  519726 */

	
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

*generate community type 
quietly{
*Basic ring defition
#delimit ;
gen def_1 = 1 if (city=="Arlington" | 
			city=="Belmont" | 
			city=="Boston" | 
			city=="Brookline" | 
			city=="Cambridge" | 
			city=="Chelsea" |
			city=="Everett" | 
			city=="Malden" | 
			city=="Medford" | 
			city=="Melrose" | 
			city=="Newton" | 
			city=="Revere" | 
			city=="Somerville" | 
			city=="Waltham" | 
			city=="Watertown" | 
			city=="Winthrop") ;
				   
replace def_1 = 2 if (city=="Beverly" | 
			city=="Framingham" | 
			city=="Gloucester"| 
			city=="Lynn" | 
			city=="Marlboro" | 
			city=="Milford" | 
			city=="Salem" | city=="Woburn") ;
				   
replace def_1 = 3 if (city=="Acton" | 
			city=="Bedford" | 
			city=="Canton"| 
			city=="Concord" | 
			city=="Dedham" | 
			city=="Duxbury" |
			city=="Hingham" | 
			city=="Holbrook" | 
			city=="Hull" | 
			city=="Lexington" | 
			city=="Lincoln" | 
			city=="Marblehead" | 
			city=="Marshfield" | 
			city=="Maynard" | 
			city=="Medfield" | 
			city=="Milton" | 
			city=="Nahant"| 
			city=="Natick" | 
			city=="Needham" | 
			city=="North Reading" | 
			city=="Pembroke" | 
			city=="Randolph" | 
			city=="Scituate" |	
			city=="Sharon" | 
			city=="Southboro" |  
			city=="Stoneham" | 
			city=="Stoughton" |  
			city=="Sudbury" | 
			city=="Swampscott" | 
			city=="Wakefield" | 
			city=="Wayland" | 
			city=="Wellesley" | 
			city=="Weston" | 
			city=="Westwood" | 
			city=="Weymouth") ;
				   
replace def_1 = 4 if (city=="Bolton" | 
			city=="Boxboro" | 
			city=="Carlisle"| 
			city=="Cohasset" | 
			city=="Dover" | 
			city=="Essex" | 
			city=="Foxboro" | 
			city=="Franklin" | 
			city=="Hanover" | 
			city=="Holliston" | 
			city=="Hopkinton" | 
			city=="Hudson" | 
			city=="Littleton" | 
			city=="Manchester" | 
			city=="Medway" | 
			city=="Middleton" | 
			city=="Millis"| 
			city=="Norfolk" | 
			city=="Norwell" | 
			city=="Rockland" | 
			city=="Rockport" | 
			city=="Sherborn" | 
			city=="Stow" | 
			city=="Topsfield" | 
			city=="Walpole" | 
			city=="Wrentham" ) ;
#delimit cr			


gen def_name = "Inner Core" if def_1 == 1 /* Blue  */
replace def_name = "Regional Urban" if def_1 == 2 /* Grey  */
replace def_name = "Mature Suburbs" if def_1 == 3 /* Green  */
replace def_name = "Developing Suburbs" if def_1 == 4 /* Yellow  */

rename county_fip orig_county_fip
rename county orig_county

gen county_fip = def_1
gen county = def_1
}

*AK: merge in ACS data 
*TO DO - CHECK WHICH ID TO USE warren_GEOID_full or orig_GEOID_full <--- confirmed it is warren_GEOID_full
*block data
merge m:1 warren_GEOID_full using "$DATAPATH/acs/blocks_2010.dta"

drop if _merge ==2
drop _merge 

*block group data
gen BLKGRP = substr(warren_GEOID_full,1,12)

merge m:1 year BLKGRP using "$DATAPATH/acs/acs_amenities.dta", keepusing(B19113001 B0100300 SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25)
drop if _merge == 2
drop _merge 

rename B19113001 median_inc
rename B0100300 total_pop

preserve

*TABLE 1
*means and t-test (NEW VARIABLES)

*means
eststo only_du: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if only_du == 1
eststo only_mf: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if only_mf == 1
eststo only_he: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if only_he == 1
eststo du_he: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if du_he == 1
eststo mf_du: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if mf_du == 1
eststo mf_he: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if mf_he == 1

/*
//OLD CODE
eststo only_du: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if only_du == 1
eststo only_mf: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if only_mf == 1
eststo only_he: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if only_he == 1
eststo du_he: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if du_he == 1
eststo mf_du: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if mf_du == 1
eststo mf_he: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if mf_he == 1
*/

*ttests (NEW VARIABLES)
eststo t_mf: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if (only_du == 1 | only_mf == 1), by(only_du)
eststo t_he: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if (only_du == 1 | only_he == 1), by(only_du)
eststo t_duhe: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if (only_du == 1 | du_he == 1), by(only_du)
eststo t_mfdu: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if (only_du == 1 | mf_du == 1), by(only_du)
eststo t_mfhe: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25 if (only_du == 1 | mf_he == 1), by(only_du)

esttab only_mf only_du t_mf, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_he only_du t_he, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab du_he only_du t_duhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_du only_du t_mfdu, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_he only_du t_mfhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

eststo clear



*TABLE 2 (NEW VARIABLES)

foreach i of numlist 1 3 4 {
	levelsof def_name if def_1==`i'
	*means
	eststo only_du: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if only_du == 1 & def_1 == `i'
	eststo only_mf: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if only_mf == 1 & def_1 == `i'
	eststo only_he: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if only_he == 1 & def_1 == `i'
	eststo du_he: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if du_he == 1 & def_1 == `i'
	eststo mf_du: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if mf_du == 1 & def_1 == `i'
	eststo mf_he: quietly estpost summarize units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if mf_he == 1 & def_1 == `i'
	
	/*
	//OLD CODE
	eststo only_du: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if only_du == 1 & def_1 == `i'
	eststo only_mf: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if only_mf == 1 & def_1 == `i'
	eststo only_he: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if only_he == 1 & def_1 == `i'
	eststo du_he: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if du_he == 1 & def_1 == `i'
	eststo mf_du: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if mf_du == 1 & def_1 == `i'
	eststo mf_he: sum units rent price closest_city_dist frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc if mf_he == 1 & def_1 == `i'
*/
	*ttests (NEW VARIABLES)
	eststo t_mf: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if (only_du == 1 | only_mf == 1) & def_1 == `i', by(only_du)
	eststo t_he: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if (only_du == 1 | only_he == 1) & def_1 == `i', by(only_du)
	eststo t_duhe: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if (only_du == 1 | du_he == 1) & def_1 == `i', by(only_du)
	eststo t_mfdu: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if (only_du == 1 | mf_du == 1) & def_1 == `i', by(only_du)
	eststo t_mfhe: quietly estpost ttest units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K if (only_du == 1 | mf_he == 1) & def_1 == `i', by(only_du)

	esttab only_mf only_du t_mf, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab only_he only_du t_he, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab du_he only_du t_duhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab mf_du only_du t_mfdu, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab mf_he only_du t_mfhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

	eststo clear

}



* collapse to calc means
collapse (mean) mean_units=units mean_rent=rent mean_price=price ///
	(count) n_units=units n_rent=rent n_price=price ///
	, by(boundary_type side)

* export data as a .dta file
drop if boundary_type == ""

* label export variables
lab var boundary_type "regulation boundary type"
lab var mean_units "avg. number of units"
lab var mean_rent "avg. rent"
lab var mean_price "avg sales price"
lab var n_units "count of properties used in mean_units"
lab var n_rent "count of properties used in mean_rent"
lab var n_price "count of properties used in mean_price"

* save as .dta file
//save "postQJE_means_property_lvl.dta", replace

* display output in log file
di "Property level MEANS for units, rent, prices"
tabdisp boundary_type side, cell(mean_units mean_rent mean_price)

di "Property level COUNTS for units, rent, prices"
tabdisp boundary_type side, cell(n_units n_rent n_price)

restore


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

/*
//OLD CODE
eststo only_du: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe  if only_du == 1
eststo only_mf: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe  if only_mf == 1
eststo only_he: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe  if only_he == 1
eststo du_he: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if du_he == 1
eststo mf_du: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if mf_du == 1
eststo mf_he: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if mf_he == 1
*/

* eststo ttests (NEW VARIABLES)
eststo t_mf: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | only_mf == 1), by(only_du)
eststo t_he: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | only_he == 1), by(only_du)
eststo t_duhe: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | du_he == 1), by(only_du)
eststo t_mfdu: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | mf_du == 1), by(only_du)
eststo t_mfhe: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | mf_he == 1), by(only_du)

esttab only_mf only_du t_mf, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab only_he only_du t_he, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab du_he only_du t_duhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_du only_du t_mfdu, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
esttab mf_he only_du t_mfhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

eststo clear



*look at distribution of deltas 
summarize mean_deltamf mean_deltadu mean_deltahe if only_du == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if only_mf == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if only_he == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if du_he == 1, d
summarize mean_deltamf mean_deltadu mean_deltahe if mf_du == 1, d 
summarize mean_deltamf mean_deltadu mean_deltahe if mf_he == 1, d


restore

** Table 2 (NEW VARIABLES)
preserve 

* Table 2, collapse by boundary type and city type 
collapse  (mean) m_closest_city_lamseg=closest_city_lamseg m_transit_dist_lamseg=transit_dist_lamseg m_frac_under18=frac_under18 m_frac_over65=frac_over65 m_frac_mortgage = frac_mortgage m_frac_rented = frac_rented m_frac_female = frac_female m_frac_black=frac_black m_frac_asian=frac_asian m_frac_hispanic=frac_hispanic m_frac_nonhispanicwhite=frac_nonhispanicwhite m_frac_morethan4=frac_morethan4 m_median_inc=median_inc m_total_pop = total_pop m_SHARE_CAR_MBIKE = SHARE_CAR_MBIKE m_SHARE_PUBLICTRANS =SHARE_PUBLICTRANS m_SHARE_INC_OVER200K = SHARE_INC_OVER200K m_SHARE_BACHELOR_25=SHARE_BACHELOR_25 only_du only_mf only_he du_he mf_du mf_he  mean_height=height mean_dupac=dupac mean_mfallow=mf_allow mean_deltamf = mf_delta mean_deltahe = he_delta mean_deltadu = du_delta (count) n_height=height n_dupac=dupac n_mfallow=mf_allow, by(lam_seg def_1 def_name)
	
foreach i of numlist 1 3 4 {
	levelsof def_name if def_1==`i'
	*means 
	eststo only_du: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if only_du == 1 & def_1 == `i'
	eststo only_mf: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if only_mf == 1 & def_1 == `i'
	eststo only_he: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if only_he == 1 & def_1 == `i'
	eststo du_he: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if du_he == 1 & def_1 == `i'
	eststo mf_du: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if mf_du == 1 & def_1 == `i'
	eststo mf_he: quietly estpost summarize mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if mf_he == 1 & def_1 == `i'
	
	/*
	//OLD CODE
	eststo only_du: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if only_du == 1 & def_1 == `i'
	eststo only_mf: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if only_mf == 1 & def_1 == `i'
	eststo only_he: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if only_he == 1 & def_1 == `i'
	eststo du_he: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if du_he == 1 & def_1 == `i'
	eststo mf_du: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if mf_du == 1 & def_1 == `i'
	eststo mf_he: sum mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe if mf_he == 1 & def_1 == `i'
	*/

	*ttests
	eststo t_mf: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | only_mf == 1) & def_1 == `i', by(only_du)
	eststo t_he: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | only_he == 1)& def_1 == `i', by(only_du)
	eststo t_duhe: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | du_he == 1)& def_1 == `i', by(only_du)
	eststo t_mfdu: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | mf_du == 1) & def_1 == `i', by(only_du)
	eststo t_mfhe: quietly estpost ttest mean_height mean_dupac mean_mfallow mean_deltamf mean_deltadu mean_deltahe m_closest_city_lamseg m_transit_dist_lamseg m_frac_under18 m_frac_over65 m_frac_mortgage  m_frac_rented  m_frac_female  m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE  m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 if (only_du == 1 | mf_he == 1) & def_1 == `i', by(only_du)

	esttab only_mf only_du t_mf, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab only_he only_du t_he, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab du_he only_du t_duhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab mf_du only_du t_mfdu, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
	esttab mf_he only_du t_mfhe, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label

	eststo clear

}
	
	

restore



********************************************************************************
** gen and export town level means for units, rents, prices by relaxed/strict
********************************************************************************
preserve

unique cousub_name boundary_type side
	/* assert `r(N)' ==  962015
	assert `r(sum)' ==  400
	assert `r(unique)' ==  400 */
	
collapse (mean) mean_units=units mean_rent=rent mean_price=price (mean) mean_fam23_1918 = fam23_1918 mean_fam23_1956 = fam23_1956 mean_fam4plus_1918 = fam4plus_1918 mean_fam4plus_1956 = fam4plus_1956 mean_singlefam = singlefam (count) n_units=units n_rent=rent n_price=price (count) n_fam23_1918 = fam23_1918 n_fam23_1956 = fam23_1956 n_fam4plus_1918 = fam4plus_1918 n_fam4plus_1956 = fam4plus_1956 n_singlefam = singlefam, by(cousub_name boundary_type side)

drop if boundary_type == ""
	
* error check
/* assert _N == 395 */
	
* export data as a .dta file

lab var cousub_name "municipality name"
lab var boundary_type "regulation boundary type"
lab var side "strict vs. relaxed"
lab var mean_units "avg. number of units"
lab var mean_rent "avg. rent"
lab var mean_price "avg sales price"
lab var n_units "count of properties used in mean_units"
lab var n_rent "count of properties used in mean_rent"
lab var n_price "count of properties used in mean_price"

//save "postQJE_means_town_lvl.dta", replace

restore


********************************************************************************
** end
********************************************************************************
log close
clear all
