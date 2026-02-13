
use "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong.dta", clear

gen MUNI = NAME
	replace MUNI = upper(MUNI)
	replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
	replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
	replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
	replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

merge 1:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta", nogen keep(3)

gen muninotused = 0
local city = `""BELLINGHAM" "BRAINTREE" "BURLINGTON" "CHELSEA" "CONCORD" "DANVERS" "HAMILTON" "HINGHAM" "IPSWICH" "LYNNFIELD" "MEDFORD" "MELROSE" "NATICK" "NORWOOD" "PEABODY" "QUINCY" "READING" "WATERTOWN" "WENHAM" "WILMINGTON" "WINCHESTER" "WOBURN""'	
foreach c in `city' {
	display "Dropping `c'..."	
	replace muninotused = 1 if MUNI=="`c'"
}

keep _ID MUNI muninotused ALAND _CX _CY

tab muninotused

merge 1:m _ID using "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", keep(1 3) keepusing(_X _Y shape_order) nogen

sort _ID shape_order

********************************************************************************
/* file name */			local FILENAME	"map_appendix1"

/* chart title */		local TITLE	"Appendix 1: Municipalities Included in Analysis" 

/* chart subtitle */		local SUBTITLE	"Massachusetts Greater Boston Area"

/* chart footnote */		local FOOTNOTE	"Note(s):"

/* data sources */		local SOURCE	"Source(s):"

/* legend descr. */		local LEGEND	`" 2 "Municipality Included" 3 "Municipality Not Included" "'

/* y axis title */		local YTITLE	"<ytitle>"

/* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************

#delimit ;
twoway	
	area _Y _X if ALAND>0 & _ID!=., nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(50) fcol(gray)
	||area _Y _X if muninotused==0 & ALAND>0 & _ID!=., nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(50) fcol(green)
	||area _Y _X if muninotused==1 & ALAND>0 & _ID!=., nodropbase cmiss(n) lwidth(.1) lcolor(white) fi(50) fcol(gray)

	||scatter _CY _CX if _ID!=., mlabel(MUNI) mlabsize(1) mlabcolor(black) msize(.1) mcolor(black)
	
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
		rows(1) size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(`FILENAME', replace)	;	
#delimit cr

graph export "$FIGPATH/`FILENAME'$EXT", replace


