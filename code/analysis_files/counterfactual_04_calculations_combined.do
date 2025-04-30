********************************************************************************
*			Policy value calculations for:
*		How to Increase Housing Affordability? Understanding
*		  Local Deterrents to Building Multifamily Housing
*	
********************************************************************************

********************************************************************************
* This dofile 
*-imports the means calculated and prepare the data set to be merged with data on 
*coefficients
*-calculates policy numbers
*- plots them on a  map
********************************************************************************

clear 
set more off 

global dir "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\REStat Replication Package\analysis_files_short\counterfactual\Int"
global code_dir "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\REStat Replication Package\analysis_files_short\counterfactual"

********************************************************************************
* Means by town
********************************************************************************

*** First, prepeare the sample getting the cousub match
clear
use "$dir\postQJE_means_town_train_stations.dta", clear

*drop the empty values
drop if mean_height == . 

*keep only particular boundaries with one station nearby 
*keep if boundary_n == 1 /*only stations with one boundary within 0.5 miles*/
keep if boundary_type == "du_he" | boundary_type == "mf_du" | boundary_type == "only_du"  | boundary_type == "only_mf"

*--> 194 to 185 stations


destring station_id, replace
encode boundary_type, gen(boundary_type_int)
order  boundary_type_int, after(boundary_type)
encode side, gen(side_int)
order  side_int, after(side)
encode cousub_name, gen(town)


*Count the number of cases by station by boundary, drop if only one

bysort station_id boundary_type_int: gen number = _N

*save stops that don't have both sides for completeness
preserve

keep if number==1
save "$dir\stations_without_two_sides.dta", replace

restore




drop if number == 1     /*for these boundaries we don't have one of the two sides*/



*--> now 148 stations, don't have anything on the strict/relaxed side

* Rename to merge 
rename def_1 county_fip

*149 unique stations

save "$dir\means_clean_town.dta", replace

clear

/*
sort station_id side_int boundary_type
keep station_id side_int boundary_type mean_height	mean_dupac	prop_n	mean_units	mean_saleprice	mean_rent
export excel "$dir\means_clean_town_sample.xls", firstrow(variable) replace
*/


********************************************************************************
*calculate policy numbers*******************************************************
********************************************************************************

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

use "$dir\spatial_unit_coeff_MAPCdefinition.dta", clear

drop if county == ""
reshape wide *u18* , i(county_fip) j(spec) string

* Keep only linear coefficient for 0.20 miles + linear coefficient for 0.02 miles for only du boundaries
keep *_20_x1 *_2_x1 county_fip
* Drop standard errors
drop *_se_* *_s_*
* Drop coefficients for 1956
*drop *_u56_*

*drop dupac_coeff_u18_c_20_x1 t_dupac_coeff_u18_c_20_x1 


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
use "$dir\means_clean_town.dta", clear

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
label save using "$code_dir\labels.do", replace

* Save the table with values
preserve
collapse (mean) name county_fip unit_effect unit_effect_percent, by (station_id boundary_type_int)
do "$code_dir\labels.do"
label value name name
label define county_fip 1 "Inner Core" 2 "Regional Urban" 3 "Mature Suburbs" 4 "Developing Suburbs"
label value  county_fip county_fip
export excel "$dir\values_units_town_C2.xls", firstrow(variables) replace
save "$dir\values_units_town_C2.dta", replace
restore


********************************************************************************
*		B.	Prices 
********************************************************************************

use "$dir\spatial_price_coeff_MAPCdefinition.dta", clear

drop if county == ""
reshape wide *_c , i(county_fip) j(spec) string

merge n:n county_fip using "$dir\means_clean_town.dta"
drop _merge
encode station_name, gen(name)
encode def_name, gen(type)


* Keep only linear coefficient for 0.20 miles + linear coefficient for 0.02 miles for only du boundaries
keep *_20_x1 *_2_x1 county_fip
* Drop standard errors
drop *_se_* *_s_*

drop dupac_coeff_renters_c_20_x1 dupac_coeff_owners_c_20_x1 dupac_dXh_c_r_c_2_x1 height_dXh_c_r_c_2_x1 duXhe_dXh_c_r_c_2_x1 dupac_dXh_c_o_c_2_x1 height_dXh_c_o_c_2_x1 duXhe_dXh_c_o_c_2_x1   dupac_dXmf_c_o_c_2_x1 mf_dXmf_c_o_c_2_x1 duXmf_dXmf_c_o_c_2_x1 t_dupac_dXh_c_r_c_2_x1 t_height_dXh_c_r_c_2_x1 t_dupac_dXh_c_o_c_2_x1 t_height_dXh_c_o_c_2_x1 t_duXhe_dXh_c_o_c_2_x1 t_dupac_dXmf_c_o_c_2_x1 t_mf_dXmf_c_o_c_2_x1 t_duXmf_dXmf_c_o_c_2_x1  t_mf_coeff_owners_c_2_x1 t_dupac_coeff_renters_c_20_x1 t_dupac_coeff_owners_c_20_x1  mf_coeff_owners_c_2_x1 t_duXhe_dXh_c_r_c_2_x1 


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
use "$dir\means_clean_town.dta", clear

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


* mf price
replace price_effect_mf_o = mf_o * mean_saleprice if (mf_sig_o == 1 & boundary_type_int == 4)
replace price_effect_mf_o = .		if (mean_saleprice == . & boundary_type_int == 4)
replace price_effect_mf_o_percent = (price_effect_mf_o * 100) / (mean_saleprice) if (mf_sig_o == 1 & boundary_type_int == 4)

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
	replace coef_sig_r = 1 if (boundary_type_int == 1 & du_he_sig_r == 1) |  (boundary_type_int == 3 & du_sig_r == 1) 
gen coef_sig_o = 0
	replace coef_sig_o = 1 if (boundary_type_int == 1 & du_he_sig_o == 1) | (boundary_type_int == 2 & du_mf_sig_o == 1) | (boundary_type_int == 3 & du_sig_o == 1) | (boundary_type_int == 4 & mf_sig_o == 1) 

** Recode effects to 0 if missing in order to calculate averages
recode price_effect_r price_effect_o price_effect_r_percent price_effect_o_percent (. = 0)

** Gen coeff of interaction to see if it's = 0
gen interaction_r = 0
	replace interaction_r = 1 if (boundary_type_int == 1 & duXhe_dXh_r == 0)  
gen interaction_o = 0
	replace interaction_o = 1 if (boundary_type_int == 1 & duXhe_dXh_o == 0) | (boundary_type_int ==2 & duXmf_dXmf_o == 0) 
	
sort station_id boundary_type_int side_int 
export excel "$dir\values_prices_town_C2.xls", firstrow(variables) replace

local stations_name: variable label name
label save using "$code_dir\labels.do", replace

* Save the table with values
preserve
collapse (mean) name county_fip dupac_relax dupac_strict mean_rent rent_relax rent_strict mean_saleprice price_relax price_strict coef_sig_r interaction_r price_effect_r price_effect_r_percent coef_sig_o interaction_o price_effect_o price_effect_o_percent, by (station_id boundary_type_int)
do "$code_dir\labels.do"
label value name name
label define county_fip 1 "Inner Core" 2 "Regional Urban" 3 "Mature Suburbs" 4 "Developing Suburbs"
label value  county_fip county_fip
export excel "$dir\values_prices_town_C2.xls", firstrow(variables) replace
save "$dir\values_prices_town_C2.dta", replace
restore

use "$dir\values_prices_town_C2.dta", clear

merge n:n station_id using "$dir\values_units_town_C2.dta", nogen

export excel "$dir\values_town_new_C2.xls", replace firstrow(variables)


***************************************************************************
*Prepare for map
***************************************************************************

*get regulation means for units
clear 

*Counterfactual 1: chapter 40a
import excel "$dir\values_town_new_C2.xls", sheet("Sheet1") firstrow
by station_id boundary_type_int, sort: gen nvals = _n == 1
keep if nvals == 1
drop nvals 
keep station_id boundary_type_int dupac_relax dupac_strict
encode boundary_type_int, gen(bla)
drop boundary_type_int
rename bla boundary_type_int

tempfile reg_mean
save `reg_mean', replace

*UNITS SEPARATELY

clear 
set more off 

*Counterfactual 1: chapter 40a
use "$dir\values_units_town_C2.dta"

*recast str7 boundary_type_int

merge m:1 station_id boundary_type_int using `reg_mean'

drop if _merge == 2

drop if station_id == .
drop if station_id == 227 & boundary_type_int == 2    
/*this observation is entirely missing*/
drop if station_id == 269 & boundary_type_int == 1
/*this observation is entirely missing*/

replace unit_effect_percent = 0 if unit_effect<0
replace unit_effect = 0 if unit_effect<0


*find stations that show up multiple times 
by station_id, sort: gen num_station_regs = _N 
tab num_station_regs 

*generate indicator for already above 15 dupac 
gen above_15 = dupac_relax>15 & dupac_strict>15

replace unit_effect = . if above_15==1 & unit_effect == 0 & (boundary_type_int == 1  | boundary_type_int == 3)      /*duhe and onlydu cannot have effects if above 15 already*/
replace unit_effect_percent = . if above_15==1 & unit_effect_percent == 0 & (boundary_type_int == 1  | boundary_type_int == 3)


drop num_station_regs
by station_id, sort: gen num_station_regs = _N  
tab num_station_regs

drop if num_station_regs >1 & unit_effect == 0 & above_15==0

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  
tab num_station_regs

*some stops are in the data multiple times
by name boundary_type_int, sort: gen nvals = _n == 1
drop if nvals == 0 
drop nvals 


drop num_station_regs
by station_id, sort: gen num_station_regs = _N  
tab num_station_regs


*for remaining multiples, drop above 15 if at least one is not above 15
*see if there is any negative price effect
by name, sort: gen num_stations = _N
by name, sort: egen total_above = total(above_15)
gen frac_above = total_above/num_stations

drop if frac_above>0 & frac_above<1 & above_15==1 & num_station_regs>1
drop num_station_regs
by station_id, sort: gen num_station_regs = _N  
tab num_station_regs


*if all types are above 15 keep one at random 
by name, sort: gen nvals = _n == 1
drop if nvals == 0 & frac_above == 1

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  
tab num_station_regs

rename name STATION


export delimited using "$dir\units_40a.csv", replace




*PRICES

clear 
set more off 

*Counterfactual 1: chapter 40a
import excel "$dir\values_town_new_C2.xls", sheet("Sheet1") firstrow

drop if county_fip == "4"
drop if station_id == .
drop if station_id == 227 & boundary_type_int == "mf_du"    
/*this observation is entirely missing*/
drop if station_id == 269 & boundary_type_int == "du_he"
/*this observation is entirely missing*/

replace unit_effect_percent = 0 if unit_effect<0
replace unit_effect = 0 if unit_effect<0


*find stations that show up multiple times 
by station_id, sort: gen num_station_regs = _N  

*generate indicator for already above 15 dupac 
gen above_15 = dupac_relax>15 & dupac_strict>15



replace price_effect_r = . if above_15==1 &price_effect_r == 0 & (boundary_type_int == "only_du"  | boundary_type_int == "du_he")    /*possible to have positive effects through allowing mf*/
replace price_effect_r_percent = . if above_15==1 & price_effect_r_percent==0 & (boundary_type_int == "only_du"  | boundary_type_int == "du_he")    
replace price_effect_o = . if above_15==1 & price_effect_o == 0 & (boundary_type_int == "only_du"  | boundary_type_int == "du_he")    
replace price_effect_o_percent = . if above_15==1 & price_effect_o_percent==0 & (boundary_type_int == "only_du"  | boundary_type_int == "du_he")    
replace unit_effect = . if above_15==1 & unit_effect == 0 & (boundary_type_int == "only_du"  | boundary_type_int == "du_he")   
replace unit_effect_percent = . if above_15==1 & unit_effect_percent==0 & (boundary_type_int == "only_du"  | boundary_type_int == "du_he")    


*drop if no reg type has an effect and dupac below 15
drop if num_station_regs == 2 & price_effect_r == 0 & price_effect_o == 0 & unit_effect == 0 & above_15==0

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  

*some stops are in the data multiple times
by name boundary_type_int, sort: gen nvals = _n == 1
drop if nvals == 0 
drop nvals 


drop num_station_regs
by station_id, sort: gen num_station_regs = _N  


*for remaining multiples, focus on negative price effects
*see if there is any negative price effect
by name, sort: gen any_negative = price_effect_o<0 | price_effect_r<0
by name, sort: egen max_neg = max(any_negative)
drop any_negative

drop if num_station_regs >1 & price_effect_o>0 & price_effect_o!=. & max_neg==1

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  

*if all types are above 15 keep one at random 
by name, sort: gen num_stations = _N
by name, sort: egen total_above = total(above_15)
gen frac_above = total_above/num_stations

by name, sort: gen nvals = _n == 1
drop if nvals == 0 & frac_above == 1

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  


*among remaining duplicates, keep the one with the largest negative effects
by name, sort: egen max_price = min(price_effect_o_percent)
by name, sort: egen max_rent = min(price_effect_r_percent)

drop if num_station_regs>1 & price_effect_o_percent!=max_price & price_effect_r_percent!=max_rent

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  


*if rent effects are also 0, drop again
drop if num_station_regs>1 & price_effect_o_percent!=max_price & max_rent == 0

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  


rename name STATION


export delimited using "$dir\prices_units_40a.csv", replace




********************************************************************************
*Making maps
********************************************************************************
********************************************************************************
** load and tempsave the city/town outlines for MAPC area
********************************************************************************
* load city/town shapefile
use "C:/Users/User/Dropbox/Boston Affordable Housing Project (Aradhya, Nick)/bosfed_files/Bos_Fed_NonWarren_Data_July2024/originals/cb_2018_25_cousub_500k.dta", clear

* correct town names for merge
gen MUNI = NAME
	replace MUNI = upper(MUNI)
	replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
	replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
	replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
	replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

* merge on mapc town list 
merge 1:1 MUNI using "C:/Users/User/Dropbox/Boston Affordable Housing Project (Aradhya, Nick)/bosfed_files/working_paper/data/geocoding/MAPC_town_list.dta",

	* validate merge results
	sum _merge
	
	/*
	assert `r(N)' ==  351
	assert `r(sum_w)' ==  351
	assert `r(mean)' ==  1.575498575498576
	assert `r(Var)' ==  .8221408221408221
	assert `r(sd)' ==  .9067198145738418
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  553
	*/
	
	keep if _merge == 3
	drop _merge


* tag unused mapc municipalities
gen muninotused = 0

local city "BELLINGHAM" ///
		"BRAINTREE" ///
		"BURLINGTON" ///
		"CHELSEA" ///
		"CONCORD" ///
		"DANVERS" ///
		"HAMILTON" ///
		"HINGHAM" ////
		"IPSWICH" ///
		"LYNNFIELD" ///
		"MEDFORD" ///
		"MELROSE" ///
		"NATICK" ///
		"NORWOOD" ///
		"PEABODY" ///
		"QUINCY" ///
		"READING" ///
		"WATERTOWN" ///
		"WENHAM" ///
		"WILMINGTON" ///
		"WINCHESTER" ///
		"WOBURN"
		
foreach c in "`city'" {
	display "Dropping `c'..."	
	replace muninotused = 1 if MUNI=="`c'"
}

keep _ID MUNI muninotused ALAND _CX _CY COUNTYFP

* merge on city/town coordinates
merge 1:m _ID using "C:/Users/User/Dropbox/Boston Affordable Housing Project (Aradhya, Nick)/bosfed_files/Bos_Fed_NonWarren_Data_July2024/originals/cb_2018_25_cousub_500k_shp.dta", keepusing(_X _Y shape_order)
	
	* validate merge
	sum _merge
	
	/*
	assert `r(N)' ==  19039
	assert `r(sum_w)' ==  19039
	assert `r(mean)' ==  2.34413572141394
	assert `r(Var)' ==  .2257181822300592
	assert `r(sd)' ==  .4750980764327079
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  44630
	*/
	
	drop if _merge == 2
	drop _merge

sort _ID shape_order

tempfile outline
save `outline', replace


********************************************************************************
** load list of all train stops
********************************************************************************
import delimited "C:/Users/User/Dropbox/Boston Affordable Housing Project (Aradhya, Nick)/bosfed_files/Bos_Fed_NonWarren_Data_July2024/train_stops/all_stations.csv", clear

keep station_id station_name station_lat station_lon

tempfile stations
save `stations', replace


********************************************************************************
** load list of train stops without enough data
********************************************************************************
use "$dir/stations_without_two_sides.dta", clear

drop if def_name == "Regional Urban"

bysort station_id: keep if _n == 1

keep station_id station_name
order station_id station_name

gen no_two_sides = 1

tempfile no_two_sides
save `no_two_sides', replace


********************************************************************************
** load the prices/rents effects data
/* Note: the unit effects data are incorrect in this file and so we should use
the units_40a.csv file for those instead */
********************************************************************************
import delimited "$dir/prices_units_40a.csv", clear

merge 1:1 station_id using `no_two_sides'
	replace no_two_sides = . if _merge == 3 
	drop _merge
	
merge 1:1 station_id using `stations'
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** clear maps for prices/rents
********************************************************************************
* rent effect mapping variables
gen map_var_r = .

* n/a rent values
replace map_var_r = 1 if no_two_sides == 1 					// <-- no two sides
replace map_var_r = 2 if price_effect_r_percent == . & no_two_sides != 1 	// <-- ch40a has no impact
replace map_var_r = 3 if price_effect_r_percent == 0 				// <-- true zero/insignficant value

* positive rent effect values
replace map_var_r = 11 if map_var_r == . & (price_effect_r_percent > 0 & price_effect_r_percent < 5)
replace map_var_r = 12 if map_var_r == . & (price_effect_r_percent >= 5 & price_effect_r_percent < 10)
replace map_var_r = 13 if map_var_r == . & (price_effect_r_percent >= 10)

* negative rent effect values
replace map_var_r = -11 if map_var_r == . & (price_effect_r_percent < 0 & price_effect_r_percent > -5)
replace map_var_r = -12 if map_var_r == . & (price_effect_r_percent <= -5 & price_effect_r_percent > -10)
replace map_var_r = -13 if map_var_r == . & (price_effect_r_percent <= -10)	


** prices effect mapping variable
gen map_var_o = .

* n/a price values
replace map_var_o = 1 if no_two_sides == 1 					// <-- no two sides
replace map_var_o = 2 if price_effect_o_percent==. & no_two_sides!=1 		// <-- ch40a has no impact
replace map_var_o = 3 if price_effect_o_percent==0 				// <-- true zero/insignficant value

* positive price effect values
replace map_var_o = 11 if map_var_o==. & (price_effect_o_percent>0 & price_effect_o_percent<5)
replace map_var_o = 12 if map_var_o==. & (price_effect_o_percent>=5 & price_effect_o_percent<10)
replace map_var_o = 13 if map_var_o==. & (price_effect_o_percent>=10)

* negative price effect values
replace map_var_o = -11 if map_var_o==. & (price_effect_o_percent<0 & price_effect_o_percent>-5)
replace map_var_o = -12 if map_var_o==. & (price_effect_o_percent<=-5 & price_effect_o_percent>-10)
replace map_var_o = -13 if map_var_o==. & (price_effect_o_percent<=-10)	

tempfile prices
save `prices', replace


********************************************************************************
** load units effect data
********************************************************************************
import delimited "$dir/units_40a.csv", clear

drop _merge

merge 1:1 station_id using `no_two_sides'
	replace no_two_sides = . if _merge == 3 
	drop _merge
	
merge 1:1 station_id using `stations'
	drop if _merge == 2
	drop _merge

* unit effect mapping variable
gen map_var_u = .

* n/a unit effect values
replace map_var_u  = 1 if no_two_sides == 1 					// <-- no two sides
replace map_var_u = 2 if unit_effect == . & no_two_sides != 1 & above_15 == 1	// <-- ch40a has no impact
replace map_var_u = 3 if unit_effect == 0 					// <-- true zero/insignficant value

* positive unit effect values
replace map_var_u = 11 if map_var_u==. & (unit_effect>0 & unit_effect<.15)
replace map_var_u = 12 if map_var_u==. & (unit_effect>=.15 & unit_effect<.30)
replace map_var_u = 13 if map_var_u==. & (unit_effect>=.3)

merge 1:1 station_id using `prices'
	drop if _merge == 1

replace map_var_u = 1 if map_var_r == 1 & map_var_o == 1
replace map_var_u = 2 if map_var_r == 2 & map_var_o == 2
replace map_var_u = 3 if (map_var_u == 1 | map_var_u == 2 | map_var_u == .) ///
			& ((map_var_r>=11 | map_var_r <=-11) | (map_var_o>=11 | map_var_o<=-11))
			
replace map_var_u = 3 if map_var_r == 3 & map_var_o == 3 & (map_var_u==2 | map_var_u == 1)

keep station_id station station_lat station_lon *_effect* map_var_* _merge
order station_id station station_lat station_lon station *_effect* map_var_* _merge

			
* merge on city/town outline
append using `outline',
sort _ID shape_order



********************************************************************************
** rents maps
********************************************************************************
* create rent map
local LEGEND 2 "No boundary near station" ///
		3 "Regulation already lower than Chapter 40A" ///
		7 "0% (null effect)" ///
		99 "" ///
		6 "< 0% to -4.99%" ///
		5 "-5% to -9.99%" ///
		4 "</= -10%" ///
		99 "" ///
		8 "> 0% to 4.99%" ///
		9 "5% to 9.99%" ///
		10 ">/= 10%"

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_r==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_r==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_r==-13, msymbol(o) msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_r==-12, msymbol(o) msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_r==-11, msymbol(o) msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_r==3, msymbol(o) msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_r==11, msymbol(o) msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_r==12, msymbol(o) msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_r==13, msymbol(o)  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:Monthly Rent}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(rents, replace)	;	
#delimit cr

graph save rents "$dir/station_rents_map.gph", replace
graph export "$dir/station_rents_map.pdf", replace name(rents)

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_r==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_r==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_r==-13, msymbol(o) msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_r==-12, msymbol(o) msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_r==-11, msymbol(o) msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_r==3, msymbol(o) msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_r==11, msymbol(o) msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_r==12, msymbol(o) msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_r==13, msymbol(o)  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(off)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(rents, replace)	;	
#delimit cr

graph save rents "$dir/station_rents_map_noleg.gph", replace
graph export "$dir/station_rents_map_noleg.pdf", replace name(rents)

graph close _all


********************************************************************************
** prices maps
********************************************************************************
* create prices map
local LEGEND 2 "No boundary near station" ///
		3 "Regulation already lower than Chapter 40A" ///
		7 "0% (null effect)" ///
		99 "" ///
		6 "< 0% to -4.99%" ///
		5 "-5% to -9.99%" ///
		4 "</= -10%" ///
		99 "" ///
		8 "> 0% to 4.99%" ///
		9 "5% to 9.99%" ///
		10 ">/= 10%"
		
#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_o==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_o==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_o==-13, msymbol(o) msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_o==-12, msymbol(o) msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_o==-11, msymbol(o) msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_o==3, msymbol(o) msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_o==11, msymbol(o) msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_o==12, msymbol(o) msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_o==13, msymbol(o)  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:Sinlge-family Sales Price}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(prices, replace)	;	
#delimit cr

graph save prices "$dir/station_prices_map.gph", replace
graph export "$dir/station_prices_map.pdf", replace name(prices)

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_o==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_o==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_o==-13, msymbol(o) msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_o==-12, msymbol(o) msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_o==-11, msymbol(o) msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_o==3, msymbol(o) msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_o==11, msymbol(o) msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_o==12, msymbol(o) msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_o==13, msymbol(o)  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(off)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(prices, replace)	;	
#delimit cr

graph save prices "$dir/station_prices_map_noleg.gph", replace
graph export "$dir/station_prices_map_noleg.pdf", replace name(prices)


graph close _all


********************************************************************************
** units maps
********************************************************************************
* create unit effect maps
local LEGEND 2 "No boundary near station" ///
		3 "Regulation already lower than Chapter 40A" ///
		4 "0 (null effect)" ///
		5 "> 0 to .14" ///
		6 ".15 to .29" ///
		7 ">/= .30"
		
#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_u==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_u==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_u==3, msymbol(o) msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_u==11, msymbol(o) msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_u==12, msymbol(o) msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_u==13, msymbol(o)  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
											
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:Units Per Lot}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") title("{bf:# Change in Units}", size(2) pos(11))
		rows() cols(1) size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(units, replace)	;	
#delimit cr

graph save units "$dir/station_units_map.gph", replace
graph export "$dir/station_units_map.pdf", replace name(units)

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_u==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_u==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_u==3, msymbol(o) msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_u==11, msymbol(o) msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_u==12, msymbol(o) msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_u==13, msymbol(o)  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
											
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(off)
	legend( order(" `LEGEND' ") title("{bf:# Change in Units}", size(2) pos(11))
		rows() cols(3) size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(units, replace)	;	
#delimit cr

graph save units "$dir/station_units_map_noleg.gph", replace
graph export "$dir/station_units_map_noleg.pdf", replace name(units)

graph close _all




