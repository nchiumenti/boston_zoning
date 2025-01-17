clear all

** S:/ Drive Version **

********************************************************************************
* File name:		61_ch40b_boundary_matches.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		This takes the exported CH40B matches and assigns them
*			to a zoning boundary based on the closest boundary ID.
*		
*			5 closest boundaries are given. If no boundary is found
*			it loops through all 5 options until one is identified.
* 				
* Inputs:		./warren/warren_MAPC_all_annual.dta
*				
* Outputs:		./warren/warren_density_measures.dta
*
* Created:		03/08/2021
* Last updated:		11/21/2022
********************************************************************************

/* Note on boundary matching variables:
Boundary matches are stored as a string in Python format of a list[tuple(<match>)] 
so it is necessary to reformat this variable in orer to extract the boundary ID 
and its lat/long points. Each address point will have at most 5 matches. 'foreach' 
loops iterate over each of the 5 match sets. */


********************************************************************************
** import top 5 closest boundary matches from python output
********************************************************************************
* load data
import delimited "$DATAPATH/closest_boundary_matches/closest_boundary_matches_ch40b.csv", clear stringcols(_all)
	
* initial error checks
assert l_r_fid == left_fid if boundary_side=="LEFT"	
assert l_r_fid == right_fid if boundary_side=="RIGHT"	

* drop merge variables
drop lside_merge rside_merge

* destring matching variables
destring zo_usety reg_type l_r_fid left_fid right_fid match_num, replace

* reshape wide w/ match number identifier
local r_vars l_r_fid unique_id_fid left_fid right_fid boundary_side nearest_point_dist nearest_point_lat nearest_point_lon

local i_vars unique_id ch40b_id cousub_name ch40b_lat ch40b_lon reg_type zo_usety

local j_vars match_num

reshape wide `r_vars', i(`i_vars') j(`j_vars')

* error check
assert _N == 1133
	
* rename to preserve zone use type and reg are type variables
rename reg_type reg_type_base
rename zo_usety zo_usety_base


********************************************************************************
** create variables to store regulation data
* home_ -> zoning regulations for property's location
* nn_ -> zoning regulations on opposite side of closest boundary to property
********************************************************************************
* home location zoning regulations
gen home_zo_usety = .
gen home_mxht_eff = .
gen home_dupac_eff = .
gen home_mulfam = .
gen home_reg_type = .

* nearest neighbor zoning regulations
gen nn_zo_usety = .
gen nn_mxht_eff = .
gen nn_dupac_eff = .
gen nn_mulfam = .
gen nn_reg_type = .

* boundary id variables
gen boundary_using_id = ""
gen boundary_using_num = ""
gen boundary_using_side = ""
gen boundary_using_left_fid = .
gen boundary_using_right_fid = .


********************************************************************************
** select best closest boundary match to property
********************************************************************************
* iterate through th 5 closest matches
forval i = 1(1)5 {
	
	* store working boundary information
	replace boundary_using_num = "`i'" if boundary_using_num == ""
	replace boundary_using_id = unique_id_fid`i' if boundary_using_id == ""
	replace boundary_using_side = boundary_side`i' if boundary_using_side == ""
	replace boundary_using_left_fid = left_fid`i' if boundary_using_left_fid == .
	replace boundary_using_right_fid = right_fid`i' if boundary_using_right_fid == .

	* match regulation data to left side matches
	gen LRID = boundary_using_left_fid

	merge m:1 LRID using "$DATAPATH/regulation_data/regulation_types.dta"

		* merge results
		tab _merge
		drop if _merge==2
	
	* assign regulation variables to home_ if LEFT side match, nn_ if RIGHT side
	foreach var in zo_usety mxht_eff dupac_eff mulfam reg_type {
		
		* if left side match, assign as home_ regulation variables
		replace home_`var' = `var' if home_`var' == . & boundary_side`i' == "LEFT"
		
		* if right side match, assign as nn_ regulation variables
		replace nn_`var' = `var' if nn_`var' == . & boundary_side`i' == "RIGHT"
	}

	* drop regulation variables to rematch on right side
	drop LRID zo_usety mxht_eff dupac_eff mulfam reg_type _merge

	* match regulation data to right side matches
	gen LRID = boundary_using_right_fid 

	merge m:1 LRID using "$DATAPATH/regulation_data/regulation_types.dta"
		
		* merge results
		tab _merge
		drop if _merge==2
		
	* assign regulation variables to home_ if RIGHT side match, nn_ if LEFT side
	foreach var of varlist zo_usety mxht_eff dupac_eff mulfam reg_type {
		
		* if left side match, assign as home_ regulation variables
		replace home_`var' = `var' if home_`var' == . & boundary_side`i' == "RIGHT"
		
		* if right side match, assign as nn_ regulation variables
		replace nn_`var' = `var' if nn_`var' == . & boundary_side`i' == "LEFT"
	}

	* drop reglation variables
	drop LRID zo_usety mxht_eff dupac_eff mulfam reg_type _merge

	/* clear boundary id and regulation data if regulation data is missing 
	or if left_fid matches right_fid (both sides of the boundary are the same) */
	foreach var in zo_usety mxht_eff dupac_eff mulfam reg_type {
		
		* clear regulation data
		replace home_`var'=. if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"
		replace nn_`var'=. if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"

		* clear boundary data
		replace boundary_using_left_fid  = . if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"
		replace boundary_using_right_fid  = . if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"
		replace boundary_using_num = "" if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"
		replace boundary_using_id = "" if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"
		replace boundary_using_side = "" if (home_`var' == . | nn_`var' == .) | boundary_side`i' == "BOTH L&R"
	}
} // end of full loop

tab boundary_using_num, missing

* results from 10/26/2021
* boundary_us |
*     ing_num |      Freq.     Percent        Cum.
* ------------+-----------------------------------
*           1 |      1,074       85.31       85.31
*           2 |         24        1.91       87.21
*           3 |          8        0.64       87.85
*           4 |          3        0.24       88.09
*           5 |          4        0.32       88.40
*           . |        146       11.60      100.00
* ------------+-----------------------------------
*       Total |      1,259      100.00


********************************************************************************
** calculate distance from property to assigned boundary
********************************************************************************
* gen variables to store lat/lon coordinates
gen boundary_using_lat = ""
gen boundary_using_lon = ""

* use lat/lon coordinates of assigned match
forval i = 1(1)5 {
	replace boundary_using_lat = nearest_point_lat`i' if boundary_using_num == "`i'"
	replace boundary_using_lon = nearest_point_lon`i' if boundary_using_num == "`i'"
}

* destring
destring ch40b_lat ch40b_lon boundary_using_lat boundary_using_lon, replace

* calc distance in miles between property and boundary
vincenty ch40b_lat ch40b_lon boundary_using_lat boundary_using_lon, hav(boundary_using_dist)

* gen dummy to identify props within 1 mile
gen boundary_using_1mile = (boundary_using_dist <= 1)

tab boundary_using_num boundary_using_1mile, missing


********************************************************************************
** check for errors to ensure results match previous runs
********************************************************************************
* drop properties without match
drop if boundary_using_num == ""

* destrings
destring unique_id ch40b_id boundary_using_num boundary_using_id, replace

* error checks
assert _N == 1113

unique unique_id
assert `r(unique)' == `r(N)'

sum unique_id
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  1604.470799640611
assert `r(Var)' ==  952397.1720332629
assert `r(sd)' ==  975.9083830120852
assert `r(min)' ==  1
assert `r(max)' ==  3475
assert `r(sum)' ==  1785776

sum ch40b_id
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  4063.061096136568
assert `r(Var)' ==  13491914.3254006
assert `r(sd)' ==  3673.134128425015
assert `r(min)' ==  10
assert `r(max)' ==  10582
assert `r(sum)' ==  4522187

sum boundary_using_id
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  14748.18598382749
assert `r(Var)' ==  100869193.7108825
assert `r(sd)' ==  10043.36565653579
assert `r(min)' ==  41
assert `r(max)' ==  32964
assert `r(sum)' ==  16414731

sum boundary_using_num
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  1.058400718778077
assert `r(Var)' ==  .1287805335246628
assert `r(sd)' ==  .3588600472672637
assert `r(min)' ==  1
assert `r(max)' ==  5
assert `r(sum)' ==  1178

sum boundary_using_1mile
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  .9838274932614556
assert `r(Var)' ==  .0159252651786926
assert `r(sd)' ==  .1261953453131003
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  1095

count if boundary_using_side == "LEFT"
assert `r(N)' == 612

count if boundary_using_side == "RIGHT"
assert `r(N)' == 501

sum home_zo_usety
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  1.704402515723271
assert `r(Var)' ==  .8630831184109317
assert `r(sd)' ==  .9290226684053149
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  1897

sum home_mxht_eff
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  38.87241689128481
assert `r(Var)' ==  247.294858991513
assert `r(sd)' ==  15.72561156176487
assert `r(min)' ==  0
assert `r(max)' ==  140
assert `r(sum)' ==  43265

sum home_dupac_eff
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  16.11949685534591
assert `r(Var)' ==  610.9416429120854
assert `r(sd)' ==  24.71723372289232
assert `r(min)' ==  0
assert `r(max)' ==  145
assert `r(sum)' ==  17941

sum home_mulfam
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  .7277628032345014
assert `r(Var)' ==  .1983022746223506
assert `r(sd)' ==  .4453114355396127
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  810

sum home_reg_type
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  225.1168014375561
assert `r(Var)' ==  16608.95936673841
assert `r(sd)' ==  128.8757516631364
assert `r(min)' ==  4
assert `r(max)' ==  537
assert `r(sum)' ==  250555

sum nn_zo_usety
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  1.833782569631626
assert `r(Var)' ==  1.025404474264254
assert `r(sd)' ==  1.012622572464319
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  2041

sum nn_mxht_eff
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  36.83647798742138
assert `r(Var)' ==  220.7214379439844
assert `r(sd)' ==  14.85669673729609
assert `r(min)' ==  0
assert `r(max)' ==  120
assert `r(sum)' ==  40999

sum nn_dupac_eff
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  14.50673854447439
assert `r(Var)' ==  590.7861505943494
assert `r(sd)' ==  24.30609286977957
assert `r(min)' ==  0
assert `r(max)' ==  145
assert `r(sum)' ==  16146

sum nn_mulfam
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  .6397124887690926
assert `r(Var)' ==  .2306876870471278
assert `r(sd)' ==  .4802995805194168
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  712

sum nn_reg_type
assert `r(N)' ==  1113
assert `r(sum_w)' ==  1113
assert `r(mean)' ==  201.1608265947889
assert `r(Var)' ==  17639.30234895641
assert `r(sd)' ==  132.8130353126394
assert `r(min)' ==  3
assert `r(max)' ==  526
assert `r(sum)' ==  223892


********************************************************************************
** drop, order, label
********************************************************************************
* keep and order variables
#delimit ;

keep 	
	unique_id 
	ch40b_id
	cousub_name 
	ch40b_lat
	ch40b_lon
	boundary_using_id 
	boundary_using_num 
	boundary_using_side
	boundary_using_left_fid 
	boundary_using_right_fid
	boundary_using_lat 
	boundary_using_lon
	boundary_using_dist 
	boundary_using_1mile
	home_zo_usety 
	home_mxht_eff 
	home_dupac_eff 
	home_mulfam 
	home_reg_type 
	nn_zo_usety 
	nn_mxht_eff 
	nn_dupac_eff 
	nn_mulfam 
	nn_reg_type ;

order 	
	unique_id 
	ch40b_id
	cousub_name 
	ch40b_lat
	ch40b_lon
	boundary_using_id 
	boundary_using_num 
	boundary_using_side
	boundary_using_left_fid 
	boundary_using_right_fid
	boundary_using_lat 
	boundary_using_lon
	boundary_using_dist 
	boundary_using_1mile
	home_zo_usety 
	home_mxht_eff 
	home_dupac_eff 
	home_mulfam 
	home_reg_type 
	nn_zo_usety 
	nn_mxht_eff 
	nn_dupac_eff 
	nn_mulfam 
	nn_reg_type ;

#delimit cr

* give variable labels
lab var unique_id "constructed unique ch40b address identifier"
lab var ch40b_id "ch40b group property identifier"
lab var cousub_name "city/town location of property"
lab var ch40b_lat "property latitude coordinates"
lab var ch40b_lon "property longitude coordinates"

lab var boundary_using_id "amd3_latlong boundary _ID index value"
lab var boundary_using_num "nth closest match number"
lab var boundary_using_side "left/right side of boundary match"
lab var boundary_using_left_fid "left side match id (LEFT_FID)"
lab var boundary_using_right_fid "right side match id (RIGHT_FID)"
lab var boundary_using_lat "lat coordinates of nearest point on boundary to property"
lab var boundary_using_lon "lon coordinates of nearest point on boundary to property"
lab var boundary_using_dist "distance from property to nearest point in miles"
lab var boundary_using_1mile "=1 if distance from property to nearest point <= 1 mile"

lab var home_zo_usety "zone use type in home area"
lab var home_mxht_eff "max effective height in home area"
lab var home_dupac_eff "effective dwelling units per acre in home area"
lab var home_mulfam "=1 if multifamily allowed by right in home area"
lab var home_reg_type "regulation type area in hoem area"

lab var nn_zo_usety "zone use type in comparison area"
lab var nn_mxht_eff "max effective height in comparison area"
lab var nn_dupac_eff "effective dwelling units per acre in comparison area"
lab var nn_mulfam "=1 if multifamily allowed by right in comparison area"
lab var nn_reg_type "regulation type area in comparison area"


********************************************************************************
* label and save boundary matches
********************************************************************************
save "$DATAPATH/closest_boundary_matches/closest_boundary_matches_ch40b_with_regs.dta", replace

clear all
