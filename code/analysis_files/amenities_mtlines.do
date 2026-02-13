* start here
clear all
log close _all
set linesize 255

local name ="amenities_mtlines"  // <--- change when necessry

* create an output directory if none exists
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
* File name:		amenities_mtlines.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		Primarily a robustness focused file that tests the model 
*					against various amenities indicators to check if there is 
*					any discontinuity across boundaries.
*
* Inputs:		    mt_orthogonal_dist_100m_07-01-22_v2.dta
*				    dist_south_station_2022_09_29.csv
*                   transit_distance.csv
*                   soil_quality_matches.dta
*                   warren_group_walkability.dta
*                   within_town_analysis_data.dta
*
* Outputs:		    Table 2, Figure C.1 (a-e), Table C.1 means
*
* Date Created:		06/23/2021
*
* Last Updated:		01/09/2026
********************************************************************************

* confirm that all input data files are present under $DATAPATH
confirm file "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_v2.dta"
confirm file "$DATAPATH/dist_south_station_2022_09_29.csv"
confirm file "$DATAPATH/transit_distance.csv"
confirm file "$DATAPATH/soil_quality_matches.dta"
confirm file "$DATAPATH/warren_group_walkability.dta"
confirm file "$DATAPATH/within_town_analysis_data.dta"


********************************************************************************
** load and tempsave the mt lines data
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
** load and tempsave the soil data //new variables added 19.05.2024
********************************************************************************
use "$DATAPATH/soil_quality_matches.dta", clear // bringing back the old soil data

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear


********************************************************************************
** merge on transit data
********************************************************************************
merge m:1 prop_id using `transit'
	
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
	
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'
	
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

	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* merge error check
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
** merge on walkscore variables 
********************************************************************************
merge m:1 prop_id using `walkscore', 
    sum _merge
    drop if _merge == 2
    drop _merge 


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


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


********************************************************************************
** distance to highway 
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.1 Subfigures (e) and (f); means for Table C.1
quietly eststo road_du: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo road_duhe: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_mfdu: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_mf: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_mfhe: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_he: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab road_du road_duhe road_mfdu road_mf road_mfhe road_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") title("Distance to Highway (miles)") 

* export coefs for closest strict-side bin
esttab road_du road_duhe road_mfdu road_mf road_mfhe road_he using "$EXPORTPATH/amenities_table_road.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") ///
	title("Distance to Highway (miles)")
	
** [PAPER SOURCE]: For Figure C.1, Subfigures (e) and (f)
* generate coefplots
local plot_list road_du road_he
local l1_title "Distance to Highway (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_road_all"

foreach r in `plot_list' {
	if "`r'" == "road_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "road_he" {
		local title "Only Height Changes"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
	
	
********************************************************************************
** distance to river
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.1 Subfigure (a); means for Table C.1
* run regressions
quietly eststo river_du: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_duhe: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_mfdu: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_mf: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_mfhe: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_he: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab river_du river_duhe river_mfdu river_mf river_mfhe river_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") title("Distance to River (miles)") 

* export coefs for closest strict-side bin
esttab river_du river_duhe river_mfdu river_mf river_mfhe river_he using "$EXPORTPATH/amenities_table_river.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") ///
	title("Distance to River (miles)") 
	
** [PAPER SOURCE]: For Figure C.1, Subfigure (a)
* generate coefplots
local plot_list river_mf 
local l1_title "Distance to River (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_river_all"

foreach r in `plot_list' {	
	if "`r'" == "river_mf" {
		local title "Only MF Allowed Changes"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all


********************************************************************************
** distance to green space
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.1 Subfigure (b); means for Table C.1
* run regressions
quietly eststo space_du: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo space_duhe: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_mfdu: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_mf: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_mfhe: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_he: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab space_du space_duhe space_mfdu space_mf space_mfhe space_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") title("Distance to Green Space (miles)") 
	
* export coefs for closest strict-side bin
esttab space_du space_duhe space_mfdu space_mf space_mfhe space_he using "$EXPORTPATH/amenities_table_space.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") ///
	title("Distance to Green Space (miles)") 

** [PAPER SOURCE]: For Figure C.1, Subfigure (b)	
* generate coefplots
local plot_list space_mfdu 
local l1_title "Distance to Green Space (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_space_all"

foreach r in `plot_list' {
	if "`r'" == "space_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all


********************************************************************************
* distance to school
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.1 Subfigure (c); means for Table C.1
* run regressions
quietly eststo school_du: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo school_duhe: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_mfdu: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_mf: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_mfhe: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_he: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab school_du school_duhe school_mfdu school_mf school_mfhe school_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") title("Distance to School (miles)") 

* export coefs for closest strict-side bin
esttab school_du school_duhe school_mfdu school_mf school_mfhe school_he using "$EXPORTPATH/amenities_table_school.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") ///
	title("Distance to School (miles)") 
	
** [PAPER SOURCE]: For Figure C.1, Subfigure (c)
* generate coefplots
local plot_list school_duhe 
local l1_title "Distance to School (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_school_all"

foreach r in `plot_list' {
	if "`r'" == "school_duhe" {
		local title "DUPAC and Height Change"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all


********************************************************************************
** distance to city center
********************************************************************************
** [PAPER SOURCE]:Regression results for Table 2, Figure C.1 Subfigure (d); means for Table C.1
* run regressions
quietly eststo center_du: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo center_duhe: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_mfdu: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_mf: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_mfhe: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_he: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab center_du center_duhe center_mfdu center_mf center_mfhe center_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") title("Distance to City Center (miles)") 

* export coefs for closest strict-side bin
esttab center_du center_duhe center_mfdu center_mf center_mfhe center_he using "$EXPORTPATH/amenities_table_center.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") ///
	title("Distance to City Center (miles)") 
	

** [PAPER SOURCE]: For Figure C.1, Subfigure (d)
* generate coefplots
local plot_list center_mfhe 
local l1_title "Distance to City Center (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_center_all"

foreach r in `plot_list' {	
	if "`r'" == "center_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all


********************************************************************************
** commuting distance to downtown distance (south station)
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.2 Subfigure (a); means for Table C.1
* run regressions
quietly eststo transit_du: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_duhe: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_mfdu: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_mf: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_mfhe: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_he: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") title("Public Transit Distance to Downtown Boston (miles)") 

* export coefs for closest strict-side bin
esttab transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he using "$EXPORTPATH/amenities_table_transit.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") ///
	title("Public Transit Distance to Downtown Boston (miles)") 

** [PAPER SOURCE]: For Figure C.2, Subfigure (a)	
* generate coefplots
local plot_list transit_du 
local l1_title "Public Transit Distance to Downtown Boston (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_transit_all"

foreach r in `plot_list' {
	if "`r'" == "transit_du" {
		local title "Only DUPAC Changes"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all


********************************************************************************
** Mean slope of lot
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.2 Subfigures (b) and (c); means for Table C.1
* run regressions
quietly eststo slope_du: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo slope_duhe: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_mfdu: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_mf: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_mfhe: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_he: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") title("Mean Slope of Lot (degrees)") 

* export coefs for closest strict-side bin
esttab slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he using "$EXPORTPATH/amenities_table_slope.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") ///
	title("Mean Slope of Lot (degrees)") 

** [PAPER SOURCE]: For Figure C.2, Subfigures (b) and (c)
* generate coefplots
local plot_list slope_du slope_mfdu
local l1_title "Mean Slope of Lot (degrees)"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_slope_all"

foreach r in `plot_list' {
	if "`r'" == "slope_du" {
		local title "Only DUPAC Changes"
	}

	if "`r'" == "slope_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
	

********************************************************************************
** percent of lot >15 degrees
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, means for Table C.1
* run regressions
quietly eststo slope15_du: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_duhe: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_mfdu: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_mf: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_mfhe: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_he: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") title("Percent of Lot with Slope >15 Degrees") 

* export coefs for closest strict-side bin	  
esttab slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he using "$EXPORTPATH/amenities_table_slope15.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") ///
	title("Percent of Lot with Slope >15 Degrees") 
	
********************************************************************************
** depth to restrictive layer
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.2 Subfigure (d); means for Table C.1
* run regressions
quietly eststo depth_du: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo depth_duhe: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_mfdu: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_mf: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_mfhe: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_he: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") title("Depth to Restrictive Layer (cm)") 

* export coefs for closest strict-side bin	  
esttab depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he using "$EXPORTPATH/amenities_table_depth.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") ///
	title("Depth to Restrictive Layer (cm)") 
	
** [PAPER SOURCE]: For Figure C.2, Subfigure (d)
* generate coefplots
local plot_list depth_mfdu 
local l1_title "Depth to Restrictive Layer (cm)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_depth_all"

foreach r in `plot_list' {
	if "`r'" == "depth_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
	

********************************************************************************
** mean percent sand
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.2 Subfigure (f); means for Table C.1
* run regressions
quietly eststo sand_du: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo sand_duhe: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_mfdu: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_mf: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_mfhe: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_he: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") title("Avg. Percent Sand") 
	
* export coefs for closest strict-side bin
esttab sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he using "$EXPORTPATH/amenities_table_sand.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") ///
	title("Avg. Percent Sand") 
	
** [PAPER SOURCE]: For Figure C.2, Subfigure (f)
* generate coefplots
local plot_list sand_duhe 
local l1_title "Avg. Percent Sand"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_sand_all"

foreach r in `plot_list' {	
	if "`r'" == "sand_duhe" {
		local title "DUPAC and Height Change"
	}
	
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
	

********************************************************************************
** mean percent clay
********************************************************************************
** [PAPER SOURCE]: Regression results for Table 2, Figure C.2 Subfigure (e); means for Table C.1
* run regressions
quietly eststo clay_du: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo clay_duhe: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_mfdu: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_mf: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_mfhe: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_he: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") title("Mean Percent Clay") 

* export coefs for closest strict-side bin	  
esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he using "$EXPORTPATH/amenities_table_clay.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") ///
	title("Mean Percent Clay") 
	
** [PAPER SOURCE]: For Figure C.2, Subfigure (e)
* generate coefplots
local plot_list clay_mf
local l1_title "Mean Percent Clay"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_clay_all"

foreach r in `plot_list' {	
	if "`r'" == "clay_mf" {
		local title "Only MF Allowed Changes"
	}
		
	* coefplots
	#delimit ;
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
		
		graph save "`r'a" "$EXPORTPATH/coef_`r'", replace;
	#delimit cr
}
	
* combine all graphs
#delimit ;
	graph combine `plot_list',
		rows(3) cols(2) ysize() xsize() iscale() imargin(0)
		graphregion(fc(white) lcolor(white))
		l1title("{bf:`l1_title'}", size(3) margin(t=0 b=0 l=0 r=1))
		b1title("`b1_title'", size(2))
		b2title("{bf:`b2_title'}", size(3) margin(t=1 b=0 l=0 r=0))
		name("graph_all", replace);
	graph save "graph_all" "$EXPORTPATH/`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all


********************************************************************************
*WALKABILITY VARIABLES
********************************************************************************
********************************************************************************
** National Walkability Index score
********************************************************************************
** [PAPER SOURCE]:Regression results for Table 2, means for Table C.1
* run regressions
quietly eststo walk_du: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo walk_duhe: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_mfdu: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_mf: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_mfhe: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_he: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab walk_du walk_duhe walk_mfdu walk_mf walk_mfhe walk_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") title("Walkability Index") 
	
* export coefs for closest strict-side bin 
esttab walk_du walk_duhe walk_mfdu walk_mf walk_mfhe walk_he using "$EXPORTPATH/amenities_table_walkability.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") ///
	title("Walkability Index") 
	

********************************************************************************
** Employment mix  (only tables)
********************************************************************************
** [PAPER SOURCE]:Regression results for Table 2, means for Table C.1
* run regressions
quietly eststo empl_du: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo empl_duhe: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_mfdu: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_mf: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_mfhe: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_he: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

* print entire regression table
esttab empl_du empl_duhe empl_mfdu empl_mf empl_mfhe empl_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") title("Employment mix") 
	
* export coefs for closest strict-side bin  
esttab empl_du empl_duhe empl_mfdu empl_mf empl_mfhe empl_he using "$EXPORTPATH/amenities_table_emplmix.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") ///
	title("Employment mix") 
	
log close
clear all


********************************************************************************
** convert all gph to pdfs
********************************************************************************
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 
