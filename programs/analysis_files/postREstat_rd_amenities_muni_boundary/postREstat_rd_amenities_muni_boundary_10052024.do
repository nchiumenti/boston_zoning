clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREstat_rd_amenities_muni_boundary" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postREstat_rd_amenities_muni_boundary.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Post QJE updates
*			technically these are coefplots
* 			striaght line boundaries (matt turner orthogona lines)
* 			Ammenities only:
*				- dist to school
*				- dist to city center
*				- dist to major road
*				- dist to major river
*				- dist to green space
*				- soil quality (x5)
*				- transit dist nearest stop (manhattan)
*				  and downtown (public transit)
*				- walk score (tables only)
*
*           Note on 5-29-2024: This version of the file uses the warren group to
*           town boundary matches and their regulations. It also includes the expanded
*           soild data. This version DOES NOT use the mt_lines file becasue it is not
*			relevant for this analysis
*
* Inputs:		
*				
* Outputs:		
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


********************************************************************************
** load and tempsave the transit data
********************************************************************************
import delimited "$DATAPATH/train_stops/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/train_stops/transit_distance.csv", clear stringcols(_all)

merge m:1 station_id using `dist_south_station'
		
		* merge error check
		sum _merge
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
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear // bringing back the old soil data

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


********************************************************************************
** load final dataset
********************************************************************************
use "$DATAPATH/warren/final_dataset_town_comparisons.dta", clear // Note on 5/29/2024 to HB/EI - set the file path to the town boundary matched data here


********************************************************************************
** run postQJE within town setup file
********************************************************************************
run "$DOPATH/postREStat_within_town_setup_HB.do"


********************************************************************************
** merge on transit data
********************************************************************************
merge m:1 prop_id using `transit'

	* merge error check
	sum _merge	
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'

	* merge error check
	sum _merge
	drop if _merge == 2
	drop _merge 

	
********************************************************************************
** merge on walkscore variables 
********************************************************************************
merge m:1 prop_id using `walkscore', 

	* merge error check
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


save("$DATAPATH/final_dataset_town_comparisons_postsetup_20240930.dta"), replace

stop


********************************************************************************
** distance to highway 
********************************************************************************
capture noisily {
** regressions
quietly eststo road_du: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo road_duhe: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_mfdu: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_mf: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_mfhe: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo road_he: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab road_du road_duhe road_mfdu road_mf road_mfhe road_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") title("Distance to Highway (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab road_du road_duhe road_mfdu road_mf road_mfhe road_he using "$RDPATH/amenities_table_road.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") ///
	title("Distance to Highway (miles)") 
	
*robust s.e.
quietly eststo road_du_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo road_duhe_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo road_mfdu_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo road_mf_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo road_mfhe_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo road_he_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab road_du_robust road_duhe_robust road_mfdu_robust road_mf_robust road_mfhe_robust road_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") title("Distance to Highway (miles), robust s.e.") 
	

** coefplots
local plot_list road_du road_duhe road_mfdu road_mf road_mfhe road_he
local l1_title "Distance to Highway (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_road_all"

foreach r in `plot_list'{
	if "`r'" == "road_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "road_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "road_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "road_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "road_mfhe" {
		local title "MF Allowed and Height Change"
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	
	
********************************************************************************
** distance to river
********************************************************************************
capture noisily {

** regressions
quietly eststo river_du: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_duhe: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_mfdu: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_mf: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_mfhe: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo river_he: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab river_du river_duhe river_mfdu river_mf river_mfhe river_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") title("Distance to River (miles)") 

/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab river_du river_duhe river_mfdu river_mf river_mfhe river_he using "$RDPATH/amenities_table_river.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") ///
	title("Distance to River (miles)") 
	
*robust s.e.
quietly eststo river_du_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo river_duhe_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo river_mfdu_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo river_mf_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo river_mfhe_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo river_he_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab river_du_robust river_duhe_robust river_mfdu_robust river_mf_robust river_mfhe_robust river_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") title("Distance to River (miles), robust s.e.") 
	
	
** coefplots
local plot_list river_du river_duhe river_mfdu river_mf river_mfhe river_he
local l1_title "Distance to River (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_river_all"

foreach r in `plot_list'{
	if "`r'" == "river_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "river_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "river_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "river_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "river_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "river_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** distance to green space
********************************************************************************
capture noisily {
** regressions
quietly eststo space_du: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo space_duhe: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_mfdu: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_mf: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_mfhe: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo space_he: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab space_du space_duhe space_mfdu space_mf space_mfhe space_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") title("Distance to Green Space (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab space_du space_duhe space_mfdu space_mf space_mfhe space_he using "$RDPATH/amenities_table_space.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") ///
	title("Distance to Green Space (miles)") 
	
*robust s.e.
quietly eststo space_du_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo space_duhe_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo space_mfdu_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo space_mf_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo space_mfhe_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo space_he_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab space_du_robust space_duhe_robust space_mfdu_robust space_mf_robust space_mfhe_robust space_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") title("Distance to Green Space (miles), robust s.e.") 
	

** coefplots
local plot_list space_du space_duhe space_mfdu space_mf space_mfhe space_he
local l1_title "Distance to Green Space (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_space_all"

foreach r in `plot_list'{
	if "`r'" == "space_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "space_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "space_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "space_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "space_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "space_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
* distance to school
********************************************************************************
capture noisily {
** regressions
quietly eststo school_du: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo school_duhe: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_mfdu: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_mf: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_mfhe: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo school_he: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab school_du school_duhe school_mfdu school_mf school_mfhe school_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") title("Distance to School (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab school_du school_duhe school_mfdu school_mf school_mfhe school_he using "$RDPATH/amenities_table_school.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") ///
	title("Distance to School (miles)") 
	
*robust s.e.
quietly eststo school_du_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo school_duhe_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo school_mfdu_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo school_mf_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo school_mfhe_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo school_he_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab school_du_robust school_duhe_robust school_mfdu_robust school_mf_robust school_mfhe_robust school_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") title("Distance to School (miles), robust s.e.") 
	

** coefplots
local plot_list school_du school_duhe school_mfdu school_mf school_mfhe school_he
local l1_title "Distance to School (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_school_all"

foreach r in `plot_list'{
	if "`r'" == "school_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "school_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "school_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "school_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "school_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "school_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** distance to city center
********************************************************************************
capture noisily {
** regressions
quietly eststo center_du: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo center_duhe: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_mfdu: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_mf: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_mfhe: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo center_he: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab center_du center_duhe center_mfdu center_mf center_mfhe center_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") title("Distance to City Center (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab center_du center_duhe center_mfdu center_mf center_mfhe center_he using "$RDPATH/amenities_table_center.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") ///
	title("Distance to City Center (miles)") 
	
*robust s.e.
quietly eststo center_du_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo center_duhe_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo center_mfdu_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo center_mf_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo center_mfhe_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo center_he_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab center_du_robust center_duhe_robust center_mfdu_robust center_mf_robust center_mfhe_robust center_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") title("Distance to City Center (miles), robust s.e.") 
	

** coefplots
local plot_list center_du center_duhe center_mfdu center_mf center_mfhe center_he
local l1_title "Distance to City Center (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_center_all"

foreach r in `plot_list'{
	if "`r'" == "center_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "center_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "center_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "center_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "center_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "center_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** commuting distance to downtown distance (south station)
********************************************************************************
capture noisily {
** regressions
quietly eststo transit_du: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_duhe: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_mfdu: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_mf: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_mfhe: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo transit_he: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") title("Public Transit Distance to Downtown Boston (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he using "$RDPATH/amenities_table_transit.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") ///
	title("Public Transit Distance to Downtown Boston (miles)") 
	
*robust s.e.
quietly eststo transit_du_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo transit_duhe_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo transit_mfdu_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo transit_mf_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo transit_mfhe_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo transit_he_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab transit_du_robust transit_duhe_robust transit_mfdu_robust transit_mf_robust transit_mfhe_robust transit_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") title("Public Transit Distance to Downtown Boston (miles), robust s.e.") 
	
	

** coefplots
local plot_list transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he
local l1_title "Public Transit Distance to Downtown Boston (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_transit_all"

foreach r in `plot_list'{
	if "`r'" == "transit_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "transit_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "transit_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "transit_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "transit_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "transit_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** Mean slope of lot
********************************************************************************
capture noisily {
** regressions
quietly eststo slope_du: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo slope_duhe: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_mfdu: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_mf: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_mfhe: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope_he: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") title("Mean Slope of Lot (degrees)") 

/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he using "$RDPATH/amenities_table_slope.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") ///
	title("Mean Slope of Lot (degrees)") 

*robust s.e.
quietly eststo slope_du_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo slope_duhe_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope_mfdu_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope_mf_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope_mfhe_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope_he_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab slope_du_robust slope_duhe_robust slope_mfdu_robust slope_mf_robust slope_mfhe_robust slope_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") title("Mean Slope of Lot (degrees), robust s.e.") 
	
	
** coefplots
local plot_list slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he
local l1_title "Mean Slope of Lot (degrees)"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_slope_all"

foreach r in `plot_list'{
	if "`r'" == "slope_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "slope_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "slope_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "slope_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "slope_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "slope_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	

********************************************************************************
** percent of lot >15 degrees
********************************************************************************
capture noisily {
** regressions
quietly eststo slope15_du: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_duhe: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_mfdu: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_mf: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_mfhe: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo slope15_he: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") title("Percent of Lot with Slope >15 Degrees") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he using "$RDPATH/amenities_table_slope15.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") ///
	title("Percent of Lot with Slope >15 Degrees") 
	
*robust s.e.
quietly eststo slope15_du_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope15_duhe_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope15_mfdu_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope15_mf_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope15_mfhe_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo slope15_he_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab slope15_du_robust slope15_duhe_robust slope15_mfdu_robust slope15_mf_robust slope15_mfhe_robust slope15_he_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") title("Percent of Lot with Slope >15 Degrees, robust s.e.") 
	
	
** coefplots
local plot_list slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he
local l1_title "Percent of Lot with Slope >15 Degrees"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_slope15_all"

foreach r in `plot_list'{
	if "`r'" == "slope15_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "slope15_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "slope15_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "slope15_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "slope15_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "slope15_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** depth to restrictive layer
********************************************************************************
capture noisily {
** regressions
quietly eststo depth_du: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo depth_duhe: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_mfdu: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_mf: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_mfhe: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo depth_he: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") title("Depth to Restrictive Layer (cm)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he using "$RDPATH/amenities_table_depth.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") ///
	title("Depth to Restrictive Layer (cm)") 
	
*robust s.e.
quietly eststo depth_du_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo depth_duhe_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo depth_mfdu_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo depth_mf_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo depth_mfhe_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo depth_he_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab depth_du_r depth_duhe_r depth_mfdu_r depth_mf_r depth_mfhe_r depth_he_r, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") title("Depth to Restrictive Layer (cm), robust s.e.") 
	

** coefplots
local plot_list depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he
local l1_title "Depth to Restrictive Layer (cm)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_depth_all"

foreach r in `plot_list'{
	if "`r'" == "depth_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "depth_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "depth_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "depth_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "depth_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "depth_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	

********************************************************************************
** mean percent sand
********************************************************************************
capture noisily {
** regressions
quietly eststo sand_du: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo sand_duhe: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_mfdu: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_mf: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_mfhe: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo sand_he: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") title("Avg. Percent Sand") 
	
*REStat Revision - allow for table - NC check
*keeping only the first coefficient on the more restrictive side of the boundary, check if correct bin kept
esttab sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he using "$RDPATH/amenities_table_sand.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") ///
	title("Avg. Percent Sand") 
	
*robust s.e.
quietly eststo sand_du_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo sand_duhe_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo sand_mfdu_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo sand_mf_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo sand_mfhe_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo sand_he_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab sand_du_r sand_duhe_r sand_mfdu_r sand_mf_r sand_mfhe_r sand_he_r, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") title("Avg. Percent Sand, robust s.e.") 
	
	
** coefplots
local plot_list sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he
local l1_title "Avg. Percent Sand"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_sand_all"

foreach r in `plot_list'{
	if "`r'" == "sand_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "sand_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "sand_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "sand_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "sand_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "sand_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	

********************************************************************************
** mean percent clay
********************************************************************************
capture noisily {
** regressions
quietly eststo clay_du: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo clay_duhe: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_mfdu: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_mf: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_mfhe: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo clay_he: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") title("Mean Percent Clay") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he using "$RDPATH/amenities_table_clay.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") ///
	title("Mean Percent Clay") 
	
*robust s.e.
quietly eststo clay_du_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo clay_duhe_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo clay_mfdu_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo clay_mf_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo clay_mfhe_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo clay_he_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab clay_du_r clay_duhe_r clay_mfdu_r clay_mf_r clay_mfhe_r clay_he_r, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") title("Mean Percent Clay, robust s.e.") 
	
	

** coefplots
local plot_list clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he
local l1_title "Mean Percent Clay"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_clay_all"

foreach r in `plot_list'{
	if "`r'" == "clay_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "clay_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "clay_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "clay_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "clay_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "clay_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}



********************************************************************************
*WALKABILITY VARIABLES
********************************************************************************
********************************************************************************
** National Walkability Index score
********************************************************************************
capture noisily {
** regressions
quietly eststo walk_du: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo walk_duhe: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_mfdu: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_mf: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_mfhe: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo walk_he: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab walk_du walk_duhe walk_mfdu walk_mf walk_mfhe walk_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") title("Walkability Index") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he using "$RDPATH/amenities_table_walkability.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") ///
	title("Walkability Index") 
	
*robust s.e.
quietly eststo walk_du_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo walk_duhe_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo walk_mfdu_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo walk_mf_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo walk_mfhe_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo walk_he_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab walk_du_r walk_duhe_r walk_mfdu_r walk_mf_r walk_mfhe_r walk_he_r, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") title("Walkability Index, robust s.e.") 
	
	

** coefplots
local plot_list walk_du walk_duhe walk_mfdu walk_mf walk_mfhe walk_he
local l1_title "Walkability Index"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_walk_all"

foreach r in `plot_list'{
	if "`r'" == "walk_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "walk_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "walk_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "walk_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "walk_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "walk_he" {
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
		
		graph save "`r'a" "coef_muni_`r'", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** Employment mix  (only tables)
********************************************************************************
capture noisily {
** regressions
quietly eststo empl_du: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo empl_duhe: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_mfdu: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_mf: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_mfhe: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo empl_he: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab empl_du empl_duhe empl_mfdu empl_mf empl_mfhe empl_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") title("Employment mix") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab empl_du empl_duhe empl_mfdu empl_mf empl_mfhe empl_he using "$RDPATH/amenities_table_emplmix.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") ///
	title("Employment mix") 
	
*robust s.e.
quietly eststo empl_du_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo empl_duhe_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo empl_mfdu_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo empl_mf_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo empl_mfhe_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo empl_he_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab empl_du_r empl_duhe_r empl_mfdu_r empl_mf_r empl_mfhe_r empl_he_r, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") title("Employment mix, robust s.e.") 
}


********************************************************************************
** Employment mix rank (only tables)
********************************************************************************
capture noisily {
** regressions
quietly eststo emplrank_du: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_ranked if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_ranked if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"
	
quietly eststo emplrank_duhe: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_ranked if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_ranked if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo emplrank_mfdu: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_ranked if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_ranked if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo emplrank_mf: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_ranked if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_ranked if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo emplrank_mfhe: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_ranked if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_ranked if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

quietly eststo emplrank_he: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_ranked if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_ranked if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab emplrank_du emplrank_duhe emplrank_mfdu emplrank_mf emplrank_mfhe emplrank_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("emplrank_du" "emplrank_duhe" "emplrank_mfdu" "emplrank_mf" "emplrank_mfhe" "emplrank_he") title("Employment mix rank") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab emplrank_du emplrank_duhe emplrank_mfdu emplrank_mf emplrank_mfhe emplrank_he using "$RDPATH/amenities_table_emplrank.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("emplrank_du" "emplrank_duhe" "emplrank_mfdu" "emplrank_mf" "emplrank_mfhe" "emplrank_he") ///
	title("Employment mix rank") 
	
*robust s.e.
quietly eststo emplrank_du_r: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(robust)
	
quietly eststo emplrank_duhe_r: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo emplrank_mfdu_r: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo emplrank_mf_r: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo emplrank_mfhe_r: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(robust)

quietly eststo emplrank_he_r: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(robust)

esttab emplrank_du_r emplrank_duhe_r emplrank_mfdu_r emplrank_mf_r emplrank_mfhe_r emplrank_he_r, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("emplrank_du" "emplrank_duhe" "emplrank_mfdu" "emplrank_mf" "emplrank_mfhe" "emplrank_he") title("Employment mix rank, robust s.e.") 
}




********************************************************************************
*Standard errors clustered by municipality
********************************************************************************
********************************************************************************
** distance to highway 
********************************************************************************
capture noisily {
** regressions
quietly eststo road_du: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo road_duhe: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo road_mfdu: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo road_mf: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo road_mfhe: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo road_he: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab road_du road_duhe road_mfdu road_mf road_mfhe road_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") title("Distance to Highway (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab road_du road_duhe road_mfdu road_mf road_mfhe road_he using "$RDPATH/amenities_table_road_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_du" "road_duhe" "road_mfdu" "road_mf" "road_mfhe" "road_he") ///
	title("Distance to Highway (miles)") 
	

** coefplots
local plot_list road_du road_duhe road_mfdu road_mf road_mfhe road_he
local l1_title "Distance to Highway (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_road_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "road_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "road_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "road_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "road_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "road_mfhe" {
		local title "MF Allowed and Height Change"
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	
	
********************************************************************************
** distance to river
********************************************************************************
capture noisily {

** regressions
quietly eststo river_du: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo river_duhe: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo river_mfdu: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo river_mf: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo river_mfhe: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo river_he: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab river_du river_duhe river_mfdu river_mf river_mfhe river_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") title("Distance to River (miles)") 

/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */

esttab river_du river_duhe river_mfdu river_mf river_mfhe river_he using "$RDPATH/amenities_table_river_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_du" "river_duhe" "river_mfdu" "river_mf" "river_mfhe" "river_he") ///
	title("Distance to River (miles)") 
		
	
** coefplots
local plot_list river_du river_duhe river_mfdu river_mf river_mfhe river_he
local l1_title "Distance to River (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_river_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "river_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "river_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "river_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "river_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "river_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "river_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** distance to green space
********************************************************************************
capture noisily {
** regressions
quietly eststo space_du: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo space_duhe: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo space_mfdu: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo space_mf: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo space_mfhe: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo space_he: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab space_du space_duhe space_mfdu space_mf space_mfhe space_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") title("Distance to Green Space (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab space_du space_duhe space_mfdu space_mf space_mfhe space_he using "$RDPATH/amenities_table_space_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_du" "space_duhe" "space_mfdu" "space_mf" "space_mfhe" "space_he") ///
	title("Distance to Green Space (miles)") 
		

** coefplots
local plot_list space_du space_duhe space_mfdu space_mf space_mfhe space_he
local l1_title "Distance to Green Space (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_space_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "space_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "space_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "space_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "space_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "space_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "space_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
* distance to school
********************************************************************************
capture noisily {
** regressions
quietly eststo school_du: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo school_duhe: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo school_mfdu: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo school_mf: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo school_mfhe: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo school_he: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab school_du school_duhe school_mfdu school_mf school_mfhe school_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") title("Distance to School (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab school_du school_duhe school_mfdu school_mf school_mfhe school_he using "$RDPATH/amenities_table_school_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_du" "school_duhe" "school_mfdu" "school_mf" "school_mfhe" "school_he") ///
	title("Distance to School (miles)") 
		

** coefplots
local plot_list school_du school_duhe school_mfdu school_mf school_mfhe school_he
local l1_title "Distance to School (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_school_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "school_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "school_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "school_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "school_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "school_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "school_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** distance to city center
********************************************************************************
capture noisily {
** regressions
quietly eststo center_du: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo center_duhe: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo center_mfdu: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo center_mf: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo center_mfhe: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo center_he: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab center_du center_duhe center_mfdu center_mf center_mfhe center_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") title("Distance to City Center (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab center_du center_duhe center_mfdu center_mf center_mfhe center_he using "$RDPATH/amenities_table_center_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") ///
	title("Distance to City Center (miles)") 
		

** coefplots
local plot_list center_du center_duhe center_mfdu center_mf center_mfhe center_he
local l1_title "Distance to City Center (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_center_all"

foreach r in `plot_list'{
	if "`r'" == "center_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "center_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "center_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "center_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "center_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "center_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** commuting distance to downtown distance (south station)
********************************************************************************
capture noisily {
** regressions
quietly eststo transit_du: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo transit_duhe: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo transit_mfdu: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo transit_mf: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo transit_mfhe: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo transit_he: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") title("Public Transit Distance to Downtown Boston (miles)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he using "$RDPATH/amenities_table_transit_municluster.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_du" "transit_duhe" "transit_mfdu" "transit_mf" "transit_mfhe" "transit_he") ///
	title("Public Transit Distance to Downtown Boston (miles)") 
		

** coefplots
local plot_list transit_du transit_duhe transit_mfdu transit_mf transit_mfhe transit_he
local l1_title "Public Transit Distance to Downtown Boston (miles)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_transit_all"

foreach r in `plot_list'{
	if "`r'" == "transit_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "transit_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "transit_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "transit_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "transit_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "transit_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** Mean slope of lot
********************************************************************************
capture noisily {
** regressions
quietly eststo slope_du: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo slope_duhe: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope_mfdu: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope_mf: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope_mfhe: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope_he: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") title("Mean Slope of Lot (degrees)") 

/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he using "$RDPATH/amenities_table_slope_municluster.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_du" "slope_duhe" "slope_mfdu" "slope_mf" "slope_mfhe" "slope_he") ///
	title("Mean Slope of Lot (degrees)") 
	
	
** coefplots
local plot_list slope_du slope_duhe slope_mfdu slope_mf slope_mfhe slope_he
local l1_title "Mean Slope of Lot (degrees)"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_slope_all"

foreach r in `plot_list'{
	if "`r'" == "slope_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "slope_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "slope_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "slope_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "slope_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "slope_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	

********************************************************************************
** percent of lot >15 degrees
********************************************************************************
capture noisily {
** regressions
quietly eststo slope15_du: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope15_duhe: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope15_mfdu: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope15_mf: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope15_mfhe: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo slope15_he: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") title("Percent of Lot with Slope >15 Degrees") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he using "$RDPATH/amenities_table_slope15_municluster.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_du" "slope15_duhe" "slope15_mfdu" "slope15_mf" "slope15_mfhe" "slope15_he") ///
	title("Percent of Lot with Slope >15 Degrees") 
		
	
** coefplots
local plot_list slope15_du slope15_duhe slope15_mfdu slope15_mf slope15_mfhe slope15_he
local l1_title "Percent of Lot with Slope >15 Degrees"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_slope15_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "slope15_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "slope15_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "slope15_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "slope15_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "slope15_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "slope15_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** depth to restrictive layer
********************************************************************************
capture noisily {
** regressions
quietly eststo depth_du: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo depth_duhe: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo depth_mfdu: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo depth_mf: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo depth_mfhe: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo depth_he: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") title("Depth to Restrictive Layer (cm)") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he using "$RDPATH/amenities_table_depth.tex", replace keep(25.dist3) ///
se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_du" "depth_duhe" "depth_mfdu" "depth_mf" "depth_mfhe" "depth_he") ///
	title("Depth to Restrictive Layer (cm)") 
	

** coefplots
local plot_list depth_du depth_duhe depth_mfdu depth_mf depth_mfhe depth_he
local l1_title "Depth to Restrictive Layer (cm)"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_depth_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "depth_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "depth_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "depth_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "depth_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "depth_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "depth_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	

********************************************************************************
** mean percent sand
********************************************************************************
capture noisily {
** regressions
quietly eststo sand_du: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo sand_duhe: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo sand_mfdu: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo sand_mf: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo sand_mfhe: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo sand_he: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") title("Avg. Percent Sand") 
	
*REStat Revision - allow for table - NC check
*keeping only the first coefficient on the more restrictive side of the boundary, check if correct bin kept
esttab sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he using "$RDPATH/amenities_table_sand_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("sand_du" "sand_duhe" "sand_mfdu" "sand_mf" "sand_mfhe" "sand_he") ///
	title("Avg. Percent Sand") 
	
	
** coefplots
local plot_list sand_du sand_duhe sand_mfdu sand_mf sand_mfhe sand_he
local l1_title "Avg. Percent Sand"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_sand_all"

foreach r in `plot_list'{
	if "`r'" == "sand_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "sand_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "sand_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "sand_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "sand_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "sand_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}
	

********************************************************************************
** mean percent clay
********************************************************************************
capture noisily {
** regressions
quietly eststo clay_du: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo clay_duhe: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo clay_mfdu: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo clay_mf: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo clay_mfhe: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo clay_he: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") title("Mean Percent Clay") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he using "$RDPATH/amenities_table_clay_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_du" "clay_duhe" "clay_mfdu" "clay_mf" "clay_mfhe" "clay_he") ///
	title("Mean Percent Clay") 
		
	

** coefplots
local plot_list clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he
local l1_title "Mean Percent Clay"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_clay_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "clay_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "clay_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "clay_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "clay_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "clay_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "clay_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}



********************************************************************************
*WALKABILITY VARIABLES
********************************************************************************
********************************************************************************
** National Walkability Index score
********************************************************************************
capture noisily {
** regressions
quietly eststo walk_du: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo walk_duhe: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo walk_mfdu: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo walk_mf: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo walk_mfhe: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo walk_he: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab walk_du walk_duhe walk_mfdu walk_mf walk_mfhe walk_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") title("Walkability Index") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab clay_du clay_duhe clay_mfdu clay_mf clay_mfhe clay_he using "$RDPATH/amenities_table_walkability_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_du" "walk_duhe" "walk_mfdu" "walk_mf" "walk_mfhe" "walk_he") ///
	title("Walkability Index") 
		

** coefplots
local plot_list walk_du walk_duhe walk_mfdu walk_mf walk_mfhe walk_he
local l1_title "Walkability Index"
local b1_title "<-More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"
local graph_title "coef_muni_walk_all_municluster"

foreach r in `plot_list'{
	if "`r'" == "walk_du" {
		local title "Only DUPAC Changes"
	}
	
	if "`r'" == "walk_duhe" {
		local title "DUPAC and Height Change"
	}

	if "`r'" == "walk_mfdu" {
		local title "MF Allowed and DUPAC Change"
	}
	
	if "`r'" == "walk_mf" {
		local title "Only MF Allowed Changes"
	}
	
	if "`r'" == "walk_mfhe" {
		local title "MF Allowed and Height Change"
	}
	
	if "`r'" == "walk_he" {
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
		
		graph save "`r'a" "coef_muni_`r'_municluster", replace;
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
		name("graph_all_muni", replace);
	graph save "graph_all_muni" "`graph_title'", replace;
#delimit cr	

eststo clear
graph close _all
}


********************************************************************************
** Employment mix  (only tables)
********************************************************************************
capture noisily {
** regressions
quietly eststo empl_du: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo empl_duhe: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo empl_mfdu: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo empl_mf: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo empl_mfhe: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo empl_he: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab empl_du empl_duhe empl_mfdu empl_mf empl_mfhe empl_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") title("Employment mix") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab empl_du empl_duhe empl_mfdu empl_mf empl_mfhe empl_he using "$RDPATH/amenities_table_emplmix_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_du" "empl_duhe" "empl_mfdu" "empl_mf" "empl_mfhe" "empl_he") ///
	title("Employment mix") 
	
}


********************************************************************************
** Employment mix rank (only tables)
********************************************************************************
capture noisily {
** regressions
quietly eststo emplrank_du: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)
	
quietly eststo emplrank_duhe: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo emplrank_mfdu: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo emplrank_mf: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo emplrank_mfhe: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

quietly eststo emplrank_he: reg d2b_ranked ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex !="Condominiums") , vce(cluster XXX)

esttab emplrank_du emplrank_duhe emplrank_mfdu emplrank_mf emplrank_mfhe emplrank_he, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("emplrank_du" "emplrank_duhe" "emplrank_mfdu" "emplrank_mf" "emplrank_mfhe" "emplrank_he") title("Employment mix rank") 
	
/* REStat Revision 03-27-2024 - allow for table - NC check
	- keeping only the first coefficient on the more restrictive side of the 
	  boundary, check if correct bin kept */
	  
esttab emplrank_du emplrank_duhe emplrank_mfdu emplrank_mf emplrank_mfhe emplrank_he using "$RDPATH/amenities_table_emplrank_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("emplrank_du" "emplrank_duhe" "emplrank_mfdu" "emplrank_mf" "emplrank_mfhe" "emplrank_he") ///
	title("Employment mix rank") 
	
}




log close
clear all

********************************************************************************
** convert gph to pdfs
********************************************************************************
local files : dir "$RDPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$RDPATH/`fin'"
	
	graph export "$RDPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 
	





