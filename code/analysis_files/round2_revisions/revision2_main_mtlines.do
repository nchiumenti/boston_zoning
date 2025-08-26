* start here
clear all
log close _all
set linesize 255

local name ="revision2_main_mtlines"  // <--- change when necessry

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
* File name:		main_mtlines.do
*
* Project title:	Boston Zoning Project
*
* Description:		Main regression specifications for the paper. Runs through
*					multiple models and specifications. Has been cut down to 
*					just include versions used in the paper.
*					
*					Part 1: Units >=1918
*						Units >=1918, baseline
*					Part 2: Units >=1956
* 						Units >=1956, baseline
* 						Units >=1956, w/ characteristics
*					Part 3: Units no year restriction
* 						Units no year restriction, baseline
*					Part 4: Sales prices
*						Sales prices, baseline
*						Sales prices, w/ characteristics
*					Part 5: Land prices
*						Land prices, baseline
*					Part 6: Rents
*						Rents, baseline
*						Rents, w/ characteristics
* 				
* Inputs:			mt_orthogonal_dist_100m_07-01-22_v2.dta
*					dist_south_station_2022_09_29.csv
*					transit_distance.csv
*					soil_quality_matches.dta
*					within_town_analysis_data.dta
*				
* Outputs:			log file w/ tables
*					coef_units_1918_base_du.gph (pdf)
*					coef_units_1918_base_duhe.gph (pdf)
*					coef_units_1918_base_he.gph (pdf)
*					coef_units_1918_base_mf.gph (pdf)
*					coef_units_1918_base_mfdu.gph (pdf)
*					coef_units_1918_base_mfhe.gph (pdf)
*
* Created:			06/23/2021
* Updated:			03/18/2025
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
** load and tempsave the soil data
********************************************************************************
use "$DATAPATH/soil_quality_matches.dta", clear

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


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
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'
	
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

keep if straight_line == 1  // <-- drops non-straight line properties


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** property characteristic variables
********************************************************************************
gen char1_lotsizeac1 = ln(lot_sizeac) if lot_sizeac != 0  // lot size in acres, excl zero acre --> NOW IN LOGS
gen char2_livingarea1 = ln(livingarea) / num_units1 if livingarea != 0  // living area in XX per unit, excl zero --> NOW IN LOGS
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0  // num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0  // num full bathrooms per unit, atleast 1

gen log_lotacres = ln(lot_acres) if lot_acres!=0
gen log_bldgarea =ln(grossbldg_area) if grossbldg_area!=0

global char_vars i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num


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

global char_vars_land dist_school dist_center dist_road dist_river dist_space transit_dist soil_avgslope soil_slope15 soil_avgrestri soil_avgsand soil_avgclay


********************************************************************************
** Part 1: Units >=1918
* Part 1a: units >=1918, baseline
* @Nick: need to put this on the same scale (-150 to 50)
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
	
* robust s.e.
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
		/*ylabel(, labsize(4) gmin gmax) ymtick()		Old, commenting out @nick*/
		yscale(range(-150 50)) ylabel(-150(50)50,labsize(4)) ymtick()
		
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
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
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
	
	graph save "final_graph" "$EXPORTPATH/`suffix'_all", replace;
#delimit cr	
}

eststo clear
graph close _all


********************************************************************************
** Part 1: Units >=1918
* Part 1a: units >=1918, baseline
* @Nick: need to put this on a reasonable same scale (up to you!)
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
	
* robust s.e.
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
		/*ylabel(, labsize(4) gmin gmax) ymtick()	old, commenting out @Nick*/
		yscale(range(-20 30)) ylabel(-20(10)30,labsize(4)) ymtick()

		
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
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
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
	
	graph save "final_graph" "$EXPORTPATH/`suffix'_all", replace;
#delimit cr	
}

eststo clear
graph close _all


********************************************************************************
** Calculate number of SF/HD/GD properties in estimation sample 
********************************************************************************

*@Nick, I don't think the r_dist_relax etc has been calcualted at this point, so added them here 
********************************************************************************
** Define distance polynomial trends
********************************************************************************
gen r_dist_relax = relaxed * dist_both
gen r_dist_strict = strict * dist_both

gen r_dist_relax2 = r_dist_relax ^ 2
gen r_dist_relax3 = r_dist_relax ^ 3
gen r_dist_relax4 = r_dist_relax ^ 4
gen r_dist_relax5 = r_dist_relax ^ 5

gen r_dist_strict2 = r_dist_strict ^ 2
gen r_dist_strict3 = r_dist_strict ^ 3
gen r_dist_strict4 = r_dist_strict ^ 4
gen r_dist_strict5 = r_dist_strict ^ 5


********************************************************************************
** Define distance polynomial trends varlist
********************************************************************************
local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist2 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"

********************************************************************************
** Part 6: SUPPLY EFFECT GENTLE DENSITY BASELINE
* 6a: gentle density baseline after 1918 @ .20 miles
********************************************************************************
** 6a: gentle density baseline after 1918 @ .20 miles
* loop over different degrees of distance polynomial trends
forvalues i = 1/3 {

	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
	
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"      
	sum dupac if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"     /*this is used in Table 3*/
	
	tab fam23_1 if e(sample), miss    /*missings are neither SF nor GD*/
	
	tab fam4plus_1 if e(sample), miss

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)
		
		eststo E
	
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	
	tab fam23_1 if e(sample), miss    /*missings are neither SF nor GD*/
	tab fam4plus_1 if e(sample), miss
	
	* combine results

		
esttab A E, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "mf_du" ) ///
		title("Part 6a: gentle density baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
		
		
	eststo clear 
}


********************************************************************************
** Part 7: SUPPLY EFFECT HIGH DENSITY BASELINE
* 7a: high density baseline after 1918 @ .20 miles
********************************************************************************
** 7a: high density baseline after 1918 @ .20 miles
*loop over different degrees of distance polynomial trends
forvalues i = 1/3{
	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
		
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	sum dupac if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		/*this is used in Table 3*/
	
	tab fam4plus_1 if e(sample), miss    /*missings are neither SF nor HD*/	
	tab fam23_1 if e(sample), miss
	
	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)
		
		eststo E
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	
	tab fam4plus_1 if e(sample), miss    /*missings are neither SF nor HD*/		
	tab fam23_1 if e(sample), miss
	
	* combine results
	esttab A  E , se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "mf_du") ///
		title("Part 7a: high density baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
	eststo clear
		
		
}





********************************************************************************
** end
********************************************************************************
log off 
log close
clear all

** convert gph to pdf
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 

