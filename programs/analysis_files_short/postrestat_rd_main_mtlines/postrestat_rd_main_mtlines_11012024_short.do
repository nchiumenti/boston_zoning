/// make an edit

clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREStat_rd_main_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postQJE_rd_main_mtlines"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		post QJE updated rd graphs / coefplots.
* 			striaght line boundaries (matt turner orthogona lines)
* 			for house prices, rents, units. regression output 
*			printed w/o characteristics (a) and w/ (b).
*
*			Contents:
*				Part 1: Units >=1918
*				Part 2: Units >=1956
*				Part 3: Units, no year restriction
*				Part 4(a-b): Sales prices
*				Part 5(a-b): Land prices
*				Part 6(a-b): Rents
* 				
* Inputs:		mt_orthogonal_dist_100m_07-01-22_v2.dta
*			final_dataset_10-28-2021.dta
*				
* Outputs:		lots of graphs
*			_base -> w/o char_vars
*			_char -> w/ char_vars
*			_both -> overlay w/o and w/ char_vars
*
* Created:		06/23/2021
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

/* Eli: commenting this out after running it once, to save time troubleshooting
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
//Eli: changing $SHAPEPATH to $DATAPATH
import delimited "$DATAPATH/train_stops/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/train_stops/transit_distance.csv", clear stringcols(_all)

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
** load and tempsave the soil data
********************************************************************************
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace

********************************************************************************
** load final dataset
********************************************************************************
use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
run "$DOPATH/postREStat_within_town_setup_05062024.do"

// Eli: added these sections in, copied from the amenities do file
********************************************************************************
** merge on transit data
********************************************************************************

merge m:1 prop_id using `transit'
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
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on soil quality data
********************************************************************************
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
	drop if _merge == 2
	drop _merge


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* checks for errors in merge
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
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year

// Eli: saving data here so I can troubleshoot more effectively.

save "$DATAPATH/Eli_data_April_2024_main_round2.dta"
eji
*/

use "$DATAPATH/Eli_data_April_2024_main_round2.dta", clear



********************************************************************************
** property characteristic variables
********************************************************************************
gen char1_lotsizeac1 = ln(lot_sizeac) if lot_sizeac != 0			// lot size in acres, excl zero acre --> NOW IN LOGS
gen char2_livingarea1 = ln(livingarea) / num_units1 if livingarea != 0		// living area in XX per unit, excl zero --> NOW IN LOGS
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0		// num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0		// num full bathrooms per unit, atleast 1

gen log_lotacres = ln(lot_acres) if lot_acres!=0
gen log_bldgarea =ln(grossbldg_area) if grossbldg_area!=0

global char_vars i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num


********************************************************************************
** gen amenity variables
********************************************************************************
*NC Check -- new for RESTAT RnR

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

********************************************************************************
** Part 1: Units >=1918
* Part 1a: units >=1918, baseline
********************************************************************************
** regressions
* set regression conditions
local regression_conditions year_built>=1918 & year==2018 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

* Part 1a: units >=1918, baseline
quietly eststo units_du: reg num_units1 ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_du == 1 & year_built>=1918 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_du == 1 & year_built>=1918 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	
quietly eststo units_duhe: reg num_units1 ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if du_he == 1 & year_built>=1918 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if du_he == 1 & year_built>=1918 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mfdu: reg num_units1 ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if mf_du == 1 & year_built>=1918 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if mf_du == 1 & year_built>=1918 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mf: reg num_units1 ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_mf == 1 & year_built>=1918 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_mf == 1 & year_built>=1918 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mfhe: reg num_units1 ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if mf_he == 1 & year_built>=1918 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if mf_he == 1 & year_built>=1918 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_he: reg num_units1 ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_he == 1 & year_built>=1918 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_he == 1 & year_built>=1918 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

esttab units_du units_duhe units_mfdu units_mf units_mfhe units_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units >=1918, baseline") 
	
*robust s.e.
quietly eststo units_du_robust: reg num_units1 ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(robust)
	
quietly eststo units_duhe_robust: reg num_units1 ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo units_mfdu_robust: reg num_units1 ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo units_mf_robust: reg num_units1 ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo units_mfhe_robust: reg num_units1 ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo units_he_robust: reg num_units1 ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(robust)

esttab units_du_robust units_duhe_robust units_mfdu_robust units_mf_robust units_mfhe_robust units_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units >=1918, baseline, robust s.e.")	
	

** coefplots
* coefplots, units >=1918 w/o characteristics
{
local plot_list units_du units_duhe units_mfdu units_mf units_mfhe units_he
local suffix "coef_units_1918_base"
local l1_title "Number of Units"
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
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

* combine all
#delimit ;
graph combine units_du units_duhe units_mfdu units_mf units_mfhe units_he,
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
** Part 2: Units >=1956
* Part 2a: units >=1956, baseline
* Part 2b: units >=1956, w/ characteristics
********************************************************************************
** regressions
* set regression conditions
local regression_conditions year_built>=1956 & year==2018 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

* Part 2a: units >=1956, baseline
quietly eststo units_du: reg num_units1 ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_du == 1 & year_built>=1956 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_du == 1 & year_built>=1956 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	
quietly eststo units_duhe: reg num_units1 ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if du_he == 1 & year_built>=1956 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if du_he == 1 & year_built>=1956 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mfdu: reg num_units1 ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if mf_du == 1 & year_built>=1956 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if mf_du == 1 & year_built>=1956 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mf: reg num_units1 ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_mf == 1 & year_built>=1956 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_mf == 1 & year_built>=1956 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mfhe: reg num_units1 ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if mf_he == 1 & year_built>=1956 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if mf_he == 1 & year_built>=1956 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_he: reg num_units1 ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_he == 1 & year_built>=1956 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_he == 1 & year_built>=1956 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

esttab units_du units_duhe units_mfdu units_mf units_mfhe units_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units >=1956, baseline") 
	
*robust s.e.
quietly eststo units_du_robust: reg num_units1 ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(robust)
	
quietly eststo units_duhe_robust: reg num_units1 ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo units_mfdu_robust: reg num_units1 ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo units_mf_robust: reg num_units1 ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo units_mfhe_robust: reg num_units1 ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo units_he_robust: reg num_units1 ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(robust)

esttab units_du_robust units_duhe_robust units_mfdu_robust units_mf_robust units_mfhe_robust units_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units >=1956, baseline, robust s.e.") 
	
	

** coefplots
* coefplots, units >=1956 w/o characteristics
{
local plot_list units_du units_duhe units_mfdu units_mf units_mfhe units_he
local suffix "coef_units_1956_base"
local l1_title "Number of Units"
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
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

* combine all
#delimit ;
graph combine units_du units_duhe units_mfdu units_mf units_mfhe units_he,
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
** Part 3: Units no year restriction
* Part 3a: units no year restriction, baseline
********************************************************************************
** regressions
* set regression conditions
local regression_conditions year==2018 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"

* Part 3a: units no year restriction, baseline
quietly eststo units_du: reg num_units1 ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	
quietly eststo units_duhe: reg num_units1 ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mfdu: reg num_units1 ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mf: reg num_units1 ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_mfhe: reg num_units1 ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

quietly eststo units_he: reg num_units1 ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum num_units1 if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
sum num_units1 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

esttab units_du units_duhe units_mfdu units_mf units_mfhe units_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units, baseline") 
	
* export table version 	
esttab units_du units_duhe units_mfdu units_mf units_mfhe units_he using "$RDPATH/units_noyear_table.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units, baseline") 		
	
*robust s.e.
quietly eststo units_du_robust: reg num_units1 ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(robust)
	
quietly eststo units_duhe_robust: reg num_units1 ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo units_mfdu_robust: reg num_units1 ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo units_mf_robust: reg num_units1 ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo units_mfhe_robust: reg num_units1 ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo units_he_robust: reg num_units1 ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(robust)

esttab units_du_robust units_duhe_robust units_mfdu_robust units_mf_robust units_mfhe_robust units_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg") interaction(" X ") ///
	label mtitles("units_du" "units_duhe" "units_mfdu" "units_mf" "units_mfhe" "units_he") ///
	title("Units, baseline, robust s.e.") 
		

** coefplots
* coefplots, units no year restriction w/o characteristics
{
local plot_list units_du units_duhe units_mfdu units_mf units_mfhe units_he
local suffix "coef_units_noyear_base"
local l1_title "Number of Units"
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
		name("`r'", replace) ;
		
	graph combine `r',
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("`r'a", replace);
	
	graph save "`r'a" "`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

* combine all
#delimit ;
graph combine units_du units_duhe units_mfdu units_mf units_mfhe units_he,
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
** Part 4: Sales prices
* Part 4a: Sales prices, baseline
* Part 4b: Sales prices, w/ characteristics
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* Part 3a: Sales price w/o characteristics
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_mfhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

quietly eststo price_he: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0

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

esttab price_du_robust price_duhe_robust price_mfdu_robust price_mf_robust price_mfhe_robust price_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline, robust s.e.") 
	
	
* Part 3b: Sales price w/ characteristis
quietly eststo price_du2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_he2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr" "Year Built f.e.=*year_built") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices w/ characteristics") 

*robust s.e.
quietly eststo price_du2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo price_mf2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo price_mfhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo price_he2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions', vce(robust)
	
esttab price_du2_robust price_duhe2_robust price_mfdu2_robust price_mf2_robust price_mfhe2_robust price_he2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr" "Year Built f.e.=*year_built") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices w/ characteristics, robust s.e.") 
	
	
** coefplots
* coefplots, sales prices w/o characteristics
{
local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_base"
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


* coefplots, sales prices w/ characteristics
{
local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_char"
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
		/* relaxed side graphing variables */
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) lpattern(dash)
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30) lpattern(dash)
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
		name(`r'2, replace) ;
		
	graph combine `r'2,
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
graph combine price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
}


* coefplots, sales prices both
{
local plot_list price_du price_duhe price_mfdu price_mf price_mfhe price_he
local suffix "coef_price_both"
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
graph combine price_du3 price_duhe3 price_mfdu3 price_mf3 price_mfhe3 price_he3,
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
** Part 5: Land prices
* Part 5a: Land prices, baseline
********************************************************************************
** regressions

gen log_land = log(assd_landval)

*per squarefoot price of land 
gen land_per_sqft = assd_landval/lot_sizesqft
gen log_land_per_sqft = log(land_per_sqft)

* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & assd_landval !=0

* Part 5a: Land value w/o characteristics
quietly eststo land_du: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0
sum land_per_sqft if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0
	
quietly eststo land_duhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0
sum land_per_sqft if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0

quietly eststo land_mfdu: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0
sum land_per_sqft if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0

quietly eststo land_mf: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
sum land_per_sqft if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0
sum land_per_sqft if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0

quietly eststo land_mfhe: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum land_per_sqft if mf_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0
sum land_per_sqft if mf_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0

quietly eststo land_he: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum land_per_sqft if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & assd_landval !=0
sum land_per_sqft if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & assd_landval !=0
	
esttab land_du land_duhe land_mfdu land_mf land_mfhe land_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_mfhe" "land_he") ///
	title("Land price per squarefoot baseline") 
	
* export table version 	
esttab land_du land_duhe land_mfdu land_mf land_mfhe land_he using "$RDPATH/land_price_table.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_mfhe" "land_he") ///
	title("Assessed Land Value Per Squarefoot")	
	
*robust s.e.
quietly eststo land_du_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo land_duhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo land_mfdu_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if  mf_du == 1 & `regression_conditions', vce(robust)

quietly eststo land_mf_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if only_mf== 1 & `regression_conditions', vce(robust)

quietly eststo land_mfhe_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if mf_he == 1 & `regression_conditions', vce(robust)

quietly eststo land_he_robust: reg log_land_per_sqft ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	//Eli: replaced price_he_robust with land_he_robust
esttab land_du_robust land_duhe_robust land_mfdu_robust land_mf_robust land_mfhe_robust land_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("land_du" "land_duhe" "land_mfdu" "land_mf" "land_mfhe" "land_he") ///
	title("Land Price baseline, robust s.e.") 	
	
** coefplots
* coefplots, sales prices w/o characteristics
{
local plot_list land_du land_duhe land_mfdu land_mf land_mfhe land_he
local suffix "coef_land_base"
local l1_title "Log Land Price Per Squarefoot"
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
graph combine land_du land_duhe land_mfdu land_mf land_mfhe land_he,
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
** Part 6: Rents
* Part 6a: Rents, baseline
* Part 6b: Rents, w/ characteristics
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 5a: Rents w/o characteristics
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
*robust s.e.
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du_robust rent_duhe_robust rent_he_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline, robust s.e.") 
	
	
* Part 5b: Rents w/ characteristics
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he2: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du2 rent_duhe2 rent_he2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, w/ characteristics") 
	
*robust s.e.
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions', vce(robust)
	
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions', vce(robust)

quietly eststo rent_he2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $char_vars if only_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du2_robust rent_duhe2_robust rent_he2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, w/ characteristics, robust s.e.") 
	
	
** coefplots
* coefplots, Rents w/o characteristics
{
local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_base"
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
graph combine rent_du rent_duhe rent_he,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
}

* coefplots, Rents w/ characteristics
{
local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_char"
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
	
	if "`str'" == "he" {
		local title "Only Height Changes"
	}
	
	* coefplots
	#delimit;
	coefplot 
		/* relaxed side graphing variables */
		(`r'2, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) lpattern(dash)
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'2, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(gs5%30) lpattern(dash)
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
		name(`r'2, replace) ;
		
	graph combine `r'2,
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
graph combine rent_du2 rent_duhe2 rent_he2,
	rows(3) cols(2) ysize() xsize() iscale() imargin(0)
	graphregion(fc(white) lcolor(white))
	l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
	b1title("`b1_title'", size(2))
	b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
	name("final_graph", replace);
	
	graph save "final_graph" "`suffix'_all", replace;
#delimit cr	
}

* coefplots, Rents both
{
local plot_list rent_du rent_duhe rent_he
local suffix "coef_rent_both"
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
}

eststo clear
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

