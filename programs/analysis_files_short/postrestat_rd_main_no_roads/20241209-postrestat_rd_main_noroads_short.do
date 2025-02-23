clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postrestat_rd_main_no_roads" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

********************************************************************************
* File name:		"postREStat_rd_main_no_roads"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		This is a very trimmed down version of the original no roads
*					file. It overlays the no roads coegplots with versions using
*					the baseline data. It has been edited to run on Fed computers
*					
*					Note from 05-29-2024: This version uses weights to adjust the
*					different boundary coefficients
*
*					Note from 12-4-2024: This version was updated to cut out all 
*					of the non price and rent regressions and just focus on those.
*					The section naming schemes were kept the same
*
*					Contents:
*					Part 4: Sales prices
*					- 4a. Basline (same as mt lines main file)
*					- 4b. No roads w/ tract weights
*					- 4c. No roads w/ tract weights and robust SE
*					- 4d. no roads w/o tract weights w/ no_roads indicator restriction
*					- 4e. no roads w/ tract weights and robust SE w/ no_roads indicator restriction
*					- 4f. Basline boundaries but only in tracts that also have a no roads boundary <-- baseline but just no roads only
*					- 4g. - no roads w/o tract weights
*
*					Part 6: Rents
*					- 6a. Basline (same as mt lines main file)
*					- 6b. No roads w/ tract weights
*					- 6c. No roads w/ tract weights and robust SE
*					- 6d. no roads w/o tract weights w/ no_roads indicator restriction
*					- 6e. no roads w/o tract weights and robust SE w/ no_roads indicator restriction
*					- 6f. Baseline boundaries but only in tracts that also have a no roads boundary <-- baseline but just no roads only
*					- 6g. No roads w/o tract weights
* 				
* Inputs:		mt_orthogonal_dist_100m_07-01-22_v2.dta
*				final_dataset_10-28-2021.dta
*				
* Outputs:		lots of graphs
*
* Created:		06/23/2021
* Updated:		12/4/2024
********************************************************************************
* create a save directory if none exists
global RDPATH "$FIGPATH/`name'_`date_stamp'"

capture confirm file "$RDPATH"


if _rc!=0 {
	di "making directory $RDPATH"
	shell mkdir $RDPATH
}

cd $RDPATH

/* NFC Note to self: Mike Corbett ran this setup already and saved the output so it
would be faster to run. As such the setup code has been commented out */

/* This comments out the entire setup code
********************************************************************************
** Setup step 1: Get the no road boundary data
********************************************************************************
/* NFC Note: The .do file below is self contained, meaning you do not need to 
load any .dta file before running it. Ultimately the only variables we need from 
this step are lam_seg, dist_both, and dist3 */

run "$DOPATH/miscellaneous_dofiles/postQJE_within_town_setup_no_roads.do"  // NFC Note: This uses a postQJE version setup file because we do not need a postREStat version

keep if straight_line == 1 // <-- drops non-straight line properties

keep if (year >= 2010 & year <= 2018)

// NFC flag: do i need to keep the regulation variables too?

* keep only the regulation variables and vars to match
keep prop_id year dist_both dist3 lam_seg only_du only_he only_mf mf_he mf_du du_he mf_he_du

tab year

* temp save the data
tempfile noroads
save `noroads', replace
clear

/* NFC Note: Now at this point we are going to use the make "baseline" dataset
to run both calculate the tract weights and use for the background data */


********************************************************************************
** Setup step 2: Compile the baseline data 
********************************************************************************
* load the mt lines data and tempsave
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace

* load final dataset and run the setup file
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear
// run "$DOPATH/postREStat_within_town_setup.do"

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta", clear  // NFC Note: we can use the pre-saved data here

** merge on mt lines to keep straight line properties
merge m:1 prop_id using `mtlines', keepusing(straight_line)

	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties

keep if (year >= 2010 & year <= 2018)  // drops out of scope year observaions


********************************************************************************
** Setup step 3: Calculate the tract weights
********************************************************************************
* preserve the data
preserve

* calculate share of total observations in each census tract
by warren_GEOID_full, sort: gen num_obs_tract = _N
gen total_obs = _N

gen pop_perc_tract = num_obs_tract/total_obs

* calculate share of census tract observations in each boundary type
by only_du, sort: gen total_obs_du = _N
by only_mf, sort: gen total_obs_mf = _N
by only_he, sort: gen total_obs_he = _N
by mf_du, sort: gen total_obs_mfdu = _N
by du_he, sort: gen total_obs_duhe = _N
by mf_he, sort: gen total_obs_mfhe = _N

by warren_GEOID_full only_du, sort: gen tract_obs_du = _N
by warren_GEOID_full only_mf, sort: gen tract_obs_mf = _N
by warren_GEOID_full only_he, sort: gen tract_obs_he = _N
by warren_GEOID_full mf_du, sort: gen tract_obs_mfdu = _N
by warren_GEOID_full du_he, sort: gen tract_obs_duhe = _N
by warren_GEOID_full mf_he, sort: gen tract_obs_mfhe = _N

gen pop_perc_tract_du = tract_obs_du/total_obs_du
gen pop_perc_tract_mf = tract_obs_mf/total_obs_mf
gen pop_perc_tract_he = tract_obs_he/total_obs_he
gen pop_perc_tract_mfdu = tract_obs_mfdu/total_obs_mfdu
gen pop_perc_tract_duhe = tract_obs_duhe/total_obs_duhe
gen pop_perc_tract_mfhe = tract_obs_mfhe/total_obs_mfhe

replace pop_perc_tract_du = . if only_du == 0
replace pop_perc_tract_mf = . if only_mf == 0
replace pop_perc_tract_he = . if only_he == 0
replace pop_perc_tract_mfdu = . if mf_du == 0 
replace pop_perc_tract_duhe = . if du_he == 0
replace pop_perc_tract_mfhe = . if mf_he == 0

* for each census tract, set the share in the boundary type to the same value
sort warren_GEOID_full pop_perc_tract_du
by warren_GEOID_full: replace pop_perc_tract_du = pop_perc_tract_du[_n-1] if pop_perc_tract_du==. & pop_perc_tract_du[_n-1]!=.

sort warren_GEOID_full pop_perc_tract_mf
by warren_GEOID_full: replace pop_perc_tract_mf = pop_perc_tract_mf[_n-1] if pop_perc_tract_mf==. & pop_perc_tract_mf[_n-1]!=.

sort warren_GEOID_full pop_perc_tract_he
by warren_GEOID_full: replace pop_perc_tract_he = pop_perc_tract_he[_n-1] if pop_perc_tract_he==. & pop_perc_tract_he[_n-1]!=.

sort warren_GEOID_full pop_perc_tract_mfdu
by warren_GEOID_full: replace pop_perc_tract_mfdu = pop_perc_tract_mfdu[_n-1] if pop_perc_tract_mfdu==. & pop_perc_tract_mfdu[_n-1]!=.

sort warren_GEOID_full pop_perc_tract_duhe
by warren_GEOID_full: replace pop_perc_tract_duhe = pop_perc_tract_duhe[_n-1] if pop_perc_tract_duhe==. & pop_perc_tract_duhe[_n-1]!=.

sort warren_GEOID_full pop_perc_tract_mfhe
by warren_GEOID_full: replace pop_perc_tract_mfhe = pop_perc_tract_mfhe[_n-1] if pop_perc_tract_mfhe==. & pop_perc_tract_mfhe[_n-1]!=.

* for all census tracts, keep all proportions when types == 1
by warren_GEOID_full, sort: gen nvals = _n == 1
keep if nvals == 1

* trim variable list
keep warren_GEOID_full pop_perc_*

* temp save the tract population weights that will be merged back after no-roads setup
tempfile tract_pop_weights
save `tract_pop_weights', replace 

* restore the data
restore

********************************************************************************
** Setup step 4Finalize the baseline data
********************************************************************************
/* NFC Note: The first sub-step here is to just preserve the baseline data and 
then clear it. The second sub-step is to load and tempsave the characteristics data. 
The third and final sub-step is to merge the characteristics variables back onto
the baseline data */

* rename the important boundary variables to tag them as baseline versions
rename dist_both dist_both_baseline
rename dist3 dist3_baseline
rename lam_seg lam_seg_baseline
rename only_du only_du_baseline
rename only_he only_he_baseline
rename only_mf only_mf_baseline
rename mf_he mf_he_baseline
rename mf_du mf_du_baseline
rename du_he du_he_baseline
rename mf_he_du mf_he_du_baseline

tempfile baseline
save`baseline', replace
clear


********************************************************************************
** Setup step 4.1: load and tempsave the soil data
********************************************************************************
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** Setup step 4.2: load and tempsave the transit data
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
** Setup step 4.3: merge on characteristics data
********************************************************************************
use `baseline', clear

* soil data
merge m:1 prop_id using `soil'
	/*
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
    */
   
    tab _merge
	drop if _merge == 2
	drop _merge

* transit data
merge m:1 prop_id using `transit'
	
	* merge error check
	/* sum _merge
	assert `r(N)' ==  3642292
	assert `r(sum_w)' ==  3642292
	assert `r(mean)' ==  2.878361207723049
	assert `r(Var)' ==  .1068428258243096
	assert `r(sd)' ==  .3268682086473226
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  10483832 */
	
    tab _merge
	drop if _merge == 2
	drop _merge

* drop out of scope years just to be safe
keep if (year >= 2010 & year <= 2018)

tab year

* merge on block data level characteristics
merge m:1 warren_GEOID_full using "$DATAPATH/acs/blocks_2010.dta", update replace
	
	* summarize _merge var and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

    * create block group making variable
    gen BLKGRP = substr(warren_GEOID_full,1,12)

* merge on acs amenities dataset
merge m:1 year BLKGRP using "$DATAPATH/acs/acs_amenities.dta", keepusing(B19113001)

	* summarize merge and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

	* rename median income variable
	rename B19113001 median_inc


********************************************************************************
** Setup step 5: merge on tract weights
********************************************************************************
merge m:1 warren_GEOID_full using `tract_pop_weights'

    tab _merge
    drop if _merge == 2
    drop _merge 

********************************************************************************
** Setup step 6: merge on no roads variables
********************************************************************************
merge 1:1 prop_id year using `noroads'

    tab _merge
    drop if _merge == 2
    drop _merge 


********************************************************************************
** property characteristic variables
********************************************************************************

* define a global set of acs variable controls
global acs_vars frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc

* define a global set of characteristic variables
gen char1_lotsizeac1 = ln(lot_sizeac) if lot_sizeac != 0			// lot size in acres, excl zero acre --> NOW IN LOGS
gen char2_livingarea1 = ln(livingarea) / num_units1 if livingarea != 0		// living area in XX per unit, excl zero --> NOW IN LOGS
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0		// num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0		// num full bathrooms per unit, atleast 1

gen log_lotacres = ln(lot_acres) if lot_acres!=0
gen log_bldgarea =ln(grossbldg_area) if grossbldg_area!=0

global char_vars i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num

* define a global set of amenity variables
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

global char_vars_land dist_school dist_center dist_road dist_river dist_space transit_dist soil_avgslope soil_slope15 soil_avgrestri soil_avgsand soil_avgclay

** END OF SETUP STEPS **
/* NFC Note: At this point we should have a dataset that has 4 main components:
    1) The "baseline" straight line regulation data and corresponding warren group property data, tagged as "_baseline"
    2) The characteristics (acs, amenities, and distance to stuff)
    3) The tract weights based on the baseline data
    4) The "noroads" versions of lam_seg, distance to boundary (dist_both and dist3) and boundary types
*/
save "$DATAPATH/interim_20240927",replace
stop

End of Commented Setup */

********************************************************************************
** Beginning of analysis portion of file
********************************************************************************

* load the interim dataset for analaysis
use "$DATAPATH/interim_20240927", clear

* define the globals used for regressions
global acs_vars frac_under18 frac_over65 frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc
global char_vars i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num
global char_vars_land dist_school dist_center dist_road dist_river dist_space transit_dist soil_avgslope soil_slope15 soil_avgrestri soil_avgsand soil_avgclay

* generate no roads indicator and baseline indicator
gen no_roads = lam_seg != .  // is no roads obs if lam_seg is not missing
gen baseline = lam_seg_baseline != .  // is baseline obs if lam_seg_baseline is not missing

* check the samples
tab no_roads baseline, miss 


********************************************************************************
** Define the MAPC town types used in spatial heterogeneity file

/* NFC Note: this code was taken directly from "Final_Spatial_Heterogeneity.do"
and modified slightly so variable names would not conflict */
********************************************************************************
* Basic ring defition
cap drop town_type_1 town_type_name
replace city = upper(city)

#delimit ;

gen town_type_1 = 1 if (city=="ARLINGTON" | 
			city=="BELMONT" | 
			city=="BOSTON" | 
			city=="BROOKLINE" | 
			city=="CAMBRIDGE" | 
			city=="CHELSEA" |
			city=="EVERETT" | 
			city=="MALDEN" | 
			city=="MEDFORD" | 
			city=="MELROSE" | 
			city=="NEWTON" | 
			city=="REVERE" | 
			city=="SOMERVILLE" | 
			city=="WALTHAM" | 
			city=="WATERTOWN" | 
			city=="WINTHROP") ;
				   
replace town_type_1 = 2 if (city=="BEVERLY" | 
			city=="FRAMINGHAM" | 
			city=="GLOUCESTER"| 
			city=="LYNN" | 
			city=="MARLBORO" | 
			city=="MILFORD" | 
			city=="SALEM" | city=="WOBURN") ;
				   
replace town_type_1 = 3 if (city=="ACTON" | 
			city=="BEDFORD" | 
			city=="CANTON"| 
			city=="CONCORD" | 
			city=="DEDHAM" | 
			city=="DUXBURY" |
			city=="HINGHAM" | 
			city=="HOLBROOK" | 
			city=="HULL" | 
			city=="LEXINGTON" | 
			city=="LINCOLN" | 
			city=="MARBLEHEAD" | 
			city=="MARSHFIELD" | 
			city=="MAYNARD" | 
			city=="MEDFIELD" | 
			city=="MILTON" | 
			city=="NAHANT"| 
			city=="NATICK" | 
			city=="NEEDHAM" | 
			city=="NORTH READING" | 
			city=="PEMBROKE" | 
			city=="RANDOLPH" | 
			city=="SCITUATE" |	
			city=="SHARON" | 
			city=="SOUTHBORO" |  
			city=="STONEHAM" | 
			city=="STOUGHTON" |  
			city=="SUDBURY" | 
			city=="SWAMPSCOTT" | 
			city=="WAKEFIELD" | 
			city=="WAYLAND" | 
			city=="WELLESLEY" | 
			city=="WESTON" | 
			city=="WESTWOOD" | 
			city=="WEYMOUTH") ;
				   
replace town_type_1 = 4 if (city=="BOLTON" | 
			city=="BOXBORO" | 
			city=="CARLISLE"| 
			city=="COHASSET" | 
			city=="DOVER" | 
			city=="ESSEX" | 
			city=="FOXBORO" | 
			city=="FRANKLIN" | 
			city=="HANOVER" | 
			city=="HOLLISTON" | 
			city=="HOPKINTON" | 
			city=="HUDSON" | 
			city=="LITTLETON" | 
			city=="MANCHESTER" | 
			city=="MEDWAY" | 
			city=="MIDDLETON" | 
			city=="MILLIS"| 
			city=="NORFOLK" | 
			city=="NORWELL" | 
			city=="ROCKLAND" | 
			city=="ROCKPORT" | 
			city=="SHERBORN" | 
			city=="STOW" | 
			city=="TOPSFIELD" | 
			city=="WALPOLE" | 
			city=="WRENTHAM" ) ;
#delimit cr			

gen town_type_name = "Inner Core" if town_type_1 == 1 /* Blue  */
	replace town_type_name = "Regional Urban" if town_type_1 == 2 /* Grey  */
	replace town_type_name = "Mature Suburbs" if town_type_1 == 3 /* Green  */
	replace town_type_name = "Developing Suburbs" if town_type_1 == 4 /* Yellow  */

tab town_type_name no_roads, miss  // this should show the town types and how many obs in each are no roads



////stop// NFC 12-4-2024: remove this //stopafter verifying things look ok

tab town_type_name no_roads,miss col

/*******************************************************************************
** Part 4: Sales prices
	- 4a. Basline (same as mt lines main file)
	- 4b. No roads w/ tract weights
	- 4c. No roads w/ tract weights and robust SE
	- 4d. no roads w/o tract weights w/ no_roads indicator restriction
	- 4e. no roads w/o tract weights and robust SE w/ no_roads indicator restriction
	- 4f. Basline boundaries but only in tracts that also have a no roads boundary <-- baseline but just no roads only
	- 4g. No roads w/o tract weights, no roads tracts only
*******************************************************************************/
* summary statistics for all boundaries (baseline only + no roads only)
sum dist_center transit_dist dupac height mf_allowed if baseline==1 & res_typex =="Single Family Res" & last_saleyr>=2010 & last_saleyr<=2018,d

* summary stats for baseline only boundaries
sum dist_center transit_dist dupac height mf_allowed if baseline==1 & no_roads == 0 & res_typex =="Single Family Res" & last_saleyr>=2010 & last_saleyr<=2018,d

* summary statistics for no roads only
sum dist_center transit_dist dupac height mf_allowed if no_roads==1 & res_typex =="Single Family Res" & last_saleyr>=2010 & last_saleyr<=2018,d

* summary states by town types
tabstat dist_center transit_dist dupac height mf_allowed if baseline==1 & res_typex =="Single Family Res" & last_saleyr>=2010 & last_saleyr<=2018, by(town_type_name) statistics(n mean sd min max)

* baseline only boundaries
tabstat dist_center transit_dist dupac height mf_allowed if baseline==1 & no_roads == 0 & res_typex =="Single Family Res" & last_saleyr>=2010 & last_saleyr<=2018, by(town_type_name) statistics(n mean sd min max)

* no roads only
tabstat dist_center transit_dist dupac height mf_allowed if no_roads==1 & res_typex =="Single Family Res" & last_saleyr>=2010 & last_saleyr<=2018, by(town_type_name) statistics(n mean sd min max)

stop // NFC 12-9-2024: do not need to run beyond this point

*******************************************
** 4a. Basline (same as mt lines main file)
*******************************************
* define local regression conditions
gen dist3_unique = dist3_baseline

local regression_conditions_baseline (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both_baseline<=0.21 & dist_both_baseline>=-0.2) & res_typex=="Single Family Res"

* run baseline regressions
quietly eststo price_du_4a: reg log_saleprice ib26.dist3_unique i.lam_seg_baseline i.last_saleyr if only_du_baseline==1 & `regression_conditions_baseline', vce(cluster lam_seg_baseline)	
	
quietly eststo price_duhe_4a: reg log_saleprice ib26.dist3_unique i.lam_seg_baseline i.last_saleyr if du_he_baseline == 1 & `regression_conditions_baseline' , vce(cluster lam_seg_baseline)

quietly eststo price_mfdu_4a: reg log_saleprice ib26.dist3_unique i.lam_seg_baseline i.last_saleyr if  mf_du_baseline == 1 & `regression_conditions_baseline' , vce(cluster lam_seg_baseline)

quietly eststo price_mf_4a: reg log_saleprice ib26.dist3_unique i.lam_seg_baseline i.last_saleyr if only_mf_baseline== 1 & `regression_conditions_baseline' , vce(cluster lam_seg_baseline)

quietly eststo price_mfhe_4a: reg log_saleprice ib26.dist3_unique i.lam_seg_baseline i.last_saleyr if mf_he_baseline == 1 & `regression_conditions_baseline' , vce(cluster lam_seg_baseline)

quietly eststo price_he_4a: reg log_saleprice ib26.dist3_unique i.lam_seg_baseline i.last_saleyr if only_he_baseline == 1 & `regression_conditions_baseline', vce(cluster lam_seg_baseline)

esttab price_du_4a price_duhe_4a price_mfdu_4a price_mf_4a price_mfhe_4a price_he_4a, ///
	se r2 indicate("Boundary f.e.=*lam_seg_baseline" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du_baseline" "price_duhe_baseline" "price_mfdu_baseline" "price_mf_baseline" "price_mfhe_baseline" "price_he_baseline") ///
	title("4a. Sales Prices, baseline") 
	
*******************************************************************
** 4d. No roads w/o tract weights w/ no_roads indicator restriction
*******************************************************************
* set regression conditions for no roads version
drop dist3_unique
gen dist3_unique = dist3

local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & no_roads==1  // conditioned on no_roads indicator here

* run no roads regressions
quietly eststo price_du_4d: reg log_saleprice ib26.dist3_unique i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_duhe_4d: reg log_saleprice ib26.dist3_unique i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu_4d: reg log_saleprice ib26.dist3_unique i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions' , vce(cluster lam_seg)

quietly eststo price_mf_4d: reg log_saleprice ib26.dist3_unique i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe_4d: reg log_saleprice ib26.dist3_unique i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he_4d: reg log_saleprice ib26.dist3_unique i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du_4d price_duhe_4d price_mfdu_4d price_mf_4d price_mfhe_4d price_he_4d, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("4d. Sales Prices, no roads ") 


//stop // NFC 12-4-2024: remove this //stopafter verifying things look ok

/*******************************************************************************
** Part 4: Generate Graphs
	- 4.1. Baseline 4a with weighted no roads 4b
	- 4.2. Baseline 4a with unweighted no roads 4d
	- 4.3. Baseline 4f with unweighted no roads 4g, no roads tracks only
*******************************************************************************/

* 4.2. Baseline 4a with no roads 4d
local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_base_unweighted_noroads"
local l1_title "Log Sales Price"
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
		/* baseline side relaxed side graphing variables */
		(`r'_4a, keep(16.dist3_unique 17.dist3_unique 18.dist3_unique 19.dist3_unique 20.dist3_unique 21.dist3_unique 22.dist3_unique 23.dist3_unique 24.dist3_unique 25.dist3_unique) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* baseline side strict side graphing variables */
		(`r'_4a, keep(26.dist3_unique 27.dist3_unique 28.dist3_unique 29.dist3_unique 30.dist3_unique 31.dist3_unique 32.dist3_unique 33.dist3_unique 34.dist3_unique 35.dist3_unique)
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			)
			
		(`r'_4d, keep(16.dist3_unique 17.dist3_unique 18.dist3_unique 19.dist3_unique 20.dist3_unique 21.dist3_unique 22.dist3_unique 23.dist3_unique 24.dist3_unique 25.dist3_unique) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'_4d, keep(26.dist3_unique 27.dist3_unique 28.dist3_unique 29.dist3_unique 30.dist3_unique 31.dist3_unique 32.dist3_unique 33.dist3_unique 34.dist3_unique 35.dist3_unique) 
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
		name(`r'_42, replace) ;
		
	graph combine `r'_42,
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name(`r'_42a, replace);
	graph save `r'_42a `suffix'_`str', replace;
	graph close `r'_42a;
	#delimit cr
}

* combine all ##
#delimit ;
graph combine price_du_42 price_duhe_42 price_mfdu_42 price_mf_42 price_mfhe_42 price_he_42,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	

//eststo clear
graph close _all

/*******************************************************************************
** Part 6: Rents
	- 6a. Basline (same as mt lines main file)
	- 6b. No roads w/ tract weights
	- 6c. No roads w/ tract weights and robust SE
	- 6d. no roads w/o tract weights w/ no_roads indicator restriction
	- 6e. no roads w/o tract weights and robust SE w/ no_roads indicator restriction
	- 6f. Baseline boundaries but only in tracts that also have a no roads boundary <-- baseline but just no roads only
	- 6g. No roads w/o tract weights
*******************************************************************************/

* summary statistics for baseline
sum dist_center transit_dist dupac height mf_allowed if baseline==1 & res_typex != "Condominiums" & year>=2010 & year<=2018 & log_mfrent!=.

* summary statistics for no roads
sum dist_center transit_dist dupac height mf_allowed if no_roads==1 & res_typex != "Condominiums" & year>=2010 & year<=2018 & log_mfrent!=.

* summary states by town types
tabstat dist_center transit_dist dupac height mf_allowed if baseline==1 & res_typex != "Condominiums" & year>=2010 & year<=2018 & log_mfrent!=., by(town_type_name) statistics(n mean sd min max)

tabstat dist_center transit_dist dupac height mf_allowed if no_roads==1 & res_typex != "Condominiums" & year>=2010 & year<=2018 & log_mfrent!=., by(town_type_name) statistics(n mean sd min max)

////stop// NFC 12-4-2024: remove this //stopafter verifying things look ok

*******************************************
** 6a. Basline (same as mt lines main file)
*******************************************
* set baseline regression conditions
drop dist3_unique
gen dist3_unique = dist3_baseline

local regression_conditions_baseline (year>=2010 & year<=2018) & (dist_both_baseline<=0.21 & dist_both_baseline>=-0.2) & res_typex != "Condominiums"

* Part 6a: Rents w/o characteristics
quietly eststo rent_du_6a: reg log_mfrent ib26.dist3_unique i.lam_seg_baseline i.year if only_du_baseline==1 & `regression_conditions_baseline', vce(cluster lam_seg_baseline)
	
quietly eststo rent_duhe_6a: reg log_mfrent ib26.dist3_unique i.lam_seg_baseline i.year if du_he_baseline == 1 & `regression_conditions_baseline', vce(cluster lam_seg_baseline)

quietly eststo rent_mfdu_6a: reg log_mfrent ib26.dist3_unique i.lam_seg_baseline i.year if mf_du_baseline == 1 & `regression_conditions_baseline' , vce(cluster lam_seg_baseline)

quietly eststo rent_mf_6a: reg log_mfrent ib26.dist3_unique i.lam_seg_baseline i.year if only_mf_baseline== 1 & `regression_conditions_baseline', vce(cluster lam_seg_baseline)

quietly eststo rent_mfhe_6a: reg log_mfrent ib26.dist3_unique i.lam_seg_baseline i.year if mf_he_baseline == 1 & `regression_conditions_baseline' , vce(cluster lam_seg_baseline)

quietly eststo rent_he_6a: reg log_mfrent ib26.dist3_unique i.lam_seg_baseline i.year if only_he_baseline == 1 & `regression_conditions_baseline', vce(cluster lam_seg_baseline)
	
esttab rent_du_6a rent_duhe_6a rent_mfdu_6a rent_mf_6a rent_mfhe_6a rent_he_6a, se r2 ///
	indicate("Boundary f.e.=*lam_seg_baseline" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("6a. Rents, baseline") 

	
*******************************************************************
** 6d. no roads w/o tract weights w/ no_roads indicator restriction
*******************************************************************
* set regression conditions for no roads version
drop dist3_unique
gen dist3_unique = dist3

local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"  & no_roads == 1    /*conditioning on no roads indicator here */

* run regressions
quietly eststo rent_du_6d: reg log_mfrent ib26.dist3_unique i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe_6d: reg log_mfrent ib26.dist3_unique i.lam_seg i.year if du_he == 1 & `regression_conditions' , vce(cluster lam_seg)

quietly eststo rent_mfdu_6d: reg log_mfrent ib26.dist3_unique i.lam_seg i.year if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_mf_6d: reg log_mfrent ib26.dist3_unique i.lam_seg i.year if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_mfhe_6d: reg log_mfrent ib26.dist3_unique i.lam_seg i.year if mf_he == 1 & `regression_conditions' , vce(cluster lam_seg)

quietly eststo rent_he_6d: reg log_mfrent ib26.dist3_unique i.lam_seg i.year if only_he == 1 & `regression_conditions' , vce(cluster lam_seg)
	
esttab rent_du_6d rent_duhe_6d rent_mfdu_6d rent_mf_6d rent_mfhe_6d rent_he_6d, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
	title("6d. Rents, no roads") 

/*******************************************************************************
** Part 6: Generate Graphs
	- 6.1. Baseline 6a with weighted no roads 6b
	- 6.2. Baseline 6a with unweighted no roads 6d
	- 6.3. Baseline 6f with unweighted no roads 6g, no roads tracks only
*******************************************************************************/

* 6.2. Baseline 6a with no roads 6d
local plot_list rent_du rent_duhe rent_mfdu rent_mf rent_mfhe rent_he
local suffix "coef_rent_base_unweighted_noroads"
local l1_title "Log Monthly Rent"
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
		/* relaxed side graphing variables */
		(`r'_6a, keep(16.dist3_unique 17.dist3_unique 18.dist3_unique 19.dist3_unique 20.dist3_unique 21.dist3_unique 22.dist3_unique 23.dist3_unique 24.dist3_unique 25.dist3_unique) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'_6a, keep(26.dist3_unique 27.dist3_unique 28.dist3_unique 29.dist3_unique 30.dist3_unique 31.dist3_unique 32.dist3_unique 33.dist3_unique 34.dist3_unique 35.dist3_unique)
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			)

			

		(`r'_6d, keep(16.dist3_unique 17.dist3_unique 18.dist3_unique 19.dist3_unique 20.dist3_unique 21.dist3_unique 22.dist3_unique 23.dist3_unique 24.dist3_unique 25.dist3_unique) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'_6d, keep(26.dist3_unique 27.dist3_unique 28.dist3_unique 29.dist3_unique 30.dist3_unique 31.dist3_unique 32.dist3_unique 33.dist3_unique 34.dist3_unique 35.dist3_unique) 
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
		name(`r'_62, replace) ;
		
	graph combine `r'_62,
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name(`r'_62a, replace);
	
	graph save `r'_62a `suffix'_`str', replace;
	graph close `r'_62a;
	#delimit cr
}

* combine all
#delimit ;
graph combine rent_du_62 rent_duhe_62 rent_mfdu_62 rent_mf_62 rent_mfhe_62 rent_he_62,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	

//eststo clear
graph close _all


********************************************************************************
** end
********************************************************************************
log off 
log close

** convert gph to pdf
local files : dir "$RDPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$RDPATH/`fin'"
	
	graph export "$RDPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!"
