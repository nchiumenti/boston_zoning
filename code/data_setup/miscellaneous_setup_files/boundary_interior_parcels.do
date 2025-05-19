clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="boundary_interior_parcels" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

********************************************************************************
* File name:		"boundary_interior_parcels.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		This code was primarily done by Amrita and calculates the 
*			difference between interior and exterior parcels close
*			to a boundary
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		3/24/2022
* Last updated:		3/24/2022
********************************************************************************

********************************************************************************
*Comparison of boundary and interior parcels************************************
********************************************************************************

*USE OUR DATA - 1028
use "$DATAPATH/final_dataset_10-28-2021.dta", clear

run "$DOPATH/wp_within_town_setup" // running main analysis set-up file (drops blah_sum)

*house characteristics
gen char1_lotsizeac1 = lot_sizeac if lot_sizeac != 0			// lot size in acres, excl zero acre
gen char2_livingarea1 = livingarea / num_units1 if livingarea != 0	// living area in square feet per unit, excl zero
gen char3_bedrooms1 = bedroom_num / num_units1 if bedroom_num != 0	// num bedrooms per unit, atleast 1
gen char4_bathfull1 = bathfull_num / num_units1 if bathfull_num != 0	// num full bathrooms per unit, atleast 1
gen char5_numunits1 = num_units1 if num_units1 != 0
gen char6_numfloors1 = num_floors1 if num_floors != 0


label var char1 "Lot size (acres)"
label var char2 "Living area in square feet per unit"
label var char3 "Bedrooms per unit"
label var char4 "Bathrooms per unit"
label var char5 "Number of units"
label var char6 "Number of floors"

* 1 = boundary parcel, 0 = interior parcel
gen boundary_def1 = .
replace boundary_def1 = 1 if year == 2018 & dist_both<=0.02 & dist_both>=-0.02 & year_built>=1918 
replace boundary_def1 = 0 if year == 2018 & ((dist_both>0.02 & dist_both<=0.3) | (dist_both<-0.02 & dist_both>=-0.3)) & year_built>=1918 

tab boundary_def1

gen boundary_def2 = .
replace boundary_def2 = 1 if year == 2018 & dist_both<=0.1 & dist_both>=-0.1 & year_built>=1918 
replace boundary_def2 = 0 if year == 2018 & ((dist_both>0.1 & dist_both<=0.3) | (dist_both<-0.1 & dist_both>=-0.3)) & year_built>=1918 

tab boundary_def2

gen boundary_def3 = .
replace boundary_def3 = 1 if year == 2018 & dist_both<=0.2 & dist_both>=-0.2 & year_built>=1918 
replace boundary_def3 = 0 if year == 2018 & ((dist_both>0.2 & dist_both<=0.3) | (dist_both<-0.2 & dist_both>=-0.3)) & year_built>=1918 

tab boundary_def3

** boundary def 1
estpost sum char1 char2 char3 char4 char5 char6 if boundary_def1 == 1  /*boundary parcels*/

eststo boundary

estpost sum char1 char2 char3 char4 char5 char6 if boundary_def1 == 0   /*interior parcels*/

eststo interior

estpost ttest char1 char2 char3 char4 char5 char6 , by(boundary_def1)  /*ttest*/

eststo ttest1

esttab boundary interior ttest1, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") nonumbers mtitles("Boundary (0-0.02)" "Interior (0.02-0.3)" "t-Test") replace
esttab boundary interior ttest1 using boundary_def1.tex, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") nonumbers mtitles("Boundary (0-0.02)" "Interior (0.02-0.3)" "t-Test") replace

eststo clear

** boundary def 2
estpost sum char1 char2 char3 char4 char5 char6 if boundary_def2 == 1

eststo boundary

estpost sum char1 char2 char3 char4 char5 char6 if boundary_def2 == 0

eststo interior

estpost ttest char1 char2 char3 char4 char5 char6, by(boundary_def2)

eststo ttest1

esttab boundary interior ttest1, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") nonumbers mtitles("Boundary (0-0.1)" "Interior (0.1-0.3)" "t-Test") replace
esttab boundary interior ttest1 using boundary_def2.tex, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") nonumbers mtitles("Boundary (0-0.1)" "Interior (0.1-0.3)" "t-Test") replace

eststo clear

** boundary def 3
estpost sum char1 char2 char3 char4 char5 char6 if boundary_def3 == 1

eststo boundary

estpost sum char1 char2 char3 char4 char5 char6 if boundary_def3 == 0

eststo interior

estpost ttest char1 char2 char3 char4 char5 char6, by(boundary_def3)

eststo ttest1

esttab boundary interior ttest1 , cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") nonumbers mtitles("Boundary (0-0.2)" "Interior (0.2-0.3)" "t-Test") replace
esttab boundary interior ttest1 using boundary_def3.tex, cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") nonumbers mtitles("Boundary (0-0.2)" "Interior (0.2-0.3)" "t-Test") replace

eststo clear

log off 
log close
