********************************************************************************
* File name:		'11_geocoding.do'		
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Runs under './10_main_dataset_compile.do' and adds and 
*			fixes various geo-coding variables. This file references 
*			a dataset of corrected lat/long points that is created 
*			through a python program running the Census GeoCoder 
*			API. If not present of if source data has changed it 
*			will need to be runagain.
* 				
* Inputs:		none			
* Outputs:		none
*
* Created:		03/08/2021
* Last updated:		10/18/2022
********************************************************************************

********************************************************************************
** Combine lat/lon coordinate variables
/*Ensures that each property record has uniform coordinates accross years. */
********************************************************************************
* store original warren group lat/lon cordinates
gen orig_latitude = latitude_2013
replace orig_latitude = latitude if orig_latitude==.
	
gen orig_longitude = longitude_2013
replace orig_longitude = longitude if orig_longitude==.

* populate missing coords with most recent
bysort prop_id (fy): replace orig_latitude  = orig_latitude[_N]

bysort prop_id (fy): replace orig_longitude  = orig_longitude[_N]

drop latitude latitude_2013 longitude longitude_2013

sum orig_latitude
assert `r(N)' ==  27541280
assert `r(sum_w)' ==  27541280
assert `r(mean)' ==  42.23812677777105
assert `r(Var)' ==  .0955136146767105
assert `r(sd)' ==  .309052770051832
assert `r(min)' ==  41.24234008789063
assert `r(max)' ==  42.88534927368164
assert `r(sum)' ==  1163292076.26209

sum orig_longitude
assert `r(N)' ==  27541280
assert `r(sum_w)' ==  27541280
assert `r(mean)' ==  -71.32469102634614
assert `r(Var)' ==  .4360906126824937
assert `r(sd)' ==  .6603715716795309
assert `r(min)' ==  -73.48712921142578
assert `r(max)' ==  -69.93846893310547
assert `r(sum)' ==  -1964373286.470087


********************************************************************************
** Add FIPS codes and standardized municipal names
********************************************************************************
* state FIPS code
gen state_fip="25"

* county FIPS code
gen county_fip=""

local county_pairs = "001_Barnstable 003_Berkshire 005_Bristol 007_Dukes 009_Essex 011_Franklin 013_Hampden 015_Hampshire 017_Middlesex 019_Nantucket 021_Norfolk 023_Plymouth 025_Suffolk 027_Worcester"	

foreach pair in `county_pairs'{

	local CNTY = substr("`pair'",5,.)

	noisily display "Adding FIPS code for `CNTY' county..."
	
	replace county_fip = substr("`pair'",1,3) if county=="`CNTY'"
}

* correct local Boston neighborhood namings
local neighborhoods = `""Allston" "Brighton" "Charlestown" "Dorchester" "East Boston" "Hyde Park" "Jamaica Plain" "Mattapan" "Roslindale" "Roxbury" "South Boston" "West Roxbury""'

foreach n in `neighborhoods'{

	noisily display "Replacing '`n'' with 'Boston'..."

	replace city = "Boston" if city=="`n'"
}

* corrent local Barnstable town village namings
local villages = `""Centerville" "Cotuit" "Hyannis" "Marstons Mills" "Osterville" "West Barnstable""'

foreach v in `villages' {
	
	noisily display "Replacing '`v'' with 'Barnstable'..."
	
	replace city = "Barnstable" if city=="`v'"
}

* Format cousub_name as upper-case
gen cousub_name = upper(city)

* Remove 'TOWN' and 'CITY' from end of string
replace cousub_name = regexr(cousub_name,"( TOWN| CITY)+","")

* Replace all 'BOROUGH' with 'BORO' suffix
replace cousub_name = regexr(cousub_name, "(BOROUGH)$","BORO")

* Rename 'MT WASHINGTON'->'MOUNT WASHINGTON'; 'MANCHESTER-BY-THE-SEA'->'MANCHESTER'
replace cousub_name = "MOUNT WASHINGTON" if cousub_name=="MT WASHINGTON"

replace cousub_name = "MANCHESTER" if cousub_name=="MANCHESTER-BY-THE-SEA"

* error checks
tab state_fip
assert `r(N)' ==  27665432
assert `r(r)' ==  1

tab county_fip
assert `r(N)' ==  27665424
assert `r(r)' ==  14

tab cousub_name
assert `r(N)' ==  27665432
assert `r(r)' ==  357


********************************************************************************
** Geo coordinate fixes
********************************************************************************

/* Run this code only if data sample has recently changes. 
The .do file exports a set of all properties with incorrectly assigned lat/longs.
The output is used in python program BatchAddressMatch_final.ipynb to geocode 
lat/lon coords using the US census geocoder api */

** DO NOT RUN THIS UNLESS YOU NEED TO AS IT MAY CHANGE THE OUTPUT DATASET** */

// run "$DATAPATH/warren/geocode_fixes/geocode_fixes.do"

** RUN PYTHON PROGRAM BatchAddressMatch_final.ipynb BEFORE CONTINUING **


********************************************************************************
** Add on the corrected lat/lon coordinates
********************************************************************************
* merge on census geocode fixes
merge m:1 prop_id using "$DATAPATH/warren/geocode_fixes/address_corrections_output.dta", keepusing(cg_match_ind cg_latitude cg_longitude cg_GEOID)

	* check merge cfor errors
	unique prop_id if cg_match_ind!=""
	assert `r(N)' ==  1120894
        assert `r(sum)' ==  155843
        assert `r(unique)' ==  155843
	
	sum _merge
	assert `r(N)' ==  27665432
	assert `r(sum_w)' ==  27665432
	assert `r(mean)' ==  1.081032098107125
	assert `r(Var)' ==  .1554980009112681
	assert `r(sd)' ==  .3943323482942632
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  29907220

	* drop merge
	drop if _merge == 2
	drop _merge

* gen corrected lat/lon coordinates variables
destring cg_latitude cg_longitude, replace

gen warren_latitude = cg_latitude
		
replace warren_latitude = orig_latitude if warren_latitude==.
		
gen warren_longitude = cg_longitude
		
replace warren_longitude = orig_longitude if warren_longitude==.

* error checks
sum warren_latitude
assert `r(N)' ==  27631161
assert `r(sum_w)' ==  27631161
assert `r(mean)' ==  42.23755909175891
assert `r(Var)' ==  .095890120326179
assert `r(sd)' ==  .30966129936784
assert `r(min)' ==  41.24234008789063
assert `r(max)' ==  42.88534927368164
assert `r(sum)' ==  1167072795.511404

sum warren_longitude
assert `r(N)' ==  27631161
assert `r(sum_w)' ==  27631161
assert `r(mean)' ==  -71.32411827098053
assert `r(Var)' ==  .4358856880142525
assert `r(sd)' ==  .6602163948390349
assert `r(min)' ==  -73.48712921142578
assert `r(max)' ==  -69.93846893310547
assert `r(sum)' ==  -1970768195.128505


********************************************************************************
** Block level GEOID variable
********************************************************************************
* destring and clean census tract/block variables
tostring census_tract census_tract2010, format(%06.0f) replace
	
tostring census_block census_block2010, format(%04.0f) replace

foreach var of varlist census_tract* census_block*{
	replace `var' = "" if `var'=="."
}

* construct full geoid variables using original fips codes from warren group
gen orig_GEOID_full = state_fip + county_fip + census_tract2010 + census_block2010

replace orig_GEOID_full = "" if length(orig_GEOID_full)<15 // sets as missing if not a full GEOID

replace orig_GEOID_full = state_fip + county_fip + census_tract + census_block ///
				if orig_GEOID_full == ""

replace orig_GEOID_full = "" if length(orig_GEOID_full)<15 // sets as missing if not a full GEOID

* construct corrected fuill geoid variable of warren and census group corrections
gen warren_GEOID_full = cg_GEOID

replace warren_GEOID_full = orig_GEOID_full if warren_GEOID_full == ""

* ensure every property record has the same geo coordinates and IDs
bysort prop_id (fy): replace warren_latitude = warren_latitude[_N]

bysort prop_id (fy): replace warren_longitude = warren_longitude[_N]

bysort prop_id (fy): replace warren_GEOID_full = warren_GEOID_full[_N]

* error checks
destring warren_GEOID_full, gen(geoid_destring)

sum geoid_destring
assert `r(N)' ==  27626247
assert `r(sum_w)' ==  27626247
assert `r(mean)' ==  250163842213949.8
assert `r(Var)' ==  6.64890736632e+21
assert `r(sd)' ==  81540832509.33264
assert `r(min)' ==  250010001001021
assert `r(max)' ==  250279856001064
assert `r(sum)' ==  6.91108809547e+21

drop geoid_destring

* drop census tract and census block variables (now stored in full GEOID)
drop census_tract* census_block*

********************************************************************************
** label geocoded variables
********************************************************************************
lab var orig_latitude "original warren group lat coords + 2013 update"
lab var orig_longitude "original warren group long coords + 2013 update"
lab var warren_latitude "original + corrected lat coords"
lab var warren_longitude "original + correct long coords"
lab var orig_GEOID_full	"original GEOID down to block + 2013 update"
lab var warren_GEOID_full "original + corrected GEOID down to block, should be 2010 Census values"


*** END OF 11_geocoding.do ***
