clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="price_units_map" // <--- change when necessry

// log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: drive version ***

********************************************************************************
* File name:		"price_units_map.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		creates 3 maps showing the spatial effect of regulations
*			around train stations for units/rents/prices.
*
* Inputs:		./cb_2018_25_cousub_500k.dta
*			./cb_2018_25_cousub_500k_shp.dta
*			./all_stations.csv
*			./stations_without_two_sides.dta
*			./prices_units_40a.csv
*			./units_40a.csv
*
* Outputs:		./stations_prices_map.gph/.pdf
*			./stations_rents_map.gph.pdf
*			./station_units_map.gph/.pdf
*
* Created:		11/09/2022
* Updated:		11/10/2022
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
** load and tempsave the city/town outlines for MAPC area
********************************************************************************
* load city/town shapefile
use "$SHAPEPATH/originals/cb_2018_25_cousub_500k.dta", clear

* correct town names for merge
gen MUNI = NAME
	replace MUNI = upper(MUNI)
	replace MUNI = regexr(MUNI,"( TOWN| CITY)+","")
	replace MUNI = regexr(MUNI, "(BOROUGH)$","BORO")
	replace MUNI = "MOUNT WASHINGTON" if MUNI=="MT WASHINGTON"
	replace MUNI = "MANCHESTER" if MUNI=="MANCHESTER-BY-THE-SEA"

* merge on mapc town list 
merge 1:1 MUNI using "$DATAPATH/geocoding/MAPC_town_list.dta",

	* validate merge results
	sum _merge
	assert `r(N)' ==  351
	assert `r(sum_w)' ==  351
	assert `r(mean)' ==  1.575498575498576
	assert `r(Var)' ==  .8221408221408221
	assert `r(sd)' ==  .9067198145738418
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  553
	
	keep if _merge == 3
	drop _merge


* tag unused mapc municipalities
gen muninotused = 0

local city "BELLINGHAM" ///
		"BRAINTREE" ///
		"BURLINGTON" ///
		"CHELSEA" ///
		"CONCORD" ///
		"DANVERS" ///
		"HAMILTON" ///
		"HINGHAM" ////
		"IPSWICH" ///
		"LYNNFIELD" ///
		"MEDFORD" ///
		"MELROSE" ///
		"NATICK" ///
		"NORWOOD" ///
		"PEABODY" ///
		"QUINCY" ///
		"READING" ///
		"WATERTOWN" ///
		"WENHAM" ///
		"WILMINGTON" ///
		"WINCHESTER" ///
		"WOBURN"
		
foreach c in "`city'" {
	display "Dropping `c'..."	
	replace muninotused = 1 if MUNI=="`c'"
}

keep _ID MUNI muninotused ALAND _CX _CY COUNTYFP

* merge on city/town coordinates
merge 1:m _ID using "$SHAPEPATH/originals/cb_2018_25_cousub_500k_shp.dta", keepusing(_X _Y shape_order)
	
	* validate merge
	sum _merge
	assert `r(N)' ==  19039
	assert `r(sum_w)' ==  19039
	assert `r(mean)' ==  2.34413572141394
	assert `r(Var)' ==  .2257181822300592
	assert `r(sd)' ==  .4750980764327079
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  44630
	
	drop if _merge == 2
	drop _merge

sort _ID shape_order

tempfile outline
save `outline', replace


********************************************************************************
** load list of all train stops
********************************************************************************
import delimited "$DATAPATH/train_stops/all_stations.csv", clear

keep station_id station_name station_lat station_lon

tempfile stations
save `stations', replace


********************************************************************************
** load list of train stops without enough data
********************************************************************************
use "$DATAPATH/price_units_map/stations_without_two_sides.dta", clear

drop if def_name == "Regional Urban"

bysort station_id: keep if _n == 1

keep station_id station_name
order station_id station_name

gen no_two_sides = 1

tempfile no_two_sides
save `no_two_sides', replace


********************************************************************************
** load the prices/rents effects data
/* Note: the unit effects data are incorrect in this file and so we should use
the units_40a.csv file for those instead */
********************************************************************************
import delimited "$DATAPATH/price_units_map/prices_units_40a.csv", clear

merge 1:1 station_id using `no_two_sides'
	replace no_two_sides = . if _merge == 3 
	drop _merge
	
merge 1:1 station_id using `stations'
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** clear maps for prices/rents
********************************************************************************

/* mapping variable log is as follows:
	- stations where there are boundaries with no comparison side are shown in gray
	- stations where ch40a doesnt apply are those with density >15 already
	- zero values are statistically insignficant
	- the rest of these are bucketed */

* rent effect mapping variables
gen map_var_r = .

* n/a rent values
replace map_var_r = 1 if no_two_sides == 1 					// <-- no two sides
replace map_var_r = 2 if price_effect_r_percent == . & no_two_sides != 1 	// <-- ch40a has no impact
replace map_var_r = 3 if price_effect_r_percent == 0 				// <-- true zero/insignficant value

* positive rent effect values
replace map_var_r = 11 if map_var_r == . & (price_effect_r_percent > 0 & price_effect_r_percent < 5)
replace map_var_r = 12 if map_var_r == . & (price_effect_r_percent >= 5 & price_effect_r_percent < 10)
replace map_var_r = 13 if map_var_r == . & (price_effect_r_percent >= 10)

* negative rent effect values
replace map_var_r = -11 if map_var_r == . & (price_effect_r_percent < 0 & price_effect_r_percent > -5)
replace map_var_r = -12 if map_var_r == . & (price_effect_r_percent <= -5 & price_effect_r_percent > -10)
replace map_var_r = -13 if map_var_r == . & (price_effect_r_percent <= -10)	


** prices effect mapping variable
gen map_var_o = .

* n/a price values
replace map_var_o = 1 if no_two_sides == 1 					// <-- no two sides
replace map_var_o = 2 if price_effect_o_percent==. & no_two_sides!=1 		// <-- ch40a has no impact
replace map_var_o = 3 if price_effect_o_percent==0 				// <-- true zero/insignficant value

* positive price effect values
replace map_var_o = 11 if map_var_o==. & (price_effect_o_percent>0 & price_effect_o_percent<5)
replace map_var_o = 12 if map_var_o==. & (price_effect_o_percent>=5 & price_effect_o_percent<10)
replace map_var_o = 13 if map_var_o==. & (price_effect_o_percent>=10)

* negative price effect values
replace map_var_o = -11 if map_var_o==. & (price_effect_o_percent<0 & price_effect_o_percent>-5)
replace map_var_o = -12 if map_var_o==. & (price_effect_o_percent<=-5 & price_effect_o_percent>-10)
replace map_var_o = -13 if map_var_o==. & (price_effect_o_percent<=-10)	

tempfile prices
save `prices', replace


********************************************************************************
** load units effect data
********************************************************************************
import delimited "$DATAPATH/price_units_map/units_40a.csv", clear

drop _merge

merge 1:1 station_id using `no_two_sides'
	replace no_two_sides = . if _merge == 3 
	drop _merge
	
merge 1:1 station_id using `stations'
	drop if _merge == 2
	drop _merge

* unit effect mapping variable
gen map_var_u = .

* n/a unit effect values
replace map_var_u  = 1 if no_two_sides == 1 					// <-- no two sides
replace map_var_u = 2 if unit_effect == . & no_two_sides != 1 & above_15 == 1	// <-- ch40a has no impact
replace map_var_u = 3 if unit_effect == 0 					// <-- true zero/insignficant value

* positive unit effect values
replace map_var_u = 11 if map_var_u==. & (unit_effect>0 & unit_effect<.15)
replace map_var_u = 12 if map_var_u==. & (unit_effect>=.15 & unit_effect<.30)
replace map_var_u = 13 if map_var_u==. & (unit_effect>=.3)

merge 1:1 station_id using `prices'
	drop if _merge == 1

replace map_var_u = 1 if map_var_r == 1 & map_var_o == 1
replace map_var_u = 2 if map_var_r == 2 & map_var_o == 2
replace map_var_u = 3 if (map_var_u == 1 | map_var_u == 2 | map_var_u == .) ///
			& ((map_var_r>=11 | map_var_r <=-11) | (map_var_o>=11 | map_var_o<=-11))
			
replace map_var_u = 3 if map_var_r == 3 & map_var_o == 3 & (map_var_u==2 | map_var_u == 1)

keep station_id station station_lat station_lon *_effect* map_var_* _merge
order station_id station station_lat station_lon station *_effect* map_var_* _merge

			
* merge on city/town outline
append using `outline',
sort _ID shape_order



********************************************************************************
** rents maps
********************************************************************************
* create rent map
local LEGEND 2 "No boundary near station" ///
		3 "Regulation already lower than Chapter 40A" ///
		7 "0% (null effect)" ///
		99 "" ///
		6 "< 0% to -4.99%" ///
		5 "-5% to -9.99%" ///
		4 "</= -10%" ///
		99 "" ///
		8 "> 0% to 4.99%" ///
		9 "5% to 9.99%" ///
		10 ">/= 10%"

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_r==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_r==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_r==-13, msymbol() msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_r==-12, msymbol() msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_r==-11, msymbol() msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_r==3, msymbol() msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_r==11, msymbol() msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_r==12, msymbol() msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_r==13, msymbol()  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:Monthly Rent}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(rents, replace)	;	
#delimit cr

graph save rents "station_rents_map.gph", replace
graph export "station_rents_map.pdf", replace name(rents)

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_r==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_r==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_r==-13, msymbol() msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_r==-12, msymbol() msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_r==-11, msymbol() msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_r==3, msymbol() msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_r==11, msymbol() msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_r==12, msymbol() msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_r==13, msymbol()  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(off)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(rents, replace)	;	
#delimit cr

graph save rents "station_rents_map_noleg.gph", replace
graph export "station_rents_map_noleg.pdf", replace name(rents)

graph close _all


********************************************************************************
** prices maps
********************************************************************************
* create prices map
local LEGEND 2 "No boundary near station" ///
		3 "Regulation already lower than Chapter 40A" ///
		7 "0% (null effect)" ///
		99 "" ///
		6 "< 0% to -4.99%" ///
		5 "-5% to -9.99%" ///
		4 "</= -10%" ///
		99 "" ///
		8 "> 0% to 4.99%" ///
		9 "5% to 9.99%" ///
		10 ">/= 10%"
		
#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_o==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_o==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_o==-13, msymbol() msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_o==-12, msymbol() msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_o==-11, msymbol() msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_o==3, msymbol() msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_o==11, msymbol() msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_o==12, msymbol() msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_o==13, msymbol()  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:Sinlge-family Sales Price}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(prices, replace)	;	
#delimit cr

graph save prices "station_prices_map.gph", replace
graph export "station_prices_map.pdf", replace name(prices)

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_o==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_o==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_o==-13, msymbol() msize(1.5)  mcolor("129 63 22")
	|| scatter station_lat station_lon if map_var_o==-12, msymbol() msize(1.5) mcolor("224 134 80")
	|| scatter station_lat station_lon if map_var_o==-11, msymbol() msize(1.5) mcolor("236 182 149")

	|| scatter station_lat station_lon if map_var_o==3, msymbol() msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_o==11, msymbol() msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_o==12, msymbol() msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_o==13, msymbol()  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
	
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(off)
	legend( order(" `LEGEND' ") title("{bf:% Change in Price/Rent}", size(2) pos(11))
		rows(3) cols() size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(prices, replace)	;	
#delimit cr

graph save prices "station_prices_map_noleg.gph", replace
graph export "station_prices_map_noleg.pdf", replace name(prices)


graph close _all


********************************************************************************
** units maps
********************************************************************************
* create unit effect maps
local LEGEND 2 "No boundary near station" ///
		3 "Regulation already lower than Chapter 40A" ///
		4 "0 (null effect)" ///
		5 "> 0 to .14" ///
		6 ".15 to .29" ///
		7 ">/= .30"
		
#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_u==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_u==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_u==3, msymbol() msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_u==11, msymbol() msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_u==12, msymbol() msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_u==13, msymbol()  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
											
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:Units Per Lot}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(on)
	legend( order(" `LEGEND' ") title("{bf:# Change in Units}", size(2) pos(11))
		rows() cols(1) size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(units, replace)	;	
#delimit cr

graph save units "station_units_map.gph", replace
graph export "station_units_map.pdf", replace name(units)

#delimit ;
twoway	area _Y _X if _ID!=., nodropbase cmiss(n) lwidth(.05) lcolor(black) fi(15) fcol(gs8)

	/* actual scatter plots */
	|| scatter station_lat station_lon if map_var_u==1, msymbol(X) msize(1.5) mcolor(gs6)
	|| scatter station_lat station_lon if map_var_u==2, msymbol(T) msize(1.5) mcolor(gs6)

	|| scatter station_lat station_lon if map_var_u==3, msymbol() msize(1.5) mlwidth(.1) mlcolor(black) mfcolor(white)

	|| scatter station_lat station_lon if map_var_u==11, msymbol() msize(1.5) mcolor("145 183 202")
	|| scatter station_lat station_lon if map_var_u==12, msymbol() msize(1.5) mcolor("77 134 160")
	|| scatter station_lat station_lon if map_var_u==13, msymbol()  msize(1.5) mcolor("38 67 81")

	/*|| scatter boston_lat boston_lon if boston_lab!="", mlabel(boston_lab) msymbol(S) mcolor(black) mlabcolor(black) mlabsize(4)*/
											
	/* graph format region [do not change] */
	aspectratio(1) graphregion(fc(white) lcolor(white) margin(0 0 0 0)) plotregion(fc(white) margin(0 0 0 0))
	ysize(1) xsize(1)
	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
	
	/* titles, subtitles, notes */		
	title("{bf:}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)	
	subtitle("`SUBTITLE'", size(2) pos(11) margin(t=0 b=0 l=0 r=0) span)
	note("`FOOTNOTE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	caption("`SOURCE'", size(1) margin(t=1 b=0 l=0 r=0) span)		
	
	/* legend */
	leg(off)
	legend( order(" `LEGEND' ") title("{bf:# Change in Units}", size(2) pos(11))
		rows() cols(3) size(2) 
		nobox fcolor() 
		region(fcolor(none) lpattern(blank)) 
		symy(2) symx(3) position(6) )	

	/* graph name */	
	name(units, replace)	;	
#delimit cr

graph save units "station_units_map_noleg.gph", replace
graph export "station_units_map_noleg.pdf", replace name(units)

graph close _all


********************************************************************************
** end
********************************************************************************
clear all
