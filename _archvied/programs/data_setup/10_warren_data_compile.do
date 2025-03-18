*** S:\ DRIVE VERSION ***

********************************************************************************
* File name:		"10_warren_data_compile.do"
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Uses the Warren Group MA time series property file to 
*			construct 4 data sets. These datasets contain total 
*			properties for each year between 2007-2019 and a unique
*			set of every unique property record during those years.
* 				
* Inputs:		$DATAPATH/warren/originals/MA_assessor_annual_expanded.dta
*				
* Outputs:		$DATAPATH/warren/warren_MA_all_annual.dta
*			$DATAPATH/warren/warren_MA_all_unique.dta
*			$DATAPATH/warren/warren_MAPC_all_annual.dta
*			$DATAPATH/warren/warren_MAPC_all_unique.dta
*
* Created:		03/08/2021
* Last updated:		10/18/2022
********************************************************************************


/* If data file not present run './data/warren/MA_assessor_annual_expanded.do' 

This do file is identical to the one found under T:/warren/assessor except
it keeps a few more variables than the original. However, the source data is 
likely to change as it is updated and so running the file again will change the 
asserts used and may change the final data exports.
*/

// do "$DATAPATH/warren/originals/MA_assessor_annual_expanded.do"

********************************************************************************
** Load expanded warren tax assessment data
********************************************************************************
use "$DATAPATH/warren/originals/MA_assessor_annual_expanded.dta", clear

* check the loaded dataset for consistency 
unique prop_id fy
assert `r(N)' ==  32576158
assert `r(sum)' ==  32576158
assert `r(unique)' ==  32576158
assert `r(N)' == `r(unique)'

sum prop_id
assert `r(N)' ==  32576158
assert `r(sum_w)' ==  32576158
assert `r(mean)' ==  2225758.353386056
assert `r(Var)' ==  1954468964726.673
assert `r(sd)' ==  1398023.234687705
assert `r(min)' ==  3
assert `r(max)' ==  5108436
assert `r(sum)' ==  72506655789724

sum fy
assert `r(N)' ==  32576158
assert `r(sum_w)' ==  32576158
assert `r(mean)' ==  2013.82115533698
assert `r(Var)' ==  15.56617805213884
assert `r(sd)' ==  3.945399606141163
assert `r(min)' ==  1994
assert `r(max)' ==  2021
assert `r(sum)' ==  65602556140


********************************************************************************
** Standardize and trim dataset
********************************************************************************
* standardize address information
/* for every <prop_id>, if street number, street name, zip-code, or city is 
missing in earlier years, use the most recent value, drop any missings that 
remain. only really a problem for street numbers and street names. */

bysort prop_id (fy): replace st_num = st_num[_N] if missing(st_num) & st_num[_N]!=.	

bysort prop_id (fy): replace st_numext = st_numext[_N] if missing(st_numext) & st_numext[_N]!=""	

bysort prop_id (fy): replace street = street[_N] if missing(street) & street[_N]!=""	

bysort prop_id (fy): replace zipcode = zipcode[_N] if missing(zipcode) & zipcode[_N]!=.	

bysort prop_id (fy): replace city = city[_N] if missing(city) & city[_N]!=""		

* drop if no address information is available
drop if st_num==. | street=="" | zipcode==. | city==""				

* drop observations outside of research period 2007-2019
keep if fy>=2007 & fy<=2019

* check for consitency
sum prop_id
assert `r(N)' ==  27665432
assert `r(sum_w)' ==  27665432
assert `r(mean)' ==  2174061.055141593
assert `r(Var)' ==  1912332167863.587
assert `r(sd)' ==  1382870.987425648
assert `r(min)' ==  3
assert `r(max)' ==  5068045
assert `r(sum)' ==  60146338284868

sum fy
assert `r(N)' ==  27665432
assert `r(sum_w)' ==  27665432
assert `r(mean)' ==  2013.196852664365
assert `r(Var)' ==  13.45364262114451
assert `r(sd)' ==  3.667920749027235
assert `r(min)' ==  2007
assert `r(max)' ==  2019
assert `r(sum)' ==  55695960630


********************************************************************************
** Geocoding
********************************************************************************

/* Run './15a_geocoding.do':
This adds and fixes a bunch of things and including correcting lat/long 
coordinate points that plot outside of the city/town they are meant to be in. 
*/

do "$DOPATH/data_setup/11_geocoding.do"


********************************************************************************
** Drop missing or misscoded lat/long coordinates
********************************************************************************

/* Even after correcting some of the lat/long points there are still those that 
are missing or do not plot to the correct municipality. These will be dropped 
from the final dataset. */

* drop missing lat/long coordinates
drop if warren_latitude==. | warren_longitude==. // 27,631,161 obs left

* drop misscoded lat/long coordinates
preserve
	sort prop_id fy

	by prop_id: keep if _n == _N // 2,538,987 obs left

	duplicates report prop_id
	
	geoinpoly warren_latitude warren_longitude using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta"
	
	duplicates report prop_id
	
	duplicates tag prop_id, gen(dup_tag)
	
	merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta", keep(1 3) keepusing(NAME)
		drop _merge
	
	* standardized municipal names
	replace NAME = upper(NAME)
	replace NAME = regexr(NAME,"( TOWN| CITY)+","")
	replace NAME = regexr(NAME, "(BOROUGH)$","BORO")
	replace NAME = "MOUNT WASHINGTON" if NAME=="MT WASHINGTON"
	replace NAME = "MANCHESTER" if NAME=="MANCHESTER-BY-THE-SEA"
	
	* dummy to tag correctly matched points
	gen check = 0
		replace check = 1 if cousub_name==NAME	
	
	/* Results of match: 
	Of the 48 observations match to >1 municipality, half matched to the 
	correct one so we should keep them. */
	
	tab dup_tag check
		
	drop if dup_tag == 1 & check == 0 // drops 24 observations
	
	/* We noq are back at the original unique number of 2,538,987 */
	
	/* Drop misscoded properties:
	This will make a dataset of property IDs that correctly mapped to 
	municipalities. */

	drop if check == 0 // 43,902 drops -> 2,495,085 left
		
	tempfile uniques
	save `uniques', replace

restore

merge m:1 prop_id using `uniques', keepusing(check)

* merge error check
sum _merge
assert `r(N)' ==  27631161
assert `r(sum_w)' ==  27631161
assert `r(mean)' ==  2.979089839909369
assert `r(Var)' ==  .0413830868839425
assert `r(sd)' ==  .2034283335328254
assert `r(min)' ==  1
assert `r(max)' ==  3
assert `r(sum)' ==  82315711

/* there should be 0 unmatched from using, keep only matches */	

keep if _merge==3 // 288,886 drops -> 27,342,275 left
drop check _merge
	
* check observation count
assert _N == 27342275
	
	
********************************************************************************
** Residential types
********************************************************************************	
/* run the res type file, this collapses the residential use codes into larger 
categories and drops properties coded as ones we do not need */

do "$DOPATH/data_setup/12_res_types.do"


********************************************************************************
** Dealing with condominiums
********************************************************************************	
/* run the condo collapse file, this collapses condo records under 1 unique p
roperty record */

do "$DOPATH/data_setup/13_condo_collapse.do"


********************************************************************************
** export final datasets
********************************************************************************
* confirm initial observation count
assert _N == 23294781

** export file 1a: all residential properties in MA 2007-2019
* error checks
sum prop_id
assert `r(N)' ==  23294781
assert `r(sum_w)' ==  23294781
assert `r(mean)' ==  2075511.45639167
assert `r(Var)' ==  1731900573696.136
assert `r(sd)' ==  1316016.935185918
assert `r(min)' ==  3
assert `r(max)' ==  5068039
assert `r(sum)' ==  48348584839635

* save data
save "$DATAPATH/warren/warren_MA_all_annual.dta", replace

** export file 1b: all unique residential property records in MA 2007-2019  
preserve

bysort prop_id (fy): keep if _n == _N

* error checks
assert _N == 1961277

sum prop_id
assert `r(N)' ==  1961277
assert `r(sum_w)' ==  1961277
assert `r(mean)' ==  2184470.890842548
assert `r(Var)' ==  1935285127142.365
assert `r(sd)' ==  1391145.257384133
assert `r(min)' ==  3
assert `r(max)' ==  5068039
assert `r(sum)' ==  4284352515379

save "$DATAPATH/warren/warren_MA_all_unique.dta", replace

restore

** export file 2a: all residential properties in MAPC region 2007-2019
* merge on MAPC town list identifier
gen MUNI = cousub_name

merge m:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta"
	
	* check merge
	sum _merge
	assert `r(N)' ==  23294781
	assert `r(sum_w)' ==  23294781
	assert `r(mean)' ==  1.82890034467377
	assert `r(Var)' ==  .9707249496185945
	assert `r(sd)' ==  .9852537488477749
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  42603833

	* drop _merge
	keep if _merge == 3
	drop _merge MUNI MUNI_ID MUNI_IDS_ALL
	
* error checks
assert _N == 9654526

sum prop_id
assert `r(N)' == 9654526
assert `r(sum_w)' == 9654526
assert `r(mean)' == 1273062.482862338
assert `r(Var)' == 1544427108478.022
assert `r(sd)' == 1242749.81733172
assert `r(min)' == 264
assert `r(max)' == 5068039
assert `r(sum)' == 12290814840419

* save data
save "$DATAPATH/warren/warren_MAPC_all_annual.dta", replace	

** export file 2b: all unique residential properties in MAPC region 2007-2019
* keep more recent property record
bysort prop_id (fy): keep if _n == _N

* error checks
assert _N == 821237

sum prop_id
assert `r(N)' == 821237
assert `r(sum_w)' == 821237
assert `r(mean)' == 1452949.470121293
assert `r(Var)' == 2059756671999.198
assert `r(sd)' == 1435185.239611667
assert `r(min)' == 264
assert `r(max)' == 5068039
assert `r(sum)' == 1193215863994

* save data
save "$DATAPATH/warren/warren_MAPC_all_unique.dta", replace

*** END ***
clear all
