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
* This dofile imports the means calculated and prepare the data set to be merged
* with data on coefficients
********************************************************************************

*-------------------------------------------------------------------------------
*	Take the mean values from external files
*-------------------------------------------------------------------------------

*global dir "C:\Users\macha116\Dropbox\PhD\Research\RA_IO_Urban\postQJE_Spatial_ReducedForm_mtlines_2022-09-30\test"
*global dir "C:\Users\maxim\Dropbox\PhD\Research\RA_IO_Urban\postQJE_Spatial_ReducedForm_mtlines_2022-09-30\test"
clear
use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\postQJE_train_station_means_2022-10-05\postQJE_train_station_means.dta", clear 

*keep only particular boundaries with one station nearby 
*keep if boundary_n == 1 /*only stations with one boundary within 0.5 miles*/
keep if boundary_type == "du_he" | boundary_type == "mf_du" | boundary_type == "only_du" | boundary_type == "only_mf"

*--> 194 to 185 stations

destring station_id, replace
encode boundary_type, gen(boundary_type_int)
order  boundary_type_int, after(boundary_type)
encode side, gen(side_int)
order  side_int, after(side)
*Count the number of cases by station by boundary, drop if only one

*gen unit = 1
*bysort station_id boundary_type_int: gen number = sum(unit)
bysort station_id boundary_type_int: gen number = _N
drop if number == 1     /*for these boundaries we don't have one of the two sides*/

*--> now 148 stations, don't have anything on the strict/relaxed side

* Rename to merge 
rename def_1 county_fip

save "$dir\means_clean.dta", replace

sort station_id side_int boundary_type
keep station_id side_int boundary_type mean_height	mean_dupac	prop_n	mean_units	mean_saleprice	mean_rent
export excel "$dir\means_clean_station_sample.xls", firstrow(variable) replace

********************************************************************************
* Means by town
********************************************************************************

*** First, prepeare the sample getting the cousub match
*do "$dir\means_town.do"  --> taken from Maxi
clear
use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Welfare Calculations\Maxi\programs\programs\postQJE_means_town_lvl_tomerge.dta", clear

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
save "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\stations_without_two_sides.dta", replace

restore




drop if number == 1     /*for these boundaries we don't have one of the two sides*/



*--> now 148 stations, don't have anything on the strict/relaxed side

* Rename to merge 
rename def_1 county_fip

*149 unique stations

save "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\means_clean_town.dta", replace

/*
sort station_id side_int boundary_type
keep station_id side_int boundary_type mean_height	mean_dupac	prop_n	mean_units	mean_saleprice	mean_rent
export excel "$dir\means_clean_town_sample.xls", firstrow(variable) replace
*/





