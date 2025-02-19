clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")
local name ="postrestat_histogram" // <--- change when necessry
log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

* create a save directory if none exists
global RDPATH "$FIGPATH/`name'_`date_stamp'"

capture confirm file "$RDPATH"

if _rc!=0 {
	di "making directory $RDPATH"
	shell mkdir $RDPATH
}

cd $RDPATH

********************************************************************************
* File name:		"postrestat_histogram"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		makes both histograms and scatter plots
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		09/21/2021
* Updated:		11/15/2024
********************************************************************************

use "$DATAPATH/final_dataset_10-28-2021.dta", clear

do "$DOPATH/archived/wp_within_town_setup.do"

// use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear //created with "$DOPATH/postREStat_within_town_setup_07102024.do"


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

stop

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

graph save hist_1a "postrestat_histogram_1a.gph", replace
graph export hist_1a "postrestat_histogram_1a.pdf", replace


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

graph save "postrestat_histogram_1b.gph", replace
graph export "postrestat_histogram_1b.pdf", replace


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

graph save "postrestat_histogram_1c.gph", replace
graph export "postrestat_histogram_1c.pdf", replace


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

graph save "postrestat_histogram_1d.gph", replace
graph export "postrestat_histogram_1d.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_scatter_2a.gph", replace
graph export "postrestat_scatter_2a.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_scatter_2b.gph", replace
graph export "postrestat_scatter_2b.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_scatter_2c.gph", replace
graph export "postrestat_scatter_2c.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_scatter_2d.gph", replace
graph export "postrestat_scatter_2d.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_binscatter_3a.gph", replace
graph export "postrestat_binscatter_3a.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_binscatter_3b.gph", replace
graph export "postrestat_binscatter_3b.pdf", replace


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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_binscatter_3c.gph", replace
graph export "postrestat_binscatter_3c.pdf", replace


********************************************************************************
** BinScatter 2.D: winsorized
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
	ylabel("Imputed (6.29%)",labsize(4) gmin gmax) ymtick()	
	
	xlabel("CoStar", labsize(3) angle(45) gmax)
		
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

graph save "postrestat_binscatter_3d.gph", replace
graph export "postrestat_binscatter_3d.pdf", replace


********************************************************************************
** the og histogram
********************************************************************************

twoway (histogram AvgAskingUnit,  color(red%30)) (histogram pred_cstar if pred_cstar>0,  color(green%30)) ///
		(histogram pred_nocstar if (pred_nocstar > 0 & pred_nocstar<10000  ), color(blue%30))  ///
		(histogram comb_rent1 if (res_typex!= "Single Family Res" ) ,  color(purple%30)) ///
		(histogram rent if acs2019==1 & rent>0, color(yellow%30)), ///
		 legend(order(1 "CoStar Rent" 2 "Imputed (CoStar)" 3 "Imputed (ACS)" 4 "Imputed (6.29%)" 5 "ACS 2018")) graphregion(color(white))
graph export "Histogram_imputed_rent_6pct.pdf", replace
