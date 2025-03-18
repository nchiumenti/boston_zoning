clear all

********************************************************************************
* File name:		"12_chapter40b.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Cleans the original ch40b file. 
*			Returns 2 datasets of (1) all ch40b properties in raw but
*			usable format and (2) a clean version with boundary IDs
*			attached (for use in the warren/ch40b crosswalk).
*
*			Two python programs are run on JupyterHub. (1) a geocoding
*			programs that assigns lat/lon coordinates using the 
*			Census API geocoder. (2) the boundary match program similar
*			to the one that is used for the Warren records.
* 				
*			Note 08/06/2021: An initial partial list of CH40B properties
*			was received back in December 2020. We received an updated 
*			full list of properties in May of 2021. Because of time 
*			constraints the hand matching with Warren datathat was done 
*			to the initial list could not be expanded upon. The hand-matches
*			from this initial list are used plus geocoding of the new
*			list when applicable to find all best matches between CH40B
*			and Warren properties.
*
*			Note 10/15/2021: Additional hand geocoding was done on 
*			properties by research assistants from U. Toronto 
*			working with Aradhya Sood. These additional coded 
*			properties are appended after the initial geocoding and 
*			before the boundary matching takes place.
*
*
* Inputs:		$DATAPATH/chapter40B/data/chapter40B/Data for Nick Chiumenti 12-23-20_match_criteria.xlsx (received 12/23/2020)
*			$DATAPATH/chapter40B/data/chapter40B/SHI 5-21-21_match_criteria.xlsx (received 5-21-21)
*			$DATAPATH/chapter40B/data/chapter40B/roy_ch40b_project_data_NCedits
*			$DATAPATH/chapter40B/data/chapter40B/jordan_ch40b_project_data_NCedits
*			$DATAPATH/chapter40B/data/chapter40B/geocoder_export_20211020.csv (the last usable run of the python program)
*			$DATAPATH/chapter40B/data/chapter40B/ch40b_export.csv" (boundary match export file)
*
* Outputs:		$DATAPATH/chapter40B/data/chapter40B/chapter40b_mapc.csv
*			$DATAPATH/chapter40B/data/chapter40B/chapter40b_mapc_final
*
* Created:		02/16/2021
* Last updated:		10/20/2021
********************************************************************************

********************************************************************************
** Import original list, comp permits sheet **
/* This part imports the original list received from DHCD that has some hand coded
matches between Warren and CH40b. Comp permits were given seperate from all other
properties counted toward the SHI. The process for this original matching was to
duplicate CH40B records when they match to more than 1 Warren address. If a
ch40b property matches to every property on a road (i.e. a large sub-development)
this is noted under 'matchcriteria'.

The original file is labeled: 'Data for Nick Chiumenti 12-23-20.csv'
The edited version is labeled: 'Data for Nick Chiumenti 12-23-20_match_criteria'
*/
********************************************************************************
import excel "$DATAPATH/chapter40B/originals/Data for Nick Chiumenti 12-23-20_match_criteria.xlsx", sheet("40B (comp permit) projects (2)") firstrow allstring clear

* gen ch40b variables
gen ch40b_id = ID

gen ch40b_projectname = ProjectName

gen ch40b_address_orig = Address

gen ch40b_city = upper(CityTown)

gen ch40b_st_num = st_num

gen ch40b_street = upper(street)

gen ch40b_state = "MA"

gen ch40b_zipcode = ""

gen ch40b_units = SHIunits

gen ch40b_startdate = DateCompPermitIssued

gen ch40b_enddate = YrEnd

gen ch40b_owntype = ownorrent

gen ch40b_agency = FundingAgency

gen ch40b_notes = new_notes

gen ch40b_matchcriteria = matchcriteria

gen ch40b_source = "comp permits sheet"

keep ch40b_*

* error checks
assert _N == 535

destring ch40b_id, gen(ch40b_id_d)
sum ch40b_id_d
assert `r(N)' ==  474
assert `r(sum_w)' ==  474
assert `r(mean)' ==  7191.493670886076
assert `r(Var)' ==  9783935.743088821
assert `r(sd)' ==  3127.928346859758
assert `r(min)' ==  5
assert `r(max)' ==  10529
assert `r(sum)' ==  3408768

* temp save
tempfile comp_permits
save `comp_permits', replace


********************************************************************************
** Import non-comp permits sheet **
/* This part imports the original list received from DHCD that has some hand coded
matches between Warren and CH40b. Comp permits were given seperate from all other
properties counted toward the SHI. The process for this original matching was to
duplicates CH40B records when they match to more than 1 Warren address. If a
ch40b property matches to every property on a road (i. a large sub-development)
this is noted under 'matchcriteria'.

The original file is labeled: 'Data for Nick Chiumenti 12-23-20.csv'
The edited version is labeled: 'Data for Nick Chiumenti 12-23-20_match_criteria'
*/
********************************************************************************
import excel "$DATAPATH/chapter40B/originals/Data for Nick Chiumenti 12-23-20_match_criteria.xlsx", ///
		sheet("non-40B-LIP Local Action Un (2)") firstrow allstring clear

* gen ch40b variables
gen ch40b_id = ID

gen ch40b_projectname = ProjectName

gen ch40b_address_orig = Address

gen ch40b_city = upper(CityTown)

gen ch40b_st_num = st_num

gen ch40b_street = upper(street)

gen ch40b_state = "MA"

gen ch40b_zipcode = ""

gen ch40b_units = SHIunits

gen ch40b_startdate = "no start dates available"

gen ch40b_enddate = YrEnd

gen ch40b_owntype = ownorrent

gen ch40b_agency = ""

gen ch40b_notes = new_notes

gen ch40b_matchcriteria = matchcriteria

gen ch40b_source = "non-40b Local Action Units"

keep ch40b_*

* error checks
assert _N == 489

destring ch40b_id, gen(ch40b_id_d)

sum ch40b_id_d

assert `r(N)' ==  478
assert `r(sum_w)' ==  478
assert `r(mean)' ==  7854.987447698745
assert `r(Var)' ==  10535696.77552345
assert `r(sd)' ==  3245.873807701626
assert `r(min)' ==  16
assert `r(max)' ==  10558
assert `r(sum)' ==  3754684


********************************************************************************
** combine both comp and non-comp permits
********************************************************************************
append using `comp_permits'

drop if ch40b_id=="" | ch40b_matchcriteria=="" | ch40b_matchcriteria=="no match"

gen ch40b_address = ch40b_st_num + " " + ch40b_street

* error checks
assert _N == 609

sum ch40b_id_d
assert `r(N)' ==  609
assert `r(sum_w)' ==  609
assert `r(mean)' ==  7497.952380952381
assert `r(Var)' ==  10117477.59476817
assert `r(sd)' ==  3180.798263764643
assert `r(min)' ==  17
assert `r(max)' ==  10553
assert `r(sum)' ==  4566253

drop *_d

* temp save
tempfile originals
save `originals', replace


********************************************************************************
** Import new full CH40B list
/* Imports the new CH40B list received from DHCD in May 2021 and links it with
the hand matches already done in the previous iteration. In this recent version
the only hand coding that occured was when multi-addresses were clear in the CH40B
data. the match criteria file contains any hand made edits to the data, which
is linked to the main file for clarity.
*/
********************************************************************************
* import expanded address data
import excel "$DATAPATH/chapter40B/originals/SHI 5-21-21_match_criteria.xlsx", sheet("Sheet1") firstrow allstring clear
	
	* drop if no addresses
	keep if STANDARDIZEDADDRESS!=""
	
	tempfile tempsave
	save `tempsave', replace

* import original file
import excel "$DATAPATH/chapter40B/originals/SHI 5-21-21.xlsx", sheet("SHI 5-21-21") cellrange(A5:J7578) firstrow allstring clear

* merge the hand coded expanded addresses for some properties
merge m:1 ID using `tempsave', keepusing(addressisretrievable STANDARDIZEDADDRESS)
	
	* validate merge
	sum _merge
	assert `r(N)' ==  7573
	assert `r(sum_w)' ==  7573
	assert `r(mean)' ==  1.078172454773538
	assert `r(Var)' ==  .1502538175877002
	assert `r(sd)' ==  .3876258732175913
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  8165
		
	drop if _merge==2 // there should be 0 drops
	drop _merge
	
* drop if no addresses
sum if STANDARDIZEDADDRESS!=""
	
* standardized municipal names under MUNI
gen MUNI = upper(CityTown)
replace MUNI = upper(MUNI)
replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"


********************************************************************************
** extract the matching addresses
********************************************************************************
* counts multi address matches
gen count = length(STANDARDIZEDADDRESS) - length(subinstr(STANDARDIZEDADDRESS, ";", "", .))

replace count =1 if count==0

* error check the counts
sum count
assert `r(N)' ==  7573
assert `r(sum_w)' ==  7573
assert `r(mean)' ==  1.048329591971478
assert `r(Var)' ==  .3146211528444848
assert `r(sd)' ==  .5609110026060149
assert `r(min)' ==  1
assert `r(max)' ==  20
assert `r(sum)' ==  7939

* expands dataset to duplicate multi address ch40b properties
expand = count, gen(expand_var)

bysort ID: gen n = _n

* replaces <new_address> for each unique address from multi-address ch40b matches
split STANDARDIZEDADDRESS, gen(stub_) pars(";")

gen new_address = ""

foreach x of numlist 1(1)20{
	replace new_address = stub_`x' if n==`x'
}

drop stub_*

* fills in missings with original address given
replace new_address = Address if new_address=="" 

* adds on older data set matches
gen ch40b_id = ID

merge m:m ch40b_id using `originals', keepusing(ch40b_address ch40b_notes ch40b_source)

	* validate merge
	sum _merge
	assert `r(N)' ==  8078
	assert `r(sum_w)' ==  8078
	assert `r(mean)' ==  1.157712305025997
	assert `r(Var)' ==  .2905874115880748
	assert `r(sd)' ==  .5390616027765981
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  9352

	drop if _merge == 2
	drop _merge
	
* creates a new final address variable and standardizes street suffixes
replace ch40b_address = upper(new_address) if ch40b_address==""
replace ch40b_address = subinstr(ch40b_address,".","",.)
replace ch40b_address = regexr(ch40b_address, "(ROAD)$","RD")
replace ch40b_address = regexr(ch40b_address, "(STREET)$","ST")
replace ch40b_address = regexr(ch40b_address, "(AVENUE)$","AVE")
replace ch40b_address = regexr(ch40b_address, "(PLACE)$","PL")
replace ch40b_address = regexr(ch40b_address, "(COURT)$","CT")
replace ch40b_address = regexr(ch40b_address, "(DRIVE)$","DR")
replace ch40b_address = regexr(ch40b_address, "(TERRACE)$","TR")
replace ch40b_address = regexr(ch40b_address, "(CIRCLE)$","CR")
replace ch40b_address = regexr(ch40b_address, "(SQUARE)$","SQ")
replace ch40b_address = regexr(ch40b_address, "(LANE)$","LN")
replace ch40b_address = regexr(ch40b_address, "(PARKWAY)$","PKWY")
replace ch40b_address = regexr(ch40b_address, "(BOULEVARD)$","BLVD")

* error checks
destring ch40b_id, gen(destring_id)

sum destring_id
assert `r(N)' ==  8078
assert `r(sum_w)' ==  8078
assert `r(mean)' ==  4937.439960386234
assert `r(Var)' ==  12333018.51236608
assert `r(sd)' ==  3511.839761772464
assert `r(min)' ==  2
assert `r(max)' ==  10584
assert `r(sum)' ==  39884640


********************************************************************************
** add on RA geo coded properties
********************************************************************************
preserve	
	* jordan's list
	import excel "$DATAPATH/chapter40B/originals/jordan_ch40b_project_data_NCedits.xlsx", sheet("Sheet1") firstrow allstring clear
	
	keep if jordan_flag=="1"
	
	tempfile jordan
	save `jordan', replace
	
	* roy's list
	import excel "$DATAPATH/chapter40B/originals/roy_ch40b_project_data_NCedits.xlsx", sheet("Sheet1") firstrow allstring clear
	
	keep if roy_flag=="1"
	
	* merge them togethr
	merge 1:m ProjectID using `jordan', keepusing()
	
	* drop non-coded properties
	drop if ch40b_lon=="" | ch40b_lat=="" | prop_id!=""
	
	* drop duplicates
	bysort ID ch40b_lon ch40b_lat: keep if _n==1 // drops duplicated ID with same lat/lon coors
	
	bysort ID (ProjectID): keep if _n==1 // a somewhat arbitrary drop of duplicate IDs based on Project ID
	
	* trim and temp save
	rename ch40b_lon new_lon
	rename ch40b_lat new_lat
	
	gen jr_flag = 1 if jordan_flag=="1" | roy_flag=="1"
	
	keep ProjectID ID Address new_lon new_lat Identifiable Notes FLAG jr_flag
	order ProjectID ID Address new_lon new_lat Identifiable Notes FLAG jr_flag
	
	* error checks
	unique ID
	assert `r(unique)' == `r(N)'
	
	destring new_lon new_lat, gen(destring_lon destring_lat)
	
	sum destring_lon
	assert `r(N)' ==  262
	assert `r(sum_w)' ==  262
	assert `r(mean)' ==  -71.19926151168085
	assert `r(Var)' ==  .0561008909214485
	assert `r(sd)' ==  .2368562663757252
	assert `r(min)' ==  -71.6009869803157
	assert `r(max)' ==  -70.622587217391
	assert `r(sum)' ==  -18654.20651606038
	
	sum destring_lat
	assert `r(N)' ==  262
	assert `r(sum_w)' ==  262
	assert `r(mean)' ==  42.3494973906826
	assert `r(Var)' ==  .0245029171934578
	assert `r(sd)' ==  .1565340767802903
	assert `r(min)' ==  42.0149859567389
	assert `r(max)' ==  42.680694237286
	assert `r(sum)' ==  11095.56831635884
		
	tempfile jordan_roy
	save `jordan_roy', replace
restore
	
* merge on final new geo codes
merge m:1 ID using `jordan_roy', keepusing(jr_flag)

	* validate merge
	sum _merge
	assert `r(N)' ==  8089
	assert `r(sum_w)' ==  8089
	assert `r(mean)' ==  1.08987513907776
	assert `r(Var)' ==  .170333923576962
	assert `r(sd)' ==  .4127153057217069
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  8816

	drop if _merge == 2
	drop _merge

* drops if the address is missing a street number and jr_flag!=1
drop if regexm(ch40b_address, "^[0-9 ]|^[* ]") != 1 & jr_flag != 1

bysort ch40b_address (ch40b_id): keep if _n==1 // drop duplicated addresses

sort ch40b_id ch40b_address

gen unique_id = _n

gen ch40b_city = MUNI

gen ch40b_state="MA"

gen ch40b_zip=""

* data check: make sure unique IDs correspond to the following properties
list ch40b_address ch40b_city if unique_id==484 | unique_id==488		
*       +--------------------------------+
*       |     ch40b_address   ch40b_city |
*       |--------------------------------|
*  484. |      2-12 ORAN RD   FRAMINGHAM |
*  488. | 37-39 NORMANDY RD   FRAMINGHAM |
*       +--------------------------------+

assert ch40b_address == "2-12 ORAN RD" if unique_id==484
assert ch40b_address == "37-39 NORMANDY RD" if unique_id==488

* error checks
sum unique_id
assert `r(N)' ==  3475
assert `r(sum_w)' ==  3475
assert `r(mean)' ==  1738
assert `r(Var)' ==  1006591.666666667
assert `r(sd)' ==  1003.290419901768
assert `r(min)' ==  1
assert `r(max)' ==  3475
assert `r(sum)' ==  6039550

// tempfile save_point
// save `save_point', replace
// stop	

	
********************************************************************************
** Geocoding and boundary matching of CH40B properties
/* Only uncomment if you intend to re-run the geocoding program. Even though
the code should re-produce the same dataset each time there may be errors and the
unique_id variable may be end up being different, which will cause a miss-match.
For the purposes of this report the Oct 20th 2021 export geocoded export file is 
used.*/
********************************************************************************	
preserve

* exports ch40b property set for geocoding
// keep unique_id ch40b_address ch40b_city ch40b_state ch40b_zip
// order unique_id ch40b_address ch40b_city ch40b_state ch40b_zip
//
// local date_stamp : di %tdCCYYNNDD date("$S_DATE","DMY")
// export delimited using "$DATAPATH/chapter40B/chapter40b_geocode_inputs_`date_stamp'.csv", novarnames replace

*** RUN PYTHON PROGRAM BatchAddressMatch_final.ipynb BEFORE NEXT STEP ***

* import the geocoder exported file after running the python API program
import delimited using "$DATAPATH/chapter40B/chapter40b_geocoder_export_20211020.csv", stringcols(_all) clear
	
destring recordidnumber, replace

rename recordidnumber unique_id
rename interpolatedlongitudeandlatitude ch40b_coors

* error checks
assert _N == 3475

count if tigermatchtype == "Exact"
assert `r(N)' == 2348

count if tigermatchtype == "Non_Exact"
assert `r(N)' == 285

tab tigermatchtype

tempfile geocodes
save `geocodes', replace
	
restore

* merge on geocoded file to main ch40b dataset
merge 1:1 unique_id using `geocodes', keepusing()
	
	* validate merge
	sum _merge
	assert `r(N)' ==  3475
	assert `r(sum_w)' ==  3475
	assert `r(mean)' ==  3
	assert `r(Var)' ==  0
	assert `r(sd)' ==  0
	assert `r(min)' ==  3
	assert `r(max)' ==  3
	assert `r(sum)' ==  10425
	
	* drop using non matches
	drop if _merge==2 // 0 drops, all _merge==3
	drop _merge

* add back on jordan/roy file
merge m:1 ID using `jordan_roy',

	* validate merge
	sum _merge
	assert `r(N)' ==  3518
	assert `r(sum_w)' ==  3518
	assert `r(mean)' ==  1.167993177942013
	assert `r(Var)' ==  .2956258265101708
	assert `r(sd)' ==  .5437148393323202
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  4109
	
	* drop using non matches
	drop if _merge==2 // 43 drops, 274 matches
	drop _merge


********************************************************************************
** format geocodes
********************************************************************************
* create latitude and longitude coordinate vaariables
split ch40b_coors, parse(,) gen(coors_)

replace coors_1 = new_lon if new_lon != ""
replace coors_2 = new_lat if new_lat != ""

destring coors_*, replace

gen ch40b_lon = coors_1
gen ch40b_lat = coors_2

* create fips code variables
rename statecode state_fip
rename countycode county_fip
rename tractcode census_tract
rename blockcode block_group

tostring state_fip, replace format(%02.0f)
tostring county_fip, replace format(%03.0f)
tostring census_tract, replace format(%06.0f)
tostring block_group, replace format(%04.0f)

* error checks
destring state_fip county_fip census_tract block_group, gen(state_fip_d county_fip_d census_tract_d block_group_d)

sum state_fip_d
assert `r(N)' ==  2633
assert `r(sum_w)' ==  2633
assert `r(mean)' ==  25
assert `r(Var)' ==  0
assert `r(sd)' ==  0
assert `r(min)' ==  25
assert `r(max)' ==  25
assert `r(sum)' ==  65825

sum county_fip_d
assert `r(N)' ==  2633
assert `r(sum_w)' ==  2633
assert `r(mean)' ==  15.73832130649449
assert `r(Var)' ==  44.54585994687488
assert `r(sd)' ==  6.674268495264098
assert `r(min)' ==  1
assert `r(max)' ==  27
assert `r(sum)' ==  41439

sum census_tract_d
assert `r(N)' ==  2633
assert `r(sum_w)' ==  2633
assert `r(mean)' ==  432118.1591340676
assert `r(Var)' ==  46028202858.991
assert `r(sd)' ==  214541.8440747422
assert `r(min)' ==  10100
assert `r(max)' ==  985600
assert `r(sum)' ==  1137767113

sum block_group_d
assert `r(N)' ==  2633
assert `r(sum_w)' ==  2633
assert `r(mean)' ==  2199.925180402583
assert `r(Var)' ==  1416827.77365522
assert `r(sd)' ==  1190.305747972016
assert `r(min)' ==  1000
assert `r(max)' ==  8007
assert `r(sum)' ==  5792403

drop *_d


********************************************************************************
** relabel and order
********************************************************************************
* drop and order the dataset
#delimit ;
keep 
	unique_id 
	ch40b_id 
	ch40b_address 
	ch40b_city 
	state_fip 
	county_fip 
	census_tract 
	block_group 
	ch40b_lon 
	ch40b_lat
	SHIUnits 
	CompPermit
	ch40b_source
	YrEnd 
	OwnorRent 
	SubsidizingAgency 
	DateCompPermitIssued 
	MUNI;

order 
	unique_id 
	ch40b_id 
	ch40b_address 
	ch40b_city 
	state_fip 
	county_fip 
	census_tract 
	block_group 
	ch40b_lon 
	ch40b_lat
	SHIUnits 
	CompPermit 
	ch40b_source
	YrEnd 
	OwnorRent 
	SubsidizingAgency 
	DateCompPermitIssued 
	MUNI;
	
#delimit cr


********************************************************************************
** save all MA chapter40b sample
********************************************************************************
save "$DATAPATH/chapter40B/chapter40b_ma.dta", replace


********************************************************************************
** save restricted MAPC chapter40b sample
********************************************************************************
* merge with MAPC town list to drop out of scope towns
merge m:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta"

	* validate _merge
	sum _merge
	assert `r(N)' ==  3478
	assert `r(sum_w)' ==  3478
	assert `r(mean)' ==  2.111845888441633
	assert `r(Var)' ==  .9869116909393744
	assert `r(sd)' ==  .9934342912036882
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  7345
	
	* keep master-using matches
	keep if _merge ==3
	drop _merge

save "$DATAPATH/chapter40B/chapter40b_mapc.dta", replace


********************************************************************************
** run ch40b sub files
********************************************************************************
do "$DOPATH/data_setup/61_ch40b_boundary_matches.do"

do "$DOPATH/data_setup/62_ch40b_warren_xwalk.do"

clear all
