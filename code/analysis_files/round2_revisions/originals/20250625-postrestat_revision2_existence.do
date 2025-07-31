clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="mc_10072024_postREStat_rd_amenities_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** Post REStat Submission Version **

********************************************************************************
* File name:		"postQJE_rd_amenities_mtlines.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Post QJE updates
*			technically these are coefplots
* 			striaght line boundaries (matt turner orthogona lines)
* 			Ammenities only:
*				- dist to school
*				- dist to city center
*				- dist to major road
*				- dist to major river
*				- dist to green space
*				- soil quality (x5)
*				- transit dist nearest stop (manhattan)
*				  and downtown (public transit)
*				- walk score (tables only)
*
* Inputs:		
*				
* Outputs:		
*
* Created:		06/23/2021
* Updated:		03/27/2024
********************************************************************************
* create a save directory if none exists
global RDPATH "$FIGPATH/`name'_`date_stamp'"

capture confirm file "$RDPATH"

if _rc!=0 {
	di "making directory $RDPATH"
	shell mkdir $RDPATH
}

cd $RDPATH

********************************************************************************
** load and tempsave the mt lines data
********************************************************************************
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load and tempsave the transit data
********************************************************************************
import delimited "$DATAPATH/train_stops/dist_south_station_2022_09_29.csv", clear stringcols(_all)

tempfile dist_south_station
save `dist_south_station', replace

import delimited "$DATAPATH/train_stops/transit_distance.csv", clear stringcols(_all)

merge m:1 station_id using `dist_south_station'
		
		* merge error check
		sum _merge
		assert `r(N)' ==  821248
		assert `r(sum_w)' ==  821248
		assert `r(mean)' ==  2.999986605751247
		assert `r(Var)' ==  .0000133940856566
		assert `r(sd)' ==  .0036597931166456
		assert `r(min)' ==  2
		assert `r(max)' ==  3
		assert `r(sum)' ==  2463733

		drop if _merge == 2
		drop _merge
	
keep prop_id station_id station_name distance_m_* length_m

destring prop_id distance_m_* length_m, replace

gen transit_dist_m = distance_m_man + length_m

tempfile transit
save `transit', replace


********************************************************************************
** load and tempsave the soil data //new variables added 19.05.2024
********************************************************************************
use "$SHAPEPATH/soil_quality/soil_quality_matches.dta", clear // bringing back the old soil data

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


********************************************************************************
** load final dataset
********************************************************************************
use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
run "$DOPATH/postREStat_within_town_setup.do"


********************************************************************************
** merge on transit data
********************************************************************************
merge m:1 prop_id using `transit'
	
	* merge error check
	sum _merge
	assert `r(N)' ==  3642292
	assert `r(sum_w)' ==  3642292
	assert `r(mean)' ==  2.878361207723049
	assert `r(Var)' ==  .1068428258243096
	assert `r(sd)' ==  .3268682086473226
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  10483832
	
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on soil quality data
********************************************************************************
merge m:1 prop_id using `soil'
	
	* merge error check
	sum _merge
	assert `r(N)' ==  3642292
	assert `r(sum_w)' ==  3642292
	assert `r(mean)' ==  2.878361207723049
	assert `r(Var)' ==  .1068428258243096
	assert `r(sd)' ==  .3268682086473226
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  10483832

	drop if _merge == 2
	drop _merge

	
********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* merge error check
	sum _merge
	assert `r(N)' ==  3400297
	assert `r(sum_w)' ==  3400297
	assert `r(mean)' ==  2.940873106084557
	assert `r(Var)' ==  .0556309206919615
	assert `r(sd)' ==  .235862079809285
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9999842

	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties


********************************************************************************
** merge on walkscore variables 
********************************************************************************
merge m:1 prop_id using `walkscore', 
    sum _merge
    drop if _merge == 2
    drop _merge 
	
********************************************************************************
*Merge in ACS data *REVISION 2
********************************************************************************
*block data
merge m:1 warren_GEOID_full using "$DATAPATH/acs/blocks_2010.dta"

drop if _merge ==2
drop _merge 

*block group data
gen BLKGRP = substr(warren_GEOID_full,1,12)

merge m:1 year BLKGRP using "$DATAPATH/acs/acs_amenities.dta", keepusing(B19113001 B0100300 SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25)
drop if _merge == 2
drop _merge 

rename B19113001 median_inc
rename B0100300 total_pop
		

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

********************************************************************************
*Compare communities (cities) with many and few boundaries along observables 
********************************************************************************


*XXX add tax rates/ tax amounts 


*Calculate number of boundaries within city: 
*confirm city is the correct variable to use here 

by city lam_seg, sort: gen nvals = _n == 1
by city, sort: egen num_boundaries = total(nvals)

drop nvals 

*need some way to measure area of a city 
*then do number of boundaries per area 

gen boundaries_pa = num_boundaries/CityACRESXXX



*collapse data at the city level and then scatter 

collapse (mean) m_units=units m_rent=rent m_price=price m_frac_under18=frac_under18 m_frac_over65=frac_over65 m_frac_mortgage=frac_mortgage m_frac_rented=frac_rented m_frac_female=frac_female m_frac_black=frac_black m_frac_asian=frac_asian m_frac_hispanic=frac_hispanic m_frac_nonhispanicwhite=frac_nonhispanicwhite m_frac_morethan4=frac_morethan4 m_median_inc=median_inc m_total_pop=total_pop m_SHARE_CAR_MBIKE=SHARE_CAR_MBIKE m_SHARE_PUBLICTRANS=SHARE_PUBLICTRANS m_SHARE_INC_OVER200K=SHARE_INC_OVER200K m_SHARE_BACHELOR_25=SHARE_BACHELOR_25 m_num_bondaries=num_boundaries m_natwalkind=natwalkind m_property_taxXXX m_boundaries_pa=boundaries_pa, by(city)


foreach l in m_units m_rent m_price m_frac_under18 m_frac_over65 m_frac_mortgage m_frac_rented m_frac_female m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 m_natwalkind {
	
	*scatter against number of boundaries 
	twoway scatter `l' num_boundaries, xtitle("# of boundaries in city") ytitle("`l'")
	*SAVE XXX
	
	*scatter against number of boundaries per area
	twoway scatter `l' num_boundaries, xtitle("# of boundaries per acre in city") ytitle("`l'")

	
}




/*
units rent price closest_city_dist frac_under18 frac_over65 frac_mortgage frac_rented frac_female frac_black frac_asian frac_hispanic frac_nonhispanicwhite frac_morethan4 median_inc total_pop SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25
*/






log close
clear all

********************************************************************************
** convert gph to pdfs
********************************************************************************
local files : dir "$RDPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$RDPATH/`fin'"
	
	graph export "$RDPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 
	





