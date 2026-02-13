
use "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong.dta", clear

gen MUNI = NAME
	replace MUNI = upper(MUNI)
	replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
	replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
	replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
	replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

merge 1:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta", nogen keep(3)

// gen muninotused = 0
// local city = `""BELLINGHAM" "BRAINTREE" "BURLINGTON" "CHELSEA" "CONCORD" "DANVERS" "HAMILTON" "HINGHAM" "IPSWICH" "LYNNFIELD" "MEDFORD" "MELROSE" "NATICK" "NORWOOD" "PEABODY" "QUINCY" "READING" "WATERTOWN" "WENHAM" "WILMINGTON" "WINCHESTER" "WOBURN""'	
// foreach c in `city' {
// 	display "Dropping `c'..."	
// 	replace muninotused = 1 if MUNI=="`c'"
// }
//
// keep _ID MUNI muninotused

keep _ID MUNI

merge 1:m _ID using "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", keep(1 3) keepusing(_X _Y shape_order) nogen

rename _ID _ID_muni
rename _X _X_muni
rename _Y _Y_muni
rename shape_order shape_order_muni

sort _ID_muni shape_order_muni

tempfile muni_borders
save `muni_borders', replace

* zoning atlas data

use "$DATAPATH/shapefiles/standardized/zoning_atlas_latlong.dta", clear

gen mulfam_cat = .
	replace mulfam_cat = 0 if mulfam2 == 0 | mulfam3_4 == 0 | mulfam5_19 == 0 | mulfam20_ == 0 // not allowed by right
	replace mulfam_cat = 1 if mulfam2 != 0 | mulfam3_4 != 0 | mulfam5_19 != 0 | mulfam20_ != 0 // allowed by special permit
	replace mulfam_cat = . if mulfam2 == . | mulfam3_4 == . | mulfam5_19 == . | mulfam20_ == .  // allowed by right

gen mxht_cat = .
	replace mxht_cat = 0 if mxht_eff==0
	replace mxht_cat = 1 if mxht_eff>=10 & mxht_eff<=30
	replace mxht_cat = 2 if mxht_eff>=31 & mxht_eff<=35
	replace mxht_cat = 3 if mxht_eff>=36 & mxht_eff<=40
	replace mxht_cat = 4 if mxht_eff>=41

gen dupac_cat = .
	replace dupac_cat = 0 if dupac_eff==0
	replace dupac_cat = 1 if dupac_eff>=1 & dupac_eff<=2
	replace dupac_cat = 2 if dupac_eff>=3 & dupac_eff<=4
	replace dupac_cat = 3 if dupac_eff>=5 & dupac_eff<=10
	replace dupac_cat = 4 if dupac_eff>=11 & dupac_eff<=20
	replace dupac_cat = 5 if dupac_eff>=21

	//& dupac_eff<=40
	//replace dupac_cat = 5 if dupac_eff>=41 & dupac_eff<=50
	//replace dupac_cat = 6 if dupac_eff>=51

keep _ID *_cat

merge 1:m _ID using "$DATAPATH/shapefiles/TO_BE_DELETED 3-15-2021/old standardized versions/zoning_atlas_latlong_shp.dta", keepusing(_X _Y shape_order)

// rename _ID _ID_main
// rename shape_order shape_order_main

sort _ID shape_order

append using `muni_borders'

********************************************************************************
// /* file name */			local FILENAME1	"map_mfallow"
//
/* chart title */		local TITLE	"Multi-Family" 
//
// /* chart subtitle */		local SUBTITLE	"by municipality in the Greater Boston Area, 2019"
//
// /* chart footnote */		local FOOTNOTE	"Note(s):"
//
// /* data sources */		local SOURCE	"Source(s): Metropolitan Area Planning Council (MAPC) Zoning Atlas."
//
/* legend descr. */		local LEGEND	`" 2 "not allowed by-right" 3 "allowed by-right" "'
//
// /* y axis title */		local YTITLE	"<ytitle>"
//
// /* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************
#delimit ;
twoway	
	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)
	|| area _Y _X if mulfam_cat==0 & _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(100) fcol("144 109 150")		
	|| area _Y _X if mulfam_cat==1 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(100) fcol("255 210 110")			

	/* municipal outlines */
	|| area _Y_muni _X_muni if _ID_muni!=. , nodropbase cmiss(n) lwidth(.1) lcolor(black) fcol(none)
	/*|| area _Y_muni _X_muni if muninotused==1 & _ID_muni!=. , nodropbase cmiss(n) lwidth(.1) lcolor(black) fi(50) fcol(gray)*/

	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:`TITLE'}", size(2) pos(9) margin(t=0 b=0 l=0 r=5) span justification(left))	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) )
	subtitle("{it:<`FILENAME'>}", suffix size(2) pos() margin(t=0 b=0 l=0 r=0)) // TEMPORARY FILENAME ID
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") 
		cols(1) size(3) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(3) )	

	/* graph name */	
	name("map_mfallow", replace)	;	
#delimit cr

// graph export "$FIGPATH/`FILENAME'$EXT",replace


********************************************************************************
// /* file name */			local FILENAME2	"map_maxheight"
//
/* chart title */		local TITLE	"Maximum Height" 
//
// /* chart subtitle */		local SUBTITLE	"by municipality in the Greater Boston Area, 2019"
//
// /* chart footnote */		local FOOTNOTE	"Note(s):"
//
// /* data sources */		local SOURCE	"Source(s): Metropolitan Area Planning Council (MAPC) Zoning Atlas."
//
/* legend descr. */		local LEGEND	`" 1 "not allowed by-right" 2 "10-30 feet" 3 "31-35 feet" 4 "36-40 feet" 5 "41+ feet" "'
//
// /* y axis title */		local YTITLE	"<ytitle>"
//
// /* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************
#delimit ;
twoway	
	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)
	|| area _Y _X if mxht_cat==1 & _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(25) fcol("191 60 78")		
	|| area _Y _X if mxht_cat==2 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol("191 60 78")			
	|| area _Y _X if mxht_cat==3 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(75) fcol("191 60 78")		
	|| area _Y _X if mxht_cat==4 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(100) fcol("191 60 78")	
	|| area _Y _X if mxht_cat==5 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(125) fcol("191 60 78")	
	|| area _Y _X if mxht_cat==6 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(150) fcol("191 60 78")	
	
	/* municipal outlines */
	|| area _Y_muni _X_muni if _ID_muni!=. , nodropbase cmiss(n) lwidth(.1) lcolor(black) fcol(none)
	/*|| area _Y_muni _X_muni if muninotused==1 & _ID_muni!=. , nodropbase cmiss(n) lwidth(.1) lcolor(black) fi(50) fcol(gray)*/

	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:`TITLE'}", size(2) pos(9) margin(t=0 b=0 l=0 r=5) span justification(left))	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) )
	subtitle("{it:<`FILENAME'>}", suffix size(2) pos() margin(t=0 b=0 l=0 r=0)) // TEMPORARY FILENAME ID
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") 
		cols(1) size(3) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(3) )	

	/* graph name */	
	name("map_maxheight", replace)	;	
#delimit cr

// graph export "$FIGPATH/`FILENAME'$EXT",replace

********************************************************************************
// /* file name */			local FILENAME3	"map_dupac_eff"
//
/* chart title */		local TITLE	"Maximum DUPAC" 
//
// /* chart subtitle */		local SUBTITLE	"by municipality in the Greater Boston Area, 2019"
//
// /* chart footnote */		local FOOTNOTE	"Note(s):"
//
// /* data sources */		local SOURCE	"Source(s): Metropolitan Area Planning Council (MAPC) Zoning Atlas."
//
/* legend descr. */		local LEGEND	`" 1 "not allowed by-right" 2 "1-2 units" 3 "3-4 units" 4 "5-10 units" 5 "11-20 units" 6 "21+ units" "'
//
// /* y axis title */		local YTITLE	"<ytitle>"
//
// /* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************
#delimit ;
twoway	
	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol(gray)
	|| area _Y _X if dupac_cat==1 & _ID!=., nodropbase cmiss(n) lwidth(0) lcolor(white) fi(25) fcol("224 134 80")
	|| area _Y _X if dupac_cat==2 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(50) fcol("224 134 80")	
	|| area _Y _X if dupac_cat==3 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(75) fcol("224 134 80")		
	|| area _Y _X if dupac_cat==4 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(100) fcol("224 134 80")	
	|| area _Y _X if dupac_cat==5 & _ID!=. , nodropbase cmiss(n) lwidth(0) lcolor(white) fi(125) fcol("224 134 80")	
	
	/* municipal outlines */
	|| area _Y_muni _X_muni if _ID_muni!=. , nodropbase cmiss(n) lwidth(.1) lcolor(black) fcol(none)
	/*|| area _Y_muni _X_muni if muninotused==1 & _ID_muni!=. , nodropbase cmiss(n) lwidth(.1) lcolor(black) fi(50) fcol(gray)*/

	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:`TITLE'}", size(2) pos(9) margin(t=0 b=0 l=0 r=5) span justification(left))	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) )
	subtitle("{it:<`FILENAME'>}", suffix size(2) pos() margin(t=0 b=0 l=0 r=0)) // TEMPORARY FILENAME ID
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") 
		cols(1) size(3) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(3) )	

	/* graph name */	
	name("map_dupac_eff", replace)	;	
#delimit cr

/* chart title */		local TITLE	"Figure 1: Local Zoning Regulations Across Greater Boston" 
/* chart subtitle */		local SUBTITLE	"by municipality in Greater Boston"
/* chart footnote */		local FOOTNOTE	"Note(s): Multi-family allowed includes areas where multi-family construction is allowed only by special-permit." "Maximum height and DUPAC indicate the maximum building height and density allowed in an area."
/* data sources */		local SOURCE	"Source(s): Metropolitan Area Planning Council's (MAPC) 2020 Zoning Atlas."

#delimit ;
graph combine map_mfallow map_maxheight map_dupac_eff, cols(1) ysize(11) xsize(8.5)
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))

	title("{bf:`TITLE'}", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span justification(left))	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) )
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	
	/* graph name */	
	name("fig1_mf_height_dupac", replace)	;	
# delimit cr

graph close map_mfallow map_maxheight map_dupac_eff
	
graph export "$FIGPATH/figure_1.$EXT", replace

graph close _all

clear all




