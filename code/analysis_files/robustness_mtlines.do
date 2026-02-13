* start here
clear all
log close _all
set linesize 255

local name ="robustness_mtlines"  // <--- change when necessry

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
* File name:		robustness_mtlines.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		This file runs a myriad of robustness checks, not main line
*					specifications. it has been trimmed down considerably. As
*					such, the .do file 'part' numbers are not consecutive but 
*					they should align to prior versions of the file.
* 				
* Inputs:			mt_orthogonal_dist_100m_07-01-22_moreregs.dta
*					dist_south_station_2022_09_29.csv
*					transit_distance.csv
*					soil_quality_matches.dta
*					warren_group_walkability.dta"
*					within_town_analysis_data.dta
*					final_addon_regs_intersect.dta
*					blocks_2010.dta
*					acs_amenities.dta
*
* Outputs:			Figure C.12, Figure C.8, Figure C.9, Table C.12, Figure C.10
*
* Created:			10/05/2022
* Updated:			01/25/2026
********************************************************************************

* confirm that all input data files are present under $DATAPATH
confirm file "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_moreregs.dta"
confirm file "$DATAPATH/dist_south_station_2022_09_29.csv"
confirm file "$DATAPATH/transit_distance.csv"
confirm file "$DATAPATH/soil_quality_matches.dta"
confirm file "$DATAPATH/warren_group_walkability.dta"
confirm file "$DATAPATH/within_town_analysis_data.dta"
confirm file "$DATAPATH/final_addon_regs_intersect.dta"
confirm file "$DATAPATH/blocks_2010.dta"
confirm file "$DATAPATH/acs_amenities.dta"

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
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren_group_walkability.dta"

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


********************************************************************************
** load and tempsave regulations data
********************************************************************************
use "$DATAPATH/final_addon_regs_intersect.dta", clear

rename addon_* *  // should remove the addon_prefix from all variables

keep prop_id *_esval  // keep all esval variables, i.e. imputation flags

tempfile regs
save `regs', replace


********************************************************************************
** load and tempsave the transit data
********************************************************************************
import delimited "$DATAPATH/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/transit_distance.csv", clear stringcols(_all)

merge m:1 station_id using `dist_south_station'

	* merge error check
	tab _merge
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

	* merge error check
	tab _merge
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'
	
	* merge error check
	tab _merge
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)
	
	* merge error check
	tab _merge
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
** merge on imputation flags for regulations
********************************************************************************
merge m:1 prop_id using `regs'
sum _merge

* merge error check
tab _merge
drop if _merge == 2
drop _merge


********************************************************************************
** merge on ACS characteristics
********************************************************************************
* merge on block data level characteristics
merge m:1 warren_GEOID_full using "$DATAPATH/blocks_2010.dta", update replace
	
	* summarize _merge var and drop
	tab _merge
	drop if _merge == 2
	drop _merge 

* create block group making variable
gen BLKGRP = substr(warren_GEOID_full,1,12)

* merge on ace amenities dataset
merge m:1 year BLKGRP using "$DATAPATH/acs_amenities.dta", keepusing(B19113001 SHARE_BACHELOR_25)

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

gen transit_dist = transit_dist_m/1609

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
global char_vars dist_road
global char_vars_duhe dist_road soil_avgslope soil_avgrestri

*new amenities controls (for discontinuous amenities)
global char_vars_highway dist_road
global char_vars_highway_walkability dist_road natwalkind
global char_vars_walkability natwalkind
global char_vars_hiway_wlkblty_muni dist_road natwalkind dist_center

global char_vars_1 i.year_built log_lotacres num_floors log_bldgarea bedroom_num bathfull_num

sum $char_vars


********************************************************************************
** calcualte means
********************************************************************************
* means for only_du boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & only_du == 1 & res_typex != "Condominiums")

* means for du_he boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & du_he == 1 & res_typex != "Condominiums")

* means for mf_du boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & mf_du == 1 & res_typex != "Condominiums")

* means for only_mf boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf == 1 & res_typex != "Condominiums")

* means for mf_he boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & mf_he == 1 & res_typex != "Condominiums")

* means for only_he boundaries
sum char* if year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2 & only_he == 1 & res_typex != "Condominiums")

* count boundaries
unique lam_seg
unique lam_seg if only_du == 1
unique lam_seg if only_he == 1
unique lam_seg if only_mf == 1

unique lam_seg if du_he == 1
unique lam_seg if mf_du == 1
unique lam_seg if mf_he == 1


********************************************************************************
** Optimal bandwidth calculation
********************************************************************************
** without controls
* rents uniform kernel
rdbwselect log_mfrent dist_both if (only_mf == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (only_he == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (only_du == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (mf_he == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (mf_du == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)
rdbwselect log_mfrent dist_both if (du_he == 1 & res_typex !="Condominiums" ), c(0) all kernel(uni)

* house price uniform kernel
rdbwselect log_saleprice dist_both if (only_mf == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni) 
rdbwselect log_saleprice dist_both if (only_he == 1 & res_typex=="Single Family Res"), c(0) all kernel(uni) 
rdbwselect log_saleprice dist_both if (only_du == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni) 
rdbwselect log_saleprice dist_both if (mf_he == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)
rdbwselect log_saleprice dist_both if (mf_du == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)
rdbwselect log_saleprice dist_both if (du_he == 1 & res_typex=="Single Family Res" ), c(0) all kernel(uni)

global char_vars_highway dist_road
global char_vars_highway_walkability dist_road natwalkind
global char_vars_walkability natwalkind
global char_vars_hiway_wlkblty_muni dist_road natwalkind dist_center


********************************************************************************
** Rents
* Rents, baseline
* Rents, not between $500 - $1400
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Rents all
* [PAPER SOURCE]: Figure C.12.a
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
* [PAPER SOURCE]: Figure C.12.b
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
* Rents w/o 500-1400$
* [PAPER SOURCE]: For Figure C.12 Subfigure (a)
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.12 Subfigure (b)
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(cluster lam_seg)

esttab rent_du2 rent_duhe2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, not between $500 - $1400") 

esttab rent_du2 rent_duhe2 using "$EXPORTPATH/rents_table_5001400.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, not between $500 - $1400") 
	
* robust s.e.
* [PAPER SOURCE]: For Figure C.12 Subfigure (a)
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(robust)
	
* [PAPER SOURCE]: For Figure C.12 Subfigure (b)
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions' & (comb_rent2<500 | comb_rent2>1400), vce(robust)

esttab rent_du2_robust rent_duhe2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, not between $500 - $1400, robust s.e.") 
		
* coefplots, Rents both
* [PAPER SOURCE]: For Figure C.12 Subfigures (a) and (b)
local plot_list rent_du rent_duhe
local suffix "coef_rent_robustness_5001400_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all


********************************************************************************
** Rents
* Rents, baseline
* CoStar imputation dummy 
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Rents all
* [PAPER SOURCE]: Figure C.12.a
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
* [PAPER SOURCE]: Figure C.12.a
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab rent_du rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe") ///
	title("Rents, baseline") 
	
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* CoStar imputation dummy
cap drop imputation_dummy  // dummy = 1 if no rent from costar, else 0

gen imputation_dummy = 0
replace imputation_dummy = 1 if AvgAskingUnit == .

* [PAPER SOURCE]: Figure C.8 Subfigure (a)
quietly eststo rent_du3: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
* [PAPER SOURCE]: Figure C.8 Subfigure (a)
quietly eststo rent_duhe3: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab rent_du3 rent_duhe3, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe") ///
	title("Rents, baseline") 

esttab rent_du3 rent_duhe3 rent_he3 using "$EXPORTPATH/rents_table_costardummy.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe") ///
	title("Rents, baseline") 
	
* robust s.e.
* [PAPER SOURCE]: Figure C.8 Subfigure (a)
quietly eststo rent_du3_robust: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
* [PAPER SOURCE]: Figure C.8 Subfigure (a)
quietly eststo rent_duhe3_robust: reg log_mfrent ib26.dist3 imputation_dummy i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_du3_robust rent_duhe3_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe") ///
	title("Rents, baseline, robust s.e.") 

* coefplots, Rents both
* [PAPER SOURCE]: Figure C.8 Subfigures (a) and (b)
local plot_list rent_du rent_duhe
local suffix "coef_rent_robustness_costardummy_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
			
		(`r'3, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(gs5%30) 
			ciopts(recast(rarea) color(gs5%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`r'3, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all


********************************************************************************
** Part 5: Sales prices
* Sales prices, baseline
* Sales prices with ACS controls
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* Sales price w/ ACS controls
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo price_mf: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du price_duhe price_mfdu price_mf, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
	title("Sales Prices baseline") 

* Sales price w/ ACS and house controls
* [PAPER SOURCE]: Figure C.9 Subfigure (a)
quietly eststo price_du2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
* [PAPER SOURCE]: Figure C.9 Subfigure (c)
quietly eststo price_duhe2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: Figure C.9 Subfigure (f)
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: Figure C.9 Subfigure (e)
quietly eststo price_mf2: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du2 price_duhe2 price_mfdu2 price_mf2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2") ///
	title("Sales Prices w/ characteristics") 

esttab price_du2 price_duhe2 price_mfdu2 price_mf2 using "$EXPORTPATH/salesprice_table_onlyACScontrols.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2") ///
	title("Sales Prices w/ characteristics") 	
	
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"
	
* robust s.e.
* [PAPER SOURCE]: Figure C.9 Subfigure (a)
quietly eststo price_du2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_du==1 & `regression_conditions', vce(robust)

* [PAPER SOURCE]: Figure C.9 Subfigure (c)
quietly eststo price_duhe2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if du_he == 1 & `regression_conditions', vce(robust)

* [PAPER SOURCE]: Figure C.9 Subfigure (f)
quietly eststo price_mfdu2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if  mf_du == 1 & `regression_conditions', vce(robust)

* [PAPER SOURCE]: Figure C.9 Subfigure (e)
quietly eststo price_mf2_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr $acs_vars if only_mf== 1 & `regression_conditions', vce(robust)

esttab price_du2_robust price_duhe2_robust price_mfdu2_robust price_mf2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
	title("Sales Prices w/ characteristics, robust s.e.") 
	
* [PAPER SOURCE]: Figure C.9 Subfigures (a), (c), (e), and (f)
* coefplots, sales prices both
local plot_list price_du price_duhe price_mfdu price_mf
local suffix "coef_price_robustness_acs_both"
local l1_title "Log Sales Price"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
			ciopts(recast(rarea) color(gs5%30) lwidth(1))
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all


********************************************************************************
** Rents
* Rents, baseline
* Rents, w/ ACS controls 
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* [PAPER SOURCE]: Figure C.9 Subfigure (b)
* Part 7a: Rents w/ ACS controls
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: Figure C.9 Subfigure (d)
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab rent_du rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
* Rents w/ ACS and house controls
* [PAPER SOURCE]: Figure C.9 Subfigure (b)
quietly eststo rent_du2: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: Figure C.9 Subfigure (d)
quietly eststo rent_duhe2: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du2 rent_duhe2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, w/ characteristics") 
	
esttab rent_du2 rent_duhe2 using "$EXPORTPATH/rents_table_onlyACScontrols.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, w/ characteristics") 	
	
* robust s.e.
* [PAPER SOURCE]: Figure C.9 Subfigure (b)
quietly eststo rent_du2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if only_du==1 & `regression_conditions', vce(robust)
	
* [PAPER SOURCE]: Figure C.9 Subfigure (d)
quietly eststo rent_duhe2_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year $acs_vars if du_he == 1 & `regression_conditions', vce(robust)

esttab rent_du2_robust rent_duhe2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
	title("Rents, w/ characteristics, robust s.e.") 
	
* [PAPER SOURCE]: For Figure C.9 Subfigures (b) and (d)
* coefplots, Rents both
local plot_list rent_du rent_duhe
local suffix "coef_rent_robustness_acs_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all


********************************************************************************
** Sales prices (baseline is salesprice_table_baseline.tex from point 1)
* Sales prices, relaxed2 definition 
* Sales prices, relaxed4 definition
* Sales prices, only clear boundaries
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both2<=0.21 & dist_both2>=-0.2) & res_typex=="Single Family Res"

* Sales price (relaxed 2 definition)
* relaxed 2 density dominates mf/he
* [PAPER SOURCE]: For Table C.12
quietly eststo price_mfdu: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_mfdu") ///
	title("Sales Prices baseline") 
	  
esttab price_mfdu using "$EXPORTPATH/salesprice_table_relaxed2.tex", replace keep(25.dist3_2) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_mfdu") ///
	title("Sales Prices baseline") 
	
* robust s.e.
* [PAPER SOURCE]: For Table C.12
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3_2 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

esttab price_mfdu_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_mfdu") ///
	title("Sales Prices baseline, robust s.e.") 

eststo clear	
	
* Part 9b: Sales price (relaxed 3 definition)
* density dominates height
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both3<=0.21 & dist_both3>=-0.2) & res_typex=="Single Family Res"
	
* [PAPER SOURCE]: Table C.12
quietly eststo price_duhe: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_duhe, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe") ///
	title("Sales Prices, relaxed 3") 

esttab price_duhe using "$EXPORTPATH/salesprice_table_relaxed3.tex", replace keep(25.dist3_3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe") ///
	title("Sales Prices, relaxed 3") 
	
* robust s.e.
* [PAPER SOURCE]: For Table C.12
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3_3 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)
	
esttab price_duhe_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe") ///
	title("Sales Prices baseline, robust s.e.") 

eststo clear	

* Sales price (relaxed 4 definition)
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both4<=0.21 & dist_both4>=-0.2) & res_typex=="Single Family Res"

* [PAPER SOURCE]: For Table C.12
quietly eststo price_duhe: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_duhe, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe") ///
	title("Sales Prices, relaxed 4") 
	  
esttab price_duhe using "$EXPORTPATH/salesprice_table_relaxed4.tex", replace keep(25.dist3_4) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe") ///
	title("Sales Prices, relaxed 4") 
	
* robust s.e.
* [PAPER SOURCE]: For Table C.12
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3_4 i.lam_seg i.last_saleyr if du_he == 1 & `regression_conditions', vce(robust)

esttab price_duhe_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe") ///
	title("Sales Prices, relaxed 4, robust s.e.") 

eststo clear	

* Sales price (only clear boundaries)
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* [PAPER SOURCE]: For Table C.12
quietly eststo price_duhe: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Table C.12
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab price_duhe price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe" "price_mfdu") ///
	title("Sales Prices baseline") 
	  
esttab price_duhe price_mfdu using "$EXPORTPATH/salesprice_table_clear_boundaries.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe" "price_mfdu") ///
	title("Sales Prices baseline") 
	
* robust s.e.
* [PAPER SOURCE]: For Table C.12
quietly eststo price_duhe_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(robust)

* [PAPER SOURCE]: For Table C.12
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if clear_relaxed_strict_lam== 1 & mf_du == 1 & `regression_conditions', vce(robust)

esttab price_duhe_robust price_mfdu_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_duhe" "price_mfdu") ///
	title("Sales Prices baseline, robust s.e.") 
	
eststo clear	


********************************************************************************
** Rents (baseline is rents_table_baseline.tex from point 2)
* Rents, relaxed3 definition
* Rents, relaxed4 definition
* Rents, only clear boundaries
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both2<=0.21 & dist_both2>=-0.2) & res_typex != "Condominiums"

* Rents relaxed3	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both3<=0.21 & dist_both3>=-0.2) & res_typex != "Condominiums"
	
* [PAPER SOURCE]: For Table C.12
quietly eststo rent_duhe: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, baseline") 
	  
esttab rent_duhe using "$EXPORTPATH/rents_table_relaxed3.tex", replace keep(25.dist3_3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, baseline") 
	
* robust s.e. 
* [PAPER SOURCE]: For Table C.12
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3_3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

esttab rent_duhe_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, baseline, robust s.e.") 

eststo clear

* Rents relaxed4	
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both4<=0.21 & dist_both4>=-0.2) & res_typex != "Condominiums"
	
* [PAPER SOURCE]: For Table C.12
quietly eststo rent_duhe: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, relaxed 4") 
	  
esttab rent_duhe using "$EXPORTPATH/rents_table_relaxed3.tex", replace keep(25.dist3_4) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, relaxed 4") 
	
* robust s.e. 
* [PAPER SOURCE]: For Table C.12
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3_4 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)
	
esttab rent_duhe_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, relaxed 4, robust s.e.") 

eststo clear
	
* Rents, only clear boundaries
* set regression conditions - first 3 regs should not differ from baseline
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* [PAPER SOURCE]: For Table C.12
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, baseline") 

esttab rent_duhe using "$EXPORTPATH/rents_table_clear_boundaries.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_duhe") ///
	title("Rents, baseline") 
	
* robust s.e.
* [PAPER SOURCE]: For Table C.12
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if clear_relaxed_strict_lam== 1 & du_he == 1 & `regression_conditions', vce(robust)

esttab rent_duhe_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles(="rent_duhe") ///
	title("Rents, baseline, robust s.e.") 


********************************************************************************
** Sales prices
* Sales prices, minlotsize by-right boundaries
********************************************************************************
** regressions
* set regression conditions, minlotsize_esval = 0 means mnls is in the bylaws (notimputed)
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res" & mnls_esval==0

* Sales price baseline
* [PAPER SOURCE]: For Figure C.10 Subfigure (a)
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.10 Subfigure (a)
sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr& mnls_esval==0

* number of boundaries
unique lam_seg if only_du==1 & `regression_conditions'

* number of boundaries
unique lam_seg if du_he==1 & `regression_conditions'

* [PAPER SOURCE]: For Figure C.10 Subfigure (b)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.10 Subfigure (b)
sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex=="Single Family Res" & last_salepr > 0 & mnls_esval==0

* number of boundaries
unique lam_seg if mf_du==1 & `regression_conditions'

esttab price_du price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_mfdu") ///
	title("Sales Prices minimum lot size in bylaws, clustered s.e.") 

esttab price_du price_mfdu  using "$EXPORTPATH/salesprice_table_minlotsize.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du"  "price_mfdu") ///
	title("Sales Prices minimum lot size in bylaws, clustered s.e.") 
	
* robust s.e.
* [PAPER SOURCE]: For Figure C.10 Subfigure (a)
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)
	
* [PAPER SOURCE]: For Figure C.10 Subfigure (b)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

esttab price_du_robust price_mfdu_robust , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_mfdu" ) ///
	title("Sales Prices minimum lot size in bylaws, robust s.e.") 
		
* coefplots, sales prices w/o characteristics
* [PAPER SOURCE]: For Figure C.10 Subfigure (a) and (b)
local plot_list price_du price_mfdu 
local suffix "coef_price_minlotsize_clustered"
local l1_title "Log Sales Price"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all


********************************************************************************
** Rents
* Rents, baseline
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums" & mnls_esval==0
	
* Rents w/o characteristics
* [PAPER SOURCE]: For Figure C.10 Subfigure (c)
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.10 Subfigure (c)
sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0

*number of boundaries
unique lam_seg if only_du==1 & `regression_conditions' 

* [PAPER SOURCE]: For Figure C.10 Subfigure (d)
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.10 Subfigure (d)
sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums" & comb_rent2>0 & mnls_esval==0

* number of boundaries
unique lam_seg if du_he==1 & `regression_conditions' 

* number of boundaries
unique lam_seg if mf_du==1 & `regression_conditions' 

esttab rent_du rent_duhe, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe") ///
	title("Rents, minimum lot size in bylaws, clustered s.e.") 
	
esttab rent_du rent_duhe using "$EXPORTPATH/rents_table_minlotsize.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" ) ///
	title("Rents, minimum lot size in bylaws, clustered s.e.") 
	
* robust s.e.
* [PAPER SOURCE]: For Figure C.10 Subfigure (c)
quietly eststo rent_du_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
* [PAPER SOURCE]: For Figure C.10 Subfigure (d)
quietly eststo rent_duhe_robust: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(robust)

esttab rent_du_robust rent_duhe_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" ) ///
	title("Rents, minimum lot size in bylaws, robust s.e.") 
	
* [PAPER SOURCE]: For Figure C.10 Subfigures (c) and (d)
** coefplots

local plot_list rent_du rent_duhe
local suffix "coef_rent_minlotsize_clustered"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all


********************************************************************************
** Sales prices
* Sales prices, baseline
* Sales prices, w/ control discontinuous amenities 
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* Part 1a: Sales price baseline
* [PAPER SOURCE]: For Figure C.12 Subfigure (c)
quietly eststo price_du: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.12 Subfigure (d)
quietly eststo price_mfdu: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du price_mfdu, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_mfdu") ///
	title("Sales Prices baseline") 
	
* robust s.e.
* [PAPER SOURCE]: For Figure C.12 Subfigure (c)
quietly eststo price_du_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if only_du==1 & `regression_conditions', vce(robust)

* [PAPER SOURCE]: For Figure C.12 Subfigure (d)
quietly eststo price_mfdu_robust: reg log_saleprice ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

esttab price_du_robust price_mfdu_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du" "price_mfdu") ///
	title("Sales Prices baseline, robust s.e.") 
			
* Sales prices, w/ control for amenities
* [PAPER SOURCE]: For Figure C.12 Subfigure (c)
quietly eststo price_du2: reg log_saleprice dist_center dist_road ib26.dist3 i.lam_seg i.last_saleyr   if only_du==1 & `regression_conditions', vce(cluster lam_seg)

* [PAPER SOURCE]: For Figure C.12 Subfigure (d)
quietly eststo price_mfdu2: reg log_saleprice ib26.dist3 transit_dist dist_road natwalkind i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

esttab price_du2 price_mfdu2, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_mfdu2") ///
	title("Sales Prices w/ amenities") 
	
esttab price_du2 price_mfdu2 using "$EXPORTPATH/salesprice_table_amenities_control_new.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_mfdu2") ///
	title("Sales Prices w/ amenities") 
	
* robust s.e.
* [PAPER SOURCE]: For Figure C.12 Subfigure (c)
quietly eststo price_du2_robust: reg log_saleprice dist_center dist_road  ib26.dist3 i.lam_seg i.last_saleyr  if only_du==1 & `regression_conditions', vce(robust)

* [PAPER SOURCE]: For Figure C.12 Subfigure (d)
quietly eststo price_mfdu2_robust: reg log_saleprice transit_dist dist_road natwalkind  ib26.dist3 i.lam_seg i.last_saleyr if  mf_du == 1 & `regression_conditions', vce(robust)

esttab price_du2_robust price_mfdu2_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
	label mtitles("price_du2" "price_mfdu2") ///
	title("Sales Prices w/ amenities, robust s.e.") 
	
* [PAPER SOURCE]: For Figure C.12 Subfigures (c) and (d)
* coefplots, sales prices both
local plot_list price_du price_mfdu
local suffix "coef_price_robustness_amenitiesnew_both"
local l1_title "Log Sales Price"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
			ciopts(recast(rarea) color(gs5%30) lwidth(1))
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}


eststo clear
graph close _all


********************************************************************************
** Sales prices
* Sales prices, baseline
* Sales prices, w/ control discontinuous amenities 
********************************************************************************
** regressions
* set regression conditions
local regression_conditions (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

* Part 16a: Rents w/ ACS controls
quietly eststo rent_du: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
quietly eststo rent_duhe: reg log_mfrent ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

quietly eststo rent_he: reg log_mfrent ib26.dist3 i.lam_seg i.year if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
	
esttab rent_du rent_duhe rent_he, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du" "rent_duhe" "rent_he") ///
	title("Rents, baseline") 
	
* Rents w/ control for amenities 
* [PAPER SOURCE]: For Figure C.12 Subfigure (e)
quietly eststo rent_du2: reg log_mfrent dist_center dist_road ib26.dist3 i.lam_seg i.year  if only_du==1 & `regression_conditions', vce(cluster lam_seg)
	
* [PAPER SOURCE]: For Figure C.12 Subfigure (f)
quietly eststo rent_duhe2: reg log_mfrent dist_road ib26.dist3 i.lam_seg i.year if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

esttab rent_du2 rent_duhe2, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, w/ amenities") 

esttab rent_du2 rent_duhe2 using "$EXPORTPATH/rents_table_amenities_control_new.tex", replace keep(25.dist3) se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, w/ amenities") 	

* robust s.e.
* [PAPER SOURCE]: For Figure C.12 Subfigure (e)
quietly eststo rent_du2_robust: reg log_mfrent dist_center dist_road ib26.dist3 i.lam_seg i.year if only_du==1 & `regression_conditions', vce(robust)
	
* [PAPER SOURCE]: For Figure C.12 Subfigure (f)
quietly eststo rent_duhe2_robust: reg log_mfrent dist_road ib26.dist3 i.lam_seg i.year  if du_he == 1 & `regression_conditions', vce(robust)

esttab rent_du2_robust rent_duhe2_robust, se r2 ///
	indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("rent_du2" "rent_duhe2") ///
	title("Rents, w/ amenities, robust s.e.") 
		
* coefplots, Rents both
local plot_list rent_du rent_duhe
local suffix "coef_rent_robustness_amenitiesnew_both"
local l1_title "Log Monthly Rent"
local b1_title "<- More restrictive  |  Less restrictive ->"
local b2_title "Distance to Boundary (miles)"

foreach r in `plot_list' {
	
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
		name("`r'a", replace);
	
	graph save "`r'a" "$EXPORTPATH/`suffix'_`str'", replace;
	graph close "`r'a";
	#delimit cr
}

eststo clear
graph close _all
 
 
********************************************************************************
** end
********************************************************************************
log off
log close
clear all

** convert gph to pdfs
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files' {	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 
