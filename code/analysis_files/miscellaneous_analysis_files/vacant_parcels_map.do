********************************************************************************
* File name:		"32_figure3_props_map.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Current working directories are T Drive, creates the 
*			property scatter plot map for use in the non fed working
*			paper.
* 				
* Inputs:		warren_MAPC_all_annual.dta
*				
* Outputs:		contents for Table 1
*
* Created:		4/21/2021
* Last updated:		10/22/2021
********************************************************************************

* load city/town shapefile
// eli: changed "standardized" to "archived" in the filepath
use "$DATAPATH/shapefiles/archived/cb_2018_25_cousub_500k_latlong.dta", clear
gen MUNI = NAME
	replace MUNI = upper(MUNI)
	replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
	replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
	replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
	replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

merge 1:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta", nogen keep(3)

* tag unused municipalities
gen muninotused = 0
local city = `""BELLINGHAM" "BRAINTREE" "BURLINGTON" "CHELSEA" "CONCORD" "DANVERS" "HAMILTON" "HINGHAM" "IPSWICH" "LYNNFIELD" "MEDFORD" "MELROSE" "NATICK" "NORWOOD" "PEABODY" "QUINCY" "READING" "WATERTOWN" "WENHAM" "WILMINGTON" "WINCHESTER" "WOBURN""'	
foreach c in `city' {
	display "Dropping `c'..."	
	replace muninotused = 1 if MUNI=="`c'"
}

keep _ID MUNI muninotused ALAND _CX _CY COUNTYFP

* merge along county fips to create county outlines
preserve

local save = "$DATAPATH/shapefiles"

// Eli: changed "standardized" to "archived" in the filepath
mergepoly _ID using "$DATAPATH/shapefiles/archived/cb_2018_25_cousub_500k_latlong_shp.dta", coor("`save'/select_county_shp.dta") replace by(COUNTYFP)

save "`save'/select_county.dta", replace

use "`save'/select_county_shp.dta", clear

gen shape_order = _n

save "`save'/select_county_shp.dta", replace

use "`save'/select_county.dta", clear

merge 1:m _ID using "`save'/select_county_shp.dta",

sort shape_order

rename _ID _IDcounty

tempfile county_coors
save `county_coors', replace

restore

* merge on city/town coordinates
// Eli: changed "standardized" to "archived" in the filepath
merge 1:m _ID using "$DATAPATH/shapefiles/archived/cb_2018_25_cousub_500k_latlong_shp.dta", keep(1 3) keepusing(_X _Y shape_order) nogen

sort _ID shape_order

tempfile outline
save `outline', replace

* load warren data
use "$DATAPATH/final_dataset_10-28-2021.dta", clear

	keep if fy==2018

	gen upper_city = upper(city)
	
	drop if res_type == .


	
* drop unused city/town observation
gen muninotused = 0
local city = `""BELLINGHAM" "BRAINTREE" "BURLINGTON" "CHELSEA" "CONCORD" "DANVERS" "HAMILTON" "HINGHAM" "IPSWICH" "LYNNFIELD" "MEDFORD" "MELROSE" "NATICK" "NORWOOD" "PEABODY" "QUINCY" "READING" "WATERTOWN" "WENHAM" "WILMINGTON" "WINCHESTER" "WOBURN""'	
foreach c in `city' {
	display "Dropping `c'..."	
	replace muninotused = 1 if upper_city=="`c'"
}
drop if muninotused==1
	
** NFC added on 5/6/2024 - the below code should keep only vacant lots	
// also, res_type is encoded, so I'll decode it first
decode res_type, gen(res_typex)
//drop if res_typex != "Condominiums" & assd_landval!=0 & assd_bldgval==0
drop if res_typex == "Condominiums" //& assd_landval!=0 & assd_bldgval==0 

gen vacant_parcel = 1 if assd_landval !=0 & assd_bldgval ==0


count

count if (dist_both<=0.21 & dist_both>=-0.2)

count if vacant ==1


/* 
* add town outlines	
append using `outline',

* sort in proper order to make a map
sort year prop_id _ID shape_order


// ********************************************************************************
// /* file name */			local FILENAME	"figure3"
//
// /* chart title */		local TITLE	"Figure 3: Residential Properties by Type" 
//
// /* chart subtitle */		local SUBTITLE	"Greater Boston, 2018"
//
// /* chart footnote */		local FOOTNOTE	"Note(s): Muncipalities shaded dark gray were excluded from the analysis in this report. SHI properties are those meeting the requirements of Massachusetts'" ///
// 						"Comprehensive Permit Act to be included in a communities Subsidized Housing Inventory and exlcudes those whose addresses were suppressed or could not be accurately determined." ///
// 						"No SHI properties were avialable for Boston as the city maintains its own inventory of affordable housing."
//
// /* data sources */		local SOURCE	"Source(s): Warren Tax Assessment Records for 2018"

/* legend descr. */		local LEGEND	`" 3 "Vacant Land Parcels" "' //`" 5 "Vacant Land Parcels" "'
//
// /* y axis title */		local YTITLE	"<ytitle>"
//
// /* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)

	/* actual scatter plots */
	|| scatter warren_latitude warren_longitude if vacant_parcel == 1, mlabcolor(black) msize(.02pt) mcolor(orange_red)


	/* display for legend */ // Eli: changing this to vacant_parcel ==.
	|| scatter warren_latitude warren_longitude if vacant_parcel == ., mlabcolor(black) msize(2) mcolor(orange_red)
	
	|| area _Y _X if _ID!=. & muninotused == 1, nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(100) fcol(gray)
	
	|| area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(50) fcol(none)

	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
	ysize(8.5) xsize(11)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:`TITLE'}", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") 
		rows(1) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(`FILENAME', replace)	;	
#delimit cr

graph export "$FIGPATH/postREStat_vacant_parcels_map.pdf", replace
graph export "$FIGPATH/postREStat_vacant_parcels_map.png", replace
 */
