* start here
clear all
log close _all
set linesize 255

local name = "external_effects"  // <--- change when necessry

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
* File name:		external_effects.do
*
* Project title:	Boston Zoning Project
*
* Description:		A shortened and cleaned version of the external effects 
*                   file, last run by MC on 2/3/2025. 
*
*                   Near-far external lot analysis following Turner et al.
* 			        striaght line boundaries (matt turner orthogona lines)
* 			        for house prices, rents. regression output is tables only.
*			        printed w/o characteristics or exclusions (a) and w/ (b).
*
*					Contents:
*						Part 1(a-b): Sales prices baseline + controls 
*						Part 2(a-b): Rents baseline + controls 
* 				
* Inputs:		mt_orthogonal_dist_100m_07-01-22_moreregs.dta
*				within_town_analysis_data.dta
*				
* Outputs:		log output only
*
* Created:		04/11/2024
* Updated:      02/27/2025
********************************************************************************


********************************************************************************
** load and tempsave the mt lines data
********************************************************************************
use  "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear

** merge on mt lines to keep straight line properties
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

** drop out of scope years
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
** loop over different definitions of interior parcels
********************************************************************************
gen interior_parcel = .

forvalues i = 0.15 {
	
	display "Current interior cutoff is `i'"
	
	*interior parcel definition 
	
	local interior_min = `i'   /*current round*/
	local interior_max = 0.5

	replace interior_parcel = .
	replace interior_parcel = 1 if (dist_both>`interior_min' & dist_both<=`interior_max') | (dist_both<(`interior_min' * -1) & dist_both>=(`interior_max' * -1))
	replace interior_parcel = 0 if dist_both<=`interior_min' & dist_both>=(`interior_min' * -1)
	
	********************************************************************************
	** Part 1: Sales prices
	* Part 1a: Sales prices, baseline
	* Part 1b: Sales prices, w/ control for characteristics
	********************************************************************************
	** regressions
	* set regression conditions
	*CHECK: Change dist_both distance to relflect above criterum
	local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>=(`interior_max' * -1)) & res_typex=="Single Family Res"

	*Means (calcualted for boudnary parcel)
	sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
	sum def_saleprice if only_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0
		
	sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
	sum def_saleprice if du_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

	sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
	sum def_saleprice if mf_du == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

	sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
	sum def_saleprice if only_mf == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

	sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
	sum def_saleprice if mf_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

	sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex=="Single Family Res" & last_salepr > 0
	sum def_saleprice if only_he == 1 & (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex=="Single Family Res" & last_salepr > 0

			
	* Part 1b: Sales price w/ additional controls
	quietly eststo price_du2: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
		
	quietly eststo price_duhe2: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_mfdu2: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_mf2: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_mfhe2: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr $char_vars if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_he2: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

	* older esttab version, pre REStat
	esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2, ///
		se r2 indicate("Boundary f.e.=*lam_seg" "Sale year f.e.=*last_saleyr" "Year built f.e.=*year_built" ) interaction(" X ") ///
		label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
		title("Sales Prices w/ characteristics") 
		
	*Check RESTAT: keep only the coefficients that have interior interaction with them 	  
	esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2 using "$RDPATH/salesprice_table_external_`interior_min'_addcontrols.tex", replace keep(*interior_parcel*) ///
		se r2 indicate("Boundary f.e.=*lam_seg" "Sale year f.e.=*last_saleyr" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
		title("Sales Prices w/ characteristics") 
		
	*robust s.e.
	quietly eststo price_du2_r: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions', vce(robust)
		
	quietly eststo price_duhe2_r: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions', vce(robust)

	quietly eststo price_mfdu2_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions', vce(robust)

	quietly eststo price_mf2_r: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions', vce(robust)

	quietly eststo price_mfhe2_r: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr $char_vars if mf_he == 1 & `regression_conditions', vce(robust)

	quietly eststo price_he2_r: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions', vce(robust)

	* older esttab version, pre REStat
	esttab price_du2_r price_duhe2_r price_mfdu2_r price_mf2_r price_mfhe2_r price_he2_r, ///
		se r2 indicate("Boundary f.e.=*lam_seg" "Sale year f.e.=*last_saleyr" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
		title("Sales Prices w/ characteristics, robust s.e.") 

		
	eststo clear
	
	********************************************************************************
	** Part 2: Rents
	* Part 2a: Rents, baseline
	* Part 2b: Rents, w/ control for characteristics
	********************************************************************************
	** regressions
	* set regression conditions
	local regression_conditions (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>=(`interior_max' * -1)) & res_typex != "Condominiums"

	sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
	sum comb_rent2 if only_du == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0
		
	sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
	sum comb_rent2 if du_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0

	sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>0) & res_typex != "Condominiums" & comb_rent2>0
	sum comb_rent2 if only_he == 1 & (year>=2010 & year<=2018) & (dist_both<=0 & dist_both>=-`interior_max') & res_typex != "Condominiums" & comb_rent2>0
		
		
	* Part 2b: Rents w/ additional controls
	quietly eststo rent_du2: reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
		
	quietly eststo rent_duhe2: reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo rent_he2: reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year $char_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
		
	esttab rent_du2 rent_duhe2 rent_he2, se r2 ///
		indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
		title("Rents, w/ characteristics") 
		
	* keep only the coefficients that have interior interaction with them 	  
	esttab rent_du2 rent_duhe2 rent_he2 using "$RDPATH/rents_table_external_`interior_min'_addcontrols.tex", replace keep(*interior_parcel*) se r2 ///
		indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("rent_du2" "rent_duhe2" "rent_mfdu2" "rent_mf2" "rent_mfhe2" "rent_he2") ///
		title("Rents, w/ characteristics") 
		
		
	*robust s.e.	
	quietly eststo rent_du2_r: reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions', vce(robust)
		
	quietly eststo rent_duhe2_r: reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions', vce(robust)

	quietly eststo rent_he2_r: reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year $char_vars if only_he == 1 & `regression_conditions', vce(robust)
		
	esttab rent_du2_r rent_duhe2_r rent_he2_r, se r2 ///
		indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
		title("Rents, w/ characteristics") 
		
		
	eststo clear		
		
}	
