clear all

// log close _all
//
// local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")
//
// local name ="nhpd_boundary_matches" // <--- change when necessry
//
// log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S DRIVE VERSION **

********************************************************************************
* File name:		51_nhpd_boundary_matches.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		File is called within '11_nhpd.do'
*
*			This file assigns the boundary side to coded NHPD properties
*			based on their boundary using ID. NHPD records were coded
*			with boundary IDs using python on JupyterHub. The result
*			exports a boundary match file for crosswalking NHPD records
*			to Warren Group records.
*
*			Not all NHPD records are coded with boundaries. These are 
*			still matched based on proximity and similarity between
*			addresses.
* 				
* Inputs:		./data/nhpd/nhpd_mapc.csv
*			./data/nhpd/nhpd_export.csv
*				
* Outputs:		./data/closest_boundary_matches_nhpd_with_regs.dta
*
* Created:		04/26/2021
* Last updated:		11/16/2022
********************************************************************************

/* Note on matching scheme:
This file follows the same methods of '20_boundary_matches.do' which matches
warren records. It uses one of the closest 5 stored boundaries that are found.
It starts with the 1st closest and if no regulations are found on the LEFT or 
RIGHT side of the boundary the next closest boundary is used.

Ultimately we do not care about the regulations for NHPD properties, but we keep
the matching scheme so it alligns with the Warren record matching process. */
	
********************************************************************************
** import top 5 closest boundary matches from python output
********************************************************************************
* load data
import delimited "$DATAPATH/closest_boundary_matches/closest_boundary_matches_nhpd.csv", clear stringcols(_all)
	
* initial error checks
assert l_r_fid == left_fid if boundary_side=="LEFT"	
assert l_r_fid == right_fid if boundary_side=="RIGHT"	

* drop merge variables
drop lside_merge rside_merge

* destring matching variables
destring zo_usety reg_type l_r_fid left_fid right_fid match_num, replace

* reshape wide w/ match number identifier
local r_vars l_r_fid unique_id left_fid right_fid boundary_side nearest_point_dist nearest_point_lat nearest_point_lon

local i_vars nhpd_id cousub_name nhpd_lat nhpd_lon reg_type zo_usety

local j_vars match_num

reshape wide `r_vars', i(`i_vars') j(`j_vars')

* error check
assert _N == 1162	
	
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
	replace boundary_using_id = unique_id`i' if boundary_using_id == ""
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

* results from 4/27/2021
* boundary_us |
*     ing_num |      Freq.     Percent        Cum.
* ------------+-----------------------------------
*           1 |      1,117       89.43       89.43
*           2 |         18        1.44       90.87
*           3 |         10        0.80       91.67
*           4 |          4        0.32       91.99
*           5 |          1        0.08       92.07
*           . |         99        7.93      100.00
* ------------+-----------------------------------
*       Total |      1,249      100.00


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
destring nhpd_lat nhpd_lon boundary_using_lat boundary_using_lon, replace

* calc distance in miles between property and boundary
vincenty nhpd_lat nhpd_lon boundary_using_lat boundary_using_lon, hav(boundary_using_dist)

* gen dummy to identify props within 1 mile
gen boundary_using_1mile = (boundary_using_dist <= 1)

tab boundary_using_num boundary_using_1mile, missing
* results from 4/27/2021
* boundary_u |       boundary_dist_1mile
*   sing_num |         0          1          . |     Total
* -----------+---------------------------------+----------
*          1 |         5      1,112          0 |     1,117 
*          2 |         0         18          0 |        18 
*          3 |         2          8          0 |        10 
*          4 |         0          4          0 |         4 
*          5 |         0          1          0 |         1 
*          . |         0          0         99 |        99 
* -----------+---------------------------------+----------
*      Total |         7      1,143         99 |     1,249 


********************************************************************************
** check for errors to ensure results match previous runs
********************************************************************************
* drop properties without match
drop if boundary_using_num == ""

* destrings
destring nhpd_id boundary_using_num boundary_using_id, replace

* error checks
assert _N == 1150

unique nhpd_id
assert `r(unique)' == `r(N)'

sum nhpd_id
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  1056048.460869565
// assert `r(Var)' ==  976434258.8683542
assert `r(sd)' ==  31247.9480745273
assert `r(min)' ==  1000354
assert `r(max)' ==  1154774
assert `r(sum)' ==  1214455730

sum boundary_using_id
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  13001.07826086956
assert `r(Var)' ==  67491546.56480116
assert `r(sd)' ==  8215.323886786275
assert `r(min)' ==  20
assert `r(max)' ==  33615
assert `r(sum)' ==  14951240

sum boundary_using_num
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  1.04695652173913
assert `r(Var)' ==  .0935285881863246
assert `r(sd)' ==  .3058244401389866
assert `r(min)' ==  1
assert `r(max)' ==  5
assert `r(sum)' ==  1204

sum boundary_using_1mile
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  .9939130434782608
assert `r(Var)' ==  .0060551708479964
assert `r(sd)' ==  .0778149783010724
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  1143

count if boundary_using_side == "LEFT"
assert `r(N)' == 664

count if boundary_using_side == "RIGHT"
assert `r(N)' == 486

sum home_zo_usety
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  1.596521739130435
assert `r(Var)' ==  .7978991183259545
assert `r(sd)' ==  .8932519903845468
assert `r(min)' ==  0
assert `r(max)' ==  4
assert `r(sum)' ==  1836

sum home_mxht_eff
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  40.47391304347826
assert `r(Var)' ==  536.8413554319446
assert `r(sd)' ==  23.16983719044967
assert `r(min)' ==  0
assert `r(max)' ==  140
assert `r(sum)' ==  46545

sum home_dupac_eff
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  35.41826086956522
assert `r(Var)' ==  1673.613417338328
assert `r(sd)' ==  40.90982054884045
assert `r(min)' ==  0
assert `r(max)' ==  349
assert `r(sum)' ==  40731

sum home_mulfam
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  .7695652173913043
assert `r(Var)' ==  .1774889317743217
assert `r(sd)' ==  .4212943528868168
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  885

sum home_reg_type
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  258.2721739130435
assert `r(Var)' ==  21555.21828508722
assert `r(sd)' ==  146.8169550327455
assert `r(min)' ==  1
assert `r(max)' ==  537
assert `r(sum)' ==  297013

sum nn_zo_usety
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  1.851304347826087
assert `r(Var)' ==  1.042274189276119
assert `r(sd)' ==  1.020918306857174
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  2129

sum nn_mxht_eff
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  37.92869565217391
assert `r(Var)' ==  496.651134067431
assert `r(sd)' ==  22.28567104817423
assert `r(min)' ==  0
assert `r(max)' ==  155
assert `r(sum)' ==  43618

sum nn_dupac_eff
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  28.60869565217391
assert `r(Var)' ==  1222.612631021304
assert `r(sd)' ==  34.96587809595669
assert `r(min)' ==  0
assert `r(max)' ==  349
assert `r(sum)' ==  32900

sum nn_mulfam
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  .6739130434782609
// assert `r(Var)' ==  .2199455102735839
assert `r(sd)' ==  .4689834861416592
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  775

sum nn_reg_type
assert `r(N)' ==  1150
assert `r(sum_w)' ==  1150
assert `r(mean)' ==  231.2513043478261
assert `r(Var)' ==  23774.83583380633
assert `r(sd)' ==  154.1909071048171
assert `r(min)' ==  3
assert `r(max)' ==  540
assert `r(sum)' ==  265939

********************************************************************************
** drop, order, label
********************************************************************************
* keep and order variables
#delimit ;

keep 	
	nhpd_id 
	cousub_name 
	nhpd_lat
	nhpd_lon
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
	nhpd_id 
	cousub_name 
	nhpd_lat
	nhpd_lon
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
lab var nhpd_id "NHPD group property identifier"
lab var cousub_name "city/town location of property"
lab var nhpd_lat "property latitude coordinates"
lab var nhpd_lon "property longitude coordinates"

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
save "$DATAPATH/closest_boundary_matches/closest_boundary_matches_nhpd_with_regs.dta", replace

clear all
