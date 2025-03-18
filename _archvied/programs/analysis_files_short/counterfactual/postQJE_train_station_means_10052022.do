clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postQJE_train_stations_means" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES VERSION **


********************************************************************************
* File name:		"postQJE_train_stations_means.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		calculates means around train stations using mt lines 
*			setup. dupac and height means calcualted at boundary level
*			rents, prices, units means calc'd at property level.
*			means calc'd based on properties and boundaries within
*			.5 miles of train station.
* 				
* Inputs:		./mt_orthogonal_dist_100m_07-01-22_v2.dta
*			./final_dataset_10-28-2021.dta"
*			./station_boundary_dist.csv
*			./cb_2018_25_cousub_500k_shp.dta"
*			./cb_2018_25_cousub_500k.dta"
*			./adm3_latlong.dta
*			./regulation_types.dta
*			./all_stations.csv
*				
* Outputs:		./postQJE_train_station_means.dta
*
* Created:		05/23/2022
* Updated:		10/05/2022
********************************************************************************

* create a save directory if none exists
global EXPORTPATH "$DATAPATH/postQJE_data_exports/`name'_`date_stamp'"

capture confirm file "$EXPORTPATH"

if _rc!=0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

cd $EXPORTPATH

********************************************************************************
** load striaght line and final dataset (warren properties)
/* run with the within town setup file and keep striaght line properties to keep 
the sample the same and to calc things like sales price and rent, keep only 
year==2018 to calc means*/
********************************************************************************
use "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load final dataset
********************************************************************************
use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
run "$DOPATH/postQJE_within_town_setup.do"


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* check merge for errors
	sum _merge
	assert `r(N)' ==  3400297
	assert `r(sum_w)' ==  3400297
	assert `r(mean)' ==  2.940873106084557
	assert `r(Var)' ==  .0556309206919615
	assert `r(sd)' ==  .235862079809285
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9999842
	
	* drop merge vars	
	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties

keep if year == 2018

tab year

tempfile warren
save `warren', replace


********************************************************************************
** load train stations boundar distance file
/* source .csv file comes from python output from station_boundary_dist.ipynb 
which calcs distance from train stations to all boundaries and keeps only those
boundaries witin .5 miles */
********************************************************************************
import delimited "$SHAPEPATH/train_stops/station_boundary_dist.csv", clear stringcols(_all)

* trim variables
keep station_id station_name station_lat station_lon boundary_using_id left_fid right_fid dist_meters dist_miles
order station_id station_name station_lat station_lon boundary_using_id left_fid right_fid dist_meters dist_miles


********************************************************************************
** assign train stations to their city/town and MAPC community type
********************************************************************************
destring station_lat station_lon, replace

geoinpoly station_lat station_lon using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta"

merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta", keepusing(NAME)

	* merge error checks
	sum _merge
	assert `r(N)' ==  32086
	assert `r(sum_w)' ==  32086
	assert `r(mean)' ==  2.990400797855763
	assert `r(Var)' ==  .0095073537709077
	assert `r(sd)' ==  .0975056601993327
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  95950

	* drop merge vars
	keep if _merge == 3
	drop _merge _ID

* gen and clean municipality name
gen MUNI_NAME = upper(NAME)

replace MUNI = regexr(MUNI,"( TOWN| MUNI)+","")
replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

* define MAPC community type classifications
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

gen def_name = ""
replace def_name = "Inner Core" if def_1 == 1 		/* Blue  */
replace def_name = "Regional Urban" if def_1 == 2 	/* Grey  */
replace def_name = "Mature Suburbs" if def_1 == 3 	/* Green  */
replace def_name = "Developing Suburbs" if def_1 == 4	/* Yellow  */

drop if def_name == ""


********************************************************************************
** merge on zoning regulatory data
********************************************************************************
* confirm that obs are unique at station_id boundary_id level
unique station_id boundary_using_id
	assert `r(N)' ==  31689
	assert `r(sum)' ==  31689
	assert `r(unique)' ==  31689

* merge on left/right boundary ids
destring boundary_using_id, replace

gen _ID = boundary_using_id + 1 // <-- to match properly add 1, python ID's start at 0

merge m:1 _ID using "$SHAPEPATH/zoning_boundaries/adm3_crs4269/adm3_latlong.dta", keepusing(LEFT_FID RIGHT_FID)
	
	* check merge for errors
	sum _merge
	assert `r(N)' ==  53215
	assert `r(sum_w)' ==  53215
	assert `r(mean)' ==  2.595489993422907
	assert `r(Var)' ==  .2408861878156406
	assert `r(sd)' ==  .4908015768267667
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  138119

	* drop merge vars
	drop if _merge == 2
	drop _ID _merge

	/* check that the merge was correct on boundary_using_id, the left/right
	fid from the train station file should match the one from adm3_latlon */
	destring left_fid right_fid, replace
 	
	assert left_fid == LEFT_FID
	assert right_fid == RIGHT_FID
	
	* drop fids from initial .csv file
	drop left_fid right_fid

* reshape and merge on the regulation data
rename LEFT_FID FID_LEFT
rename RIGHT_FID FID_RIGHT
	
reshape long FID_, i(station_id boundary_using_id) j(SIDE) string

rename FID_ LRID

merge m:1 LRID using "$DATAPATH/regulation_data/regulation_types.dta", keepusing(mulfam mxht_eff dupac_eff)

	* check merge for errors
	sum _merge
	assert `r(N)' ==  68323
	assert `r(sum_w)' ==  68323
	assert `r(mean)' ==  2.356219721030985
	assert `r(Var)' ==  .8007424318601312
	assert `r(sd)' ==  .8948421267799874
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  160984

	* drop merge vars
	drop if _merge == 2
	drop _merge

/* confirm unique id level, at this point in the code observations are unique
by <station_id boundary_using_id SIDE> */
unique station_id boundary_using_id SIDE
	assert `r(N)' ==  63378
	assert `r(sum)' ==  63378
	assert `r(unique)' ==  63378

* define home and neighbor (nn_) regulation vars
rename mxht_eff home_mxht_eff
rename dupac_eff home_dupac_eff
rename mulfam home_mulfam 

gen nn_mxht_eff = .
gen nn_dupac_eff = .
gen nn_mulfam = .


********************************************************************************
** define relaxed/strict side of the boundaries
/* the code for identifying relaxed vs. strict side regulations are taken
directly from wp_within_town_setup.do */
********************************************************************************
* if RIGHT side boundary, assign LEFT side regulations to neigbor vars
bysort station_id boundary_using_id (SIDE): replace nn_mxht_eff = home_mxht_eff[1] if SIDE == "RIGHT"
bysort station_id boundary_using_id (SIDE): replace nn_dupac_eff = home_dupac_eff[1] if SIDE == "RIGHT"
bysort station_id boundary_using_id (SIDE): replace nn_mulfam = home_mulfam[1] if SIDE == "RIGHT"

* if LEFT side boundary, assign RIGHT side regulations to neigbor vars
bysort station_id boundary_using_id (SIDE): replace nn_mxht_eff = home_mxht_eff[_N] if SIDE == "LEFT"
bysort station_id boundary_using_id (SIDE): replace nn_dupac_eff = home_dupac_eff[_N] if SIDE == "LEFT"
bysort station_id boundary_using_id (SIDE): replace nn_mulfam = home_mulfam[_N] if SIDE == "LEFT"
		
* gen regulation change across boundary variables
gen mf_delta = home_mulfam - nn_mulfam  
gen he_delta = home_mxht_eff - nn_mxht_eff
gen du_delta = home_dupac_eff - nn_dupac_eff 

* gen indicators for which regulation is changing
gen only_mf = mf_delta != 0 & he_delta == 0 & du_delta == 0
gen only_he = he_delta != 0 & mf_delta == 0 & du_delta == 0
gen only_du = du_delta != 0 & he_delta == 0 & mf_delta == 0 
gen mf_he = mf_delta != 0 & he_delta != 0 & du_delta == 0
gen mf_du = mf_delta != 0 & he_delta == 0 & du_delta != 0
gen du_he = mf_delta == 0 & he_delta != 0 & du_delta != 0
gen mf_he_du = mf_delta != 0 & he_delta != 0 & du_delta != 0

* gen variables for home and neighboring zoning regulations
gen own_du = home_dupac_eff
gen other_du = nn_dupac_eff

gen own_he = home_mxht_eff
gen other_he = nn_mxht_eff

* create standardized versions of own_ and other_
sum own_du
gen std_du_own = (own_du - `r(mean)')/`r(sd)'

sum own_he
gen std_he_own = (own_he - `r(mean)')/`r(sd)'

sum other_du
gen std_du_other = (other_du - `r(mean)')/`r(sd)'

sum other_he
gen std_he_other = (other_he - `r(mean)')/`r(sd)'

** <relaxed> easy cases and letting MF allowed dominating other regulations
gen relaxed = 0
 
replace relaxed = 1 if only_he == 1 & he_delta>0
replace relaxed = 1 if only_du == 1 & du_delta>0
replace relaxed = 1 if only_mf == 1 & mf_delta==1

replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta<0   // flip this in relaxed2

* multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta<0

* this is only the clear case
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

* when two of 3 are relaxed, count as relaxed
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0

replace relaxed = . if (home_mulfam == . & home_mxht_eff == . & home_dupac_eff == .) ///
	| (nn_mulfam == . & nn_mxht_eff == . & nn_dupac_eff == .)

gen strict = 1 if relaxed == 0
replace strict = 0 if relaxed == 1

/* summarize no relaxed/strict comparison and drop if there are no relaxed or 
strict side boundaries (which happens if boundary regulation data is missing) 
or if there are 2 strict side boundaries (which happens if boundary regulations 
data are exactly the same) */
egen a = total(relaxed), by(station_id boundary_using_id)
egen b = total(strict), by(station_id boundary_using_id)

tab a b

drop if a == 0 | b == 0 | b == 2

drop a b

* check unique obs count
unique station_id boundary_using_id SIDE
	assert `r(N)' ==  41924
	assert `r(sum)' ==  41924
	assert `r(unique)' ==  41924


********************************************************************************
** merge on warren group properties
********************************************************************************
gen boundary_side = SIDE

joinby boundary_using_id boundary_side using `warren', unmatched(master) _merge(_joinby)
	
	* joinby check
	sum _joinby
	assert `r(N)' ==  102066
	assert `r(sum_w)' ==  102066
	assert `r(mean)' ==  2.250406599651206
	assert `r(Var)' ==  .9373057181807131
	assert `r(sd)' ==  .9681455046534654
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  229690

	keep if _joinby == 3
	drop _joinby

	
********************************************************************************
** calcualte distance to property
********************************************************************************
geodist station_lat station_lon warren_lat warren_lon, generate(prop_dist_mile)

drop if prop_dist_mile>.5


********************************************************************************
** generate means and collapse vars
********************************************************************************
gen saleprice = def_saleprice if res_typex == "Single Family Res"

gen rent = comb_rent2 if res_typex != "Condominiums"

gen units = num_units1 if res_typex != "Condominiums"

gen side = "relaxed" if relaxed == 1
replace side = "strict" if relaxed == 0

gen boundary_type = ""
replace boundary_type = "only_mf" if only_mf == 1
replace boundary_type = "only_he" if only_he == 1
replace boundary_type = "only_du" if only_du == 1
replace boundary_type = "mf_he" if mf_he == 1
replace boundary_type = "mf_du" if mf_du == 1
replace boundary_type = "du_he" if du_he == 1
replace boundary_type = "mf_he_du" if mf_he_du == 1

// stop
// tempfile save_point
// save `save_point', replace


********************************************************************************
** calcualte distance to property
********************************************************************************
preserve

collapse (count) prop_n=prop_id ///
	(mean) mean_units=units mean_saleprice=saleprice mean_rent=rent ///
	,by(station_id station_name station_lat station_lon def_1 def_name boundary_type side)
	
* error checks
sum mean_units
	assert `r(N)' ==  559
	assert `r(sum_w)' ==  559
	assert `r(mean)' ==  9.355653678634878
// 	assert `r(Var)' ==  1180.205872066956
	assert `r(sd)' ==  34.35412452773257
	assert `r(min)' ==  1
	assert `r(max)' ==  444
	assert `r(sum)' ==  5229.810406356897

sum mean_saleprice
	assert `r(N)' ==  270
	assert `r(sum_w)' ==  270
	assert `r(mean)' ==  825674.2827073019
// 	assert `r(Var)' ==  215686731863.4877
	assert `r(sd)' ==  464420.8564044984
	assert `r(min)' ==  190990.2496316312
	assert `r(max)' ==  1956448.897010949
	assert `r(sum)' ==  222932056.3309715

sum mean_rent
	assert `r(N)' ==  485
	assert `r(sum_w)' ==  485
	assert `r(mean)' ==  1998.016040669532
// 	assert `r(Var)' ==  937289.3210726834
	assert `r(sd)' ==  968.1370363087467
	assert `r(min)' ==  339.0915829108626
	assert `r(max)' ==  4819.001080832831
	assert `r(sum)' ==  969037.7797247233

tempfile prop_lvl
save `prop_lvl', replace

restore


********************************************************************************
** calculate means at boundary level and temp save
********************************************************************************
bysort station_id boundary_using_id side: keep if _n == 1

collapse (count) boundary_n=boundary_using_id ///
	(mean) mean_height=home_mxht_eff mean_dupac=home_dupac_eff ///
	,by(station_id station_name station_lat station_lon def_1 def_name boundary_type side)

* error checks
sum mean_height
	assert `r(N)' ==  604
	assert `r(sum_w)' ==  604
	assert `r(mean)' ==  46.07332071901608
	assert `r(Var)' ==  1443.156119614917
	assert `r(sd)' ==  37.98889468798635
	assert `r(min)' ==  0
	assert `r(max)' ==  356
	assert `r(sum)' ==  27828.28571428571

sum mean_dupac
	assert `r(N)' ==  604
	assert `r(sum_w)' ==  604
	assert `r(mean)' ==  40.25883497940617
	assert `r(Var)' ==  3252.366354105255
	assert `r(sd)' ==  57.02952177692931
	assert `r(min)' ==  0
	assert `r(max)' ==  349
	assert `r(sum)' ==  24316.33632756133


********************************************************************************
** merge on property lvl mean data
********************************************************************************
merge 1:1 station_id station_name station_lat station_lon def_1 def_name boundary_type side using `prop_lvl'
	
	* check merge for errors
	sum _merge
	assert `r(N)' ==  604
	assert `r(sum_w)' ==  604
	assert `r(mean)' ==  3
	assert `r(Var)' ==  0
	assert `r(sd)' ==  0
	assert `r(min)' ==  3
	assert `r(max)' ==  3
	assert `r(sum)' ==  1812

	* drop merge var
	drop if _merge == 2
	drop _merge


********************************************************************************
** label variables and save .dta file
********************************************************************************
* add back line layer variables
preserve
	import delimited "$SHAPEPATH/train_stops/all_stations.csv", clear stringcols(_all)
	tempfile stations
	save `stations', replace
restore

merge m:1 station_id using `stations', keepusing(line layer)
	drop if _merge == 2
	drop _merge

order station_id station_name line layer station_lat station_lon def_1 def_name side boundary_type boundary_n mean_height mean_dupac prop_n mean_units mean_saleprice mean_rent 

lab var station_id "train station unique id"
lab var station_name "train station name"
lab var line "station train line name"
lab var layer "commuter rail/mbta rapid transit"
lab var station_lat "train station latitude"
lab var station_lon "train station longitude"
lab var def_1 "community type def var"
lab var def_name "community type name"
lab var side "relaxed/strict side of boundary"
lab var boundary_type "zoning reg type"
lab var boundary_n "count of boundaries used in means"
lab var mean_height "mean max eff height reg"
lab var mean_dupac "mean eff dupac reg"
lab var prop_n "count of properties used in means"
lab var mean_units "mean number of units"
lab var mean_saleprice "mean sales price of sf homes"
lab var mean_rent "mean rent in mf properties"

* error check
unique station_id
	assert `r(N)' ==  604
	assert `r(sum)' ==  194
	assert `r(unique)' ==  194

* export with town names
destring station_lat station_lon, replace

geoinpoly station_lat station_lon using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta"

merge m:1 _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta", keepusing(NAME)

	* drop merge vars
	keep if _merge == 3
	drop _merge _ID

* gen and clean municipality name
gen MUNI_NAME = upper(NAME)

replace MUNI = regexr(MUNI,"( TOWN| MUNI)+","")
replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

rename MUNI_NAME cousub_name

drop NAME

* save file
save "postQJE_train_station_means.dta", replace


********************************************************************************
** end
********************************************************************************
log close
clear all
