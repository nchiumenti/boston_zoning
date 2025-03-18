clear all

********************************************************************************
* File name:		20_boundary_matches.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		The file takes the output of closest_boundary_matches.ipynb
*			and finds the best closest boundary match between warren
*			group property and mapc zoning boundary.
*
* Inputs:		$DATAPATH/closest_boundary_matches/closest_boundary_matches.csv
*			$DATAPATH/regulation_data/regulation_types.dta
*				
* Outputs:		$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta
*
* Created:		03/08/2021
* Last updated:		10/24/2022
********************************************************************************

********************************************************************************
** import top 5 closest boundary matches from python output
********************************************************************************
* load data
import delimited "$DATAPATH/closest_boundary_matches/closest_boundary_matches.csv", clear stringcols(_all)
	
* initial error checks
assert l_r_fid == left_fid if boundary_side=="LEFT"	
assert l_r_fid == right_fid if boundary_side=="RIGHT"	

* drop merge variables
drop lside_merge rside_merge

* destring matching variables
destring zo_usety reg_type l_r_fid left_fid right_fid match_num, replace

* reshape wide w/ match number identifier
local r_vars l_r_fid unique_id left_fid right_fid boundary_side nearest_point_dist nearest_point_lat nearest_point_lon

local i_vars prop_id cousub_name warren_latitude warren_longitude reg_type zo_usety

local j_vars match_num

reshape wide `r_vars', i(`i_vars') j(`j_vars')

* error check
assert _N == 591646

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
destring warren_latitude warren_longitude boundary_using_lat boundary_using_lon, replace

* calc distance in miles between property and boundary
vincenty warren_latitude warren_longitude boundary_using_lat boundary_using_lon, hav(boundary_using_dist)

* gen dummy to identify props within 1 mile
gen boundary_using_1mile = (boundary_using_dist <= 1)


********************************************************************************
** check for errors to ensure results match previous runs
********************************************************************************
* drop properties without match
drop if boundary_using_num == ""

* destrings
destring prop_id boundary_using_num boundary_using_id, replace

* error checks
unique prop_id
assert `r(N)' ==  579242
assert `r(sum)' ==  579242
assert `r(unique)' ==  579242
assert `r(unique)' == `r(N)'

sum prop_id
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  1530088.854727385
// assert `r(Var)' ==  2197556021722.926
assert `r(sd)' ==  1482415.603575099
assert `r(min)' ==  28314
assert `r(max)' ==  5068039
assert `r(sum)' ==  886291728390

sum boundary_using_id
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  12936.15511996713
assert `r(Var)' ==  107005772.899726
assert `r(sd)' ==  10344.35947266557
assert `r(min)' ==  4
assert `r(max)' ==  33615
assert `r(sum)' ==  7493164364
		
sum boundary_using_num
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  1.126366872567942
assert `r(Var)' ==  .3012447738137396
assert `r(sd)' ==  .5488576990566313
assert `r(min)' ==  1
assert `r(max)' ==  5
assert `r(sum)' ==  652439

sum boundary_using_1mile
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  .9608522862637723
assert `r(Var)' ==  .037615235184176
assert `r(sd)' ==  .1939464750496281
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  556566

count if boundary_using_side == "LEFT"
assert `r(N)' == 290336

count if boundary_using_side == "RIGHT"
assert `r(N)' == 288906

sum home_zo_usety
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  1.185041830530245
assert `r(Var)' ==  .3336754070178842
assert `r(sd)' ==  .5776464377263
assert `r(min)' ==  0
assert `r(max)' ==  4
assert `r(sum)' ==  686426

sum home_mxht_eff
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  34.83513799068438
assert `r(Var)' ==  107.7567981244774
assert `r(sd)' ==  10.38059719498244
assert `r(min)' ==  0
assert `r(max)' ==  356
assert `r(sum)' ==  20177975

sum home_dupac_eff
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  13.16638986813802
assert `r(Var)' ==  502.4871328937504
assert `r(sd)' ==  22.41622476898709
assert `r(min)' ==  0
assert `r(max)' ==  349
assert `r(sum)' ==  7626526

sum home_mulfam
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  .552168178412477
assert `r(Var)' ==  .2472789080619842
assert `r(sd)' ==  .4972714631486349
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  319839

sum home_reg_type
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  165.0438210626992
assert `r(Var)' ==  13969.63491999007
assert `r(sd)' ==  118.1932101264284
assert `r(min)' ==  1
assert `r(max)' ==  542
assert `r(sum)' ==  95600313

sum nn_zo_usety
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  1.702550919995442
assert `r(Var)' ==  1.065963926518694
assert `r(sd)' ==  1.032455290324329
assert `r(min)' ==  0
assert `r(max)' ==  4
assert `r(sum)' ==  986189

sum nn_mxht_eff
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  35.09956978257792
// assert `r(Var)' ==  246.4669736997032
assert `r(sd)' ==  15.69926666120756
assert `r(min)' ==  0
assert `r(max)' ==  400
assert `r(sum)' ==  20331145

sum nn_dupac_eff
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  13.36760283266752
// assert `r(Var)' ==  590.0855653540361
assert `r(sd)' ==  24.29167687406607
assert `r(min)' ==  0
assert `r(max)' ==  349
assert `r(sum)' ==  7743077

sum nn_mulfam
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  .5417908231792584
assert `r(Var)' ==  .2482539556821766
assert `r(sd)' ==  .498250896318488
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  313828

sum nn_reg_type
assert `r(N)' ==  579242
assert `r(sum_w)' ==  579242
assert `r(mean)' ==  170.2620079345075
assert `r(Var)' ==  16656.51905874034
assert `r(sd)' ==  129.0601373730105
assert `r(min)' ==  1
assert `r(max)' ==  542
assert `r(sum)' ==  98622906


********************************************************************************
** drop, order, label
********************************************************************************
* keep and order variables
#delimit ;

keep 	
	prop_id 
	cousub_name 
	warren_latitude 
	warren_longitude
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
	prop_id 
	cousub_name 
	warren_latitude 
	warren_longitude
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
lab var prop_id "warren group property identifier"
lab var cousub_name "city/town location of property"
lab var warren_latitude "property latitude coordinates"
lab var warren_longitude "property longitude coordinates"

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
** end
********************************************************************************
save "$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta", replace

clear all
