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
* Updated:			03/20/2025
********************************************************************************


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear


********************************************************************************
** define winsorized variable (drop bottom and top 1%)
********************************************************************************
sum house_rent if !missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5
local p1 = r(p1)
local p99 = r(p99)

di `p1'
di `p99'

gen winsorized = 0
replace winsorized = 1 if house_rent<`p1'
replace winsorized = 1 if house_rent>`p99' & house_rent!=.

tab winsorized


********************************************************************************
** define global conditions for histograms, scatterplots and binscatters
********************************************************************************
* NFC Note 11/18: 1.c has no observations.... have Mike tab res_typex to trouble shoot
* w/e the valyes for the clear apartment builsings, use it below for 1c and 2c
tab res_typex

global hist_cond_1ab 		`"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
global hist_cond_1cd 		`"!missing(costar_rent) & (res_typex== "Four to Eight Units" | res_typex == "More than Eight Units") & num_units1 > 5 & house_rent>0 & house_rent<=7000"'

global scat_cond_2ab 		`"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
global scat_cond_2cd 		`"!missing(costar_rent) & (res_typex== "Four to Eight Units" | res_typex == "More than Eight Units") & num_units1 > 5 & house_rent>0 & house_rent<=7000"'

global bin_cond_3ab 		`"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
global bin_cond_3cd 		`"!missing(costar_rent) & (res_typex== "Four to Eight Units" | res_typex == "More than Eight Units") & num_units1 > 5 & house_rent>0 & house_rent<=7000"'


********************************************************************************
** Histogram 1.A:
** global hist_cond_1ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5"'
********************************************************************************
#delimit ;
twoway  
	(histogram house_rent if $hist_cond_1ab, percent color(red%30) width(100))
	(histogram costar_rent if $hist_cond_1ab, percent color(blue%30) width(100)),
	
	/* plot region */
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

	/* titles, subtitles, notes */		
	title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

	/* axis titles and labels */		
	ylabel(,labsize(4) gmin gmax) ymtick()	
	
	xlabel(, labsize(3) angle(45) gmax)
		
	/* legend */
	legend(on position(6) 
		order(1 "Imputed (6.29%)" 2 "CoStar")
		symy(2) symx(3) 
		rows(1) cols() size(3) 
		nobox fcolor()
		region(fcolor(none) lpattern(blank))
		margin(t=1 b=1 l=0 r=0)span)
	name(hist_1a, replace) ;
#delimit cr

graph save hist_1a "$EXPORTPATH/histogram_1a.gph", replace


********************************************************************************
** Histogram 1.B: winsorized version
** global hist_cond_1ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5"'
********************************************************************************
#delimit ;
twoway  
	(histogram house_rent if $hist_cond_1ab & winsorized == 1, percent color(red%30) width(100))
	(histogram costar_rent if $hist_cond_1ab & winsorized == 1, percent color(blue%30) width(100)),
	
	/* plot region */
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

	/* titles, subtitles, notes */		
	title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

	/* axis titles and labels */		
	ylabel(,labsize(4) gmin gmax) ymtick()	
	
	xlabel(, labsize(3) angle(45) gmax)
		
	/* legend */
	legend(on position(6) 
		order(1 "Imputed (6.29%)" 2 "CoStar")
		symy(2) symx(3) 
		rows(1) cols() size(3) 
		nobox fcolor()
		region(fcolor(none) lpattern(blank))
		margin(t=1 b=1 l=0 r=0)span)
	name(, replace) ;
#delimit cr

graph save "$EXPORTPATH/histogram_1b.gph", replace


********************************************************************************
** Histogram 1.C:
** global hist_cond_1cd `"!missing(costar_rent) & <PRIVATE MARKET APARTMENTS ONLY> & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway  
	(histogram house_rent if $hist_cond_1cd, percent color(red%30) width(100))
	(histogram costar_rent if $hist_cond_1cd, percent color(blue%30) width(100)),
	
	/* plot region */
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

	/* titles, subtitles, notes */		
	title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

	/* axis titles and labels */		
	ylabel(,labsize(4) gmin gmax) ymtick()	
	
	xlabel(, labsize(3) angle(45) gmax)
		
	/* legend */
	legend(on position(6) 
		order(1 "Imputed (6.29%)" 2 "CoStar")
		symy(2) symx(3) 
		rows(1) cols() size(3) 
		nobox fcolor()
		region(fcolor(none) lpattern(blank))
		margin(t=1 b=1 l=0 r=0)span)
	name(, replace) ;
#delimit cr

graph save "$EXPORTPATH/histogram_1c.gph", replace


********************************************************************************
** Histogram 1.D:
** global hist_cond_1cd `"!missing(costar_rent) & <PRIVATE MARKET APARTMENTS ONLY> & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway  
	(histogram house_rent if $hist_cond_1cd & winsorized == 1, percent color(red%30) width(100))
	(histogram costar_rent if $hist_cond_1cd & winsorized == 1, percent color(blue%30) width(100)),
	
	/* plot region */
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) lcolor(white))

	/* titles, subtitles, notes */		
	title("{bf:`title'}", size(3) pos(12) margin(t=0 b=0 l=0 r=0) span)

	/* axis titles and labels */		
	ylabel(,labsize(4) gmin gmax) ymtick()	
	
	xlabel(, labsize(3) angle(45) gmax)
		
	/* legend */
	legend(on position(6) 
		order(1 "Imputed (6.29%)" 2 "CoStar")
		symy(2) symx(3) 
		rows(1) cols() size(3) 
		nobox fcolor()
		region(fcolor(none) lpattern(blank))
		margin(t=1 b=1 l=0 r=0)span)
	name(, replace) ;
#delimit cr

graph save "$EXPORTPATH/histogram_1d.gph", replace


********************************************************************************
** Scatter 2.A:
** global scat_cond_2ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    scatter house_rent costar_rent if $scat_cond_2ab, 
    
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

graph save "$EXPORTPATH/scatter_2a.gph", replace


********************************************************************************
** Scatter 2.B: winsorized
** global scat_cond_2ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    scatter house_rent costar_rent if $scat_cond_2ab & winsorized == 1, 
    
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

graph save "$EXPORTPATH/scatter_2b.gph", replace


********************************************************************************
** Scatter 2.C:
** global scat_cond_1cd `"!missing(costar_rent) & <PRIVATE MARKET APARTMENTS ONLY> & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    scatter house_rent costar_rent if $scat_cond_2cd, 
    
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

graph save "$EXPORTPATH/scatter_2c.gph", replace


********************************************************************************
** Scatter 2.D: winsorized
** global scat_cond_1cd `"!missing(costar_rent) & <PRIVATE MARKET APARTMENTS ONLY> & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    scatter house_rent costar_rent if $scat_cond_2cd & winsorized == 1, 
    
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

graph save "$EXPORTPATH/scatter_2d.gph", replace


********************************************************************************
** BinScatter 3.A:
** global bin_cond_3ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
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

graph save "$EXPORTPATH/binscatter_3a.gph", replace


********************************************************************************
** BinScatter 3.B: winsorized
** global $bin_cond_3ab `"!missing(costar_rent) & res_typex!= "Condominiums" & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    binscatter house_rent costar_rent if $bin_cond_3ab & winsorized == 1, 
    
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

graph save "$EXPORTPATH/binscatter_3b.gph", replace

/* commented out because of lack of observations
********************************************************************************
** BinScatter 3.C:
** global bin_cond_3cd `"!missing(costar_rent) & <PRIVATE MARKET APARTMENTS ONLY> & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    binscatter house_rent costar_rent if $bin_cond_3cd, 
    
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

graph save "$EXPORTPATH/binscatter_3c.gph", replace


********************************************************************************
** BinScatter 3.D: winsorized
** global bin_cond_3cd `"!missing(costar_rent) & <PRIVATE MARKET APARTMENTS ONLY> & num_units1 > 5 & house_rent>0 & house_rent<=7000"'
********************************************************************************
#delimit ;
twoway 
    binscatter house_rent costar_rent if $bin_cond_3cd & winsorized == 1, 
    
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

graph save "$EXPORTPATH/binscatter_3d.gph", replace


********************************************************************************
** the og histogram
********************************************************************************

twoway (histogram AvgAskingUnit,  color(red%30)) (histogram pred_cstar if pred_cstar>0,  color(green%30)) ///
		(histogram pred_nocstar if (pred_nocstar > 0 & pred_nocstar<10000  ), color(blue%30))  ///
		(histogram comb_rent1 if (res_typex!= "Single Family Res" ) ,  color(purple%30)) ///
		(histogram rent if acs2019==1 & rent>0, color(yellow%30)), ///
		 legend(order(1 "CoStar Rent" 2 "Imputed (CoStar)" 3 "Imputed (ACS)" 4 "Imputed (6.29%)" 5 "ACS 2018")) graphregion(color(white))

graph save "$EXPORTPATH/Histogram_imputed_rent_6pct.gph", replace
*/

********************************************************************************
** END
********************************************************************************
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

display "finished!" 