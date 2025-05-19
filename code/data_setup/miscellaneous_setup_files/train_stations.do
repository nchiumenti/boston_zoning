clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="train_stations" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

** WORKING PAPER VERSION **

********************************************************************************
* File name:		"train_stations.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		
* 				
* Inputs:		various
*				
* Outputs:		
*
* Created:		
* Updated:		
********************************************************************************


********************************************************************************
** assign towns to the train stations
********************************************************************************
** mbta stations
use "$SHAPEPATH/train_stations/MBTA_NODE_latlon.dta", clear

rename _ID mbta_node_id

drop if LINE == "SILVER"

geoinpoly _CY _CX using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta"

merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta"
	keep if _merge == 3
	
gen mbta_stations = 1

tempfile mbta 
save `mbta', replace

** commuter rail stations
use "$SHAPEPATH/train_stations/TRAINS_NODE_latlon.dta", clear

rename _ID trains_node_id

geoinpoly _CY _CX using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta"

merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta"
	keep if _merge == 3

gen train_stations = 1
	
append using `mbta'

gen station_lat = _CY
gen station_lon = _CX
gen station_name = STATION
gen muni_name = NAME

keep station_* muni_*

gen MUNI = upper(muni_name)

replace MUNI = regexr(MUNI,"( TOWN| MUNI)+","")
replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

*Basic ring defition
#delimit ;
gen def_1 = 1 if (MUNI=="ARLINGTON" | 
			MUNI=="BELMONT" | 
			MUNI=="BOSTON" | 
			MUNI=="BROOKLINE" | 
			MUNI=="CAMBRIDGE" | 
			MUNI=="CHELSEA" |
			MUNI=="EVERETT" | 
			MUNI=="MALDEN" | 
			MUNI=="MEDFORD" | 
			MUNI=="MELROSE" | 
			MUNI=="NEWTON" | 
			MUNI=="REVERE" | 
			MUNI=="SOMERVILLE" | 
			MUNI=="WALTHAM" | 
			MUNI=="WATERTOWN" | 
			MUNI=="WINTHROP") ;
				   
replace def_1 = 2 if (MUNI=="BEVERLY" | 
			MUNI=="FRAMINGHAM" | 
			MUNI=="GLOUCESTER"| 
			MUNI=="LYNN" | 
			MUNI=="MARLBORO" | 
			MUNI=="MILFORD" | 
			MUNI=="SALEM" | MUNI=="WOBURN") ;
				   
replace def_1 = 3 if (MUNI=="ACTON" | 
			MUNI=="BEDFORD" | 
			MUNI=="CANTON"| 
			MUNI=="CONCORD" | 
			MUNI=="DEDHAM" | 
			MUNI=="DUXBURY" |
			MUNI=="HINGHAM" | 
			MUNI=="HOLBROOK" | 
			MUNI=="HULL" | 
			MUNI=="LEXINGTON" | 
			MUNI=="LINCOLN" | 
			MUNI=="MARBLEHEAD" | 
			MUNI=="MARSHFIELD" | 
			MUNI=="MAYNARD" | 
			MUNI=="MEDFIELD" | 
			MUNI=="MILTON" | 
			MUNI=="NAHANT"| 
			MUNI=="NATICK" | 
			MUNI=="NEEDHAM" | 
			MUNI=="NORTH READING" | 
			MUNI=="PEMBROKE" | 
			MUNI=="RANDOLPH" | 
			MUNI=="SCITUATE" |	
			MUNI=="SHARON" | 
			MUNI=="SOUTHBORO" |  
			MUNI=="STONEHAM" | 
			MUNI=="STOUGHTON" |  
			MUNI=="SUDBURY" | 
			MUNI=="SWAMPSCOTT" | 
			MUNI=="WAKEFIELD" | 
			MUNI=="WAYLAND" | 
			MUNI=="WELLESLEY" | 
			MUNI=="WESTON" | 
			MUNI=="WESTWOOD" | 
			MUNI=="WEYMOUTH") ;
				   
replace def_1 = 4 if (MUNI=="BOLTON" | 
			MUNI=="BOXBORO" | 
			MUNI=="CARLISLE"| 
			MUNI=="COHASSET" | 
			MUNI=="DOVER" | 
			MUNI=="ESSEX" | 
			MUNI=="FOXBORO" | 
			MUNI=="FRANKLIN" | 
			MUNI=="HANOVER" | 
			MUNI=="HOLLISTON" | 
			MUNI=="HOPKINTON" | 
			MUNI=="HUDSON" | 
			MUNI=="LITTLETON" | 
			MUNI=="MANCHESTER" | 
			MUNI=="MEDWAY" | 
			MUNI=="MIDDLETON" | 
			MUNI=="MILLIS"| 
			MUNI=="NORFOLK" | 
			MUNI=="NORWELL" | 
			MUNI=="ROCKLAND" | 
			MUNI=="ROCKPORT" | 
			MUNI=="SHERBORN" | 
			MUNI=="STOW" | 
			MUNI=="TOPSFIELD" | 
			MUNI=="WALPOLE" | 
			MUNI=="WRENTHAM" ) ;
#delimit cr			


gen def_name = "Inner Core" if def_1 == 1 /* Blue  */
replace def_name = "Regional Urban" if def_1 == 2 /* Grey  */
replace def_name = "Mature Suburbs" if def_1 == 3 /* Green  */
replace def_name = "Developing Suburbs" if def_1 == 4 /* Yellow  */

drop if def_name == ""

tempfile stations
save `stations', replace

// import excel "$DATAPATH/Train_station_policy.xlsx", sheet("Sheet1") firstrow allstring clear
//
// tempfile stations
// save `stations', replace

use "$DATAPATH/final_dataset_10-28-2021.dta", clear

run "$DOPATH/wp_within_town_setup" // runs setup file quietly

keep if year == 2018

drop MUNI

gen MUNI = upper(city)

joinby MUNI using `stations', _merge(_merge)
	tab _merge
	keep if _merge == 3
	drop _merge
	
* calculate distance between property and station
destring warren_latitude warren_longitude station_lat station_lon, replace

geodist warren_latitude warren_longitude station_lat station_lon, gen(station_dist) miles
	
gen pt3miles = (station_dist <= .3)
	
tab station_name pt3miles
		
keep if station_dist <= .3
	
tempfile save_point
save `save_point', replace
	
	
* gen gd and hd measures
gen all = 1						// to count all properties

gen gd = (res_type!=. & (num_units==2 | num_units==3))	// to count gentle density

gen hd = (res_type!=. & (num_units>=4 & num_units!=.))	// to count high density

* gen boundary type variable
gen boundary_type = ""
	replace boundary_type = "only_du" if only_du == 1
	replace boundary_type = "only_he" if only_he == 1
	replace boundary_type = "only_mf" if only_mf == 1
	replace boundary_type = "du_he" if du_he == 1
	replace boundary_type = "mf_he" if mf_he == 1
	replace boundary_type = "mf_du" if mf_du == 1
	replace boundary_type = "mf_he_du" if mf_he_du == 1
	
bysort station_name boundary_using_id: gen boundary_count = 1 if _n == 1 // for count of boundaries

bysort station_name boundary_using_id boundary_side: gen boundary_side_flag = 1 if _n == 1

egen boundary_side_count = total(boundary_side_flag), by(station_name boundary_using_id)

drop if boundary_side_count == 1 // drop boundaries that are missing their left or right side

* collapse to boundary level
collapse (sum) boundary_count all gd hd num_units ///
	(mean) dupac du_delta height he_delta mf_allowed ///
	(min) min_dupac=dupac (max) max_dupac=dupac ///
	(min) min_height=height (max) max_height=height ///
	(mean) house_rent def_houseprice comb_rent2, ///
	by(MUNI station_name def_1 def_name boundary_type)

* calc thetas
gen theta_gd = (gd / all)
	
gen theta_hd = (hd / all)
	
keep if boundary_type == "du_he" | boundary_type == "mf_du" | boundary_type == "only_du"

********************************************************************************
** summary stats at boundary level
********************************************************************************
// restrict to at least containing one of these (keep all if yes):
// 	du_he
// 	mf_du
// 	only_du
//	
// restrict avg to just 1 decimal
//
// avg mf_allowed

// check: is boundary_using_id the unqiue id or is it id + left/right
	
* count of boundaries by regulation type
table station_name boundary_type, c(sum boundary_count) by(MUNI) missing column concise

* sum stats for  dupac, delta dupac, height, delta height
bysort MUNI def_name station_name: tabdisp boundary_type, cellvar(dupac height du_delta he_delta mf_allowed) format(%4.3f)

* sum stats for thetas
// bysort Station_Name: tabstat theta_gd theta_hd, by(boundary_type) s(min max mean) c(s)
bysort MUNI def_name station_name: tabdisp boundary_type, cellvar(theta_gd theta_hd) format(%4.3f)

* average number of units
// bysort Station_Name: tabstat num_units, by(boundary_type) s(sum mean) c(s)
bysort MUNI def_name station_name: tabdisp boundary_type, cellvar(num_units) format(%4.3f)

* average rents and houseprices (with dupac and height means
bysort MUNI def_name station_name: tabdisp boundary_type, cellvar(dupac height house_rent def_houseprice comb_rent2) format(%11.3f)



********************************************************************************
log off
	
	
	
	
	
	
	
