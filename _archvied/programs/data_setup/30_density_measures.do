clear all

********************************************************************************
* File name:		30_density_measures.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		calculates the share of properties that are single-family
*			and 2-3 units around .1 miles of every property record 
*			that is 1 mile or less from the zone boundary.
* 				
* Inputs:		$DATAPATH/warren/warren/warren_MAPC_all_annual.dta
*			$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta
*				
* Outputs:		"$DATAPATH/warren/warren_density_measures.dta"
*
* Created:		04/06/2021
* Last updated:		11/04/2021
********************************************************************************

********************************************************************************
** load warren data unique MAPC property set
********************************************************************************
use "$DATAPATH/warren/warren_MAPC_all_annual.dta", clear


********************************************************************************
** match zone boundary matches
********************************************************************************
merge m:1 prop_id using "$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta",
	
	* verify merge results		
	sum _merge
	assert `r(N)' ==  9654526
	assert `r(sum_w)' ==  9654526
	assert `r(mean)' ==  2.400264083394669
	assert `r(Var)' ==  .8397887505281696
	assert `r(sd)' ==  .9163998857093827
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  23173412

	drop if _merge == 2
	drop _merge

gen boundary_dist_1mile = boundary_using_1mile

********************************************************************************
** construct density measures for each year in dataset
********************************************************************************
* tag single_family properties
gen proptype_sf = 0 if res_type != .
replace proptype_sf = 1 if res_type == 1

* tag 2-3 unit properties
gen proptype_gentle = 0 if res_type != .
replace proptype_gentle = 1 if res_type != . & (num_units == 2 | num_units == 3)

* tag 4+ unit properties
gen proptype_hard = 0 if res_type != .
replace proptype_hard = 1 if res_type != . & (num_units >= 4 & num_units != .)

* tag all residential properties	
gen proptype_all = 1 if res_type != .

* error checks
sum proptype_sf
assert `r(N)' ==  9429067
assert `r(sum_w)' ==  9429067
assert `r(mean)' ==  .7365064857424388
assert `r(Var)' ==  .1940647027832998
assert `r(sd)' ==  .440527754838784
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  6944569

sum proptype_gentle
assert `r(N)' ==  9429067
assert `r(sum_w)' ==  9429067
assert `r(mean)' ==  .1772005650187871
assert `r(Var)' ==  .1458005402386906
assert `r(sd)' ==  .3818383692594167
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  1670836

sum proptype_hard
assert `r(N)' ==  9429067
assert `r(sum_w)' ==  9429067
assert `r(mean)' ==  .030375009531696
assert `r(Var)' ==  .0294523714512175
assert `r(sd)' ==  .1716169322975374
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  286408

sum proptype_all
assert `r(N)' ==  9429067
assert `r(sum_w)' ==  9429067
assert `r(mean)' ==  1
assert `r(Var)' ==  0
assert `r(sd)' ==  0
assert `r(min)' ==  1
assert `r(max)' ==  1
assert `r(sum)' ==  9429067

/* iterate over each year in dataset; for properties within 1 mile of boundary
calculated the density of single family and 2-3 family buidlings; append back to
main dataset by year/prop_id */

* iterate over every year in data
local years = "2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019"

foreach yr of local years{
	
	* print working year
	di "`yr'"
	sum fy if fy==`yr'

	* density calculation
	preserve
	
		* keep only working year observations
		keep if fy==`yr'
	
		sum fy
	
		keep fy prop_id warren_latitude warren_longitude num_units proptype_* boundary_dist_1mile
		
		order fy prop_id warren_latitude warren_longitude num_units proptype_* boundary_dist_1mile
	
		* create comparison dataset
		rename prop_id prop_id2
	
		tempfile neighbors
		save `neighbors', replace
	
		* keep only properties one mile from boundary
		rename prop_id2 prop_id
		
		keep if boundary_dist_1mile==1
		
		sum fy
		
		* merge property records within .1 miles
		geonear prop_id warren_latitude warren_longitude using `neighbors', neighbors(prop_id2 warren_latitude warren_longitude) long within(.1) miles
		
		merge m:1 prop_id2 using `neighbors', keep (1 3) nogen
				
		* do not count properties that are zero miles away, assume same property
		replace proptype_sf = 0 if mi_to_prop_id2 == 0
		
		replace proptype_gentle = 0 if mi_to_prop_id2 == 0
		
		replace proptype_hard = 0 if mi_to_prop_id2 == 0
		
		replace proptype_all = 0 if mi_to_prop_id2 == 0
		
		* collapse and sum the number of properties by prop_id
		collapse (sum) proptype_*, by(fy prop_id)
		
		sum fy
		
		* create density shares (single-family and 2-3 units)
		gen density_sf = proptype_sf / proptype_all
		
		gen density_gentle = proptype_gentle / proptype_all
		
		gen density_hard = proptype_hard / proptype_all
		
		* save year as a tempfile
		di as result "savings density_`yr' ..."		
		
		tempfile density_`yr' 
		
		save `density_`yr'', replace
		
	restore
}

clear


********************************************************************************
** append density measures for each year together
********************************************************************************
local years = "2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019"

foreach yr of local years{
	di "appending `yr' density measures"
	
	append using `density_`yr'', gen(geonear_merge_`yr')
	
}

sum fy
assert `r(N)' ==  6486938
assert `r(sum_w)' ==  6486938
assert `r(mean)' ==  2013.078891766809
assert `r(Var)' ==  13.61606223030488
assert `r(sd)' ==  3.689994882151584
assert `r(min)' ==  2007
assert `r(max)' ==  2019
assert `r(sum)' ==  13058717960

sum density_sf 
assert `r(N)' ==  6478025
assert `r(sum_w)' ==  6478025
assert `r(mean)' ==  .7037209897968871
assert `r(Var)' ==  .1098532100231007
assert `r(sd)' ==  .3314411109429558
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  4558722.164928979

sum density_gentle 
assert `r(N)' ==  6478025
assert `r(sum_w)' ==  6478025
assert `r(mean)' ==  .2016941221184763
assert `r(Var)' ==  .0632541987297897
assert `r(sd)' ==  .251503874184454
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  1306579.565436543

sum density_hard
assert `r(N)' ==  6478025
assert `r(sum_w)' ==  6478025
assert `r(mean)' ==  .0366346320340686
assert `r(Var)' ==  .0106840543731388
assert `r(sd)' ==  .1033636994942556
assert `r(min)' ==  0
assert `r(max)' ==  1
assert `r(sum)' ==  237320.0621824974


********************************************************************************
** save and close
********************************************************************************
save "$DATAPATH/warren/warren_density_measures.dta", replace

clear all
