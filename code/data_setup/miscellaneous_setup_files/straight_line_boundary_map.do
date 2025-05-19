clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

// local name ="straight_line_boundary_map" // <--- change when necessry

// log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES SETUP VERSION **


********************************************************************************
* File name:		"straight_line_boundary_map.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		creates a .gph and .pdf file with a map of the straight
*			line boundaries (matt turner lineS)
* 				
* Inputs:		./cb_2018_25_cousub_500k_latlong.dta
*			./mt_orthogonal_lines_4269
*			./regulation_types.dta
*				
* Outputs:		./straight_line_boundary_map.gph
*			./straight_line_boundary_map.pdf
*
* Created:		10/10/2022
* Updated:		10/11/2022
********************************************************************************

********************************************************************************
** create a save directory if none exists
********************************************************************************
global EXPORTPATH "$FIGPATH/postQJE_miscellaneous_figures"

capture confirm file "$EXPORTPATH"

if _rc!=0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

cd $EXPORTPATH


********************************************************************************
** load and save municipality outlines
********************************************************************************
use "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong.dta", clear

* standardized town names
gen MUNI = NAME
	replace MUNI = upper(MUNI)
	replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
	replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
	replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
	replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

* merge on list of MAPC towns, keep only those that match
merge 1:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta",

	* merge error ceck
	sum _merge
	assert `r(N)' ==  351
	assert `r(sum_w)' ==  351
	assert `r(mean)' ==  1.575498575498576
	assert `r(Var)' ==  .8221408221408221
	assert `r(sd)' ==  .9067198145738418
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  553
	
	* merge drop
	keep if _merge == 3
	drop _merge

* identify in-sample municipalities
gen muninotused = 0
local city = `""BELLINGHAM" "BRAINTREE" "BURLINGTON" "CHELSEA" "CONCORD" "DANVERS" "HAMILTON" "HINGHAM" "IPSWICH" "LYNNFIELD" "MEDFORD" "MELROSE" "NATICK" "NORWOOD" "PEABODY" "QUINCY" "READING" "WATERTOWN" "WENHAM" "WILMINGTON" "WINCHESTER" "WOBURN""'	
foreach c in `city' {
	display "Dropping `c'..."	
	replace muninotused = 1 if MUNI=="`c'"
}

keep _ID MUNI muninotused ALAND _CX _CY

* error check
count if muninotused == 1
assert `r(N)' == 22

* merge on shape coordinates file
merge 1:m _ID using "$DATAPATH/shapefiles/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", keepusing(_X _Y shape_order)
	
	* merge error check
	sum _merge
	assert `r(N)' ==  19039
	assert `r(sum_w)' ==  19039
	assert `r(mean)' ==  2.34413572141394
	assert `r(Var)' ==  .2257181822300592
	assert `r(sd)' ==  .4750980764327079
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  44630
	
	* drop merge
	drop if _merge == 2
	drop _merge


* sort and tempsave
sort _ID shape_order

drop shape_order

gen munis = 1

tempfile outlines
save `outlines', replace


********************************************************************************
** load striaght line boundary shapefile
* the shape file was exported from matt_turner_orthogonal_lines_final.ipynb with epsg=4269
********************************************************************************
* convert shapefile to .dta db and coor files (only need to do once)
// cd "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_lines_4269"
//
// spshape2dta "mt_orthogonal_lines_4269", replace
//
// cd $EXPORTPATH

* load straight line boundary file
use "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_lines_4269/mt_orthogonal_lines_4269.dta", clear

* merge on regulations data to left boundary side
gen LRID = LEFT_FID

merge m:1 LRID using "$DATAPATH/warren/boundary_matches/regulation_types.dta", keepusing (mxht_eff dupac_eff mulfam)

	* merge error check
	sum _merge
	assert `r(N)' ==  8429
	assert `r(sum_w)' ==  8429
	assert `r(mean)' ==  2.336338830228971
	assert `r(Var)' ==  .2232415064429124
	assert `r(sd)' ==  .4724843980947016
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  19693

	* merge drop
	drop if _merge == 2
	drop _merge
	
rename mxht_eff l_height
rename dupac_eff l_dupac
rename mulfam l_mulfam

drop LRID

* merge on regulations to right boundary side
gen LRID = RIGHT_FID

merge m:1 LRID using "$DATAPATH/warren/boundary_matches/regulation_types.dta", keepusing (mxht_eff dupac_eff mulfam)

	* merge error check
	sum _merge	
	assert `r(N)' ==  8606
	assert `r(sum_w)' ==  8606
	assert `r(mean)' ==  2.329421333953056
	assert `r(Var)' ==  .2209285901502715
	assert `r(sd)' ==  .4700304140694211
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  20047

	* merge drop
	drop if _merge == 2
	drop _merge

rename mxht_eff r_height
rename dupac_eff r_dupac
rename mulfam r_mulfam

* generate regulation change identifier
gen only_du = (l_dupac != r_dupac) & (l_height == r_height) & (l_mulfam == r_mulfam) // only dupac changes

gen only_he = (l_dupac == r_dupac) & (l_height != r_height) & (l_mulfam == r_mulfam) // only height changes

gen only_mf = (l_dupac == r_dupac) & (l_height == r_height) & (l_mulfam != r_mulfam) // only multi family allowed changes

gen du_he = (l_dupac != r_dupac) & (l_height != r_height) & (l_mulfam == r_mulfam) // dupac and height change

gen du_mf = (l_dupac != r_dupac) & (l_height == r_height) & (l_mulfam != r_mulfam) // dupac and mf allowed change

gen mf_he = (l_dupac == r_dupac) & (l_height != r_height) & (l_mulfam != r_mulfam) // mf allowed and height change

gen du_mf_he = (l_dupac != r_dupac) & (l_height != r_height) & (l_mulfam != r_mulfam) // all regulations change

gen boundary_type = ""
replace boundary_type = "only_du" if only_du == 1
replace boundary_type = "only_he" if only_he == 1
replace boundary_type = "only_mf" if only_mf == 1
replace boundary_type = "du_he" if du_he == 1
replace boundary_type = "du_mf" if du_mf == 1
replace boundary_type = "mf_he" if mf_he == 1
replace boundary_type = "du_mf_he" if du_mf_he == 1

* gen a record order sort variable
gen rec_order = _n

* merge on coordinates file
merge 1:m _ID using "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_lines_4269/mt_orthogonal_lines_4269_shp.dta", keepusing(_X _Y rec_header shape_order)

	* merge error check
	sum _merge
	assert `r(N)' ==  30320
	assert `r(sum_w)' ==  30320
	assert `r(mean)' ==  3
	assert `r(Var)' ==  0
	assert `r(sd)' ==  0
	assert `r(min)' ==  3
	assert `r(max)' ==  3
	assert `r(sum)' ==  90960
	
	* merge drop
	keep if _merge == 3
	drop _merge
	
* sort observations for mapping
sort rec_order shape_order

* append on muncipality outlines
append using `outlines'


********************************************************************************
** create boundary map
********************************************************************************

// local endash = ustrunescape("\u2013")
// dis "`endash'"

********************************************************************************
/* file name */			local FILENAME	"striaght_line_boundary_map"

// /* chart title */		local TITLE	"<title>" 
//
// /* chart subtitle */		local SUBTITLE	"<subtitle>"
//
// /* chart footnote */		local FOOTNOTE	"<footnote>"
//
// /* data sources */		local SOURCE	"<source>"

/* legend descr. */		local LEGEND	`" 1 "DUPAC" 2 "Height" 3 "Multifamily" 4 "DUPAC and Height" 5 "DUPAC and Multifamily" 6 "Multifamily and Height" 7 "Municipality Not Included""'

// /* y axis title */		local YTITLE	"<ytitle>"
//
// /* x axis title */		local XTITLE	"<xtitle>"
********************************************************************************

#delimit ;
twoway	
	|| line _Y _X if _ID!=. & only_du == 1, nodropbase cmiss(n) lwidth(.3) fi(100) lcolor("0 58 93")
	|| line _Y _X if _ID!=. & only_he == 1, nodropbase cmiss(n) lwidth(.3) fi(100) lcolor("77 134 160") 
	|| line _Y _X if _ID!=. & only_mf == 1, nodropbase cmiss(n) lwidth(.3) fi(100) lcolor("191 60 78") 
	|| line _Y _X if _ID!=. & du_he == 1, nodropbase cmiss(n) lwidth(.3) fi(100) lcolor("224 134 80") 
	|| line _Y _X if _ID!=. & du_mf == 1, nodropbase cmiss(n) lwidth(.3) fi(100) lcolor("255 210 110") 
	|| line _Y _X if _ID!=. & mf_he == 1, nodropbase cmiss(n) lwidth(.3) fi(100) lcolor("144 109 150") 
	
	/* muni not used highlights */
	|| area _Y _X if _ID!=. & munis == 1 & muninotused == 1, nodropbase cmiss(n) lwidth(0) lcolor(black) fi(50) fcolor(gray)
	
	/* muni outlines */
	|| area _Y _X if _ID!=. & munis == 1, nodropbase cmiss(n) lwidth(.1) lcolor(black) fi(0) fcolor(none)
	|| scatter _CY _CX if _ID!=. & munis == 1 & MUNI=="BOSTON", nodropbase cmiss(n) msymbol(X) mcolor(red) mlabel(MUNI) mlabcolor(black)
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:`TITLE'}", size(2) pos(11) margin(t=0 b=0 l=0 r=5) span justification(left))	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span justification(left))
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) )		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") 
		cols(3) size(3) colgap(*3)
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name("`FILENAME'", replace)	;	
#delimit cr

graph save "`FILENAME'" "`FILENAME'_`date_stamp'", replace	
graph export "`FILENAME'_`date_stamp'.pdf", as(pdf) replace


********************************************************************************
** end
********************************************************************************
clear all
