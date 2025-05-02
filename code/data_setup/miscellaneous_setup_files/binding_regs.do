clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="binding_regs" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
* File name:		"binding_regs.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		calculates the bindingness of regulation types
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		4/11/2022
* Last updated:		4/11/2022
********************************************************************************


********************************************************************************
** regualtion binding-ness
********************************************************************************
use "/home/a1nfc04/Documents/boston_zoning_sdrive/data/warren/boundary_matches/adm3_latlong.dta", clear

// . unique _ID
// Number of unique values of _ID is  36151
// Number of records is  36151

rename _ID boundary_using_id

keep boundary_using_id LEFT_FID RIGHT_FID

tempfile adm3
save `adm3', replace

use "/home/a1nfc04/Documents/boston_zoning_sdrive/data/warren/boundary_matches/regulation_types_moreregs.dta", clear

// . unique LRID
// Number of unique values of LRID is  7011
// Number of records is  7011

gen LEFT_FID = LRID
gen RIGHT_FID = LRID

tempfile regs
save `regs', replace


* USE OUR DATA - 1028
use "$DATAPATH/final_dataset_10-28-2021.dta", clear

run "$DOPATH/wp_within_town_setup" // running main analysis set-up file (drops blah_sum)

* merge on the amd3 lat long file
merge m:1 boundary_using_id using `adm3'
	drop if _merge == 2
	drop _merge
	
replace LEFT_FID = . if boundary_side == "RIGHT"
replace RIGHT_FID = . if boundary_side == "LEFT"

* merge on the more regs file twice, first on left, then on right
merge m:1 LEFT_FID using `regs'
	tab boundary_side _merge, missing
	drop if _merge == 2
	drop _merge 
	drop LRID
	
foreach var of varlist zo_usety minlotsize mxht_eff maxdu dupac_eff mulfam reg_type {
	rename `var' left_`var'
}

merge m:1 RIGHT_FID using `regs'
	tab boundary_side _merge, missing
	drop if _merge == 2
	drop _merge 
	drop LRID

foreach var of varlist zo_usety minlotsize mxht_eff maxdu dupac_eff mulfam reg_type {
	rename `var' right_`var'
}


********************************************************************************
** set up for binding regulation summary
********************************************************************************

gen minlotsize = .
replace minlotsize = left_minlotsize if boundary_side == "LEFT" & minlotsize == .
replace minlotsize = right_minlotsize if boundary_side == "RIGHT" & minlotsize == .
	
gen maxdu = .
replace maxdu = left_maxdu if boundary_side == "LEFT" & maxdu == .
replace maxdu = right_maxdu if boundary_side == "RIGHT" & maxdu == .

* regulation binding-ness variables
gen below_height = (num_floors1 < (home_mxht_eff / 10))
gen at_height = (num_floors1 == (home_mxht_eff / 10))
gen above_height = (num_floors1 > (home_mxht_eff / 10)) // violates regulation

foreach var of varlist below_height at_height above_height {
	replace `var' = . if home_mxht_eff ==.
}

gen below_lotsize = (lot_sizesqft < minlotsize)
gen at_lotsize = (lot_sizesqft == minlotsize)
gen above_lotsize = (lot_sizesqft > minlotsize) // note: this means the lot complies with regulation

foreach var of varlist below_lotsize at_lotsize above_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}

gen below_du = (num_units1 < maxdu)
gen at_du = (num_units1 == maxdu)
gen above_du = (num_units1 > maxdu) // violates regulation

foreach var of varlist below_du at_du above_du {
	replace `var' = . if maxdu ==.
	replace `var' = . if maxdu ==0

}

gen boundary_reg = .
replace boundary_reg = 1 if only_mf == 1
replace boundary_reg = 2 if only_he == 1
replace boundary_reg = 3 if only_du == 1
replace boundary_reg = 4 if mf_he == 1
replace boundary_reg = 5 if mf_du == 1
replace boundary_reg = 6 if du_he == 1
replace boundary_reg = 7 if mf_he_du == 1

lab define boundary_reg_lbl ///
1 "only_mf" ///
2 "only_he" ///
3 "only_du" ///
4 "mf_he" ///
5 "mf_du" ///
6 "du_he" ///
7 "mf_du_he", replace

lab val boundary_reg boundary_reg_lbl


********************************************************************************
** binding regulations main results
********************************************************************************
** bindingness of height regulations
* all sample
table boundary_reg if inlist(boundary_reg, 2, 4, 6, 7), c(mean below_height mean at_height mean above_height) format(%4.3fc)

* height, year_built>=1918
table boundary_reg if inlist(boundary_reg, 2, 4, 6, 7) & year_built>= 1918, c(mean below_height mean at_height mean above_height) format(%4.3fc)

* height, year_built>=1956
table boundary_reg if inlist(boundary_reg, 2, 4, 6, 7) & year_built>= 1956, c(mean below_height mean at_height mean above_height) format(%4.3fc)

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7), c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918, c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956, c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

* bindingness of max dwelling unit (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7), c(mean below_du mean at_du mean above_du) format(%4.3fc)

* max dwelling unit, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918, c(mean below_du mean at_du mean above_du) format(%4.3fc)

* max dwelling unit, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956, c(mean below_du mean at_du mean above_du) format(%4.3fc)


********************************************************************************
** binding minlotsize regulation results w/ 5% buffer
********************************************************************************
local buffer = .05

gen below5_lotsize = (lot_sizesqft < (minlotsize * (1 - `buffer')))
gen at5_lotsize = (lot_sizesqft > (minlotsize * (1 - `buffer'))) & (lot_sizesqft < (minlotsize * (1 + `buffer')))
gen above5_lotsize = (lot_sizesqft > (minlotsize * (1 + `buffer'))) // note: this means the lot complies with regulation

foreach var of varlist below5_lotsize at5_lotsize above5_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7), c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918, c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956, c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)


********************************************************************************
** binding minlotsize regulation results w/ 10% buffer
********************************************************************************
local buffer = .10

gen below10_lotsize = (lot_sizesqft < (minlotsize * (1 - `buffer')))
gen at10_lotsize = (lot_sizesqft >= (minlotsize * (1 - `buffer'))) & (lot_sizesqft <= (minlotsize * (1 + `buffer')))
gen above10_lotsize = (lot_sizesqft > (minlotsize * (1 + `buffer'))) // note: this means the lot complies with regulation

foreach var of varlist below10_lotsize at10_lotsize above10_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7), c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918, c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956, c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)


********************************************************************************
** SINGLE FAMILY ONLY MIN LOT SIZE BINDINGNESS
********************************************************************************
** No Buffer
* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918 & res_typex=="Single Family Res", c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956 & res_typex=="Single Family Res", c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

** w/ 5% buffer
local buffer = .05

drop below5* at5* above5*

gen below5_lotsize = (lot_sizesqft < (minlotsize * (1 - `buffer')))
gen at5_lotsize = (lot_sizesqft >= (minlotsize * (1 - `buffer'))) & (lot_sizesqft <= (minlotsize * (1 + `buffer')))
gen above5_lotsize = (lot_sizesqft > (minlotsize * (1 + `buffer'))) // note: this means the lot complies with regulation

foreach var of varlist below5_lotsize at5_lotsize above5_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}
	

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & res_typex=="Single Family Res", c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918 & res_typex=="Single Family Res", c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956 & res_typex=="Single Family Res", c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

** w/ 10% buffer
local buffer = .10

drop below10* at10 above10

gen below10_lotsize = (lot_sizesqft < (minlotsize * (1 - `buffer')))
gen at10_lotsize = (lot_sizesqft >= (minlotsize * (1 - `buffer'))) & (lot_sizesqft <= (minlotsize * (1 + `buffer')))
gen above10_lotsize = (lot_sizesqft > (minlotsize * (1 + `buffer'))) // note: this means the lot complies with regulation

foreach var of varlist below10_lotsize at10_lotsize above10_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & res_typex=="Single Family Res", c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918 & res_typex=="Single Family Res", c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956 & res_typex=="Single Family Res", c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)


log off
log close


********************************************************************************
** SINGLE FAMILY ONLY MIN LOT SIZE BINDINGNESS
********************************************************************************
** No Buffer
* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918 & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956 & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below_lotsize mean at_lotsize mean above_lotsize) format(%4.3fc)

** w/ 5% buffer
local buffer = .05

drop below5* at5* above5*

gen below5_lotsize = (lot_sizesqft < (minlotsize * (1 - `buffer')))
gen at5_lotsize = (lot_sizesqft >= (minlotsize * (1 - `buffer'))) & (lot_sizesqft <= (minlotsize * (1 + `buffer')))
gen above5_lotsize = (lot_sizesqft > (minlotsize * (1 + `buffer'))) // note: this means the lot complies with regulation

foreach var of varlist below5_lotsize at5_lotsize above5_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}
	

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918 & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956 & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below5_lotsize mean at5_lotsize mean above5_lotsize) format(%4.3fc)

** w/ 10% buffer
local buffer = .10

drop below10* at10 above10

gen below10_lotsize = (lot_sizesqft < (minlotsize * (1 - `buffer')))
gen at10_lotsize = (lot_sizesqft >= (minlotsize * (1 - `buffer'))) & (lot_sizesqft <= (minlotsize * (1 + `buffer')))
gen above10_lotsize = (lot_sizesqft > (minlotsize * (1 + `buffer'))) // note: this means the lot complies with regulation

foreach var of varlist below10_lotsize at10_lotsize above10_lotsize {
	replace `var' = . if minlotsize ==.
	replace `var' = . if minlotsize <=1
}

* bindingness of min lot size (density) regulations
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

* min lot size, year_built>=1918
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1918 & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

* min lot size, year_built>=1956
table boundary_reg if inlist(boundary_reg, 3, 5, 6, 7) & year_built>= 1956 & res_typex!="Single Family Res" & res_typex != "Condominiums", c(mean below10_lotsize mean at10_lotsize mean above10_lotsize) format(%4.3fc)

