clear all

********************************************************************************
* File name:		"50_nhpd.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Cleans the original 'All Properties.xlsx' download. 
*			Returns 2 datasets of (1) all properties in MA and all
*			properties in MAPC region. The MAPC region file also has
*			boundary IDs assigned to properties (for use in the 
*			warren/nhpd crosswalk).
*
*			Note 08/06/2021: This dataset is no longer used in the 
*			final report but is maintained for continuity
* 				
* Inputs:		"$DATAPATH/nhpd/All Properties.xlsx" (downloaded 12/17/2020 fromhttps://preservationdatabase.org/)
*				
* Outputs:		$DATAPATH/nhpd/nhpd/nhpd_ma.dta
*			$DATAPATH/nhpd/nhpd/nhpd_mapc.dta
*			$DATAPATH/nhpd/nhpd/nhpd_ma.csv
*
* Created:		12/08/2020
* Last updated:		11/14/2022
********************************************************************************

********************************************************************************
** load original data download
********************************************************************************
import excel "$DATAPATH/nhpd/All Properties.xlsx", allstring firstrow case(upper) clear

keep if STATE == "MA" // 3225 obs after drop

assert _N == 3225

* store property id
gen nhpd_id = NHPDPROPERTYID

* check property ids for consistency
destring nhpd_id, gen(nhpd_id_ds)

sum nhpd_id_ds
assert `r(N)' ==  3225
assert `r(sum_w)' ==  3225
assert `r(mean)' ==  1054026.543875969
assert `r(Var)' ==  1049006509.76242
assert `r(sd)' ==  32388.36997692875
assert `r(min)' ==  1000354
assert `r(max)' ==  1154775
assert `r(sum)' ==  3399235604

// stop
// tempfile save_point
// save `save_point', replace

********************************************************************************
** geo code nhpd properties
* - adds census GEOID down to block-group level
* - adds FIPS code variables for various levels
* - standardizes city/town names
* - adds st_num and street name variables
********************************************************************************
destring LATITUDE LONGITUDE, replace

* merge on census block group geoids
geoinpoly LATITUDE LONGITUDE using "$SHAPEPATH/originals/cb_2018_25_bg_500k_shp.dta", unique noproj

merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_bg_500k.dta", keepusing(GEOID)

	* validate merge results
	sum _merge
	assert `r(N)' ==  6601
	assert `r(sum_w)' ==  6601
	assert `r(mean)' ==  2.488562339039539
	assert `r(Var)' ==  .2499070388784068
	assert `r(sd)' ==  .4999070302350296
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  16427

	drop if _merge == 2
	drop _ID _merge

* merge on county subdivision geoids
geoinpoly LATITUDE LONGITUDE using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta", unique noproj

merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta", keepusing(COUSUBFP NAME)

	* validate merge
	sum _merge
	assert `r(N)' ==  3332
	assert `r(sum_w)' ==  3332
	assert `r(mean)' ==  2.967887154861945
	assert `r(Var)' ==  .0310909413299994
	assert `r(sd)' ==  .1763262355124711
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9889

	drop if _merge == 2
	drop _ID _merge

* create fips codes for all levels
gen state_fip = substr(GEOID,1,2)
gen county_fip = substr(GEOID,3,3)
gen tract_fip = substr(GEOID,6,6)
gen blkgrp_fip = substr(GEOID,-1,1)
gen zipcode = substr(ZIP,1,5)

rename COUSUBFP cousub_fip

* check fips codes for errors
foreach var of varlist state_fip county_fip tract_fip blkgrp_fip zipcode cousub_fip{
	destring `var', gen(`var'_ds)
}

sum state_fip_ds
assert `r(N)' ==  3225
assert `r(sum_w)' ==  3225
assert `r(mean)' ==  25
assert `r(Var)' ==  0
assert `r(sd)' ==  0
assert `r(min)' ==  25
assert `r(max)' ==  25
assert `r(sum)' ==  80625

sum county_fip_ds
assert `r(N)' ==  3225
assert `r(sum_w)' ==  3225
assert `r(mean)' ==  17.04031007751938
assert `r(Var)' ==  64.37182372516206
assert `r(sd)' ==  8.023205327371478
assert `r(min)' ==  1
assert `r(max)' ==  27
assert `r(sum)' ==  54955

sum tract_fip_ds
assert `r(N)' ==  3225
assert `r(sum_w)' ==  3225
assert `r(mean)' ==  382566.3392248062
assert `r(Var)' ==  74939011836.45065
assert `r(sd)' ==  273749.9074638212
assert `r(min)' ==  100
assert `r(max)' ==  985600
assert `r(sum)' ==  1233776444

sum blkgrp_fip_ds
assert `r(N)' ==  3225
assert `r(sum_w)' ==  3225
assert `r(mean)' ==  2.288992248062015
assert `r(Var)' ==  1.510130032508127
assert `r(sd)' ==  1.228873481082624
assert `r(min)' ==  1
assert `r(max)' ==  7
assert `r(sum)' ==  7382

sum zipcode_ds
assert `r(N)' ==  3220
assert `r(sum_w)' ==  3220
assert `r(mean)' ==  1992.299378881988
assert `r(Var)' ==  214851.6997200242
assert `r(sd)' ==  463.5209808843869
assert `r(min)' ==  1001
assert `r(max)' ==  2790
assert `r(sum)' ==  6415204

sum cousub_fip_ds
assert `r(N)' ==  3225
assert `r(sum_w)' ==  3225
assert `r(mean)' ==  32564.01395348837
assert `r(Var)' ==  627962401.6930435
assert `r(sd)' ==  25059.17799316337
assert `r(min)' ==  170
assert `r(max)' ==  82525
assert `r(sum)' ==  105018945

drop *_ds


********************************************************************************
** format address variables and city/town names
********************************************************************************
rename NAME cousub_name
replace cousub_name = upper(cousub_name)

* remove 'TOWN' and 'CITY' from end of string...
replace cousub_name = regexr(cousub_name,"( TOWN| CITY)+","")

* replace all 'BOROUGH' with 'BORO' suffix...
replace cousub_name = regexr(cousub_name, "(BOROUGH)$","BORO")

* rename 'MT WASHINGTON'->'MOUNT WASHINGTON'; 'MANCHESTER-BY-THE-SEA'->'MANCHESTER'"
replace cousub_name = "MOUNT WASHINGTON" if cousub_name=="MT WASHINGTON"
replace cousub_name = "MANCHESTER" if cousub_name=="MANCHESTER-BY-THE-SEA"

* extract street number and street name
gen st_num = regexs(0) if regexm(PROPERTYADDRESS, "(^[0-9]+)")
gen street = strtrim(upper(regexs(1))) if regexm(PROPERTYADDRESS, "^[0-9]*([a-zA-Z0-9 |\-]+)")


********************************************************************************
** error check the county and census-tract assignments:
* - 10 non-matching county codes are missing in the original dataset. 
* - 15 non-matching census tracts are missing in the original dataset, with 
* - 41 re-assignmnets. Assume these reassignments are correct.
********************************************************************************
gen tag_tract_code = 0
replace tag_tract_code = 1 if CENSUSTRACT==(state_fip+county_fip+tract_fip)

gen tag_county_code = 0
replace tag_county_code = 1 if COUNTYCODE==(state_fip+county_fip)

// tab CENSUSTRACT if tag_tract_code==0, missing
// tab COUNTYCODE if tag_county_code==0, missing

count if tag_county_code==0
assert `r(N)' == 10

count if tag_tract_code == 0 & CENSUSTRACT == ""
assert `r(N)' == 15

count if tag_tract_code == 0 & CENSUSTRACT != ""
assert `r(N)' == 41

drop tag_*


********************************************************************************
** drop out of scope subsidy types
/* Keep only properties with specific subsidy types. Only some subsidies are 
included in the total unit count. A property is included if at least 1 of the 
folliwng subisidies is present:
	S8	Project Based Section 8
	LIHTC	Low Income Housing Tax Credit
	PH	Public Housing
	PBV	Project Based Voucher (different from S8)
	MR	Mob Rehab
*/
********************************************************************************
gen keepvar = 0

local SubsidyType = "S8 S202 LIHTC HOME PH PBV MR" // <-- change this to alter subsidies included

foreach sub in `SubsidyType' {
	foreach i of numlist 1 2 {
		replace keepvar = 1 if `sub'_`i'_STATUS != ""
		}
}

drop if keepvar == 0

* error check obs count
assert _N == 2961


********************************************************************************
** active property dates
********************************************************************************
gen earliest_start_year = substr(EARLIESTSTARTDATE,-4,4)

gen earliest_end_year = substr(EARLIESTENDDATE,-4,4)

gen latest_end_year = substr(LATESTENDDATE,-4,4)

destring earliest_start_year earliest_end_year latest_end_year, replace

local years = "2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019"

foreach yr of local years {
	gen active_in_`yr' = 0
	replace active_in_`yr' = 1 if (`yr' >= earliest_start_year | earliest_start_year == .) & (`yr' <= latest_end_year | latest_end_year)
}

* error checks
count if active_in_2007 == 1
assert `r(N)' == 1848

count if active_in_2008 == 1
assert `r(N)' == 1930

count if active_in_2009 == 1
assert `r(N)' == 2007

count if active_in_2010 == 1
assert `r(N)' == 2094

count if active_in_2011 == 1
assert `r(N)' == 2227

count if active_in_2012 == 1
assert `r(N)' == 2315

count if active_in_2013 == 1
assert `r(N)' == 2417

count if active_in_2014 == 1
assert `r(N)' == 2491

count if active_in_2015 == 1
assert `r(N)' == 2577

count if active_in_2016 == 1
assert `r(N)' == 2637

count if active_in_2017 == 1
assert `r(N)' == 2697

count if active_in_2018 == 1
assert `r(N)' == 2757

count if active_in_2019 == 1
assert `r(N)' == 2835

destring nhpd_id, gen(nhpd_id_ds)
sum nhpd_id_ds
assert `r(N)' ==  2961
assert `r(sum_w)' ==  2961
assert `r(mean)' ==  1055579.158392435
assert `r(Var)' ==  939019782.9684844
assert `r(sd)' ==  30643.42968677763
assert `r(min)' ==  1000354
assert `r(max)' ==  1154775
assert `r(sum)' ==  3125569888

drop *_ds

// stop
// tempfile save_point
// save `save_point', replace


********************************************************************************
** de-duplicate
********************************************************************************
bysort cousub_name street st_num (latest_end_year nhpd_id): keep if _n==_N

unique cousub_name street st_num
assert `r(unique)' == `r(N)'

unique nhpd_id
assert `r(unique)' == `r(N)'


********************************************************************************
** abel and save all MA file
********************************************************************************
lab var nhpd_id		"NHPD unique property ID"
lab var GEOID		"property GEOID full"
lab var	state_fip	"state FIPS code"
lab var	county_fip	"county FIPS code"
lab var	tract_fip	"census tract FIPS code"
lab var blkgrp_fip	"block group FIPS code"
lab var cousub_name	"city/town name"
lab var cousub_fip	"city/town FIPS"
lab var st_num		"street address number"
lab var street		"street address name"
lab var zipcode		"street address zip code"
lab var earliest_start_year	"first year property has an active subisdy"
lab var earliest_end_year	"first year property has an expired subsidy"
lab var latest_end_year		"last year when all subsidies expire"

* error checks
destring nhpd_id, gen(nhpd_id_ds)

sum nhpd_id_ds

assert `r(N)' ==  2931
assert `r(sum_w)' ==  2931
assert `r(mean)' ==  1055566.852951211
assert `r(Var)' ==  930346273.6101099
assert `r(sd)' ==  30501.57821507127
assert `r(min)' ==  1000354
assert `r(max)' ==  1154775
assert `r(sum)' ==  3093866446

sum LATITUDE
assert `r(N)' ==  2931
assert `r(sum_w)' ==  2931
assert `r(mean)' ==  42.26683645001706
assert `r(Var)' ==  .0855184965064237
assert `r(sd)' ==  .2924354569925195
assert `r(min)' ==  41.27324
assert `r(max)' ==  42.861
assert `r(sum)' ==  123884.097635

sum LONGITUDE
assert `r(N)' ==  2931
assert `r(sum_w)' ==  2931
assert `r(mean)' ==  -71.33294683486865
assert `r(Var)' ==  .3619590501368286
assert `r(sd)' ==  .6016303268094358
assert `r(min)' ==  -73.36205
assert `r(max)' ==  -69.97444900000001
assert `r(sum)' ==  -209076.867173

gen nhpd_lat = LATITUDE
gen nhpd_lon = LONGITUDE

* order variables
keep nhpd_id GEOID state_fip county_fip tract_fip blkgrp_fip cousub_name cousub_fip nhpd_lat nhpd_lon st_num street zipcode TOTALUNITS earliest_start_year earliest_end_year latest_end_year active_*
order nhpd_id GEOID state_fip county_fip tract_fip blkgrp_fip cousub_name cousub_fip nhpd_lat nhpd_lon st_num street zipcode TOTALUNITS earliest_start_year earliest_end_year latest_end_year active_*

* save
save "$DATAPATH/nhpd/nhpd_ma.dta", replace 


********************************************************************************
** save a MAPC region only file
********************************************************************************
* remove 'TOWN' and 'CITY' from end of string..."
replace cousub_name = regexr(cousub_name,"( TOWN| CITY)+","")

* replace all 'BOROUGH' with 'BORO' suffix..."
replace cousub_name = regexr(cousub_name, "(BOROUGH)$","BORO")

* rename 'MT WASHINGTON'->'MOUNT WASHINGTON'; 'MANCHESTER-BY-THE-SEA'->'MANCHESTER'"
replace cousub_name = "MOUNT WASHINGTON" if cousub_name=="MT WASHINGTON"
replace cousub_name = "MANCHESTER" if cousub_name=="MANCHESTER-BY-THE-SEA"

* match to mapc town list
gen MUNI = cousub_name

merge m:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta"

	* validate merge		
	sum _merge
	assert `r(N)' ==  2944
	assert `r(sum_w)' ==  2944
	assert `r(mean)' ==  2.015964673913043
	assert `r(Var)' ==  .995667570617087
	assert `r(sd)' ==  .9978314339692286
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  5935

	keep if _merge ==3
	drop _merge

* error checks
assert _N == 1489		
		
destring nhpd_id, gen(nhpd_id_ds)
sum nhpd_id_ds

assert `r(N)' ==  1489
assert `r(sum_w)' ==  1489
assert `r(mean)' ==  1056297.851578241
assert `r(Var)' ==  966687454.4786283
assert `r(sd)' ==  31091.59781160544
assert `r(min)' ==  1000354
assert `r(max)' ==  1154774
assert `r(sum)' ==  1572827501
	
* keep and order
keep nhpd_id GEOID state_fip county_fip tract_fip blkgrp_fip cousub_name cousub_fip nhpd_lat nhpd_lon st_num street zipcode TOTALUNITS earliest_start_year earliest_end_year latest_end_year active_*
order nhpd_id GEOID state_fip county_fip tract_fip blkgrp_fip cousub_name cousub_fip nhpd_lat nhpd_lon st_num street zipcode TOTALUNITS earliest_start_year earliest_end_year latest_end_year active_*

* save
save "$DATAPATH/nhpd/nhpd_mapc.dta", replace 

clear all

stop
********************************************************************************
** run nhpd sub files
********************************************************************************
do "$DOPATH/data_setup/51_nhpd_boundary_matches.do"

do "$DOPATH/data_setup/52_nhpd_warren_xwalk.do"

clear all

