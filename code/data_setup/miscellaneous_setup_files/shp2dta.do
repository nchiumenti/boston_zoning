clear all
log close _all
local date = td(`c(current_date)')
local date_stamp = string(year(`date'))+string(month(`date'),"%02.0f")+string(day(`date'),"%02.0f")
local file_name ="shp2dta" // <--- change when necessry
log using "$LOGPATH/`file_name'_log_`date_stamp'.log", replace

********************************************************************************
* File name:		"11_shp2dta.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Extracts '.shp' and saves them as '.dta' files for use 
*			in mapping.
* 				
* Inputs:		.shp files
*			MA County Subdivisions
*			MA Block Groups
*			MAPC Zoning Atlas
*				
* Outputs:		various .dta versions of the above
*
* Created:		01/20/2021
* Last updated:		01/20/2021
********************************************************************************

* set paths
clear all
global SHAPEPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/data/shapefiles"
global FIGPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/figures"
global EXT ".pdf"
cd "$DOPATH"

* convert all '.shp' files to Stata format
cd $SHAPEPATH/originals

// local files : dir "$SHAPEPATH/standardized" files "*.shp"

local files : dir "$SHAPEPATH/originals" files "*.shp"


foreach fin in `files'{	
	local fout : subinstr local fin ".shp" ""	
	
	display "converting `fin' to Stata .dta file..."
	
	quietly spshape2dta "`fin'", saving("`fout'") replace
	
	display "finished!" 
	
	display ""
}


// ********************************************************************************
// ** Mapp overlay of school attendance areas and MAPC towns
// ********************************************************************************
// * save MAPC municipalities
// use "$SHAPEPATH/standardized/zoning_atlas_latlong.dta", clear
//
// gen rec_count = 1
//
// gen CITY = upper(muni)
// replace CITY = regexr(CITY,"( TOWN| CITY)+","")			// remove town/city suffixes
// replace CITY = "MANCHESTER-BY-THE-SEA" if CITY=="MANCHESTER"	// 'Manchester' -> 'Manchester-by-the-Sea'
// replace CITY = regexr(CITY, "(BOROUGH)$","BORO") 		// standardizes borough->boro suffix
//
// levelsof(CITY), local(town_list)
//
// gen n = 1
// collapse (sum) n , by(CITY)
// drop n
//
// tempfile mapc_list
// save `mapc_list', replace
//
// * EDGE school geo-coding file
// import excel "$SHAPEPATH/EDGE_GEOCODE_PUBLICSCH_1516.xlsx", sheet("CCD_SCH_GEO_1516_new") case(lower) firstrow allstring clear
//
// keep if lstate=="MA"
// destring lat1516 lon1516, replace
// geoinpoly lat1516 lon1516 using "$SHAPEPATH/standardized/cb_2018_25_cousub_500k_latlong_shp.dta"
// merge m:1 _ID using "$SHAPEPATH/standardized/cb_2018_25_cousub_500k_latlong.dta", keep(1 3) keepusing(NAME)
//
// gen school_id = ncessch
// gen CITY = upper(NAME)
// keep school_id CITY
//
// tempfile school_geo
// save `school_geo', replace
//
// * save 2013/2014 school attendance boundaries
// use "$SHAPEPATH/standardized/SABS_1314_Primary_latlong.dta", clear
//
// keep if stAbbrev=="MA"
//
// gen school_id = ncessch
//
// merge m:1 school_id using `school_geo', keepusing(CITY) keep(1 3) nogen
//
// replace CITY ="AGAWAM" if ncessch=="250180099991"
// replace CITY ="ARLINGTON" if ncessch=="250198099991"
// replace CITY ="BEVERLY" if ncessch=="250264099991"
// replace CITY ="BOSTON" if ncessch=="250279099991"
// replace CITY ="DOUGLAS" if ncessch=="250423001162"
// replace CITY ="EASTON" if ncessch=="250462000984"
// replace CITY ="EVERETT" if ncessch=="250477099991"
// replace CITY ="FALL RIVER" if ncessch=="250483099991"
// replace CITY ="FRAMINGHAM" if ncessch=="250498001167"
// replace CITY ="LYNN" if ncessch=="250711099991"
// replace CITY ="MARBLEHEAD" if ncessch=="250726001119"
// replace CITY ="MARBLEHEAD" if ncessch=="250726099991"
// replace CITY ="MARSHFIELD" if ncessch=="250735099991"
// replace CITY ="NEWBURYPORT" if ncessch=="250858001352"
// replace CITY ="NORTH ANDOVER" if ncessch=="250870099991"
// replace CITY ="NORTH READING" if ncessch=="250882099991"
// replace CITY ="PEMBROKE" if ncessch=="250942099991"
// replace CITY ="PLYMOUTH" if ncessch=="250972099991"
// replace CITY ="SANDWHICH" if ncessch=="251047099991"
// replace CITY ="SOMERSET" if ncessch=="251086001730"
// replace CITY ="STONEHAM" if ncessch=="251122001850"
// replace CITY ="WAKEFIELD" if ncessch=="251191099991"
// replace CITY ="WALTHAM" if ncessch=="251200099991"
// replace CITY ="WESTFIELD" if ncessch=="251263099991"
// replace CITY ="WEYMOUTH" if ncessch=="251284099991"
//
// replace CITY = regexr(CITY,"( TOWN| CITY)+","")			// remove town/city suffixes
// replace CITY = "MANCHESTER-BY-THE-SEA" if CITY=="MANCHESTER"	// 'Manchester' -> 'Manchester-by-the-Sea'
// replace CITY = regexr(CITY, "(BOROUGH)$","BORO") 		// standardizes borough->boro suffix
//
// gen unassigned = 0
// replace unassigned = 1 if schnam == "Unassigned"
//
// gen mapc_town = 0
// foreach t in `town_list'{
// 	quietly replace mapc_town=1 if CITY=="`t'"
// }
//
// keep if mapc_town==1 // 251 obs after drop
//
// merge 1:m _ID using "$SHAPEPATH/standardized/SABS_1314_Primary_latlong_shp.dta", keep(3) keepusing(_X _Y shape_order) nogen
//
// gen map="SABS14"
//
// sort _ID shape_order
//
// keep _ID _X _Y shape_order map unassigned
//
// tempfile sabs14_map
// save `sabs14_map', replace
//
//
//
// * save 2015/2016 school attendance boundaries
// use "$SHAPEPATH/standardized/SABS_1516_Primary_latlong.dta", clear
//
// keep if stAbbrev=="MA"
// gen school_id = ncessch
// merge m:1 school_id using `school_geo', keepusing(CITY) keep(1 3) nogen
//
// replace CITY ="ARLINGTON" if ncessch=="250198099991"
// replace CITY ="BEVERLY" if ncessch=="250264099991"
// replace CITY ="CANTON" if ncessch=="250330099991"
// replace CITY ="EVERETT" if ncessch=="250477099991"
// replace CITY ="FALL RIVER" if ncessch=="250483099991"
// replace CITY ="FALMOUTH" if ncessch=="250486099991"
// replace CITY ="LYNN" if ncessch=="250711099991"
// replace CITY ="MARBLEHEAD" if ncessch=="250726099991"
// replace CITY ="MARSHFIELD" if ncessch=="250735099991"
// replace CITY ="PEMBROKE" if ncessch=="250942099991"
// replace CITY ="PLYMOUTH" if ncessch=="250972099991"
// replace CITY ="WAKEFIELD" if ncessch=="251191099991"
// replace CITY ="WEYMOUTH" if ncessch=="251284099991"
//
// replace CITY = regexr(CITY,"( TOWN| CITY)+","")			// remove town/city suffixes
// replace CITY = "MANCHESTER-BY-THE-SEA" if CITY=="MANCHESTER"	// 'Manchester' -> 'Manchester-by-the-Sea'
// replace CITY = regexr(CITY, "(BOROUGH)$","BORO") 		// standardizes borough->boro suffix
//
// gen unassigned = 0
// replace unassigned = 1 if schnam == "Unassigned"
//
// gen mapc_town = 0
// foreach t in `town_list'{
// 	quietly replace mapc_town=1 if CITY=="`t'"
// }
//
// keep if mapc_town==1 // 270 after drop
//
// merge 1:m _ID using "$SHAPEPATH/standardized/SABS_1516_Primary_latlong_shp.dta", keep(3) keepusing(_X _Y shape_order) nogen
//
// gen map="SABS16"
//
// sort _ID shape_order
//
// keep _ID _X _Y shape_order map unassigned
//
// tempfile sabs16_map
// save `sabs16_map', replace
//
// * save Census county subdivision list within MAPC area
// use "$SHAPEPATH/standardized/cb_2018_25_cousub_500k_latlong.dta", clear
//
// gen CITY = upper(NAME)
// replace CITY = regexr(CITY,"( TOWN| CITY)+","")
// replace CITY = "MANCHESTER-BY-THE-SEA" if CITY=="MANCHESTER"	// 'Manchester' -> 'Manchester-by-the-Sea'
// replace CITY = regexr(CITY, "(BOROUGH)$","BORO") // standardizes borough->boro suffix
//
// gen mapc_town = 0
// foreach t in `town_list'{
// 	replace mapc_town=1 if CITY=="`t'"
// }
//
// keep if mapc_town==1
//
// merge 1:m _ID using "$SHAPEPATH/standardized/cb_2018_25_cousub_500k_latlong_shp.dta", keep(3) keepusing(_X _Y shape_order)
//
// gen map="CENSUS"
//
// sort _ID shape_order
//
// keep _ID _X _Y shape_order map
//
// * graph overlapping town school attendance boundary areas
// append using `sabs14_map'
// append using `sabs16_map'
//
// # delimit;
// twoway	
// 	|| area _Y _X if map=="CENSUS", nodropbase cmiss(n) lwidth(.01) lcolor(black) fi() fcol(gray)
// 	|| area _Y _X if map=="SABS14", nodropbase cmiss(n) lwidth(.01) lcolor(black) fi() fcol(orange)
// 	|| area _Y _X if map=="SABS16", nodropbase cmiss(n) lwidth(.01) lcolor(black) fi() fcol(blue)
// 	|| area _Y _X if map=="SABS14" & unassigned==1 , nodropbase cmiss(n) lwidth(.01) lcolor(black) fi() fcol(red)
// 	|| area _Y _X if map=="SABS16" & unassigned==1 , nodropbase cmiss(n) lwidth(.01) lcolor(black) fi() fcol(red)
// 	|| area _Y _X if map=="CENSUS", nodropbase cmiss(n) lwidth(.1) lcolor(white) fi() fcol(none)
//	
// 	/* graph format region [do not change] */
// 	aspectratio(1) graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero))
// 	ysize(8.5) xsize(11)
// 	ysc(off) yla(,nogrid) xsc(off) xla(,nogrid)
//		
// 	/* legend */
// 	leg(on)
// 	legend( order(1 "MAPC Munis" 2 "SABS-2013/2014" 3 "SABS-2015/2016" 4 "Uassigned areas") 
// 		rows(1) size(2) 
// 		nobox fcolor() 
// 		region(fcolor(none) lpattern(blank)) 
// 		symy(2) symx(3) position(6) )	
// ;
// #delimit cr
//
// ********************************************************************************
// ** END: close logs and clear data
// ********************************************************************************
log close
clear all
