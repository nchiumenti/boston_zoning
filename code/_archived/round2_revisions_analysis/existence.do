* start here
clear all
log close _all
set linesize 255

local name ="existence"  // <--- change when necessry

* creates an output directory if none exists
global EXPORTPATH "$WORKINGDIR/analysis/`name'_output"

capture confirm file "$EXPORTPATH"

if _rc != 0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

* start log file
local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

log using "$EXPORTPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
* File name:		"existence.do"
*
* Project title:	Boston Zoning
*
* Description:		creates two scatter plots that will plot number of boundaries
*                   and number of boundaries per acre relative to various amenities 
*                   measures.
*
* Inputs:		
*				
* Outputs:		
*
* Created:		    07/08/2025
* Updated:		    07/08/2025
********************************************************************************
* confirm that all input data files are present under $DATAPATH
confirm file "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_v2.dta"
confirm file "$DATAPATH/dist_south_station_2022_09_29.csv"
confirm file "$DATAPATH/transit_distance.csv"
confirm file "$DATAPATH/soil_quality_matches.dta"
confirm file "$DATAPATH/warren_group_walkability.dta"
confirm file "$DATAPATH/within_town_analysis_data.dta"
confirm file "$DATAPATH/blocks_2010.dta"
confirm file "$DATAPATH/acs_amenities.dta"


********************************************************************************
** load and tempsave the mt lines data
********************************************************************************
use "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


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
use "$DATAPATH/soil_quality_matches.dta", clear // bringing back the old soil data

keep prop_id avg_slope slope_15 avg_restri avg_sand avg_clay

destring  avg_slope slope_15 avg_restri avg_sand avg_clay, replace

tempfile soil
save `soil', replace


********************************************************************************
** load and tempsave the walk score data 19.05.2024
********************************************************************************
use "$DATAPATH/warren_group_walkability.dta" // set to file path

keep prop_id d2b_e8mixa d2a_ephhm d3b d2a_ranked d2b_ranked d3b_ranked natwalkind

tempfile walkscore
save `walkscore', replace


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear


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

keep if straight_line == 1  // <-- drops non-straight line properties


********************************************************************************
** merge on walkscore variables 
********************************************************************************
merge m:1 prop_id using `walkscore', 
    sum _merge
    drop if _merge == 2
    drop _merge 


********************************************************************************
** Merge in ACS data for restart revision 2
********************************************************************************
*block data
merge m:1 warren_GEOID_full using "$DATAPATH/blocks_2010.dta"

drop if _merge ==2
drop _merge 

*block group data
gen BLKGRP = substr(warren_GEOID_full,1,12)

merge m:1 year BLKGRP using "$DATAPATH/acs_amenities.dta", keepusing(B19113001 B0100300 SHARE_CAR_MBIKE SHARE_PUBLICTRANS SHARE_INC_OVER200K SHARE_BACHELOR_25)
drop if _merge == 2
drop _merge 

rename B19113001 median_inc
rename B0100300 total_pop


********************************************************************************
** merge on muni property tax rates by year
********************************************************************************
merge m:1 year cousub_name using "$DATAPATH/muni_tax_rates.dta"

drop if _merge == 2
drop _merge 

/* the tax rate variable is called res_rate */


********************************************************************************
** merge on county gaz file
********************************************************************************
merge m:1 cousub_name using "$DATAPATH/muni_land_area.dta"

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


********************************************************************************
*Compare communities (cities) with many and few boundaries along observables 
********************************************************************************

*Calculate number of boundaries within city: 
*confirm city is the correct variable to use here 

by city lam_seg, sort: gen nvals = _n == 1

by city, sort: egen num_boundaries = total(nvals)

drop nvals 

gen city_aland_acres = ALAND / 4046.8564224

gen city_aland_sqmi = ALAND_SQMI

*need some way to measure area of a city 
*then do number of boundaries per area 

gen boundaries_per_acre = num_boundaries/city_aland_acres

gen boundaries_per_sqmi = num_boundaries/city_aland_sqmi

*collapse data at the city level and then scatter 
* will be means by city for 2010-2018, basically weighted by households (number of properties in our sample)

#delimit ;
collapse (mean) m_units=num_units 
				m_rent=comb_rent1
				m_price=def_saleprice
				m_frac_under18=frac_under18 
				m_frac_over65=frac_over65 
				m_frac_mortgage=frac_mortgage 
				m_frac_rented=frac_rented 
				m_frac_female=frac_female 
				m_frac_black=frac_black 
				m_frac_asian=frac_asian 
				m_frac_hispanic=frac_hispanic 
				m_frac_nonhispanicwhite=frac_nonhispanicwhite 
				m_frac_morethan4=frac_morethan4 
				m_median_inc=median_inc 
				m_total_pop=total_pop 
				m_SHARE_CAR_MBIKE=SHARE_CAR_MBIKE 
				m_SHARE_PUBLICTRANS=SHARE_PUBLICTRANS 
				m_SHARE_INC_OVER200K=SHARE_INC_OVER200K 
				m_SHARE_BACHELOR_25=SHARE_BACHELOR_25 
				m_num_bondaries=num_boundaries 
				m_natwalkind=natwalkind
                m_res_rate = res_rate
                m_boundaies_per_acre = boundaries_per_acre
                m_boundaries_per_sqmi = boundaries_per_sqmi, 
        by(city);
#delimit cr

foreach l in m_units m_rent m_price m_frac_under18 m_frac_over65 m_frac_mortgage m_frac_rented m_frac_female m_frac_black m_frac_asian m_frac_hispanic m_frac_nonhispanicwhite m_frac_morethan4 m_median_inc m_total_pop m_SHARE_CAR_MBIKE m_SHARE_PUBLICTRANS m_SHARE_INC_OVER200K m_SHARE_BACHELOR_25 m_natwalkind m_res_rate m_boundaies_per_acre m_boundaries_per_sqmi{
	
	*scatter against number of boundaries 
	twoway scatter `l' num_boundaries, xtitle("# of boundaries in city") ytitle("`l'")
	graph save "`l'" "`la'.gph", replace
	
	*scatter against number of boundaries per area
	twoway scatter `l' boundaries_per_acre, xtitle("# of boundaries per acre in city") ytitle("`l'")
	graph save "`l'" "`lb'.gph", replace
	
}


********************************************************************************
** end
********************************************************************************
log off
log close
clear all

** convert pdfs to gph
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files'{	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

display "finished!" 



