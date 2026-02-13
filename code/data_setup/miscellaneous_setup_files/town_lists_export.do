clear all

********************************************************************************
* File name:		"town_lists_export.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Creates tw .dta files with a list of admissable cities 
*			and towns in Massachusetts and in the MAPC region.
* 				
* Inputs:		2019_gaz_cousubs_25.txt
*			MAPC_town_list.txt
*				
* Outputs:		$DATAPATH/geocoding/MA_cousub_list.dta
*			$DATAPATH/geocoding/MAPC_town_list.dta
*			
*
* Created:		02/24/2021
* Updated:		02/24/2021
********************************************************************************

* geocoding datasets
* lists of all countysubdivisions in towns
* lists of all MAPC cities and towns

local ROOT "/home/a1nfc04/Documents/Boston_Affordable_Housing_Project_SDRIVE/data/geocoding"

* census tracks
import delimited "`ROOT'/2019_gaz_cousubs_25.txt", case(upper) stringcols(_all) varnames(1) clear

gen state_fip = substr(GEOID,1,2)
gen county_fip = substr(GEOID,3,3)
gen cousub_fip = substr(GEOID,6,.)

drop if cousub_fip == "00000"

replace NAME = upper(NAME)

replace NAME = regexr(NAME,"( TOWN| CITY)+","")
replace NAME = regexr(NAME, "(BOROUGH)$","BORO")
replace NAME = "MOUNT WASHINGTON" if NAME=="MT WASHINGTON"
replace NAME = "MANCHESTER" if NAME=="MANCHESTER-BY-THE-SEA"
rename NAME cousub_name

save "`ROOT'/MA_cousub_list.dta", replace

* MAPC towns
local ROOT "/home/a1nfc04/Documents/Boston_Affordable_Housing_Project_SDRIVE/data/geocoding"
import delimited "`ROOT'/MAPC_town_list.txt", case(upper) stringcols(_all) varnames(1) clear

replace MUNI = upper(MUNI)
replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
replace MUNI = "Mount Washington" if MUNI=="Mt Washington"

save "`ROOT'/MAPC_town_list.dta", replace

clear all
