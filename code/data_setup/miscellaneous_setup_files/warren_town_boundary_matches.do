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
** import the closest boundary matches from python output
********************************************************************************
* load data
import delimited "warren_town_boundary_matches.csv", clear stringcols(_all)
	  
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
gen home_minlotsize = .
gen home_maxdu = .

* nearest neighbor zoning regulations
gen nn_zo_usety = .
gen nn_mxht_eff = .
gen nn_dupac_eff = .
gen nn_mulfam = .
gen nn_reg_type = .
gen nn_minlotsize = .
gen nn_maxdu = .

* assign left side match regulations to home, and the right side to nearest neighbor
replace home_zo_usety = left_zo_usety if boundary_side == "LEFT"
replace home_mxht_eff = left_mxht_eff if boundary_side == "LEFT"
replace home_dupac_eff = left_dupac_eff if boundary_side == "LEFT"
replace home_mulfam = left_mulfam if boundary_side == "LEFT"
replace home_reg_type = left_reg_type if boundary_side == "LEFT"
replace home_minlotsize = left_minlotsize if boundary_side == "LEFT"
replace home_maxdu = left_maxdu if boundary_side == "LEFT"

replace nn_zo_usety = right_zo_usety if boundary_side == "LEFT"
replace nn_mxht_eff = right_mxht_eff if boundary_side == "LEFT"
replace nn_dupac_eff = right_dupac_eff if boundary_side == "LEFT"
replace nn_mulfam = right_mulfam if boundary_side == "LEFT"
replace nn_reg_type = right_reg_type if boundary_side == "LEFT"
replace nn_minlotsize = right_minlotsize if boundary_side == "LEFT"
replace nn_maxdu = right_maxdu if boundary_side == "LEFT"
					
* assign right side match regulations to home, and the left side to nearest neighbor
replace home_zo_usety = right_zo_usety if boundary_side == "RIGHT"
replace home_mxht_eff = right_mxht_eff if boundary_side == "RIGHT"
replace home_dupac_eff = right_dupac_eff if boundary_side == "RIGHT"
replace home_mulfam = right_mulfam if boundary_side == "RIGHT"
replace home_reg_type = right_reg_type if boundary_side == "RIGHT"
replace home_minlotsize = right_minlotsize if boundary_side == "RIGHT"
replace home_maxdu = right_maxdu if boundary_side == "RIGHT"

replace nn_zo_usety = left_zo_usety if boundary_side == "RIGHT"
replace nn_mxht_eff = left_mxht_eff if boundary_side == "RIGHT"
replace nn_dupac_eff = left_dupac_eff if boundary_side == "RIGHT"
replace nn_mulfam = left_mulfam if boundary_side == "RIGHT"
replace nn_reg_type = left_reg_type if boundary_side == "RIGHT"
replace nn_minlotsize = left_minlotsize if boundary_side == "RIGHT"
replace nn_maxdu = left_maxdu if boundary_side == "RIGHT"

********************************************************************************
** calculate the distance in miles between the property and the boundary
********************************************************************************
* destring
destring warren_latitude warren_longitude nearest_point_lat nearest_point_lon, replace

* calc distance in miles between property and boundary
vincenty warren_latitude warren_longitude nearest_point_lat nearest_point_lon, hav(boundary_using_dist)

* gen dummy to identify props within 1 mile
gen boundary_using_1mile = (boundary_using_dist <= 1)

********************************************************************************
** define boundary using id that will eventually be used as lam_seg
********************************************************************************
gen boundary_using_id = boundary_unique_id

********************************************************************************
* give variable labels
********************************************************************************
lab var prop_id "warren group property identifier"
lab var cousub_name "city/town location of property"
lab var warren_latitude "property latitude coordinates"
lab var warren_longitude "property longitude coordinates"

lab var home_minlotsize "min lot size in home area"
lab var home_maxdu "max dupac in home area"
lab var home_zo_usety "zone use type in home area"
lab var home_mxht_eff "max effective height in home area"
lab var home_dupac_eff "effective dwelling units per acre in home area"
lab var home_mulfam "=1 if multifamily allowed by right in home area"
lab var home_reg_type "regulation type area in hoem area"

lab var nn_minlotsize "min lot size in comparison area"
lab var nn_maxdu "max dupac in comparison area"
lab var nn_zo_usety "zone use type in comparison area"
lab var nn_mxht_eff "max effective height in comparison area"
lab var nn_dupac_eff "effective dwelling units per acre in comparison area"
lab var nn_mulfam "=1 if multifamily allowed by right in comparison area"
lab var nn_reg_type "regulation type area in comparison area"


********************************************************************************
** end
********************************************************************************
save "warren_town_closest_matches_with_regs.dta", replace

clear all
