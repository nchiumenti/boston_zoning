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
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		A shortened and cleaned version of the external effects 
*                   file, last run by MC on 2/3/2025. 
*
*                   Near-far external lot analysis following Turner et al.
* 			        striaght line boundaries (matt turner orthogona lines)
* 			        for house prices, rents. regression output is tables only.
* 				
* Inputs:			mt_orthogonal_dist_100m_07-01-22_moreregs.dta
*					within_town_analysis_data.dta
*				
* Outputs:			Table C.13
*
* Created:			04/11/2024
* Updated:      	01/30/2026
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

//forvalues i = 0.15
	
	display "Current interior cutoff is 0.15"
	
	*interior parcel definition 
	
	local interior_min = 0.15   /*current round*/
	local interior_max = 0.5

	replace interior_parcel = .
	replace interior_parcel = 1 if (dist_both>`interior_min' & dist_both<=`interior_max') | (dist_both<(`interior_min' * -1) & dist_both>=(`interior_max' * -1))
	replace interior_parcel = 0 if dist_both<=`interior_min' & dist_both>=(`interior_min' * -1)
	
	********************************************************************************
	** Sales prices
	********************************************************************************
	** regressions
	* set regression conditions
	local regression_conditions (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=`interior_max' & dist_both>=(`interior_max' * -1)) & res_typex=="Single Family Res"
			
	* Sales price w/ additional controls
	*[PAPER SOURCE]: For Table C.13 Panel (A)
	quietly eststo price_du2: reg log_saleprice i.interior_parcel##c.dupac i.lam_seg i.last_saleyr $char_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
		
	quietly eststo price_duhe2: reg log_saleprice i.interior_parcel##c.height##c.dupac i.lam_seg i.last_saleyr $char_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_mfdu2: reg log_saleprice i.interior_parcel##i.mf_allowed##c.dupac i.lam_seg i.last_saleyr $char_vars if  mf_du == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_mf2: reg log_saleprice i.interior_parcel##i.mf_allowed i.lam_seg i.last_saleyr $char_vars if only_mf== 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_mfhe2: reg log_saleprice i.interior_parcel##i.mf_allowed##c.height i.lam_seg i.last_saleyr $char_vars if mf_he == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo price_he2: reg log_saleprice i.interior_parcel##c.height i.lam_seg i.last_saleyr $char_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)

	esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2, ///
		se r2 indicate("Boundary f.e.=*lam_seg" "Sale year f.e.=*last_saleyr" "Year built f.e.=*year_built" ) interaction(" X ") ///
		label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
		title("Sales Prices w/ characteristics") 
		
	esttab price_du2 price_duhe2 price_mfdu2 price_mf2 price_mfhe2 price_he2 using "$EXPORTPATH/salesprice_table_external_`interior_min'_addcontrols.tex", replace keep(*interior_parcel*) ///
		se r2 indicate("Boundary f.e.=*lam_seg" "Sale year f.e.=*last_saleyr" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("price_du2" "price_duhe2" "price_mfdu2" "price_mf2" "price_mfhe2" "price_he2") ///
		title("Sales Prices w/ characteristics") 
		


	********************************************************************************
	** Rents
	********************************************************************************
	** regressions
	* set regression conditions
	local regression_conditions (year>=2010 & year<=2018) & (dist_both<=`interior_max' & dist_both>=(`interior_max' * -1)) & res_typex != "Condominiums"

	
	* Rents w/ additional controls
	*[PAPER SOURCE]: For Table C.13 Panel (B)
	quietly eststo rent_du2: reg log_mfrent i.interior_parcel##c.dupac i.lam_seg i.year $char_vars if only_du==1 & `regression_conditions', vce(cluster lam_seg)
		
	quietly eststo rent_duhe2: reg log_mfrent i.interior_parcel##c.height##c.dupac i.lam_seg i.year $char_vars if du_he == 1 & `regression_conditions', vce(cluster lam_seg)

	quietly eststo rent_he2: reg log_mfrent i.interior_parcel##c.height i.lam_seg i.year $char_vars if only_he == 1 & `regression_conditions', vce(cluster lam_seg)
		
	esttab rent_du2 rent_duhe2 rent_he2, se r2 ///
		indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("rent_du2" "rent_duhe2" "rent_he2") ///
		title("Rents, w/ characteristics") 
		
	esttab rent_du2 rent_duhe2 rent_he2 using "$EXPORTPATH/rents_table_external_`interior_min'_addcontrols.tex", replace keep(*interior_parcel*) se r2 ///
		indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("rent_du2" "rent_duhe2" "rent_mfdu2" "rent_mf2" "rent_mfhe2" "rent_he2") ///
		title("Rents, w/ characteristics") 
		
********************************************************************************
** end
********************************************************************************
log off
log close
clear all

** convert pdfs to gph
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 



