clear all

// log close _all
//
// local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")
//
// local name ="13_costar" // <--- change when necessry
//
// log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

********************************************************************************
* File name:		40_costar.do
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Imports all data from excel file downloads and stores in
*			one stata .dta file. Uses the first row as variable headers.
*			Data was downloaded from CoStar.com in batches for all
*			city and towns in the MAPC service region. Contains data 
*			only on multi-family properties in CoStar which usually 
*			excludes 1-4 unit properties.
*
*			This main file also calls 2 sub-files that can be run
*			independently to export a warren->costar crosswalk and
*			a costar rent history dataset
*			
* Inputs:		./costar/costar_exports/<*.xlsx>
*				
* Outputs:		./costar/costar_mf_all.dta
*
* Created:		03/02/2021
* Last updated:		11/07/2022
********************************************************************************

********************************************************************************
** combine xlsx files into one .dta file
********************************************************************************
* import .xlsx files and store as tempfiles
local files : dir "$DATAPATH/costar/costar_exports" files "*.xlsx"

local i = 1

foreach f in `files' {
	noi di "Importing and storing CoStar export file '`f''..."
	import excel "$DATAPATH/costar/costar_exports/`f'", firstrow allstring clear
	tempfile costar_`i'
	save `costar_`i''
	local i = `i' + 1
}

clear

* append costar tempfiles together
local i = `i' - 1

noi di "Appending Costar files together..."

forval n = 1(1)`i' {
	noi di char(9) "appending `n' of `i' files"
	qui append using `costar_`n''
}


********************************************************************************
** dataset cleanup
********************************************************************************
* rename un-named variables
rename AJ OneBed
rename AK TwoBed
rename AL ThreeBed
rename AM FourBed

* street number, name serparation, gen city variable
gen costar_stnum = regexs(1) if regexm(PropertyAddress, "^([0-9]+)")

gen costar_street = regexs(1) if regexm(PropertyAddress, "[ ]([ a-zA-Z0-9]+)$")

gen costar_city = upper(City)

* city/town name standardize
local neighborhoods = `""ALLSTON" "BRIGHTON" "CHARLESTOWN" "DORCHESTER" "EAST BOSTON" "FENWAY" "HYDE PARK" "JAMAICA PLAIN" "MATTAPAN" "MISSION HILL" "ROXBURY" "ROXBURY CROSSING" "SOUTH BOSTON" "WEST ROXBURY""'
foreach n in `neighborhoods'{
	di "`n'"
	replace costar_city = "BOSTON" if costar_city == "`n'"
}

local villages = `""AUBURNDALE" "NEWTON CENTER" "NEWTON HIGHLANDS" "NEWTON LOWER FALLS" "NEWTONVILLE" "WEST NEWTON" "WABAN""'
foreach v in `villages'{
	di "`v'"
	replace costar_city = "NEWTON" if costar_city == "`v'"
}

replace costar_city = "WALPOLE" if costar_city == "EAST WALPOLE"

replace costar_city = "WEYMOUTH" if costar_city == "EAST WEYMOUTH"

replace costar_city = "QUINCY" if costar_city == "NORTH QUINCY"

replace costar_city = "WEYMOUTH" if costar_city == "NORTH WEYMOUTH"

replace costar_city = "REVERE" if costar_city == "REVERE BEACH"

replace costar_city = "HAMILTON" if costar_city == "SOUTH HAMILTON"

replace costar_city = "WALPOLE" if costar_city == "SOUTH WALPOLE"

replace costar_city = "WEYMOUTH" if costar_city == "SOUTH WEYMOUTH"

replace costar_city = regexr(costar_city, "(BOROUGH)$","BORO")

destring Latitude Longitude, gen(costar_lat costar_long)

* data validity checks
destring PropertyID, gen(destring_id)
sum destring_id
assert `r(N)' ==  7130
assert `r(sum_w)' ==  7130
assert `r(mean)' ==  7883071.926928471
assert `r(Var)' ==  7677547272086.636
assert `r(sd)' ==  2770838.730797344
assert `r(min)' ==  9001
assert `r(max)' ==  12041048
assert `r(sum)' ==  56206302839

sum costar_lat
assert `r(N)' ==  7130
assert `r(sum_w)' ==  7130
assert `r(mean)' ==  42.35469422218794
assert `r(Var)' ==  .0083049821347733
assert `r(sd)' ==  .0911316747062912
assert `r(min)' ==  42.0168212
assert `r(max)' ==  42.686828
assert `r(sum)' ==  301988.9698042

sum costar_long
assert `r(N)' ==  7130
assert `r(sum_w)' ==  7130
assert `r(mean)' ==  -71.09204017314165
assert `r(Var)' ==  .0172746310056483
assert `r(sd)' ==  .1314329905527842
assert `r(min)' ==  -71.62274050000001
assert `r(max)' ==  -70.612543
assert `r(sum)' ==  -506886.2464345


********************************************************************************
** add missing cities/towns and geoids
********************************************************************************
* replaces chestnut hill properties with correct city/town (it can be any of 3 options)
local ROOT $SHAPEPATH/originals

geoinpoly costar_lat costar_long if costar_city=="CHESTNUT HILL" using "`ROOT'/cb_2018_25_cousub_500k_shp.dta", unique noprojection

merge m:1 _ID using "`ROOT'/cb_2018_25_cousub_500k.dta", keep(1 3) keepusing(NAME)

	* merge check
	sum _merge
	assert `r(N)' ==  7130
	assert `r(sum_w)' ==  7130
	assert `r(mean)' ==  1.004488078541375
	assert `r(Var)' ==  .0089572705129297
	assert `r(sd)' ==  .0946428576963403
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  7162
	
	drop if _merge == 2
	replace costar_city = upper(NAME) if _merge==3
	drop NAME _merge _ID

* costar geoid (4 are not assigned and so are included below)
local ROOT $SHAPEPATH/originals

geoinpoly costar_lat costar_long using "`ROOT'/cb_2018_25_bg_500k_shp.dta", unique noprojection

merge m:1 _ID using "`ROOT'/cb_2018_25_bg_500k.dta", keep(1 3) keepusing(GEOID)
	
	* merge check
	sum _merge
	assert `r(N)' ==  7130
	assert `r(sum_w)' ==  7130
	assert `r(mean)' ==  2.998877980364656
	assert `r(Var)' ==  .0022430949421963
	assert `r(sd)' ==  .0473613232732815
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  21382

	drop if _merge == 2

	* add census geocodes retreived from GeoCoder
	replace GEOID = "250092033022" if PropertyID == "4758080"

	replace GEOID = "250092033022" if PropertyID == "7869703"

	replace GEOID = "250251805001" if PropertyID == "9363126"

	replace GEOID = "250251805001" if PropertyID == "10343522"

	gen costar_GEOID = GEOID

	drop GEOID _merge _ID

* data validity check
destring costar_GEOID, gen(destring_geoid)
sum destring_geoid
assert `r(N)' ==  7130
assert `r(sum_w)' ==  7130
assert `r(mean)' ==  250208166694.7703
assert `r(Var)' ==  2595563324412335
assert `r(sd)' ==  50946671.37716001
assert `r(min)' ==  250092021013
assert `r(max)' ==  250277444003
assert `r(sum)' ==  1783984228533712

drop destring_*


********************************************************************************
** final cleanup and error checks
********************************************************************************	
* drop duplicates due to reload files
duplicates drop PropertyID, force

gen costar_id = PropertyID // unique ID variable

* error checks
unique costar_id
assert `r(N)' == `r(unique)'

destring costar_id, gen(destring_id)
sum destring_id
assert `r(N)' ==  7069
assert `r(sum_w)' ==  7069
assert `r(mean)' ==  7885511.494553685
assert `r(Var)' ==  7660721446785.423
assert `r(sd)' ==  2767800.832210552
assert `r(min)' ==  9001
assert `r(max)' ==  12041048
assert `r(sum)' ==  55742680755

sum costar_lat
assert `r(N)' ==  7069
assert `r(sum_w)' ==  7069
assert `r(mean)' ==  42.35478789192248
assert `r(Var)' ==  .0083733849272351
assert `r(sd)' ==  .0915062015780082
assert `r(min)' ==  42.0168212
assert `r(max)' ==  42.686828
assert `r(sum)' ==  299405.995608

sum costar_long
assert `r(N)' ==  7069
assert `r(sum_w)' ==  7069
assert `r(mean)' ==  -71.09105191966331
assert `r(Var)' ==  .0173065319479365
assert `r(sd)' ==  .1315542927765435
assert `r(min)' ==  -71.62274050000001
assert `r(max)' ==  -70.612543
assert `r(sum)' ==  -502542.6460201

count if AvgEffectiveUnit == ""
assert `r(N)' == 5184

count if AvgAskingUnit == ""
assert `r(N)' == 5184

count if AvgAskingSF == ""
assert `r(N)' == 5422


********************************************************************************
** end
********************************************************************************
save "$DATAPATH/costar/costar_mf_all.dta", replace

destring _all, replace

save "$DATAPATH/costar/costar_mf_destring.dta", replace

clear all


********************************************************************************
** run sub costar files
********************************************************************************

do "$DOPATH/data_setup/41_costar_warren_xwalk.do"

do "$DOPATH/data_setup/42_costar_rent_history.do"

clear all
