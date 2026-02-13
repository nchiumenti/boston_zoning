********************************************************************************
* File name:		"effective_dist_export.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		binscatter of straight line vs effective distance between
*			closest properties on either side of the boundary
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		3.24.2022		
* Last updated:		3.24.2022
********************************************************************************

global DATAPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/data"
global FIGPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/wp_figures"

global DOPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/wp_dofiles"

global DATAPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/data"

use "$DATAPATH/final_dataset_10-28-2021.dta", clear

do "$DOPATH/wp_within_town_setup"

* data set up
keep if year >= 2010 & year <=2018

drop if boundary_side == ""

gen address = string(st_num) + " " + street + " " + city + " " + strofreal(zipcode, "%05.0f")

keep year prop_id address boundary_using_id boundary_dist boundary_side warren_longitude warren_latitude

bysort year boundary_using_id boundary_side (boundary_dist): keep if _n == 1

reshape wide prop_id address boundary_dist warren_longitude warren_latitude, i(year boundary_using_id) j(boundary_side) string

tab year

drop if prop_idLEFT == . | prop_idRIGHT == .

tab year

geodist warren_latitudeLEFT warren_longitudeLEFT warren_latitudeRIGHT warren_longitudeRIGHT, gen(crow_dist) miles

keep if year == 2018

export delimited using "/home/a1nfc04/python_projects/effective_distances/effective_distance_inputs_2018.csv", replace

