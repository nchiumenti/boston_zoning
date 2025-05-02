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
use "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong.dta", clear

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

mergepoly _ID using "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", coor("`save'/select_county_shp.dta") replace by(COUNTYFP)

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
merge 1:m _ID using "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", keep(1 3) keepusing(_X _Y shape_order) nogen

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
	
* tag density level
gen single_fam = 0
	replace single_fam=1 if res_type==1

gen gentle_den = 0
	replace gentle_den = 1 if num_units==2 | num_units==3

gen high_den = 0
	replace high_den = 1 if num_units>=4

// merge 1:1 prop_id using "/home/a1nfc04/Documents/Boston_Affordable_Housing_Project_SDRIVE/data/warren/crosswalks/ch40b_to_warren_xwalk.dta"
// 	drop if _merge==2
	
	
append using `outline',

sort year prop_id _ID shape_order
//
// append using `county_coors'


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

/* legend descr. */		local LEGEND	`" 5 "Single-Family" 6 "2-3 Unit" 7 "4 or more Unit" "'
//
// /* y axis title */		local YTITLE	"<ytitle>"
//
// /* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)

	/* actual scatter plots */
	|| scatter warren_latitude warren_longitude if single_fam==1, mlabcolor(black) msize(.02pt) mcolor(dknavy)
	
	|| scatter warren_latitude warren_longitude if gentle_den==1, mlabcolor(black) msize(.02pt) mcolor(dkorange)
	
	|| scatter warren_latitude warren_longitude if high_den==1, mlabcolor(black) msize(.02pt) mcolor(maroon)


	/* display for legend */
	|| scatter warren_latitude warren_longitude if single_fam==., mlabcolor(black) msize(2) mcolor(dknavy)
	
	|| scatter warren_latitude warren_longitude if gentle_den==., mlabcolor(black) msize(2) mcolor(dkorange)
	
	|| scatter warren_latitude warren_longitude if high_den==., mlabcolor(black) msize(2) mcolor(maroon)

	
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
stop
graph export "$FIGPATH/figure_3_cc.pdf", replace
graph export "$FIGPATH/figure_3_cc.png", replace


// // ********************************************************************************
// // /* file name */			local FILENAME	"map_appendix1"
// //
// // /* chart title */		local TITLE	"Figure 3: Residential Properties by Housing Type" 
// // //
// // /* chart subtitle */		local SUBTITLE	"Greater Boston Area, Massachusetts 2018"
// // //
// // /* chart footnote */		local FOOTNOTE	"Note(s): Properties shown include only those within 1 mile of a zone regulation boundary. Excludes muncipalities that were not included in the final analysis."
// // //
// // /* data sources */		local SOURCE	"Source(s): Warren Tax Assessment Records"
// //
// /* legend descr. */		local LEGEND	`"5 "Single Family" 6 "2-3 Unit Properties" 7 "4+ Unit Properties" "'
// //
// // /* y axis title */		local YTITLE	"<ytitle>"
// //
// // /* x axis title */		local XTITLE	"<xtitle>"
// // ********************************************************************************
//
// #delimit ;
// twoway	
// 	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)
//	
// 	|| scatter warren_latitude warren_longitude if single_fam==1, mlabcolor(black) msize(.01pt) mcolor(green)
// 	|| scatter warren_latitude warren_longitude if gentle_den==1, mlabcolor(black) msize(.01pt) mcolor(blue)
// 	|| scatter warren_latitude warren_longitude if high_den==1, mlabcolor(black) msize(.01pt) mcolor(red)
//
// 	|| scatter warren_latitude warren_longitude if single_fam==., mlabcolor(black) msize(2) mcolor(green)
// 	|| scatter warren_latitude warren_longitude if gentle_den==., mlabcolor(black) msize(2) mcolor(blue)
// 	|| scatter warren_latitude warren_longitude if high_den==., mlabcolor(black) msize(2) mcolor(red)
//	
// 	|| area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(50) fcol(none)
//	
// 	|| area _Y _X if _IDcounty!=., nodropbase cmiss(n) lwidth(.2) lcolor(black) fi(50) fcol(none)
//
// 	/* graph format region [do not change] */
// 	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
// 	ysize(8.5) xsize(11)
// 	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
//	
// 	/* titles, subtitles, notes */		
// 	title("{bf:`TITLE'}", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)	
// 	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
// 	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
// 	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
//	
// 	/* legend */
// 	leg(on)
// 	legend( order(" `LEGEND' ") 
// 		cols(3) size(3) 
// 		nobox fcolor() 
// 		region(fcolor(none) lpattern(blank)) 
// 		symy(2) symx(3) position(6) )	
//
// 	/* graph name */	
// 	name(`FILENAME', replace)	;	
// #delimit cr
//
// graph export "$FIGPATH/map_scatter_county_v1.pdf", replace
// graph export "$FIGPATH/map_scatter_county_v1.png", replace
//
//
//
//
// /* legend descr. */		local LEGEND	`"11 "Single Family" 12 "2-3 Unit Properties" 13 "4+ Unit Properties" "'
// //
// // /* y axis title */		local YTITLE	"<ytitle>"
// //
// // /* x axis title */		local XTITLE	"<xtitle>"
// // ********************************************************************************
//
// #delimit ;
// twoway	
// 	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)
// 	|| area _Y _X if _IDcounty!=. & COUNTYFP=="009", nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(maroon)
// 	|| area _Y _X if _IDcounty!=. & COUNTYFP=="017", nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(blue)
// 	|| area _Y _X if _IDcounty!=. & COUNTYFP=="021", nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(green)
// 	|| area _Y _X if _IDcounty!=. & COUNTYFP=="023", nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(red)
// 	|| area _Y _X if _IDcounty!=. & COUNTYFP=="025", nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(purple)
// 	|| area _Y _X if _IDcounty!=. & COUNTYFP=="027", nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(orange)
//
//	
// 	|| scatter warren_latitude warren_longitude if single_fam==1, mlabcolor(black) msize(.01pt) mcolor(green)
// 	|| scatter warren_latitude warren_longitude if gentle_den==1, mlabcolor(black) msize(.01pt) mcolor(blue)
// 	|| scatter warren_latitude warren_longitude if high_den==1, mlabcolor(black) msize(.01pt) mcolor(red)
//
// 	|| scatter warren_latitude warren_longitude if single_fam==., mlabcolor(black) msize(2) mcolor(green)
// 	|| scatter warren_latitude warren_longitude if gentle_den==., mlabcolor(black) msize(2) mcolor(blue)
// 	|| scatter warren_latitude warren_longitude if high_den==., mlabcolor(black) msize(2) mcolor(red)
//	
// 	|| area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(50) fcol(none)
//	
// 	|| area _Y _X if _IDcounty!=., nodropbase cmiss(n) lwidth(.2) lcolor(black) fi(50) fcol(none)
//
// 	/* graph format region [do not change] */
// 	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
// 	ysize(8.5) xsize(11)
// 	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
//	
// 	/* titles, subtitles, notes */		
// 	title("{bf:`TITLE'}", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)	
// 	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
// 	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
// 	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
//	
// 	/* legend */
// 	leg(on)
// 	legend( order(" `LEGEND' ") 
// 		cols(3) size(3) 
// 		nobox fcolor() 
// 		region(fcolor(none) lpattern(blank)) 
// 		symy(2) symx(3) position(6) )	
//
// 	/* graph name */	
// 	name(`FILENAME', replace)	;	
// #delimit cr
//
// graph export "$FIGPATH/map_scatter_county_v2.pdf", replace
// graph export "$FIGPATH/map_scatter_county_v2.png", replace
