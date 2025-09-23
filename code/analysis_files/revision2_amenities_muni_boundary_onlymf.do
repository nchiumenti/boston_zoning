* start here
clear all
log close _all
set linesize 255

local name ="amenities_muni_boundary_onlymf"  // <--- change when necessry

* creates an output directory if none exists

global EXPORTPATH "$WORKINGDIR/analysis/`name'_output"

global DATAPATH "${DATAPATH_replication_package}"
global DOPATH "~/rda-projects/clones_dept/boston_zoning/code/analysis_files"


capture confirm file "$EXPORTPATH"

if _rc != 0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

* start log file
local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

log using "$EXPORTPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
* File name:		amenities_muni_boundary_onlymf.do
*
* Project title:	Boston Zoning Paper
*
* Description:		Is the same as amenities except comparing across town 
*					boundaries instead of zoning boundaries
*                   REStat Revision 2 - testing out what is going on with only 
*					MF boundaries at muni boundaries.
*
* Inputs:			dist_south_station_2022_09_29.csv
*					transit_distance.csv
*					soil_quality_matches.dta
*					warren_group_walkability.dta
*					final_dataset_town_comparisons.dta
*
* Outputs:			multiple .tex files
*					log output
*
* Created:			06/23/2021
* Updated:			03/19/2025
********************************************************************************

confirm file "$DATAPATH/dist_south_station_2022_09_29.csv"
confirm file "$DATAPATH/transit_distance.csv"
confirm file "$DATAPATH/soil_quality_matches.dta"
confirm file "$DATAPATH/warren_group_walkability.dta"
confirm file "$DATAPATH/final_dataset_town_comparisons.dta"

* set to 1 to run setup code
scalar UPDATE_INT_FILE = 1
if UPDATE_INT_FILE {

********************************************************************************
** load and tempsave the transit data
********************************************************************************
import delimited "$DATAPATH/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/transit_distance.csv", clear stringcols(_all)

merge m:1 station_id using `dist_south_station'
		
		* merge error check
		sum _merge
		drop if _merge == 2
		drop _merge
	
keep prop_id station_id station_name distance_m_* length_m

destring prop_id distance_m_* length_m, replace

gen transit_dist_m = distance_m_man + length_m

tempfile transit
save `transit', replace


********************************************************************************
** load and tempsave the soil data
********************************************************************************
use "$DATAPATH/soil_quality_matches.dta", clear

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren_group_walkability.dta"

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


********************************************************************************
** load final town comparisons dataset and run the setup
********************************************************************************
use "$DATAPATH/final_dataset_town_comparisons.dta", clear

run "$DOPATH/analysis_town_comparisons_setup.do"


********************************************************************************
** merge on transit data
********************************************************************************
merge m:1 prop_id using `transit'

	* merge error check
	sum _merge	
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'

	* merge error check
	sum _merge
	drop if _merge == 2
	drop _merge 

	
********************************************************************************
** merge on walkscore variables 
********************************************************************************
merge m:1 prop_id using `walkscore', 

	* merge error check
    sum _merge
    drop if _merge == 2
    drop _merge 


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** gen amenity variables
********************************************************************************
gen dist_school = closest_school_dist
gen dist_center = closest_city_dist
gen dist_road = closest_road_dist
gen dist_river = closest_river_dist
gen dist_space = closest_green_dist

gen transit_dist = transit_dist_m/1609

gen soil_avgslope = avg_slope
gen soil_slope15 = slope_15
gen soil_avgrestri = avg_restri
gen soil_avgsand = avg_sand
gen soil_avgclay = avg_clay

* save a mid-point version to cut down on run time while error checking code
// save "$DATAPATH/final_dataset_town_comparisons_postsetup_20240930.dta", replace
}
* load mid-point version to cut down on run time while error checking code
// use  "$DATAPATH/final_dataset_town_comparisons_postsetup_20240930.dta", clear


*check number of boundaries and cities for only_mf samples 
*unique number of boundaries
unique lam_seg if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" 

unique lam_seg if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" & dist_river!=.

unique lam_seg if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" & dist_school!=.


unique lam_seg if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" & lam_seg!=.


*unique number of cities
unique city if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" 

unique city if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" & dist_river !=.

unique city if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" & dist_school!=.

unique city if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>-0.02) & res_typex != "Condominiums" & lam_seg!=.


********************************************************************************
** distance to highway 
********************************************************************************
capture noisily {
** regressions
quietly eststo road_mf: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_road if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_road if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"


esttab road_mf , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_mf") title("Distance to Highway (miles)") 
	
* robust s.e.

quietly eststo road_mf_robust: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab road_mf_robust, ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("road_mf" ) title("Distance to Highway (miles), robust s.e.") 
}	
	
	
********************************************************************************
** distance to water body
********************************************************************************
capture noisily {
** regressions

quietly eststo river_mf: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_river if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_river if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab river_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("river_mf") title("Distance to River (miles)") 
	
* robust s.e.
quietly eststo river_mf_robust: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab river_mf_robust , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "river_mf" ) title("Distance to River (miles), robust s.e.") 
}


********************************************************************************
** distance to green space
********************************************************************************
capture noisily {
** regressions

quietly eststo space_mf: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_space if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_space if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab space_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_mf") title("Distance to Green Space (miles)") 
	
* robust s.e.

quietly eststo space_mf_robust: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab space_mf_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_mf") title("Distance to Green Space (miles), robust s.e.") 
}


********************************************************************************
* distance to school
********************************************************************************
capture noisily {
** regressions
quietly eststo school_mf: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_school if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_school if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"


esttab school_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_mf") title("Distance to School (miles)") 
	
* robust s.e.

quietly eststo school_mf_robust: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab school_mf_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("school_mf") title("Distance to School (miles), robust s.e.") 
}


********************************************************************************
** distance to city center
********************************************************************************
capture noisily {
** regressions

quietly eststo center_mf: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum dist_center if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum dist_center if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"


esttab center_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_mf") title("Distance to City Center (miles)") 
	
* robust s.e.

quietly eststo center_mf_robust: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab center_mf_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_du" "center_duhe" "center_mfdu" "center_mf" "center_mfhe" "center_he") title("Distance to City Center (miles), robust s.e.") 
}


********************************************************************************
** commuting distance to downtown distance (south station)
********************************************************************************
capture noisily {

quietly eststo transit_mf: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum transit_dist if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum transit_dist if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab transit_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_mf") title("Public Transit Distance to Downtown Boston (miles)") 
	
	
* robust s.e.

quietly eststo transit_mf_robust: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab transit_mf_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_mf") title("Public Transit Distance to Downtown Boston (miles), robust s.e.") 
}


********************************************************************************
** Mean slope of lot
********************************************************************************
capture noisily {
** regressions

quietly eststo slope_mf: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgslope if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgslope if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab slope_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "slope_mf") title("Mean Slope of Lot (degrees)") 

* robust s.e.

quietly eststo slope_mf_robust: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab slope_mf_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_mf") title("Mean Slope of Lot (degrees), robust s.e.") 
}


********************************************************************************
** percent of lot >15 degrees
********************************************************************************
capture noisily {
** regressions

quietly eststo slope15_mf: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_slope15 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_slope15 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab slope15_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_mf") title("Percent of Lot with Slope >15 Degrees") 
	
* robust s.e.

quietly eststo slope15_mf_robust: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab slope15_mf_robust, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope15_mf") title("Percent of Lot with Slope >15 Degrees, robust s.e.") 
}

	
********************************************************************************
** depth to restrictive layer
********************************************************************************
capture noisily {
** regressions

quietly eststo depth_mf: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgrestri if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgrestri if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab depth_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "depth_mf") title("Depth to Restrictive Layer (cm)") 
	
* robust s.e.

quietly eststo depth_mf_r: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab depth_mf_r , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("depth_mf") title("Depth to Restrictive Layer (cm), robust s.e.") 
}

	
********************************************************************************
** mean percent sand
********************************************************************************
capture noisily {
** regressions

quietly eststo sand_mf: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgsand if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgsand if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"

esttab  sand_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "sand_mf" ) title("Avg. Percent Sand") 
	
* robust s.e.
quietly eststo sand_mf_r: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab sand_mf_r , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "sand_mf" ) title("Avg. Percent Sand, robust s.e.") 
}


********************************************************************************
** mean percent clay
********************************************************************************
capture noisily {
** regressions

quietly eststo clay_mf: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum soil_avgclay if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum soil_avgclay if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"


esttab clay_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "clay_mf" ) title("Mean Percent Clay") 
		  
	
* robust s.e.

quietly eststo clay_mf_r: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab clay_mf_r , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("clay_mf" ) title("Mean Percent Clay, robust s.e.") 
}


********************************************************************************
*WALKABILITY VARIABLES
********************************************************************************
********************************************************************************
** National Walkability Index score
********************************************************************************
capture noisily {
** regressions

quietly eststo walk_mf: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum natwalkind if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum natwalkind if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"


esttab  walk_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_mf" ) title("Walkability Index") 
	
* robust s.e.

quietly eststo walk_mf_r: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)

esttab walk_mf_r , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "walk_mf" ) title("Walkability Index, robust s.e.") 
}


********************************************************************************
** Employment mix  (only tables)
********************************************************************************
capture noisily {
** regressions

quietly eststo empl_mf: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster lam_seg)
sum d2b_e8mixa if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex != "Condominiums" 
sum d2b_e8mixa if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex != "Condominiums"


esttab empl_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_mf" ) title("Employment mix") 
	
	
* robust s.e.
quietly eststo empl_mf_r: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(robust)


esttab  empl_mf_r , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_mf" ) title("Employment mix, robust s.e.") 
}


********************************************************************************
*Standard errors clustered by municipality
********************************************************************************
********************************************************************************
** distance to highway 
********************************************************************************
capture noisily {
** regressions

quietly eststo road_mf: reg dist_road ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)

esttab road_mf , ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "road_mf" ) title("Distance to Highway (miles)") 
	


********************************************************************************
** distance to river
********************************************************************************
capture noisily {
** regressions

quietly eststo river_mf: reg dist_river ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)

esttab river_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "river_mf") title("Distance to River (miles)") 
	title("Distance to River (miles)") 
}


********************************************************************************
** distance to green space
********************************************************************************
capture noisily {
** regressions
quietly eststo space_mf: reg dist_space ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab space_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "space_mf" ) title("Distance to Green Space (miles)") 
	
esttab  space_mf  using "$EXPORTPATH/amenities_table_space_municluster.tex", replace keep(25.dist3) ///
	se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("space_mf") ///
	title("Distance to Green Space (miles)") 
}


********************************************************************************
* distance to school
********************************************************************************
capture noisily {
** regressions

quietly eststo school_mf: reg dist_school ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)

esttab school_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "school_mf" ) title("Distance to School (miles)") 
	  
}


********************************************************************************
** distance to city center
********************************************************************************
capture noisily {
** regressions

quietly eststo center_mf: reg dist_center ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)

esttab center_mf , se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("center_mf") title("Distance to City Center (miles)") 
	  
}


********************************************************************************
** commuting distance to downtown distance (south station)
********************************************************************************
capture noisily {
** regressions
quietly eststo transit_mf: reg transit_dist ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)

esttab transit_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("transit_mf") title("Public Transit Distance to Downtown Boston (miles)") 
	  
}


********************************************************************************
** Mean slope of lot
********************************************************************************
capture noisily {
** regressions
quietly eststo slope_mf: reg soil_avgslope ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab slope_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("slope_mf") title("Mean Slope of Lot (degrees)") 
	  
}


********************************************************************************
** percent of lot >15 degrees
********************************************************************************
capture noisily {
** regressions
quietly eststo slope15_mf: reg soil_slope15 ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab slope15_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "slope15_mf") title("Percent of Lot with Slope >15 Degrees") 
	  
}


********************************************************************************
** depth to restrictive layer
********************************************************************************
capture noisily {
** regressions

quietly eststo depth_mf: reg soil_avgrestri ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab depth_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "depth_mf") title("Depth to Restrictive Layer (cm)") 
		  
}


********************************************************************************
** mean percent sand
********************************************************************************
capture noisily {
** regressions

quietly eststo sand_mf: reg soil_avgsand ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab sand_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "sand_mf") title("Avg. Percent Sand") 
	
}


********************************************************************************
** mean percent clay
********************************************************************************
capture noisily {
** regressions

quietly eststo clay_mf: reg soil_avgclay ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab clay_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles( "clay_mf") title("Mean Percent Clay") 
		  
}


********************************************************************************
*WALKABILITY VARIABLES
********************************************************************************
********************************************************************************
** National Walkability Index score
********************************************************************************
capture noisily {
** regressions
quietly eststo walk_mf: reg natwalkind ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)


esttab walk_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("walk_mf") title("Walkability Index") 
	  
}


********************************************************************************
** Employment mix  (only tables)
********************************************************************************
capture noisily {
** regressions

quietly eststo empl_mf: reg d2b_e8mixa ib26.dist3 i.lam_seg i.year if year==2018 & (dist_both<=0.21 & dist_both>=-0.2 & only_mf== 1 & res_typex !="Condominiums") , vce(cluster city)

esttab empl_mf, se r2 indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
	label mtitles("empl_mf") title("Employment mix") 
	  
}


********************************************************************************
** end of do file
********************************************************************************
log off
log close
clear all

display "finished!" 
}
