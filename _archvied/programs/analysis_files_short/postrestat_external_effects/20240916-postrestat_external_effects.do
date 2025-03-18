clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postREStat_external_effects_07122024" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postQJE_rd_robustness_mtlines.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		post REStat near-far external lot analysis following Turner et al.
* 			striaght line boundaries (matt turner orthogona lines)
* 			for house prices, rents. regression output is tables only.
*			printed w/o characteristics or exclusions (a) and w/ (b).
*			
*			a: baseline
*			b: control for house characteristics --> this should be preferred specification
*
*			Contents:
*				Part 1(a-b): Sales prices baseline + controls 
*				Part 2(a-b): Rents baseline + controls 
* 				
* Inputs:		./mt_orthogonal_dist_100m_07-01-22_v2.dta
*			./soil_quality_matches.dta
*			./final_dataset_10-28-2021.dta
*				
* Outputs:		lots of graphs
*			_both -> overlay w/o and w/ char_vars and exclusions
*
* Created:		04/11/2024
* Updated: 
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


********************************************************************************
** load final dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
// run "$DOPATH/postREStat_within_town_setup.do"
// run "$DOPATH/postREStat_within_town_setup_07102024.do"

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear



********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* checks for errors in merge
	sum _merge
	//assert `r(N)' ==  3400297
	//assert `r(sum_w)' ==  3400297
	//assert `r(mean)' ==  2.940873106084557
	//assert `r(Var)' ==  .0556309206919615
	//assert `r(sd)' ==  .235862079809285
	//assert `r(min)' ==  2
	//assert `r(max)' ==  3
	//assert `r(sum)' ==  9999842

	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


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
**Define distance polynomial trends
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
**Define distance polynomial trends varlist
********************************************************************************

local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist2 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"
local distance_varlist4 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4"
local distance_varlist5 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4 r_dist_relax5 r_dist_strict5"

********************************************************************************
*loop over different definitions of interior parcels
********************************************************************************

forvalues i = 0.05(0.05)0.25{
	
	display "Current interior cutoff is `i'"
	
	*interior parcel definition 
	
	local interior_min = `i'   /*current round*/
	local interior_max = 0.5

	gen interior_parcel = .
	replace interior_parcel = 1 if (dist_both>`interior_min' & dist_both<=`interior_max') | (dist_both<-`interior_min' & dist_both>=-`interior_max')
	replace interior_parcel = 0 if dist_both<=`interior_min' & dist_both>=-`interior_min'
	
	
	********************************************************************************
	** Part 1: Sales prices
	* Part 1a: Sales prices, baseline
	* Part 1b: Sales prices, w/ control for characteristics
	* Part 1c: Sales prices, baseline, only clear boundaries
	********************************************************************************
	** regressions
	* set regression conditions
	*CHECK: Change dist_both distance to relflect above criterum
	local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>=-`interior_max') & res_typex=="Single Family Res"

	
	forvalues j = 1/5 {
		* Part 1a: Sales price baseline
		quietly eststo price_du: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(cluster lam_seg)
		*Means (calculated for boundary parcel)
		sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
		sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

		quietly eststo price_duhe: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
		sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
		sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

		quietly eststo price_mfdu: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
		sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
		sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

		quietly eststo price_mf: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr `distance_varlist`j'' if only_mf==1 & `regression_conditions', vce(cluster lam_seg)
		sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
		sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

		quietly eststo price_mfhe: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
		sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
		sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

		quietly eststo price_he: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
		sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
		sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

		* older esttab version, pre REStat
		esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
			title("Sales Prices baseline (distance polynomial trends degree `j')")

		*ChEcK RESTAT: keep only the coefficients that have interior interaction with them 
		esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he using "$RDPATH/salesprice_table_external_`interior_min'_`j'.tex", replace keep(*interior_parcel*) ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") nobase ///
			label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
			title("Sales Prices baseline (distance polynomial trends degree `j')")

		* robust s.e.
		quietly eststo price_du_r: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(robust)
			
		quietly eststo price_duhe_r: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(robust)

		quietly eststo price_mfdu_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(robust)

		quietly eststo price_mf_r: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr `distance_varlist`j'' if only_mf == 1 & `regression_conditions', vce(robust)

		quietly eststo price_mfhe_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(robust)

		quietly eststo price_he_r: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(robust)

		* older esttab version, pre REStat
		esttab price_du_r price_duhe_r price_mfdu_r price_mf_r price_mfhe_r price_he_r, ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
			title("Sales Prices, robust s.e. (distance polynomial trends degree `j')")

		eststo clear
			
		* Part 1b: Sales price w/ additional controls
		quietly eststo price_du2: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(cluster lam_seg)
			
		quietly eststo price_duhe2: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo price_mfdu2: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo price_mf2: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo price_mfhe2: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo price_he2: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

		* older esttab version, pre REStat
		esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2, ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
			title("Sales Prices w/ characteristics (distance polynomial trends degree `j')") 
			
		*ChEcK RESTAT: keep only the coefficients that have interior interaction with them     
		esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2 using "$RDPATH/salesprice_table_external_`interior_min'_`j'_addcontrols.tex", replace keep(*interior_parcel*) ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
			title("Sales Prices w/ characteristics (distance polynomial trends degree `j')") 
			
		* robust s.e.
		quietly eststo price_du2_r: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(robust)
			
		quietly eststo price_duhe2_r: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(robust)

		quietly eststo price_mfdu2_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(robust)

		quietly eststo price_mf2_r: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if only_mf== 1 & `regression_conditions', vce(robust)

		quietly eststo price_mfhe2_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(robust)

		quietly eststo price_he2_r: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr $char_vars `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(robust)

		* older esttab version, pre REStat
		esttab price_du2_r price_duhe2_r price_mfdu2_r price_mf2_r price_mfhe2_r price_he2_r, ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
			title("Sales Prices w/ characteristics, robust s.e. (distance polynomial trends degree `j')")

		eststo clear
		
		* Part 1c: Sales prices, baseline, only clear boundaries
		quietly eststo price_du: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' ///
        if only_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		* Means (calculated for boundary parcel)
		sum def_saleprice if only_du == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1
		sum def_saleprice if only_du == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1

		quietly eststo price_duhe: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if du_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum def_saleprice if du_he == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1
		sum def_saleprice if du_he == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1

		quietly eststo price_mfdu: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if mf_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum def_saleprice if mf_du == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1
		sum def_saleprice if mf_du == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1

		quietly eststo price_mf: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if only_mf == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum def_saleprice if only_mf == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1
		sum def_saleprice if only_mf == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1

		quietly eststo price_mfhe: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if mf_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum def_saleprice if mf_he == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1
		sum def_saleprice if mf_he == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1

		quietly eststo price_he: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if only_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum def_saleprice if only_he == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1
		sum def_saleprice if only_he == 1 & (last_saleyr >= 2010 & last_saleyr <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex == "Single Family Res" & last_salepr > 0 & clear_relaxed_strict_lam == 1

		* older esttab version, pre REStat
		esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he, ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
			title("Sales Prices, only clear boundaries (distance polynomial trends degree `j')")

		*ChEcK RESTAT: keep only the coefficients that have interior interaction with them 
		esttab price_du price_duhe price_mfdu price_mf price_mfhe price_he using "$RDPATH/salesprice_table_external_`interior_min'_`j'_clear.tex", replace keep(*interior_parcel*) ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") nobase ///
			label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
			title("Sales Prices, only clear boundaries (distance polynomial trends degree `j')")

		* robust s.e.
		quietly eststo price_du_r: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if only_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)
			
		quietly eststo price_duhe_r: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if du_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo price_mfdu_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if mf_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo price_mf_r: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if only_mf == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo price_mfhe_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if mf_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo price_he_r: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr `distance_varlist`j'' ///
			if only_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		* older esttab version, pre REStat
		esttab price_du_r price_duhe_r price_mfdu_r price_mf_r price_mfhe_r price_he_r, ///
			se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*last_saleyr") interaction(" X ") ///
			label mtitles("price_du" "price_duhe" "price_mfdu" "price_mf" "price_mfhe" "price_he") ///
			title("Sales Prices, only clear boundaries, robust s.e. (distance polynomial trends degree `j')")

		eststo clear
		
}
	
	
	********************************************************************************
	** Part 2: Rents
	* Part 2a: Rents, baseline
	* Part 2b: Rents, w/ control for characteristics
	* Part 2c: Rents, baseline, only clear boundaries
	********************************************************************************
	*loop over different degrees of distance polynomial trends
	forvalues j = 1/5 {
		* set regression conditions
		local regression_conditions (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>=-`interior_max') & res_typex != "Condominiums"

		* Part 2a: Rents w/o characteristics
		quietly eststo rent_du`j': reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(cluster lam_seg)
		sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
		sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

		quietly eststo rent_duhe`j': reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(cluster lam_seg)
		sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
		sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

		quietly eststo rent_mfdu`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.year `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)
		sum comb_rent2 if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
		sum comb_rent2 if mf_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

		quietly eststo rent_mf`j': reg log_mfrent i.interior_parcel##i.mf_allowed i.lam_seg i.year `distance_varlist`j'' if only_mf==1 & `regression_conditions', vce(cluster lam_seg)
		sum comb_rent2 if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
		sum comb_rent2 if only_mf == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

		quietly eststo rent_mfhe`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.year `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)
		sum comb_rent2 if mf_he == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
		sum comb_rent2 if mf_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

		quietly eststo rent_he`j': reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
		sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
		sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

		esttab rent_du`j' rent_duhe`j' rent_mfdu`j' rent_mf`j' rent_mfhe`j' rent_he`j', se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
			title("Rents, baseline (distance polynomial trends degree `j')")

		*ChEcK RESTAT: keep only the coefficients that have interior interaction with them
		esttab rent_du`j' rent_duhe`j' rent_mfdu`j' rent_mf`j' rent_mfhe`j' rent_he`j' using "$RDPATH/rents_table_external_`interior_min'_`j'.tex", replace keep(*interior_parcel*) se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
			title("Rents, baseline (distance polynomial trends degree `j')")

		*robust s.e.
		quietly eststo rent_du_r`j': reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(robust)
			
		quietly eststo rent_duhe_r`j': reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(robust)

		quietly eststo rent_mfdu_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.year `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(robust)

		quietly eststo rent_mf_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed i.lam_seg i.year `distance_varlist`j'' if only_mf==1 & `regression_conditions', vce(robust)

		quietly eststo rent_mfhe_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.year `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(robust)

		quietly eststo rent_he_r`j': reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(robust)

		esttab rent_du_r`j' rent_duhe_r`j' rent_mfdu_r`j' rent_mf_r`j' rent_mfhe_r`j' rent_he_r`j', se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
			title("Rents, robust s.e. (distance polynomial trends degree `j')")

		eststo clear

		* Part 2b: Rents w/ additional controls
		quietly eststo rent_du2`j': reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year $char_vars `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(cluster lam_seg)
			
		quietly eststo rent_duhe2`j': reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year $char_vars `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo rent_mfdu2`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.year $char_vars `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo rent_mf2`j': reg log_mfrent i.interior_parcel##i.mf_allowed i.lam_seg i.year $char_vars `distance_varlist`j'' if only_mf==1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo rent_mfhe2`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.year $char_vars `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

		quietly eststo rent_he2`j': reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year $char_vars `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

		esttab rent_du2`j' rent_duhe2`j' rent_mfdu2`j' rent_mf2`j' rent_mfhe2`j' rent_he2`j', se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du2" "rent_duhe2" "rent_mfdu2" "rent_mf2" "rent_mfhe2" "rent_he2") ///
			title("Rents, w/ characteristics (distance polynomial trends degree `j')")

		*ChEcK RESTAT: keep only the coefficients that have interior interaction with them
		esttab rent_du2`j' rent_duhe2`j' rent_mfdu2`j' rent_mf2`j' rent_mfhe2`j' rent_he2`j' using "$RDPATH/rents_table_external_`interior_min'_`j'_addcontrols.tex", replace keep(*interior_parcel*) se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du2" "rent_duhe2" "rent_mfdu2" "rent_mf2" "rent_mfhe2" "rent_he2") ///
			title("Rents, w/ characteristics (distance polynomial trends degree `j')")

		*robust s.e.
		quietly eststo rent_du2_r`j': reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year $char_vars `distance_varlist`j'' if only_du==1 & `regression_conditions', vce(robust)
			
		quietly eststo rent_duhe2_r`j': reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year $char_vars `distance_varlist`j'' if du_he == 1 & `regression_conditions', vce(robust)

		quietly eststo rent_mfdu2_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.year $char_vars `distance_varlist`j'' if mf_du == 1 & `regression_conditions', vce(robust)

		quietly eststo rent_mf2_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed i.lam_seg i.year $char_vars `distance_varlist`j'' if only_mf==1 & `regression_conditions', vce(robust)

		quietly eststo rent_mfhe2_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.year $char_vars `distance_varlist`j'' if mf_he == 1 & `regression_conditions', vce(robust)

		quietly eststo rent_he2_r`j': reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year $char_vars `distance_varlist`j'' if only_he == 1 & `regression_conditions', vce(robust)

		esttab rent_du2_r`j' rent_duhe2_r`j' rent_mfdu2_r`j' rent_mf2_r`j' rent_mfhe2_r`j' rent_he2_r`j', se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du2" "rent_duhe2" "rent_mfdu2" "rent_mf2" "rent_mfhe2" "rent_he2") ///
			title("Rents, w/ characteristics, robust s.e. (distance polynomial trends degree `j')")

		eststo clear
		
		* Part 2c: Rents, baseline, only clear boundaries
		quietly eststo rent_du`j': reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year `distance_varlist`j'' ///
        if only_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum comb_rent2 if only_du == 1 & (year >= 2010 & year <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1
		sum comb_rent2 if only_du == 1 & (year >= 2010 & year <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1

		quietly eststo rent_duhe`j': reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year `distance_varlist`j'' ///
			if du_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum comb_rent2 if du_he == 1 & (year >= 2010 & year <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1
		sum comb_rent2 if du_he == 1 & (year >= 2010 & year <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1

		quietly eststo rent_mfdu`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.year `distance_varlist`j'' ///
			if mf_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum comb_rent2 if mf_du == 1 & (year >= 2010 & year <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1
		sum comb_rent2 if mf_du == 1 & (year >= 2010 & year <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1

		quietly eststo rent_mf`j': reg log_mfrent i.interior_parcel##i.mf_allowed i.lam_seg i.year `distance_varlist`j'' ///
			if only_mf == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum comb_rent2 if only_mf == 1 & (year >= 2010 & year <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1
		sum comb_rent2 if only_mf == 1 & (year >= 2010 & year <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1

		quietly eststo rent_mfhe`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.year `distance_varlist`j'' ///
			if mf_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum comb_rent2 if mf_he == 1 & (year >= 2010 & year <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1
		sum comb_rent2 if mf_he == 1 & (year >= 2010 & year <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1

		quietly eststo rent_he`j': reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year `distance_varlist`j'' ///
			if only_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(cluster lam_seg)
		sum comb_rent2 if only_he == 1 & (year >= 2010 & year <= 2018) & (dist_both <= `interior_max' & dist_both > 0) & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1
		sum comb_rent2 if only_he == 1 & (year >= 2010 & year <= 2018) & (dist_both <= 0 & dist_both >= -`interior_max') & res_typex != "Condominiums" & comb_rent2 > 0 & clear_relaxed_strict_lam == 1

		esttab rent_du`j' rent_duhe`j' rent_mfdu`j' rent_mf`j' rent_mfhe`j' rent_he`j', se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
			title("Rents, only clear boundaries (distance polynomial trends degree `j')")

		*ChEcK RESTAT: keep only the coefficients that have interior interaction with them
		esttab rent_du`j' rent_duhe`j' rent_mfdu`j' rent_mf`j' rent_mfhe`j' rent_he`j' using "$RDPATH/rents_table_external_`interior_min'_`j'_clear.tex", replace keep(*interior_parcel*) se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
			title("Rents, only clear boundaries (distance polynomial trends degree `j')")

		* robust s.e.
		quietly eststo rent_du_r`j': reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year `distance_varlist`j'' ///
			if only_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)
			
		quietly eststo rent_duhe_r`j': reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year `distance_varlist`j'' ///
			if du_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo rent_mfdu_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.year `distance_varlist`j'' ///
			if mf_du == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo rent_mf_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed i.lam_seg i.year `distance_varlist`j'' ///
			if only_mf == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo rent_mfhe_r`j': reg log_mfrent i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.year `distance_varlist`j'' ///
			if mf_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		quietly eststo rent_he_r`j': reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year `distance_varlist`j'' ///
			if only_he == 1 & `regression_conditions' & clear_relaxed_strict_lam == 1, vce(robust)

		esttab rent_du_r`j' rent_duhe_r`j' rent_mfdu_r`j' rent_mf_r`j' rent_mfhe_r`j' rent_he_r`j', se r2 ///
			indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
			label mtitles("rent_du" "rent_duhe" "rent_mfdu" "rent_mf" "rent_mfhe" "rent_he") ///
			title("Rents, only clear boundaries, robust s.e. (distance polynomial trends degree `j')")

		eststo clear
}	

	drop interior_parcel
		
}	
