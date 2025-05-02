********************************************************************************
/*This program assembles a data set of amenities, prices and institutions at the 
block group level*/
********************************************************************************
clear 
set more off 
set scheme plotplainblind

cd "$AffordableBoston\Data"
*global home "C:\Users\kulka2\Downloads"
*cd "$home"

*crosswalks 

import delimited "$AffordableBoston\Data\Crosswalks\bg2cousub.csv", varnames(1) encoding(ISO-8859-2) 
rename citytownname townname
replace townname = upper(townname)
replace townname = "MANCHESTER" if townname == "MANCHESTER-BY-THE-SEA"

by statefip countyfip tractfip blockgroupfip, sort: egen max = max(afact) /*could change this later, for now just keep max*/
keep if afact == max

*expand for 34 years
expand = 35
gen year = . 
by statefip countyfip tractfip blockgroupfip, sort: replace year = _n  /*should be 34 years for each bg*/
replace year = year +1984

*now unique by blockgroup and year
tempfile bg2cosub
save `bg2cosub', replace
clear

*similiarly for zip to bg crosswalks
import delimited "$AffordableBoston\Data\Crosswalks\bg2zcta.csv", varnames(1) rowrange(3) 
destring zcta5, replace 
destring afact, replace
rename zcta5 zip
by county tract bg, sort: egen max = max(afact)
keep if afact == max

by county tract bg, sort: gen nvals = _n == 1
tab nvals
drop if nvals == 0
drop nvals /*this comes from 99999 zip codes which have no population*/

rename state statefip
rename bg blockgroupfip
gen countyfip = substr(county,3,3)
replace tract = subinstr(tract,".","",.)
rename tract tractfip

expand = 35
gen year = . 
by statefip countyfip tractfip blockgroupfip, sort: replace year = _n  /*should be 34 years for each bg*/
replace year = year +1984

keep zip year statefip countyfip tractfip blockgroupfip

gen BLKGRP = statefip + countyfip + tractfip + blockgroupfip
drop statefip countyfip tractfip blockgroupfip

tempfile bg2zip
save `bg2zip', replace
clear

/*
import delimited "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Crosswalks\bg2place.csv", varnames(1) rowrange(3) 
gen townname = placenm
replace townname = subinstr(townname," city","",.)
replace townname = upper(townname)
replace townname = subinstr(townname," TOWN","",.)
replace townname = subinstr(townname," CDP","", .)
replace townname = subinstr(townname," VILLAGE","",.)
replace townname = subinstr(townname,", MA","",.)

tempfile bg2place
save `bg2place', replace
clear
*/

*CHAPTER 40 B

import excel "$AffordableBoston\Data\Opposition data\Chapter40B_referendum_TownResults.xlsx", sheet("Sheet1") cellrange(A1:D352) firstrow

gen passed = (Yes>No)
gen margin = (Yes-No)/(Yes+No)

gen townname = upper(Cityortown)

tempfile pioneer
save `pioneer', replace
clear

*SHI
import excel "$AffordableBoston\Data\Chapter 40B housing\shi_2017.xlsx", sheet("Sheet1") firstrow
rename E frac_aff_2017
label var frac_aff_2017 "Fraction of housing qualified as affordable"
gen townname = upper(Community)

tempfile shi
save `shi', replace
clear 



*PIONEER DATA
import excel "$AffordableBoston\Data\Pioneeer Zoning data\Pioneer Datat.xls", sheet("landreg") firstrow


*merge with pioneer data 
merge 1:1 townname using `pioneer', keepusing(passed margin)
keep if _merge ==3

drop _merge

*merge with shi
merge 1:1 townname using `shi'
keep if _merge == 3
drop _merge 

rename massgis TOWN_ID

tempfile amenities
save `amenities', replace

*TOWN STRUCTURE
clear
import excel "$AffordableBoston\Data\Opposition data\muni_forms_of_gov_2017.xlsx", sheet("Sheet1") firstrow

replace Town = upper(Town)
rename Town townname

*some cleaning 
replace townname = "FRAMINGHAM" if townname == "FRAMINGHAM*"
replace townname = "MANCHESTER" if townname == "MANCHESTER-BY-THE-SEA" 

tempfile gov
save `gov', replace

clear 
use `amenities'

merge 1:1 townname using `gov'
keep if _merge == 3
drop _merge 

save `amenities', replace

*CRIME
clear
import delimited "$AffordableBoston\Data\Amenity\Crime\AllCrimeData.csv"
keep if state == "MA"

gen townname = subinstr(agency," Police Dept","",.)
replace townname = upper(townname)
rename v16 murderrate

keep townname year populationcoverage violentcrimetotal propertycrimetotal 
rename populationcoverage population
rename violentcrimetotal violentcrime
rename propertycrimetotal propertycrime

tempfile crime
save `crime', replace
clear 


*clean and merge newer crime data 
quietly{
/*
*2011 is already in the older crime data
import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_11.xls", sheet("11tbl08ma") cellrange(A5:L268) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2011
rename City townname 
replace townname=upper(townname)
tempfile crime11
save `crime11', replace
clear
*/

import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_13.xls", sheet("13tbl8ma") cellrange(A5:M284) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2013
rename City townname 
replace townname=upper(townname)
tempfile crime13
save `crime13', replace
clear

import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_15.xls", sheet("15tbl08ma") cellrange(A5:M268) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2015
rename City townname 
replace townname=upper(townname)
tempfile crime15
save `crime15', replace
clear

import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_14.xls", sheet("14tbl08ma") cellrange(A5:M260) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2014
rename City townname 
replace townname=upper(townname)
tempfile crime14
save `crime14', replace
clear

import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_16.xls", sheet("16tbl06ma") cellrange(A5:M281) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2016
rename City townname 
replace townname=upper(townname)
tempfile crime16
save `crime16', replace
clear

import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_17.xls", sheet("17tbl08ma") cellrange(A5:L279) firstrow
keep Violentcrime Propertycrime State Population

gen year = 2017
rename State townname 
replace townname=upper(townname)
tempfile crime17
save `crime17', replace
clear

import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_18.xls", sheet("18tbl08ma") cellrange(A5:L284) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2018
rename City townname 
replace townname=upper(townname)
tempfile crime18
save `crime18', replace
clear


import excel "C:\Users\kulka\Dropbox\Boston Affordable Housing Project (Aradhya, Nick)\Data\Amenity\Crime\MA_19.xls", sheet("19tbl08ma") cellrange(A5:L286) firstrow
keep Violentcrime Propertycrime City Population

gen year = 2019
rename City townname 
replace townname=upper(townname)
tempfile crime19
save `crime19', replace
clear
}

use `crime13'
forvalues i = 14/19{
append using `crime`i''
}

rename Population population
rename Violentcrime violentcrime
rename Propertycrime propertycrime

*some cleaning
replace townname = "MANCHESTER" if townname=="MANCHESTER-BY-THE-SEA"
replace townname = "NORTH ATTLEBOROUGH" if townname=="NORTH ATTLEBORO"
replace townname = "MIDDLEBOROUGH" if townname == "MIDDLEBORO"
replace townname = "TYNGSBOROUGH" if townname == "TYNGSBORO"

append using `crime'
save `crime', replace

*merge into main data set 
clear 
use `amenities'

merge 1:m townname using `crime'   /*adding in years now hence 1:m*/
drop if _merge == 2 /*Millis town is missing in all years for the crime data, since it lies in Worcester county, this is probably not an issue*/
drop _merge 


*use crosswalk to convert to block group level 
merge 1:m townname year using `bg2cosub'  /*Millis town is missing again*/
drop if _merge == 2
drop _merge

tostring countyfip, replace
replace countyfip = "0" + countyfip if strlen(countyfip)==2
replace countyfip = "00" + countyfip if strlen(countyfip)==1
tostring blockgroupfip, replace
tostring tractfip, replace

gen BLKGRP = "25" + countyfip + tractfip + blockgroupfip

*save "$AffordableBoston\Data\Amenity\town_level_amenities.dta", replace
save `amenities', replace
clear

*EDUCATION 
import excel "$AffordableBoston\Data\School District Relationship Files\grf19_lea_blkgrp.xlsx", sheet("grf19_lea_blkgrp") firstrow

by BLKGRP, sort: egen area_tot = total(LANDAREA) 
by BLKGRP, sort: egen water_tot= total(WATERAREA)
by BLKGRP, sort: gen area_frac = (LANDAREA+WATERAREA)/(area_tot+water_tot)

by BLKGRP, sort: egen max_frac = max(area_frac)
*keep all schools and LEAIDs in descending order of land fraction
sort BLKGRP area_frac
keep LEAID BLKGRP area_frac
by BLKGRP, sort: gen school_num=_n
reshape wide LEAID area_frac, i(BLKGRP) j(school_num)

*current assumption is that school boundaries were fixed over time 
expand = 35
gen year = . 
by BLKGRP, sort: replace year = _n  /*should be 34 years for each bg*/
replace year = year +1984

tempfile educ
save `educ', replace 
clear 

*merge back in with amenities 
use `amenities'
sort BLKGRP year
merge 1:1 BLKGRP year using `educ'
drop if _merge == 2
drop _merge

save `amenities', replace
clear

*CBP
quietly{
foreach l of numlist 94 95 96 97 {
import delimited "$AffordableBoston\Data\Amenity\Establishments\zbp`l'detail.txt", varnames(1) 
keep sic zip est
keep if sic == "5600" | sic =="5610" | sic =="5620" | sic =="5630" | sic =="5640" | sic =="5650" | sic =="5660" | sic =="5690" | sic =="7830" | sic =="7832" | sic =="7833" | sic =="5800" | sic =="5810" | sic =="5812" | sic =="5813" | sic =="8400" | sic =="8410" | sic =="8420" | sic =="7900" | sic =="7920" | sic =="7910" | sic =="7922" | sic =="7929" | sic =="7930" | sic =="7940" | sic =="7941" | sic =="7948" | sic =="7990" | sic =="7991" | sic =="7992" | sic =="7993" | sic =="7996" | sic =="7997" | sic =="7999"
by zip, sort: egen total_est = total(est)
collapse total_est, by(zip)
gen year = 19`l'
tempfile zbp`l'
save `zbp`l'', replace
clear
 }
 

foreach l of numlist 98 99{
import delimited "$AffordableBoston\Data\Amenity\Establishments\zbp`l'detail.txt", varnames(1) 
rename naics sic
keep sic zip est
keep if sic == "448110" | sic =="448120" | sic =="448130" | sic =="448140" | sic =="448150" | sic =="448190" | sic =="512131" | sic =="512132" | sic =="722110" | sic =="722211" | sic =="722212" | sic =="722213" | sic =="722410" | sic =="712110" | sic =="712120" | sic =="712130" | sic =="712190" | sic =="713110" | sic =="713120" | sic =="711110" | sic =="711120" | sic =="711130" | sic =="711190" | sic =="713910" | sic =="713920" | sic =="713930" | sic =="713940" | sic =="713950" | sic =="713990" 
by zip, sort: egen total_est = total(est)
collapse total_est, by(zip)
gen year = 19`l'
tempfile zbp`l'
save `zbp`l'', replace
clear
 }
 
foreach l of numlist 10 11 12 13 14 15 16 17 18{
import delimited "$AffordableBoston\Data\Amenity\Establishments\zbp`l'detail.txt", varnames(1) 
rename naics sic
keep sic zip est
keep if sic == "448110" | sic =="448120" | sic =="448130" | sic =="448140" | sic =="448150" | sic =="448190" | sic =="512131" | sic =="512132" | sic =="722110" | sic =="722211" | sic =="722212" | sic =="722213" | sic =="722410" | sic =="712110" | sic =="712120" | sic =="712130" | sic =="712190" | sic =="713110" | sic =="713120" | sic =="711110" | sic =="711120" | sic =="711130" | sic =="711190" | sic =="713910" | sic =="713920" | sic =="713930" | sic =="713940" | sic =="713950" | sic =="713990" 
by zip, sort: egen total_est = total(est)
collapse total_est, by(zip)
gen year = 20`l'
tempfile zbp`l'
save `zbp`l'', replace
clear
 } 
  
 
forvalues l = 0/9 {
import delimited "$AffordableBoston\Data\Amenity\Establishments\zbp0`l'detail.txt", varnames(1) 
rename naics sic
keep sic zip est
keep if sic == "448110" | sic =="448120" | sic =="448130" | sic =="448140" | sic =="448150" | sic =="448190" | sic =="512131" | sic =="512132" | sic =="722110" | sic =="722211" | sic =="722212" | sic =="722213" | sic =="722410" | sic =="712110" | sic =="712120" | sic =="712130" | sic =="712190" | sic =="713110" | sic =="713120" | sic =="711110" | sic =="711120" | sic =="711130" | sic =="711190" | sic =="713910" | sic =="713920" | sic =="713930" | sic =="713940" | sic =="713950" | sic =="713990" 
by zip, sort: egen total_est = total(est)
collapse total_est, by(zip)
gen year = 200`l'
tempfile zbp`l'
save `zbp`l'', replace
clear
 }
 
 }
 use `zbp94'
 foreach l of numlist 95 96 97 98 99 10 11 12 13 14 15 16 17 18{
 append using `zbp`l''
}

forvalues l = 0/9 {
    append using `zbp`l''
}

*merge with crosswalk to get block groups
merge 1:m zip year using `bg2zip'   /*2003 - 2011 have very few unmatched*/
keep if _merge == 3
drop _merge 

tempfile cbp
save `cbp', replace

clear
use `amenities'

merge 1:1 BLKGRP year using `cbp'   /*most unmerged are in years for which there is no business info */
drop if _merge == 2
drop _merge 

*label
label var passed "Passed 2010 Chapter 40B referendum" 
label var margin "Margin by which 2010 referendum passed/failed" 
drop afact max 
label var total_est "Total number of stores, restaurants, entertainment"

*This data set is now unique by blockgroup and years
save "$AffordableBoston\Data\Amenity\bg_amenities_85_19.dta", replace

*ENVIRONMENT --> do this later after figuring out exactly what needs to be kept

