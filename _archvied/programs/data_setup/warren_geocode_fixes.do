********************************************************************************
* File name:		"geocode_fixes.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Identifies those properties in the Warrend data that have
*			miss-coded geo-ids, identified by those where the lat/long
*			do not match the city/town they are in. It is assumed that
*			the city/towns are correct because those come from the town
*			tax assessors and have the least likelihood of being wrong.
*						
*			Exports both a complete .dta file of prop_ids that need 
*			correcting and .txt files for uploading to the Census 
*			GeoCoder API (done through Python).
* 				
* Inputs:		MA_assessor_annual.dta
*				
* Outputs:		.dta; .txt
*
* Created:		01/19/2021
* Last updated:		03/11/2021
********************************************************************************

/* set warren geocoding fix path */

global GEOPATH "/home/a1nfc04/Documents/Boston_Affordable_Housing_Project_SDRIVE/data/warren/geocode_fixes"

/* create unique property list and run through Census GeoCoder API (python) */

sort prop_id fy

by prop_id: keep if _n == _N

geoinpoly orig_latitude orig_longitude using "$SHAPEPATH/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", unique

merge m:1 _ID using "$SHAPEPATH/standardized/cb_2018_25_cousub_500k_latlong.dta", keep(1 3) keepusing(NAME) nogen

replace NAME = upper(NAME)

replace NAME = regexr(NAME,"( TOWN| CITY)+","")

replace NAME = regexr(NAME, "(BOROUGH)$","BORO")

replace NAME = "MOUNT WASHINGTON" if NAME == "MT WASHINGTON"

replace NAME = "MANCHESTER" if NAME == "MANCHESTER-BY-THE-SEA"
	
gen check = 0
	replace check = 1 if cousub_name == NAME	

tab check

keep if check == 0 // 155,843 after drop

drop _ID NAME check

/* format in txt file format */

gen street_address = string(st_num)+ " " + upper(street)

tostring zipcode, format(%05.0f) replace

keep prop_id street_address cousub_name state zipcode

order prop_id street_address cousub_name state zipcode

/* erase old fix files */

local files: dir "$GEOPATH" files "address_corrections_*.txt"

foreach file in `files'{
	
	display "Deleting `file'..."

	erase "$GEOPATH/`file'"
}

/* save new address exports in text files set of 10,000 */

sort prop_id

gen seq = int((_n-1)/10000) +1

levelsof seq, local(groupid)

foreach g of local groupid{
	di "exporting group `g'"
	
	preserve
	
	local num = string(`g', "%02.0f")
	
	keep if seq == `g'
	
	drop seq
	
	export delimited using "$DATAPATH/warren/geocode_fixes/address_corrections_`num'.txt", novarnames replace
	
	restore
}

save "$GEOPATH/address_corrections_input.dta", replace

/* At this point switch to the Python program to iterate over the '.txt' files and 
upload them to Census GeoCoder in order to return the address matches. The program 
saves the combined output as a '.csv' file for importing into Stata. The '.csv' 
file is date stamped as YYYYMMDD of when it was compiled.

The following code loads the compiled '.csv' file into Stata.
*/

local DateStamp "20210311"

import delimited "$GEOPATH/geocoder_export_`DateStamp'.csv", stringcols(_all) clear

/* format prop_id for merging */

rename recordidnumber prop_id

destring prop_id, replace

/* merge on the input fil */

merge 1:1 prop_id using "$GEOPATH/address_corrections_input.dta"


/* format lat/lon variables */

split interpolatedlongitudeandlatitude, parse(",") gen(coor_)

gen cg_bg_fip = substr(blockcode,1,1)

egen cg_GEOID = concat(statecode countycode tractcode blockcode)

gen cg_flag = 0
replace cg_flag = 1 if tigermatchtype=="Match"

run "$DOPATH/10_labels.do" "warren_geocode_fixes"

save "$GEOPATH/address_corrections_output.dta", replace
