********************************************************************************
*STATION MAP PREP***************************************************************
********************************************************************************
*insignificant results are 0
*results that are missing due to already lax regulations are missing 
*unit effects that are negative set to 0 
*merge only_du results 

/*
clear 
set more off 

*Counterfactual 1: chapter 40a
import excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Welfare Calculations\Maxi\results\counterfactuals_30_10_22\values_town_new_C2.xls", sheet("Sheet1") firstrow

drop if county_fip == "4"
drop if station_id == 227 & boundary_type_int == "mf_du"    /*this observation is entirely missing*/
drop if station_id == 269 & boundary_type_int == "du_he"	/*this observation is entirely missing*/

*merge the only_du results into the others
replace price_effect_r = price_effect_r_only_du if boundary_type_int == "only_du" 
replace price_effect_r_percent = price_effect_r_percent_only_du if boundary_type_int == "only_du" 
replace price_effect_o = price_effect_o_only_du if boundary_type_int == "only_du"
replace price_effect_o_percent = price_effect_o_percent_only_du if boundary_type_int == "only_du"

replace unit_effect_percent = 0 if unit_effect<0
replace unit_effect = 0 if unit_effect<0


*find stations that show up multiple times 
by station_id, sort: gen num_station_regs = _N  /*8 multiples*/

*generate indicator for already above 15 dupac 
gen above_15 = dupac_relax>15 & dupac_strict>15
replace price_effect_r = . if above_15==1 &price_effect_r == 0    /*possible to have positive effects through allowing mf*/
replace price_effect_r_percent = . if above_15==1 & price_effect_r_percent==0
replace price_effect_o = . if above_15==1 & price_effect_o == 0
replace price_effect_o_percent = . if above_15==1 & price_effect_o_percent==0


*drop if no reg type has an effect and dupac below 15
drop if num_station_regs == 2 & price_effect_r == 0 & price_effect_o == 0 & unit_effect == 0 & above_15==0

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*7 multiples*/


*for remaining multiples, focus on negative price effects
drop if num_station_regs == 2 & price_effect_o>0 & price_effect_o!=.

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*6 multiples*/

*south station is still multiple due to spelling, drop one, they are identifcal
drop if station_id == 4

*keep one back bay station 
drop if station_id == 136 | station_id == 283
drop if station_id == 27 & boundary_type_int == "only_du"

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*3 multiples*/

*drop at random
drop if station_id == 165 & boundary_type_int=="only_du"
drop if station_id ==178 & boundary_type_int=="only_du"

drop if station_id == 238 /*somehow duplicated*/
drop if station_id == 208 /*somehow duplicated*/

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*1 multiples*/

drop if station_id == 179 & boundary_type_int=="du_he"

rename name STATION


export delimited using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Welfare Calculations\prices_units_40a.csv", replace


*Counterfactual 2
clear

import excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Welfare Calculations\Maxi\results\counterfactuals_30_10_22\values_town_new_C3.xls", sheet("Sheet1") firstrow

drop if county_fip == "4"
drop if station_id == 227 & boundary_type_int == "mf_du"    /*this observation is entirely missing*/
drop if station_id == 269 & boundary_type_int == "du_he"	/*this observation is entirely missing*/

*merge the only_du results into the others
replace price_effect_r = price_effect_r_only_du if boundary_type_int == "only_du" 
replace price_effect_r_percent = price_effect_r_percent_only_du if boundary_type_int == "only_du" 
replace price_effect_o = price_effect_o_only_du if boundary_type_int == "only_du"
replace price_effect_o_percent = price_effect_o_percent_only_du if boundary_type_int == "only_du"

replace unit_effect_percent = 0 if unit_effect<0
replace unit_effect = 0 if unit_effect<0


*find stations that show up multiple times 
by station_id, sort: gen num_station_regs = _N  /*8 multiples*/

*drop if one reg type has no effect 
drop if num_station_regs == 2 & price_effect_r == 0 & price_effect_o == 0 & unit_effect == 0

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*5 multiples*/


*back bay is in the data 6 times, keep only 1
drop if station_id == 136 | station_id == 283
drop if station_id == 27 & boundary_type_int == "only_du"

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*2 multiples*/

*for remaining multiples, focus on negative price effects
drop if num_station_regs == 2 & price_effect_o>0

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  /*0 multiples*/

*south station is still multiple due to spelling, drop one, they are identifcal
drop if station_id == 4

rename name STATION

drop if station_id == 238 /*somehow duplicated*/
drop if station_id == 208 /*somehow duplicated*/

drop num_station_regs
by station_id, sort: gen num_station_regs = _N  

sort STATION

export delimited using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Welfare Calculations\prices_units_cf2.csv", replace
*/


*****
*NEW*
*****

*get regulation means for units
clear 
set more off 

*Counterfactual 1: chapter 40a
import excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_town_new_C2.xls", sheet("Sheet1") firstrow
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
use "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_units_town_C2.dta"

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


export delimited using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\units_40a.csv", replace




*PRICES

clear 
set more off 

*Counterfactual 1: chapter 40a
import excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_town_new_C2.xls", sheet("Sheet1") firstrow

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


export delimited using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\prices_units_40a.csv", replace


*Counterfactual 2
clear

import excel "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Amrita Welfare\values_town_new_C3.xls", sheet("Sheet1") firstrow

drop if county_fip == "4"
drop if station_id == . 
drop if station_id == 227 & boundary_type_int == "mf_du"    /*this observation is entirely missing*/
drop if station_id == 269 & boundary_type_int == "du_he"	/*this observation is entirely missing*/

replace unit_effect_percent = 0 if unit_effect<0
replace unit_effect = 0 if unit_effect<0


*find stations that show up multiple times 
by station_id, sort: gen num_station_regs = _N  

*generate indicator for already above 15 dupac 
gen above_20 = dupac_relax>20 & dupac_strict>20

/*

. tab above_15

   above_15 |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |         81       39.51       39.51
          1 |        124       60.49      100.00
------------+-----------------------------------
      Total |        205      100.00

*/

replace price_effect_r = . if above_20==1 &price_effect_r == 0    /*possible to have positive effects through allowing mf*/
replace price_effect_r_percent = . if above_20==1 & price_effect_r_percent==0
replace price_effect_o = . if above_20==1 & price_effect_o == 0
replace price_effect_o_percent = . if above_20==1 & price_effect_o_percent==0
replace unit_effect = . if above_20==1 & unit_effect == 0
replace unit_effect_percent = . if above_20==1 & unit_effect_percent==0


*drop if no reg type has an effect and dupac below 15
drop if num_station_regs == 2 & price_effect_r == 0 & price_effect_o == 0 & unit_effect == 0 & above_20==0

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

*if all types are above 20 keep one at random 
by name, sort: gen num_stations = _N
by name, sort: egen total_above = total(above_20)
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

export delimited using "C:\Users\User\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Results\Post QJE\Welfare Calculations\prices_units_cf2.csv", replace