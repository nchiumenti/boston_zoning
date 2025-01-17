clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREStat_rd_chars_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
* File name:		"postREStat_rd_chars_mtlines.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		creates rd graphs/coefplots based on regressing building
*			        characteristics on baseline + i.year_built after 1918 
*                        regressors:
*           				char1_lotsizeac1 
*			               	char2_livingarea1 
*           				char3_bedrooms1 
*			            	char4_bathfull1
* 				
* Inputs:           $SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta
*                   $DATAPATH/final_dataset_10-28-2021.dta
*				
* Outputs:
*
* Created:		06/23/2021
* Updated:		09/18/2024
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
** load the mt lines data
********************************************************************************
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


// ********************************************************************************
// ** load final dataset
// ********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear
//
//
// ********************************************************************************
// ** run postQJE within town setup file
// ********************************************************************************
// run "$DOPATH/postREStat_within_town_setup.do"  // NFC note: I changed this from the postQJE setup to postREStat because i think it should generally be the same
use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear //created with "$DOPATH/postREStat_within_town_setup_07102024.do"


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* checks for errors in merge
	sum _merge
	/* assert `r(N)' ==  3400297
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


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** building characteristic variable setup
********************************************************************************
gen char1_lotsizeac1 = lot_sizeac if lot_sizeac != 0			// lot size in acres, excl zero acre
gen char2_livingarea1 = livingarea / num_units1 if livingarea != 0	// living area in XX per unit, excl zero
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0	// num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0	// num full bathrooms per unit, atleast 1

global char_vars char1_lotsizeac1 char2_livingarea1 char3_bedrooms1 char4_bathfull1

sum $char_vars

** means
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

********************************************************************************
** RD graphs
********************************************************************************

** Part 1: Char vars year==2018 & year_built>=1918
foreach char_var in $char_vars{
	di "running coefplots for: `char_var'"
	
	local char_lab = substr("`char_var'", 7, .)
	
	di "file label: `char_lab'"
	
	if "`char_var'" == "char1_lotsizeac1" {
		local y_lab "Lot Size (in acres)"
	}
	
	else if "`char_var'" == "char2_livingarea1" {
		local y_lab "Living Area (in sqft)"
	}
		
	else if "`char_var'" == "char3_bedrooms1" {
		local y_lab "Number of Bedrooms Per Unit"
	}
	
	else if "`char_var'" == "char4_bathfull1" {
		local y_lab "Number of Full Bathrooms Per Unit"
	}
	
	else {
		local y_lab "<y axis title missing>"
	}
		
	* set regression conditions
	local regression_conditions year==2018 & year_built>=1918 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

	* regression stores
	quietly eststo `char_lab'_du: reg `char_var' ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_duhe: reg `char_var' ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_mfdu: reg `char_var' ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_mf: reg `char_var' ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_mfhe: reg `char_var' ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_he: reg `char_var' ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	esttab `char_lab'_du `char_lab'_duhe `char_lab'_mfdu `char_lab'_mf `char_lab'_mfhe `char_lab'_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg") ///
	label mtitles("only_du" "du_he" "mf_du" "only_mf" "mf_he" "only_he") ////
	title("`char_lab' - year==2018 & year_built>=1918 ")
	
	
	*robust s.e.
		* regression stores
	quietly eststo `char_lab'_du_robust: reg `char_var' ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_duhe_robust: reg `char_var' ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_mfdu_robust: reg `char_var' ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_mf_robust: reg `char_var' ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_mfhe_robust: reg `char_var' ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_he_robust: reg `char_var' ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(robust)
		
	esttab `char_lab'_du_robust `char_lab'_duhe_robust `char_lab'_mfdu_robust `char_lab'_mf_robust `char_lab'_mfhe_robust `char_lab'_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg") ///
	label mtitles("only_du" "du_he" "mf_du" "only_mf" "mf_he" "only_he") ////
	title("`char_lab' - year==2018 & year_built>=1918, robust s.e. ")
	
	* only_du
	#delimit ;
	coefplot 	
		/* relaxed side graphing variables */
		(`char_lab'_du, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_du, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:Only DUPAC Changes}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph1", replace) ;
		
		graph combine graph1,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph1a", replace);

		graph save "graph1a" "coef_`char_lab'_1918_du.gph", replace ;
	#delimit cr

	* only_he
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_he, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_he, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:Only Height Changes}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph2", replace) ;
		
		graph combine graph2,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph2a", replace);
		
		graph save "graph2a" "coef_`char_lab'_1918_he.gph", replace ;
	#delimit cr

	* only_mf
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_mf, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_mf, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:Only MF Allowed Changes}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph3", replace) ;
		
		graph combine graph3,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph3a", replace);
		
		graph save "graph3a" "coef_`char_lab'_1918_mf.gph", replace ;
	#delimit cr

	* du_he
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_duhe, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_duhe, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:DUPAC and Height Change}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph4", replace) ;
		
		graph combine graph4,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph4a", replace);
		
		graph save "graph4a" "coef_`char_lab'_1918_duhe.gph", replace ;
	#delimit cr

	* mf_du
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_mfdu, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_mfdu, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:MF Allowed and DUPAC Change}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph5", replace) ;
		
		graph combine graph5,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph5a", replace);
		
		graph save "graph5a" "coef_`char_lab'_1918_mfdu.gph", replace ;
	#delimit cr

	* mf_he
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_mfhe, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_mfhe, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:MF Allowed and Height Change}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph6", replace) ;
		
		graph combine graph6,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph6a", replace);
		
		graph save "graph6a" "coef_`char_lab'_1918_mfhe.gph", replace ;
	#delimit cr

	* combine all
	#delimit ;
		graph combine graph1 graph4 graph5 graph3 graph6 graph2,
			rows(2) cols(3) ysize(9) xsize(16) iscale(*.75)
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph_all", replace);
		
		graph save "graph_all" "coef_`char_lab'_1918_all.gph", replace ;
	#delimit cr

	graph close _all
}


eststo clear


**Part 2 Char vars year==2018 & no year built restriction
foreach char_var in $char_vars{
	di "running coefplots for: `char_var'"
	
	local char_lab = substr("`char_var'", 7, .)
	
	di "file label: `char_lab'"
	
	if "`char_var'" == "char1_lotsizeac1" {
		local y_lab "Lot Size (in acres)"
	}
	
	else if "`char_var'" == "char2_livingarea1" {
		local y_lab "Living Area (in sqft)"
	}
		
	else if "`char_var'" == "char3_bedrooms1" {
		local y_lab "Number of Bedrooms Per Unit"
	}
	
	else if "`char_var'" == "char4_bathfull1" {
		local y_lab "Number of Full Bathrooms Per Unit"
	}
	
	else {
		local y_lab "<y axis title missing>"
	}
		
	* set regression conditions
	local regression_conditions year==2018 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex != "Condominiums"

	* regression stores
	quietly eststo `char_lab'_du: reg `char_var' ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if only_du == 1 & year==2018  & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if only_du == 1 & year==2018  & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_duhe: reg `char_var' ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if du_he == 1 & year==2018  & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if du_he == 1 & year==2018  & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_mfdu: reg `char_var' ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if mf_du == 1 & year==2018  & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if mf_du == 1 & year==2018  & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_mf: reg `char_var' ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if only_mf == 1 & year==2018  & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if only_mf == 1 & year==2018  & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_mfhe: reg `char_var' ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if mf_he == 1 & year==2018  & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if mf_he == 1 & year==2018  & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	quietly eststo `char_lab'_he: reg `char_var' ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
		*POSTRESTAT
		sum `char_var' if only_he == 1 & year==2018  & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
		sum `char_var' if only_he == 1 & year==2018  & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	esttab `char_lab'_du `char_lab'_duhe `char_lab'_mfdu `char_lab'_mf `char_lab'_mfhe `char_lab'_he, ///
	se r2 indicate("Boundary f.e.=*lam_seg") ///
	label mtitles("only_du" "du_he" "mf_du" "only_mf" "mf_he" "only_he") ////
	title("`char_lab' - year==2018, no year built restriction ")
	
	*robust s.e.
	* regression stores
	quietly eststo `char_lab'_du_robust: reg `char_var' ib26.dist3 i.lam_seg if only_du == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_duhe_robust: reg `char_var' ib26.dist3 i.lam_seg if du_he == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_mfdu_robust: reg `char_var' ib26.dist3 i.lam_seg if mf_du == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_mf_robust: reg `char_var' ib26.dist3 i.lam_seg if only_mf== 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_mfhe_robust: reg `char_var' ib26.dist3 i.lam_seg if mf_he == 1 & `regression_conditions', vce(robust)
		
	quietly eststo `char_lab'_he_robust: reg `char_var' ib26.dist3 i.lam_seg if only_he == 1 & `regression_conditions', vce(robust)
		
	esttab `char_lab'_du_robust `char_lab'_duhe_robust `char_lab'_mfdu_robust `char_lab'_mf_robust `char_lab'_mfhe_robust `char_lab'_he_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg") ///
	label mtitles("only_du" "du_he" "mf_du" "only_mf" "mf_he" "only_he") ////
	title("`char_lab' - year==2018, no year built restriction, robust s.e. ")
	
	* only_du
	#delimit ;
	coefplot 	
		/* relaxed side graphing variables */
		(`char_lab'_du, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_du, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),

		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:Only DUPAC Changes}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph1", replace) ;
		
		graph combine graph1,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph1a", replace);

		graph save "graph1a" "coef_`char_lab'_noyear_du.gph", replace ;
	#delimit cr

	* only_he
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_he, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_he, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:Only Height Changes}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph2", replace) ;
		
		graph combine graph2,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph2a", replace);
		
		graph save "graph2a" "coef_`char_lab'_noyear_he.gph", replace ;
	#delimit cr

	* only_mf
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_mf, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_mf, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:Only MF Allowed Changes}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph3", replace) ;
		
		graph combine graph3,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph3a", replace);
		
		graph save "graph3a" "coef_`char_lab'_noyear_mf.gph", replace ;
	#delimit cr

	* du_he
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_duhe, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_duhe, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:DUPAC and Height Change}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph4", replace) ;
		
		graph combine graph4,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph4a", replace);
		
		graph save "graph4a" "coef_`char_lab'_noyear_duhe.gph", replace ;
	#delimit cr

	* mf_du
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_mfdu, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_mfdu, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:MF Allowed and DUPAC Change}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph5", replace) ;
		
		graph combine graph5,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph5a", replace);
		
		graph save "graph5a" "coef_`char_lab'_noyear_mfdu.gph", replace ;
	#delimit cr

	* mf_he
	#delimit ;
	coefplot 
		/* relaxed side graphing variables */
		(`char_lab'_mfhe, keep(16.dist3 17.dist3 18.dist3 19.dist3 20.dist3 21.dist3 22.dist3 23.dist3 24.dist3 25.dist3) 
			recast(line) color(midblue) 
			ciopts(recast(rarea) color(midblue%30) lwidth(none))
			)
		
		/* strict side graphing variables */
		(`char_lab'_mfhe, keep(26.dist3 27.dist3 28.dist3 29.dist3 30.dist3 31.dist3 32.dist3 33.dist3 34.dist3 35.dist3) 
			recast(line) color(maroon)
			ciopts(recast(rarea) color(maroon%30) lwidth(none))
			),


		/* plot region */
		vertical levels(95) baselevels offset(0)
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		xline(10.5, lpattern(dash) lwidth(thin) lcolor(black))
		yline(0, lpattern(dash) lwidth(thin) lcolor(black))

		/* titles, subtitles, notes */		
		title("{bf:MF Allowed and Height Change}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

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
		
		/* graph name */
		name("graph6", replace) ;
		
		graph combine graph6,
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph6a", replace);
		
		graph save "graph6a" "coef_`char_lab'_noyear_mfhe.gph", replace ;
	#delimit cr

	* combine all
	#delimit ;
		graph combine graph1 graph4 graph5 graph3 graph6 graph2,
			rows(2) cols(3) ysize(9) xsize(16) iscale(*.75)
			graphregion(fc(white) lcolor(white))
			l1title("{bf:`y_lab'}", size(3) margin(t=0 b=0 l=0 r=1))
			b1title("<- More restrictive  |  Less restrictive ->", size(2))
			b2title("{bf:Distance to Boundary (miles)}", size(3) margin(t=1 b=0 l=0 r=0))
			name("graph_all", replace);
		
		graph save "graph_all" "coef_`char_lab'_noyear_all.gph", replace ;
	#delimit cr

	graph close _all
}


********************************************************************************
** end
********************************************************************************
log close
clear all

** convert pdfs to gph
local files : dir "$RDPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$RDPATH/`fin'"
	
	graph export "$RDPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 

