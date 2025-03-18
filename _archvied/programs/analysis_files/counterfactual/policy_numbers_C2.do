********************************************************************************
*			Policy value calculations for:
*		How to Increase Housing Affordability? Understanding
*		  Local Deterrents to Building Multifamily Housing
*	
*	Author: Maxi Machado
*	e-mail: maxi.machado@mail.utoronto.ca
*	RA to prof. Aradhya Sood
********************************************************************************

********************************************************************************
* This dofile imports the estimation results from authors and calculate policy 
* values according to calculations explained below.
*
*	This is the scenario of Counterfactual #1:  DUPAC changes to 15
*												height is 0
*												MF is equalized to 1
*
********************************************************************************

clear all
set more off

*global dir "C:\Users\macha116\Dropbox\PhD\Research\RA_IO_Urban\postQJE_Spatial_ReducedForm_mtlines_2022-09-30\test"
*global dir "C:\Users\maxim\Dropbox\PhD\Research\RA_IO_Urban\postQJE_Spatial_ReducedForm_mtlines_2022-09-30\test"

* Run dofile to prepare means
*do "$dir\means_prepare.do"

/*
////////////////////////////////////////////////////////////////////////////////
//			 					Means by station
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
*		A.	Units 
********************************************************************************

use "$dir\postQJE_spatial_unit_coeff_MAPCdefinition.dta", clear

* Keep only linear coefficient for 0.20 miles
keep *_20_x1 county_fip
* Drop standard errors
drop *_se_* *_s_*
* Drop coefficients for 1956
drop *_u56_*

*Rename variables to make it simpler
renvars *, subst(_c_u18_c_20_x1)
renvars *, subst(_u18_c_20_x1)
renvars *, subst(_coeff)

* Generate indicators of when coefficients are significants
gen du_sig = 1 		if abs(t_dupac) > 1.645 
gen du_he_sig = 1 	if (abs(t_dupac_dXh) > 1.645 | abs(t_height_dXh) > 1.645 | abs(t_duXhe_dXh) > 1.645)
gen du_mf_sig = 1 	if (abs(t_dupac_dXmf) > 1.645 | abs(t_mf_dXmf) > 1.645 | abs(t_duXmf_dXmf) > 1.645)
gen mf_sig = 1 		if abs(t_mf) > 1.645 

* Save a clean dataset
save "$dir\spatial_units_coef.dta", replace

* Merge means by station with coefficients
use "$dir\means_clean.dta"
merge n:n county_fip using "$dir\spatial_units_coef.dta"
drop _merge
encode station_name, gen(name)
*encode def_name, gen(type)

*-------------------------------------------------------------------------------
*	Calculate policy numbers:
*-------------------------------------------------------------------------------

drop if station_id == .

* Generate effect variables
gen 	unit_effect_mf		= 0 if boundary_type_int == 4	
gen 	unit_effect_mf_percent = 0 if boundary_type_int == 4
gen 	unit_effect_d		= 0 if boundary_type_int == 3
gen 	unit_effect_d_percent = 0 if boundary_type_int == 3
gen 	unit_effect_dXmf 	= 0 if boundary_type_int == 2
gen 	unit_effect_dXmf_percent = 0 if boundary_type_int == 2
gen 	unit_effect_dXh  	= 0 if boundary_type_int == 1
gen 	unit_effect_dXh_percent = 0 if boundary_type_int == 1

*Reduce one order of height
replace mean_height = mean_height/10

* Create a variable indicating the relaxed height for the restricted rows
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen 	relaxed_height = mean_height if side_int == 1
bysort station_id boundary_type_int: replace 	relaxed_height = relaxed_height[1] if side_int==2
order relaxed_height, after(mean_height)


** Calculate effects

* dupac 
replace unit_effect_d = max(0,(15 - mean_dupac)) * dupac / mean_units	if (du_sig == 1 & boundary_type_int==3)
replace unit_effect_d = . 		if (mean_units == . & boundary_type_int==3)
replace unit_effect_d_percent = unit_effect_d * mean_units if (du_sig == 1 & boundary_type_int==3)

* mf
replace unit_effect_mf = mf / mean_units 	if (mf_sig == 1 & boundary_type_int==4)
replace unit_effect_mf = . 					if (mean_units == . & boundary_type_int==4)
replace unit_effect_mf_percent = unit_effect_mf * mean_units if (mf_sig == 1 & boundary_type_int==4)

* dupac + mf relaxed
replace	unit_effect_dXmf =  max(0,(15 - mean_dupac))*(dupac_dXmf + duXmf_dXmf) / mean_units	if (side_int == 1 & du_mf_sig == 1 & boundary_type_int == 2)
replace unit_effect_dXmf = .	if (mean_units == . & boundary_type_int == 2)
replace unit_effect_dXmf_percent = unit_effect_dXmf * mean_units if (side_int == 1 & du_mf_sig == 1 & boundary_type_int == 2)

* dupac + mf strict
replace	unit_effect_dXmf = [max(0,(15 - mean_dupac))*dupac_dXmf + max(0,(15 - mean_dupac))*duXmf_dXmf + mf_dXmf + duXmf_dXmf * mean_dupac] / mean_units 	if (side_int == 2 & du_mf_sig == 1 & boundary_type_int == 2)
replace unit_effect_dXmf = .	if (mean_units == . & boundary_type_int == 2)
replace unit_effect_dXmf_percent = unit_effect_dXmf * mean_units	if (side_int == 2 & du_mf_sig == 1 & boundary_type_int == 2)

* dupac + he relaxed
replace unit_effect_dXh = max(0,(15 - mean_dupac))*(dupac_dXh + duXhe_dXh*mean_height) / mean_units	if  (side_int == 1 & du_he_sig == 1 & boundary_type_int == 1)
replace unit_effect_dXh = .	if (mean_units == . & boundary_type_int == 1)
replace unit_effect_dXh_percent = unit_effect_dXh * mean_units	if  (side_int == 1 & du_he_sig == 1 & boundary_type_int == 1)

* dupac + he strict
replace unit_effect_dXh = max(0,(15 - mean_dupac))*(dupac_dXh + duXhe_dXh*mean_height) / mean_units  ///
						if  (side_int == 2 & du_he_sig == 1 & boundary_type_int == 1)
replace unit_effect_dXh  = .	if (mean_units == . & boundary_type_int == 1)
replace unit_effect_dXh_percent = unit_effect_dXh * mean_units	if  (side_int == 2 & du_he_sig == 1 & boundary_type_int == 1)


** Give effect only to the correspondent boundary type 
gen unit_effect = unit_effect_dXh if boundary_type_int ==1
replace unit_effect = unit_effect_dXmf 	if boundary_type_int ==2
replace unit_effect = unit_effect_d	if boundary_type_int ==3
replace unit_effect = unit_effect_mf if boundary_type_int ==4

** Give percent only to the correspondent boundary type
gen unit_effect_percent = unit_effect_dXh_percent if boundary_type_int ==1
replace unit_effect_percent = unit_effect_dXmf_percent 	if boundary_type_int ==2
replace unit_effect_percent = unit_effect_d_percent	if boundary_type_int ==3
replace unit_effect_percent = unit_effect_mf_percent	if boundary_type_int ==4

** Save lables of stations for the collapse
local stations_name: variable label name
label save using "$dir\labels.do", replace

** Save the table with values
preserve
collapse (mean) name county_fip unit_effect unit_effect_percent, by (station_id boundary_type_int)
do "$dir\labels.do"
label value name name
label define county_fip 1 "Inner Core" 2 "Regional Urban" 3 "Mature Suburbs"
label value  county_fip county_fip
export excel "$dir\values_units_station_C2.xls", firstrow(variables) replace
save "$dir\values_units_station_C2.dta", replace
restore


********************************************************************************
*		B.	Prices 
********************************************************************************

use "$dir\postQJE_spatial_price_coeff_MAPCdefinition.dta", clear
 
* Keep only linear coefficient for 0.20 miles
keep *_20_x1 county_fip
* Drop standard errors
drop *_s_*

* Rename to see names simpler
renvars *, subst(_c)
renvars *, subst(_20_x1)
renvars *, subst(oeff)
renvars *, subst(enters)
renvars *, subst(wners)

drop if county_fip == .

save "$dir\spatial_price_coef.dta", replace

* Merge with means data
use "$dir\means_clean.dta", clear

merge n:n county_fip using "$dir\spatial_price_coef.dta"
drop _merge
encode station_name, gen(name)
encode def_name, gen(type)

*-------------------------------------------------------------------------------
*	Calculations
*-------------------------------------------------------------------------------

* Generate indicators of when coefficients are significants
gen du_sig_o 	= 1 	if (abs(t_dupac_o) > 1.645 & t_dupac_o!=.)
gen du_he_sig_o = 1 	if (abs(t_dupac_dXh_o) > 1.645 &  t_dupac_dXh_o!=.)| (abs(t_height_dXh_o) > 1.645 & t_height_dXh_o!=.) | (abs(t_duXhe_dXh_o) > 1.645 & t_duXhe_dXh_o!=.)
gen du_mf_sig_o = 1 	if (abs(t_dupac_dXmf_o) > 1.645 & t_dupac_dXmf_o!=.) | (abs(t_mf_dXmf_o) > 1.645 & t_mf_dXmf_o!=.) | (abs(t_duXmf_dXmf_o) > 1.645 != t_duXmf_dXmf_o!=.)
gen du_sig_r 	= 1 	if (abs(t_dupac_r) > 1.645 & t_dupac_r!=.)
gen du_he_sig_r = 1 	if (abs(t_dupac_dXh_r) > 1.645 & t_dupac_dXh_r!=.) | (abs(t_height_dXh_r) > 1.645 & t_height_dXh_r !=.) | (abs(t_duXhe_dXh_r) > 1.645 & t_duXhe_dXh_r != .)
gen du_mf_sig_r = 1 	if (abs(t_dupac_dXmf_r) > 1.645 | abs(t_mf_dXmf_r) > 1.645 | abs(t_duXmf_dXmf_r) > 1.645)
gen mf_sig_r 	= 1 	if (abs(t_mf_dXmf_r) > 1.645 & t_mf_dXmf_r!=.)
gen mf_sig_o 	= 1 	if (abs(t_mf_dXmf_o) > 1.645 & t_mf_dXmf_o!=.)
*Reduce one order of height
replace mean_height = mean_height/10

* Create a variable indicating the relaxed height for the restricted rows
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen 	relaxed_height = mean_height if side_int == 1
bysort station_id boundary_type_int: replace 	relaxed_height = relaxed_height[1] if side_int==2
order relaxed_height, after(mean_height)

* Generate effect variables
gen price_effect_dXh_r = 0	if boundary_type_int == 1
gen price_effect_dXh_r_percent = 0 if boundary_type_int == 1
gen price_effect_dXh_o = 0	if boundary_type_int == 1
gen price_effect_dXh_o_percent = 0 if boundary_type_int == 1

gen price_effect_mfXd_r = 0 	if boundary_type_int == 2
gen price_effect_mfXd_r_percent = 0 	if boundary_type_int == 2
gen price_effect_mfXd_o = 0 	if boundary_type_int == 2
gen price_effect_mfXd_o_percent = 0 if boundary_type_int == 2

gen price_effect_d_r = 0	if boundary_type_int == 3
gen price_effect_d_r_percent = 0 if boundary_type_int == 3
gen price_effect_d_o = 0	if boundary_type_int == 3
gen price_effect_d_o_percent = 0 if boundary_type_int == 3

gen price_effect_mf_r = 0	if boundary_type_int == 4
gen price_effect_mf_r_percent = 0 if boundary_type_int == 4
gen price_effect_mf_o = 0	if boundary_type_int == 4
gen price_effect_mf_o_percent = 0 if boundary_type_int == 4

* Calculate effects 

* dupac rent
replace price_effect_d_r = max(0,(15 - mean_dupac)) * dupac_r * mean_rent 	if (du_sig_r == 1 & boundary_type_int == 3)
replace price_effect_d_r = .		if (mean_rent == . & boundary_type_int == 3)
replace price_effect_d_r_percent = (price_effect_d_r * 100) / (mean_rent) if (du_sig_r == 1 & boundary_type_int == 3)

* dupac price
replace price_effect_d_o = max(0,(15 - mean_dupac)) * dupac_o * mean_saleprice 	if (du_sig_o == 1 & boundary_type_int == 3)
replace price_effect_d_o = .		if (mean_saleprice == . & boundary_type_int == 3)
replace price_effect_d_o_percent = (price_effect_d_o * 100) / (mean_saleprice) 	if (du_sig_o == 1 & boundary_type_int == 3)

/* mf restricted rent
replace price_effect_mf_r_r = mf_r * 100 * mean_rent 	if (mf_sig_r == 1 & boundary_type_int == 4)
replace price_effect_mf_r_r = .		if (mean_rent == . & boundary_type_int == 4) 
replace price_effect_mf_r_r_percent = 0  // price_effect_mf_r_r / (100 * mean_rent) */

* mf price
replace price_effect_mf_o = mf_o * mean_saleprice if (mf_sig_o == 1 & boundary_type_int == 4)
replace price_effect_mf_o = .		if (mean_saleprice == . & boundary_type_int == 4)
replace price_effect_mf_o_percent = (price_effect_mf_o * 100) / (mean_saleprice) if (mf_sig_r == 1 & boundary_type_int == 4)

* dupac + height relaxed rent
replace price_effect_dXh_r = max(0,(15 - mean_dupac)) * (dupac_dXh_r + duXhe_dXh_r * mean_height) * mean_rent if (side_int == 1 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)
replace price_effect_dXh_r = . 	if (mean_rent == . & boundary_type_int == 1)
replace price_effect_dXh_r_percent = (price_effect_dXh_r * 100) / (mean_rent) if (side_int == 1 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)

* dupac + height strict rent 
replace price_effect_dXh_r = max(0,(15 - mean_dupac)) * (dupac_dXh_r + duXhe_dXh_r * mean_height) * mean_rent   ///
	if (side_int == 2 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)
replace price_effect_dXh_r = . 	if (mean_rent == . & boundary_type_int == 1)
replace price_effect_dXh_r_percent = (price_effect_dXh_r * 100) / (mean_rent) if (side_int == 2 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)

* dupac + height relaxed price
replace price_effect_dXh_o = max(0,(15 - mean_dupac)) * (dupac_dXh_o + duXhe_dXh_o * mean_height) * mean_saleprice if (side_int == 1 & du_he_sig_o == 1 & boundary_type_int == 1  & duXhe_dXh_o!=0)
replace price_effect_dXh_o = . 	if (mean_saleprice == . & boundary_type_int == 1)
replace price_effect_dXh_o_percent = (price_effect_dXh_o * 100) / (mean_saleprice) if (side_int == 1 & du_he_sig_o == 1 & boundary_type_int == 1  & duXhe_dXh_o!=0)

* dupac + height strict price
replace price_effect_dXh_o = max(0,(15 - mean_dupac)) * (dupac_dXh_o + duXhe_dXh_o * mean_height) * mean_saleprice   ///
	if (side_int == 2 & du_he_sig_o == 1 & boundary_type_int == 1 & duXhe_dXh_o!=0)
replace price_effect_dXh_o = . 	if (mean_saleprice == . & boundary_type_int == 1)
replace price_effect_dXh_o_percent = (price_effect_dXh_o * 100) / (mean_saleprice) if (side_int == 2 & du_he_sig_o == 1 & boundary_type_int == 1 & duXhe_dXh_o!=0)

/* dupac + mf relaxed rent
replace price_effect_mfXd_r_r =  max(0,(15 - mean_dupac)) * (duXmf_dXmf_r) * 100 * mean_rent						if (side_int == 1 & du_mf_sig_r == 1 & boundary_type_int == 2)
replace price_effect_mfXd_r_r = . 	if (mean_rent == . & boundary_type_int == 2) 
replace price_effect_mfXd_r_r_percent = 0 // price_effect_mfXd_r_r / (100 * mean_rent) */

/* dupac + mf strict rent
replace price_effect_mfXd_s_r = [max(0,(15 - mean_dupac)) * (dupac_dXmf_r) + mf_dXmf_r + duXmf_dXmf_r * max(0,(15 - mean_dupac)) ] * mean_rent * 100	if (side_int == 2 & du_mf_sig_r == 1 & boundary_type_int == 2)
replace price_effect_mfXd_s_r = . 	if (mean_rent == . & boundary_type_int == 2) 
replace price_effect_mfXd_s_r_percent = 0 // price_effect_mfXd_s_r / (100 * mean_rent) */

* dupac + mf relaxed price
replace price_effect_mfXd_o =  max(0,(15 - mean_dupac)) * (dupac_dXmf_o + duXmf_dXmf_o) * mean_saleprice		if (side_int == 1 & du_mf_sig_o == 1 & boundary_type_int == 2 & mf_dXmf_o!=0) 
replace price_effect_mfXd_o = . 	if (mean_saleprice == . & boundary_type_int == 2)
replace price_effect_mfXd_o_percent = (price_effect_mfXd_o * 100) / (mean_saleprice)	if (side_int == 1 & du_mf_sig_o == 1 & boundary_type_int == 2 & mf_dXmf_o!=0) 

* dupac + mf strict price
replace price_effect_mfXd_o = [max(0,(15 - mean_dupac)) * (dupac_dXmf_o + duXmf_dXmf_o) + mf_dXmf_o + duXmf_dXmf_o * mean_dupac] * mean_saleprice ///
	if (side_int == 2 & du_mf_sig_o == 1 & boundary_type_int == 2 & duXmf_dXmf_o!=0)
replace price_effect_mfXd_o = . 	if (mean_saleprice == . & boundary_type_int == 2)
replace price_effect_mfXd_o_percent = (price_effect_mfXd_o * 100) / (mean_saleprice)	if (side_int == 2 & du_mf_sig_o == 1 & boundary_type_int == 2 & duXmf_dXmf_o!=0)


** Give effect only to the correspondent boundary type 
gen price_effect_r 		= price_effect_dXh_r 	if boundary_type_int == 1
replace price_effect_r 	= price_effect_mfXd_r 	if boundary_type_int == 2
replace price_effect_r 	= price_effect_d_r  	if boundary_type_int == 3
replace price_effect_r 	= price_effect_mf_r  	if boundary_type_int == 4

gen price_effect_o 		= price_effect_dXh_o 	if boundary_type_int == 1
replace price_effect_o 	= price_effect_mfXd_o 	if boundary_type_int == 2
replace price_effect_o 	= price_effect_d_o  	if boundary_type_int == 3
replace price_effect_o 	= price_effect_mf_o  	if boundary_type_int == 4

** Give percent only to the correspondent boundary type 
gen price_effect_r_percent 		= price_effect_dXh_r_percent 	if boundary_type_int == 1
replace price_effect_r_percent 	= price_effect_mfXd_r_percent 	if boundary_type_int == 2
replace price_effect_r_percent 	= price_effect_d_r_percent  	if boundary_type_int == 3
replace price_effect_r_percent 	= price_effect_mf_r_percent  	if boundary_type_int == 4

gen price_effect_o_percent 		= price_effect_dXh_o_percent 	if boundary_type_int == 1
replace price_effect_o_percent 	= price_effect_mfXd_o_percent 	if boundary_type_int == 2
replace price_effect_o_percent 	= price_effect_d_o_percent  	if boundary_type_int == 3
replace price_effect_o_percent 	= price_effect_mf_o_percent  	if boundary_type_int == 4

** Create dupac in relaxed and strict zones to inlcude in final table 
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen dupac_relax  = mean_dupac[1]
bysort station_id boundary_type_int: gen dupac_strict = mean_dupac[2]
order dupac_relax dupac_strict, after(mean_dupac)

** Create rent in relaxed and strict zones to inlcude in final table 
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen rent_relax  = mean_rent[1]
bysort station_id boundary_type_int: gen rent_strict = mean_rent[2]
order rent_relax rent_strict, after(mean_rent)

** Create price in relaxed and strict zones to inlcude in final table 
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen price_relax  = mean_saleprice[1]
bysort station_id boundary_type_int: gen price_strict = mean_saleprice[2]
order price_relax price_strict, after(mean_saleprice)

** Variable to see if the coefficients are significant
gen coef_sig_r = 0
	replace coef_sig_r = 1 if (boundary_type_int == 1 & du_he_sig_r == 1) | (boundary_type_int == 2 & du_mf_sig_r == 1) | (boundary_type_int == 3 & du_sig_r == 1) | (boundary_type_int == 4 & mf_sig_r == 1) 
gen coef_sig_o = 0
	replace coef_sig_o = 1 if (boundary_type_int == 1 & du_he_sig_o == 1) | (boundary_type_int == 2 & du_mf_sig_o == 1) | (boundary_type_int == 3 & du_sig_o == 1) | (boundary_type_int == 4 & mf_sig_o == 1) 

** Gen coeff of interaction to see if it's = 0
gen interaction_r = 0
	replace interaction_r = 1 if (boundary_type_int == 1 & duXhe_dXh_r == 0) | (boundary_type_int ==2 & duXmf_dXmf_r == 0) 
gen interaction_o = 0
	replace interaction_o = 1 if (boundary_type_int == 1 & duXhe_dXh_o == 0) | (boundary_type_int ==2 & duXmf_dXmf_o == 0) 
	
	
* Recode effects to 0 if missing in order to calculate averages
recode price_effect_r price_effect_o price_effect_r_percent price_effect_o_percent (. = 0)
 
sort station_id boundary_type_int side_int 
export excel "$dir\values_prices_station_C2.xls", firstrow(variables) replace
save "$dir\values_prices_station_all_C2.dta", replace

*** Get stations labels to plug in the collapse
local stations_name: variable label name
label save using "$dir\labels_C2.do", replace

* Save the table with values
preserve
collapse (mean) name county_fip dupac_relax dupac_strict mean_rent rent_relax rent_strict mean_saleprice price_relax price_strict coef_sig_r interaction_r price_effect_r price_effect_r_percent coef_sig_o interaction_o price_effect_o price_effect_o_percent, by (station_id boundary_type_int)
do "$dir\labels.do"
label value name name
label define county_fip 1 "Inner Core" 2 "Regional Urban" 3 "Mature Suburbs"
label value  county_fip county_fip
export excel "$dir\values_prices_station_C2.xls", firstrow(variables) replace
save "$dir\values_prices_station_C2.dta", replace
restore

*** Get the data of values by station (units+prices)
use "$dir\values_prices_station_C2.dta", clear
merge n:n station_id using "$dir\values_units_station_C2.dta", nogen

merge 1:1 station_id boundary_type_int using "$dir\only_du\values_station_only_du_0.2_C1.dta"
drop _merge 
export excel "$dir\final\values_station_new_C2.xls", replace firstrow(variables)

*/

****************************************************************************************************************************************************************************************************************************
****************************************************************************************************************************************************************************************************************************

////////////////////////////////////////////////////////////////////////////////
//			  Means by town
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
*		A.	Units 
********************************************************************************

*use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\means_clean_town.dta", clear

/*
merge n:n county_fip using "$dir\spatial_units_coef.dta"
drop if _merge==2
drop _merge
*/
 
*-------------------------------------------------------------------------------
*	Calculations
*-------------------------------------------------------------------------------

use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\postQJE_Spatial_Heterogeneity_mtlines_2022-10-14\postQJE_spatial_unit_coeff_MAPCdefinition.dta", clear

* Keep only linear coefficient for 0.20 miles + linear coefficient for 0.02 miles for only du boundaries
keep *_20_x1 *_2_x1 county_fip
* Drop standard errors
drop *_se_* *_s_*
* Drop coefficients for 1956
drop *_u56_*

drop dupac_coeff_u18_c_20_x1 t_dupac_coeff_u18_c_20_x1 dupac_dXh_c_u18_c_2_x1 height_dXh_c_u18_c_2_x1 duXhe_dXh_c_u18_c_2_x1 mf_dXmf_c_u18_c_2_x1 mf_coeff_u18_c_2_x1 t_dupac_dXh_c_u18_c_2_x1 t_height_dXh_c_u18_c_2_x1 t_duXhe_dXh_c_u18_c_2_x1 t_dupac_dXmf_c_u18_c_2_x1 t_mf_dXmf_c_u18_c_2_x1 t_duXmf_dXmf_c_u18_c_2_x1 t_mf_coeff_u18_c_2_x1 dupac_dXmf_c_u18_c_2_x1 duXmf_dXmf_c_u18_c_2_x1

*Rename variables to make it simpler
renvars *, subst(_c_u18_c_20_x1)
renvars *, subst(_u18_c_20_x1)
*renvars *, subst(_c_u18_c_2_x1)
renvars *, subst(_u18_c_2_x1)
renvars *, subst(_coeff)


* Generate indicators of when coefficients are significants
gen du_sig = 1 		if abs(t_dupac) > 1.645 
gen du_he_sig = 1 	if (abs(t_dupac_dXh) > 1.645 | abs(t_height_dXh) > 1.645 | abs(t_duXhe_dXh) > 1.645)
gen du_mf_sig = 1 	if (abs(t_dupac_dXmf) > 1.645 | abs(t_mf_dXmf) > 1.645 | abs(t_duXmf_dXmf) > 1.645)
gen mf_sig = 1 		if abs(t_mf) > 1.645 

tempfile spatial_units_coef
save `spatial_units_coef', replace

*save ${dir}spatial_units_coef.dta, replace

* Now, we want to merge this data set with the coefficients data set, using 
* counties/comunities as the merger variable. 
use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\means_clean_town.dta", clear

*use "$dir\means_clean_town.dta"
merge n:n county_fip using `spatial_units_coef'
drop _merge
encode station_name, gen(name)
encode def_name, gen(type)

*dorp regional urban
drop if county_fip == 2


*-------------------------------------------------------------------------------
*	Calculations
*-------------------------------------------------------------------------------

drop if station_id == .

* Generate effect variables
gen 	unit_effect_mf		= 0 if boundary_type_int == 4	
gen 	unit_effect_mf_percent = 0 if boundary_type_int == 4
gen 	unit_effect_d		= 0 if boundary_type_int == 3
gen 	unit_effect_d_percent = 0 if boundary_type_int == 3
gen 	unit_effect_dXmf 	= 0 if boundary_type_int == 2
gen 	unit_effect_dXmf_percent = 0 if boundary_type_int == 2
gen 	unit_effect_dXh 	= 0 if boundary_type_int == 1
gen 	unit_effect_dXh_percent = 0 if boundary_type_int == 1

*Reduce one order of height
replace mean_height = mean_height/10

* Create a variable indicating the relaxed height for the restricted rows

sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen 	relaxed_height = mean_height if side_int == 1
bysort station_id boundary_type_int: replace 	relaxed_height = relaxed_height[1] if side_int==2
order relaxed_height, after(mean_height)

* Calculate effects

* dupac 
replace unit_effect_d = max(0,(15 - mean_dupac)) * dupac / mean_units	if (du_sig == 1 & boundary_type_int==3)
replace unit_effect_d = . 		if (mean_units == . & boundary_type_int==3)
replace unit_effect_d_percent = unit_effect_d * mean_units if (du_sig == 1 & boundary_type_int==3)

* mf
replace unit_effect_mf = mf / mean_units 	if (mf_sig == 1 & boundary_type_int==4)
replace unit_effect_mf = . 					if (mean_units == . & boundary_type_int==4)
replace unit_effect_mf_percent = unit_effect_mf * mean_units if (mf_sig == 1 & boundary_type_int==4)

* dupac + mf relaxed
replace	unit_effect_dXmf =  max(0,(15 - mean_dupac))*(dupac_dXmf + duXmf_dXmf) / mean_units	if (side_int == 1 & du_mf_sig == 1 & boundary_type_int == 2)
replace unit_effect_dXmf = .	if (mean_units == . & boundary_type_int == 2)
replace unit_effect_dXmf_percent = unit_effect_dXmf * mean_units if (side_int == 1 & du_mf_sig == 1 & boundary_type_int == 2)

* dupac + mf strict
replace	unit_effect_dXmf = [max(0,(15 - mean_dupac))*dupac_dXmf + max(0,(15 - mean_dupac))*duXmf_dXmf + mf_dXmf + duXmf_dXmf * mean_dupac] / mean_units 	if (side_int == 2 & du_mf_sig == 1 & boundary_type_int == 2)
replace unit_effect_dXmf = .	if (mean_units == . & boundary_type_int == 2)
replace unit_effect_dXmf_percent = unit_effect_dXmf * mean_units	if (side_int == 2 & du_mf_sig == 1 & boundary_type_int == 2)

* dupac + he relaxed
replace unit_effect_dXh = max(0,(15 - mean_dupac))*(dupac_dXh + duXhe_dXh*mean_height) / mean_units	if  (side_int == 1 & du_he_sig == 1 & boundary_type_int == 1)
replace unit_effect_dXh = .	if (mean_units == . & boundary_type_int == 1)
replace unit_effect_dXh_percent = unit_effect_dXh * mean_units	if  (side_int == 1 & du_he_sig == 1 & boundary_type_int == 1)

* dupac + mf strict
replace unit_effect_dXh = max(0,(15 - mean_dupac))*(dupac_dXh + duXhe_dXh*mean_height) / mean_units  ///
						if  (side_int == 2 & du_he_sig == 1 & boundary_type_int == 1)
replace unit_effect_dXh  = .	if (mean_units == . & boundary_type_int == 1)
replace unit_effect_dXh_percent = unit_effect_dXh * mean_units	if  (side_int == 2 & du_he_sig == 1 & boundary_type_int == 1)

** Give effect only to the correspondent boundary type 
gen unit_effect = unit_effect_dXh if boundary_type_int ==1
replace unit_effect = unit_effect_dXmf 	if boundary_type_int ==2
replace unit_effect = unit_effect_d	if boundary_type_int ==3
replace unit_effect = unit_effect_mf if boundary_type_int ==4

** Give percent only to the correspondent boundary type
gen unit_effect_percent = unit_effect_dXh_percent if boundary_type_int ==1
replace unit_effect_percent = unit_effect_dXmf_percent 	if boundary_type_int ==2
replace unit_effect_percent = unit_effect_d_percent	if boundary_type_int ==3
replace unit_effect_percent = unit_effect_mf_percent	if boundary_type_int ==4

* Save lables of stations for the collapse
local stations_name: variable label name
label save using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\labels.do", replace

* Save the table with values
preserve
collapse (mean) name county_fip unit_effect unit_effect_percent, by (station_id boundary_type_int)
do "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\labels.do"
label value name name
label define county_fip 1 "Inner Core" 2 "Regional Urban" 3 "Mature Suburbs" 4 "Developing Suburbs"
label value  county_fip county_fip
export excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_units_town_C2.xls", firstrow(variables) replace
save "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_units_town_C2.dta", replace
restore


********************************************************************************
*		B.	Prices 
********************************************************************************

* Merge with means data
use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\means_clean_town.dta", clear
*use "$dir\means_clean_town.dta", clear

merge n:n county_fip using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\postQJE_Spatial_Heterogeneity_mtlines_2022-10-14\postQJE_spatial_price_coeff_MAPCdefinition.dta"
drop _merge
encode station_name, gen(name)
encode def_name, gen(type)



* Keep only linear coefficient for 0.20 miles + linear coefficient for 0.02 miles for only du boundaries
keep *_20_x1 *_2_x1 county_fip
* Drop standard errors
drop *_se_* *_s_*

drop dupac_coeff_renters_c_20_x1 dupac_coeff_owners_c_20_x1 dupac_dXh_c_r_c_2_x1 height_dXh_c_r_c_2_x1 duXhe_dXh_c_r_c_2_x1 dupac_dXh_c_o_c_2_x1 height_dXh_c_o_c_2_x1 duXhe_dXh_c_o_c_2_x1 mf_dXmf_c_r_c_2_x1 duXmf_dXmf_c_r_c_2_x1 dupac_dXmf_c_o_c_2_x1 mf_dXmf_c_o_c_2_x1 duXmf_dXmf_c_o_c_2_x1 t_dupac_dXh_c_r_c_2_x1 t_height_dXh_c_r_c_2_x1 t_dupac_dXh_c_o_c_2_x1 t_height_dXh_c_o_c_2_x1 t_duXhe_dXh_c_o_c_2_x1 t_dupac_dXmf_c_r_c_2_x1 t_mf_dXmf_c_r_c_2_x1 t_duXmf_dXmf_c_r_c_2_x1 t_dupac_dXmf_c_o_c_2_x1 t_mf_dXmf_c_o_c_2_x1 t_duXmf_dXmf_c_o_c_2_x1 t_mf_coeff_renters_c_2_x1 t_mf_coeff_owners_c_2_x1 t_dupac_coeff_renters_c_20_x1 t_dupac_coeff_owners_c_20_x1 mf_coeff_renters_c_2_x1 mf_coeff_owners_c_2_x1 t_duXhe_dXh_c_r_c_2_x1 dupac_dXmf_c_r_c_2_x1


* Rename to see names simpler
renvars *, subst(_c)
renvars *, subst(_20_x1)
renvars *, subst(_2_x1)
renvars *, subst(oeff)
renvars *, subst(enters)
renvars *, subst(wners)

drop if county_fip == .

tempfile spatial_price_coef
save `spatial_price_coef',replace


* Now, we want to merge this data set with the coefficients data set, using 
* counties/comunities as the merger variable. 
use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\means_clean_town.dta", clear

*use "$dir\means_clean_town.dta"
merge n:n county_fip using `spatial_price_coef'
drop _merge
encode station_name, gen(name)
encode def_name, gen(type)

*dorp regional urban
drop if county_fip == 2




*-------------------------------------------------------------------------------
*	Calculations
*-------------------------------------------------------------------------------

* Generate indicators of when coefficients are significants
gen du_sig_o 	= 1 	if (abs(t_dupac_o) > 1.645 & t_dupac_o!=.)
gen du_he_sig_o = 1 	if (abs(t_dupac_dXh_o) > 1.645 &  t_dupac_dXh_o!=.)| (abs(t_height_dXh_o) > 1.645 & t_height_dXh_o!=.) | (abs(t_duXhe_dXh_o) > 1.645 & t_duXhe_dXh_o!=.)
gen du_mf_sig_o = 1 	if (abs(t_dupac_dXmf_o) > 1.645 & t_dupac_dXmf_o!=.) | (abs(t_mf_dXmf_o) > 1.645 & t_mf_dXmf_o!=.) | (abs(t_duXmf_dXmf_o) > 1.645 != t_duXmf_dXmf_o!=.)
gen du_sig_r 	= 1 	if (abs(t_dupac_r) > 1.645 & t_dupac_r!=.)
gen du_he_sig_r = 1 	if (abs(t_dupac_dXh_r) > 1.645 & t_dupac_dXh_r!=.) | (abs(t_height_dXh_r) > 1.645 & t_height_dXh_r !=.) | (abs(t_duXhe_dXh_r) > 1.645 & t_duXhe_dXh_r != .)
gen du_mf_sig_r = 1 	if (abs(t_dupac_dXmf_r) > 1.645 | abs(t_mf_dXmf_r) > 1.645 | abs(t_duXmf_dXmf_r) > 1.645)
gen mf_sig_r 	= 1 	if (abs(t_mf_dXmf_r) > 1.645 & t_mf_dXmf_r!=.)
gen mf_sig_o 	= 1 	if (abs(t_mf_dXmf_o) > 1.645 & t_mf_dXmf_o!=.)
* Reduce one order of height
replace mean_height = mean_height/10

* Create a variable indicating the relaxed height for the restricted rows
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen 		relaxed_height = mean_height if side_int == 1
bysort station_id boundary_type_int: replace 	relaxed_height = relaxed_height[1] if side_int==2
order relaxed_height, after(mean_height)

* Generate effect variables

gen price_effect_dXh_r = 0	if boundary_type_int == 1
gen price_effect_dXh_r_percent = 0 if boundary_type_int == 1
gen price_effect_dXh_o = 0	if boundary_type_int == 1
gen price_effect_dXh_o_percent = 0 if boundary_type_int == 1

gen price_effect_mfXd_r = 0 	if boundary_type_int == 2
gen price_effect_mfXd_r_percent = 0 	if boundary_type_int == 2
gen price_effect_mfXd_o = 0 	if boundary_type_int == 2
gen price_effect_mfXd_o_percent = 0 if boundary_type_int == 2

gen price_effect_d_r = 0	if boundary_type_int == 3
gen price_effect_d_r_percent = 0 if boundary_type_int == 3
gen price_effect_d_o = 0	if boundary_type_int == 3
gen price_effect_d_o_percent = 0 if boundary_type_int == 3

gen price_effect_mf_r = 0	if boundary_type_int == 4
gen price_effect_mf_r_percent = 0 if boundary_type_int == 4
gen price_effect_mf_o = 0	if boundary_type_int == 4
gen price_effect_mf_o_percent = 0 if boundary_type_int == 4

* dupac rent
replace price_effect_d_r = max(0,(15 - mean_dupac)) * dupac_r * mean_rent 	if (du_sig_r == 1 & boundary_type_int == 3)
replace price_effect_d_r = .		if (mean_rent == . & boundary_type_int == 3)
replace price_effect_d_r_percent = (price_effect_d_r * 100) / (mean_rent) if (du_sig_r == 1 & boundary_type_int == 3)

* dupac price
replace price_effect_d_o = max(0,(15 - mean_dupac)) * dupac_o * mean_saleprice 	if (du_sig_o == 1 & boundary_type_int == 3)
replace price_effect_d_o = .		if (mean_saleprice == . & boundary_type_int == 3)
replace price_effect_d_o_percent = (price_effect_d_o * 100) / (mean_saleprice) 	if (du_sig_o == 1 & boundary_type_int == 3)

/* mf rent
replace price_effect_mf_r_r = mf_r * 100 * mean_rent 	if (mf_sig_r == 1 & boundary_type_int == 4)
replace price_effect_mf_r_r = .		if (mean_rent == . & boundary_type_int == 4) 
replace price_effect_mf_r_r_percent = 0  // price_effect_mf_r_r / (100 * mean_rent) */

* mf price
replace price_effect_mf_o = mf_o * mean_saleprice if (mf_sig_o == 1 & boundary_type_int == 4)
replace price_effect_mf_o = .		if (mean_saleprice == . & boundary_type_int == 4)
replace price_effect_mf_o_percent = (price_effect_mf_o * 100) / (mean_saleprice) if (mf_sig_r == 1 & boundary_type_int == 4)

* dupac + height relaxed rent
replace price_effect_dXh_r = max(0,(15 - mean_dupac)) * (dupac_dXh_r + duXhe_dXh_r * mean_height) * mean_rent if (side_int == 1 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)
replace price_effect_dXh_r = . 	if (mean_rent == . & boundary_type_int == 1)
replace price_effect_dXh_r_percent = (price_effect_dXh_r * 100) / (mean_rent) if (side_int == 1 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)

* dupac + height strict rent 
replace price_effect_dXh_r = max(0,(15 - mean_dupac)) * (dupac_dXh_r + duXhe_dXh_r * mean_height) * mean_rent   ///
	if (side_int == 2 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)
replace price_effect_dXh_r = . 	if (mean_rent == . & boundary_type_int == 1)
replace price_effect_dXh_r_percent = (price_effect_dXh_r * 100) / (mean_rent) if (side_int == 2 & du_he_sig_r == 1 & boundary_type_int == 1 & duXhe_dXh_r!=0)

* dupac + height relaxed price
replace price_effect_dXh_o = max(0,(15 - mean_dupac)) * (dupac_dXh_o + duXhe_dXh_o * mean_height) * mean_saleprice if (side_int == 1 & du_he_sig_o == 1 & boundary_type_int == 1  & duXhe_dXh_o!=0)
replace price_effect_dXh_o = . 	if (mean_saleprice == . & boundary_type_int == 1)
replace price_effect_dXh_o_percent = (price_effect_dXh_o * 100) / (mean_saleprice) if (side_int == 1 & du_he_sig_o == 1 & boundary_type_int == 1  & duXhe_dXh_o!=0)

* dupac + height strict price
replace price_effect_dXh_o = max(0,(15 - mean_dupac)) * (dupac_dXh_o + duXhe_dXh_o * mean_height) * mean_saleprice   ///
	if (side_int == 2 & du_he_sig_o == 1 & boundary_type_int == 1 & duXhe_dXh_o!=0)
replace price_effect_dXh_o = . 	if (mean_saleprice == . & boundary_type_int == 1)
replace price_effect_dXh_o_percent = (price_effect_dXh_o * 100) / (mean_saleprice)	if (side_int == 2 & du_he_sig_o == 1 & boundary_type_int == 1 & duXhe_dXh_o!=0)

/* dupac + mf restricted rent
replace price_effect_mfXd_r_r =  max(0,(15 - mean_dupac)) * (duXmf_dXmf_r) * 100 * mean_rent						if (side_int == 1 & du_mf_sig_r == 1 & boundary_type_int == 2)
replace price_effect_mfXd_r_r = . 	if (mean_rent == . & boundary_type_int == 2) 
replace price_effect_mfXd_r_r_percent = 0 // price_effect_mfXd_r_r / (100 * mean_rent) */

/* dupac + mf strict rent
replace price_effect_mfXd_s_r = [max(0,(15 - mean_dupac)) * (dupac_dXmf_r) + mf_dXmf_r + duXmf_dXmf_r * max(0,(15 - mean_dupac)) ] * mean_rent * 100	if (side_int == 2 & du_mf_sig_r == 1 & boundary_type_int == 2)
replace price_effect_mfXd_s_r = . 	if (mean_rent == . & boundary_type_int == 2) 
replace price_effect_mfXd_s_r_percent = 0 // price_effect_mfXd_s_r / (100 * mean_rent) */

* dupac + mf relaxed price
replace price_effect_mfXd_o =  max(0,(15 - mean_dupac)) * (dupac_dXmf_o + duXmf_dXmf_o) * mean_saleprice		if (side_int == 1 & du_mf_sig_o == 1 & boundary_type_int == 2 & mf_dXmf_o!=0) 
replace price_effect_mfXd_o = . 	if (mean_saleprice == . & boundary_type_int == 2)
replace price_effect_mfXd_o_percent = (price_effect_mfXd_o * 100) / (mean_saleprice)	if (side_int == 1 & du_mf_sig_o == 1 & boundary_type_int == 2 & mf_dXmf_o!=0) 

* dupac + mf strict price
replace price_effect_mfXd_o = [max(0,(15 - mean_dupac)) * (dupac_dXmf_o + duXmf_dXmf_o) + mf_dXmf_o + duXmf_dXmf_o * mean_dupac] * mean_saleprice ///
	if (side_int == 2 & du_mf_sig_o == 1 & boundary_type_int == 2 & duXmf_dXmf_o!=0)
replace price_effect_mfXd_o = . 	if (mean_saleprice == . & boundary_type_int == 2)
replace price_effect_mfXd_o_percent = (price_effect_mfXd_o * 100) / (mean_saleprice)	if (side_int == 2 & du_mf_sig_o == 1 & boundary_type_int == 2 & duXmf_dXmf_o!=0)


** Give effect only to the correspondent boundary type 
gen price_effect_r = price_effect_dXh_r if boundary_type_int == 1
replace price_effect_r = price_effect_mfXd_r if boundary_type_int == 2
replace price_effect_r = price_effect_d_r  if boundary_type_int == 3
replace price_effect_r = price_effect_mf_r  if boundary_type_int == 4

gen price_effect_o = price_effect_dXh_o if boundary_type_int == 1
replace price_effect_o = price_effect_mfXd_o if boundary_type_int == 2
replace price_effect_o = price_effect_d_o  if boundary_type_int == 3
replace price_effect_o = price_effect_mf_o  if boundary_type_int == 4

** Give percent only to the correspondent boundary type 
gen price_effect_r_percent = price_effect_dXh_r_percent if boundary_type_int == 1
replace price_effect_r_percent = price_effect_mfXd_r_percent if boundary_type_int == 2
replace price_effect_r_percent = price_effect_d_r_percent  if boundary_type_int == 3
replace price_effect_r_percent = price_effect_mf_r_percent  if boundary_type_int == 4

gen price_effect_o_percent = price_effect_dXh_o_percent if boundary_type_int == 1
replace price_effect_o_percent = price_effect_mfXd_o_percent if boundary_type_int == 2
replace price_effect_o_percent = price_effect_d_o_percent  if boundary_type_int == 3
replace price_effect_o_percent = price_effect_mf_o_percent  if boundary_type_int == 4

** Create dupac in relaxed and strict zones to inlcude in final table 
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen dupac_relax  = mean_dupac[1]
bysort station_id boundary_type_int: gen dupac_strict = mean_dupac[2]
order dupac_relax dupac_strict, after(mean_dupac)

** Create rent in relaxed and strict zones to inlcude in final table 
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen rent_relax  = mean_rent[1]
bysort station_id boundary_type_int: gen rent_strict = mean_rent[2]
order rent_relax rent_strict, after(mean_rent)

** Create price in relaxed and strict zones to inlcude in final table 
sort station_id boundary_type_int side_int
bysort station_id boundary_type_int: gen price_relax  = mean_saleprice[1]
bysort station_id boundary_type_int: gen price_strict = mean_saleprice[2]
order price_relax price_strict, after(mean_saleprice)

** Variable to see if the coefficients are significant
gen coef_sig_r = 0
	replace coef_sig_r = 1 if (boundary_type_int == 1 & du_he_sig_r == 1) | (boundary_type_int == 2 & du_mf_sig_r == 1) | (boundary_type_int == 3 & du_sig_r == 1) | (boundary_type_int == 4 & mf_sig_r == 1) 
gen coef_sig_o = 0
	replace coef_sig_o = 1 if (boundary_type_int == 1 & du_he_sig_o == 1) | (boundary_type_int == 2 & du_mf_sig_o == 1) | (boundary_type_int == 3 & du_sig_o == 1) | (boundary_type_int == 4 & mf_sig_o == 1) 

** Recode effects to 0 if missing in order to calculate averages
recode price_effect_r price_effect_o price_effect_r_percent price_effect_o_percent (. = 0)

** Gen coeff of interaction to see if it's = 0
gen interaction_r = 0
	replace interaction_r = 1 if (boundary_type_int == 1 & duXhe_dXh_r == 0) | (boundary_type_int ==2 & duXmf_dXmf_r == 0) 
gen interaction_o = 0
	replace interaction_o = 1 if (boundary_type_int == 1 & duXhe_dXh_o == 0) | (boundary_type_int ==2 & duXmf_dXmf_o == 0) 
	
sort station_id boundary_type_int side_int 
export excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_prices_town_C2.xls", firstrow(variables) replace

local stations_name: variable label name
label save using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\labels.do", replace

* Save the table with values
preserve
collapse (mean) name county_fip dupac_relax dupac_strict mean_rent rent_relax rent_strict mean_saleprice price_relax price_strict coef_sig_r interaction_r price_effect_r price_effect_r_percent coef_sig_o interaction_o price_effect_o price_effect_o_percent, by (station_id boundary_type_int)
do "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\labels.do"
label value name name
label define county_fip 1 "Inner Core" 2 "Regional Urban" 3 "Mature Suburbs" 4 "Developing Suburbs"
label value  county_fip county_fip
export excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_prices_town_C2.xls", firstrow(variables) replace
save "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_prices_town_C2.dta", replace
restore

use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_prices_town_C2.dta", clear

merge n:n station_id using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_units_town_C2.dta", nogen

export excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_town_new_C2.xls", replace firstrow(variables)

/*
merge 1:1 station_id boundary_type_int using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\only_du\values_town_only_du_0.2_C1.dta"
drop _merge 
export excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\final\values_town_new_C2.xls", replace firstrow(variables)
*/

	
