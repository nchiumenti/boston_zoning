* start here
clear all
log close _all
set linesize 255

local name ="histogram"  // <--- change when necessry

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
* File name:		histogram.do
*
* Project title:	Boston Zoning Paper
*
* Description:		makes a bunch of histograms and scatter plots
* 				
* Inputs:			within_town_analysis_data.dta
*				
* Outputs:			.gph and .pdf files
*
* Created:			09/21/2021
* Updated:			04/15/2025
********************************************************************************


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear



********************************************************************************
** Histogram for figure A.3 in paper
********************************************************************************
** append on acs data
preserve 


use "${DATAPATH}/ACS_2019_rent.dta", replace
	keep if unitsstr>=5
	keep if statefip == 25
	keep if rent>0

	gen acs2019 = 1

	keep acs2019 rent

	tempfile acs2019
	save `acs2019', replace
	clear

restore

* append acs 2019
append using `acs2019'

#delimit ;
twoway	(histogram comb_rent1 if res_typex!= "Single Family Res", percent color(red%30) width(100))
	(histogram rent if acs2019==1 & rent>0, percent color(blue%30) width(100)),
	
	/* plot region */
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

	/* titles, subtitles, notes */		
	title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

	/* axis titles and labels */		
	ylabel(0(2)10, labsize(4) gmin gmax) ymtick()	
	
	xlabel(0(1000)7000, labsize(3) angle(45) gmax)
		
	/* legend */
	legend(on position(6) 
		order(1 "Imputed (6.29%)" 2 "ACS 2018")
		symy(2) symx(3) 
		rows(1) cols() size(3) 
		nobox fcolor()
		region(fcolor(none) lpattern(blank))
		margin(t=1 b=1 l=0 r=0)span)
	name(, replace) ;
#delimit cr

graph save "$EXPORTPATH/histogram_A3.gph", replace

drop if acs2019 == 1

********************************************************************************
** BinScatter for figure A.4 in paper
********************************************************************************
global bin_cond_3ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'

#delimit ;

    binscatter house_rent costar_rent if $bin_cond_3ab, 
    
		/* plot region */
		graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

		/* titles, subtitles, notes */          
		title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

		/* axis titles and labels */            
		ytitle("Imputed (6.29%)") ylabel(,labsize(4) gmin gmax) 
		xtitle("CoStar") xlabel(,labsize(3) gmin gmax) 
				
		/* legend */
		legend(on position(6) 
				order(1 "Warren Group Property")
				symy(2) symx(3) 
				rows(1) cols() size(3) 
				nobox fcolor()
				region(fcolor(none) lpattern(blank))
				margin(t=1 b=1 l=0 r=0)span)
		name(, replace) ;
#delimit cr

graph save "$EXPORTPATH/binscatter_A4.gph", replace


********************************************************************************
** END
********************************************************************************
display "finished!" 
log off
log close
clear all

** convert gph to pdfs
local files : dir "$EXPORTPATH" files "*.gph"

foreach fin in `files' {	
	local fout : subinstr local fin ".gph" ".pdf"	
	
	display "converting `fin' to `fout'..."
	
	graph use "$EXPORTPATH/`fin'"
	
	graph export "$EXPORTPATH/`fout'", as(pdf) replace
	
	graph close
}

