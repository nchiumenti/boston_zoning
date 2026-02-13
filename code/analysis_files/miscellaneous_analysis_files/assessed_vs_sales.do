********************************************************************************
* File name:		"assessed_vs_sales.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		createsthe bin scatter of accessed vs sales price values
*			figure found in the working paper.
* 				
* Inputs:		warren_MAPC_all_annual.dta
*				
* Outputs:		contents for Table 1
*
* Created:		4/26/2021
* Last updated:		4/26/2021
********************************************************************************


* load and match last sales prices to assessed values
use "$DATAPATH/warren/assessor/data/MA_assessor_hist.dta", clear

	// put observations in correct update order for assessor records
	gsort prop_id fy entry_smonth batch -reload

	// keep only the latest update record for each property and fiscal year
	by prop_id fy: keep if _n == _N

	// set the data to annual time series
	tsset prop_id fy

	keep prop_id fy last_*

	tempfile sales
	save `sales', replace

use "$DATAPATH/final_dataset_10-28-2021.dta", clear

merge 1:1 prop_id fy using `sales'
	drop if _merge == 2
	drop _merge

	
********************************************************************************
tempfile save_point
save `save_point', replace	
********************************************************************************

* standardize height and dupac
gen height = home_mxht_eff // NFC
gen dupac = home_dupac_eff // NFC
gen mf_allowed = home_mulfam // NFC

sum height
local a = r(mean)
local b = r(sd)
gen std_he = (height - `a')/`b'
label var std_he "Standardized height"
sum dupac 
local a = r(mean)
local b = r(sd)
gen std_du = (dupac - `a')/`b'
label var std_du "Standardized DUPAC"

replace height = height/10 // show in units of 10 feet

*gen height_2 = height^2
gen dupac_2 = dupac^2

gen lot_acres = lot_sizesqft/43560

gen byright_he = 0 if height==0 
replace byright_he = 1 if height!=0 

gen byright_du = 0 if dupac==0 
replace byright_du = 1 if dupac!=0 

gen lam_seg = boundary_using_id
by lam_seg boundary_side, sort : gen blah = _n ==1 
by lam_seg, sort : egen blah_sum = total(blah) 
tab blah_sum

keep if blah_sum==2   // Drop the boundaries where the other side has no observations

* NFC - theta_sf and theta_gd
gen theta_sf = density_sf 
gen theta_gd = density_gentle
gen theta_hd = density_hard

* NFC - regulation variables
gen mf_delta = home_mulfam - nn_mulfam  
gen he_delta = home_mxht_eff - nn_mxht_eff
gen du_delta = home_dupac_eff - nn_dupac_eff 

gen only_mf = mf_delta != 0 & he_delta == 0 & du_delta == 0
gen only_he = he_delta != 0 & mf_delta == 0 & du_delta == 0
gen only_du = du_delta != 0 & he_delta == 0 & mf_delta == 0 
gen mf_he = mf_delta != 0 & he_delta != 0 & du_delta == 0
gen mf_du = mf_delta != 0 & he_delta == 0 & du_delta != 0
gen du_he = mf_delta == 0 & he_delta != 0 & du_delta != 0
gen mf_he_du = mf_delta != 0 & he_delta != 0 & du_delta != 0

*definition of which side of the boundary is relaxed
*treatment is: relaxing the regulation
*height (more height = relaxed)
*du (more density = relaxed)
*mf (allowing mf = relaxed)

gen own_du = home_dupac_eff // NFC
gen other_du = nn_dupac_eff // NFC

gen own_he = home_mxht_eff // NFC
gen other_he = nn_mxht_eff // NFC

sum own_du
local a = r(mean)
local b = r(sd)
gen std_du_own = (own_du - `a')/`b'
sum own_he
local a = r(mean)
local b = r(sd)
gen std_he_own = (own_he - `a')/`b'

sum other_du
local a = r(mean)
local b = r(sd)
gen std_du_other = (other_du - `a')/`b'
sum other_he
local a = r(mean)
local b = r(sd)
gen std_he_other = (other_he - `a')/`b'

*easy cases and letting MF allowed dominating other regulations
gen relaxed = 0
 
replace relaxed = 1 if only_he == 1 & he_delta>0
replace relaxed = 1 if only_du == 1 & du_delta>0
replace relaxed = 1 if only_mf == 1 & mf_delta==1

replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta<0   // flip this in relaxed2

*multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta<0

*this is only the clear case
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

*when two of 3 are relaxed, count as relaxed
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0

*letting height and dupac dominate mf allowed
gen relaxed2 = 0
replace relaxed2 = 1 if only_he == 1 & he_delta>0
replace relaxed2 = 1 if only_du == 1 & du_delta>0
replace relaxed2 = 1 if only_mf == 1 & mf_delta==1

replace relaxed2 = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed2 = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed2 = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed2 = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed2 = 1 if mf_du == 1 & mf_delta == -1 & du_delta>0  

*multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed2 = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed2 = 1 if mf_he == 1 & mf_delta == -1 & he_delta>0

*this is only the clear case
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

*when two of 3 are relaxed, count as relaxed
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0


* keep date range of report
drop if fy < 2010 | fy > 2018	
		
* gen last sale year record
tostring(last_saledate), gen(last_saleyr)

replace last_saleyr = substr(last_saleyr,1,4)

destring last_saleyr, replace

* drop top and bottom 2% of ass and sale values
drop if assd_totval == . | last_salepr == . | assd_totval == 0 | last_salepr == 0

* drop props that haven't sold within last 5 years
// drop if (fy - last_saleyr > 5) | (fy - last_saleyr < 0)

* keep only if assessed year == sales year
keep if fy == last_saleyr


********************************************************************************
tempfile save_point2
save `save_point2', replace	
********************************************************************************


* convert house prices into 2019 prices: Deflated House Prices
gen year = fy

merge m:1 year using "$DATAPATH/Fred_CPI/CPI_2019.dta" // NFC - changed to m:1 merge
	drop if _merge == 2 // NFC - not all years match
	drop _merge 

replace assd_totval = assd_totval/fred_cpi

replace last_salepr = last_salepr/fred_cpi

* calculate percentiles
egen sale_pct = xtile(last_salepr), by(fy) n(100)

egen ass_pct = xtile(assd_totval), by(fy) n(100)

sum sale_pct ass_pct

* drop top and bottom 2%
drop if ass_pct <=2 | ass_pct>=98 | sale_pct<=2 | sale_pct>=98

* gen graphing variables
gen assd_to_sale = assd_totval / last_salepr

replace last_salepr = last_salepr / 1000

** summary and graphhing
corr assd_totval last_salepr 

bysort relaxed: corr assd_totval last_salepr,


binscatter assd_to_sale last_salepr, n(20) ///
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero)) ///
	xlabel(0(200)1600, gmin gmax format(%8.0fc)) ///
	ylabel(0(.25)2, gmin gmax) ///
	xtitle("{bf:Sale Price (thousands)}") ///
	ytitle("{bf:Assessed-Sale Ratio}") ///
	legend(rows(1) size(2) nobox fcolor() region(fcolor(none) lpattern(blank)) symy(2) symx(3) position(6)) ///
	name("assessed_sales", replace)
	graph save "assessed_sales" "$FIGPATH/assessed_sales.gph", replace
	graph export "$FIGPATH/assessed_sales.pdf", name("assessed_sales") replace

binscatter assd_to_sale last_salepr, n(20) by(relaxed) ///
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero)) ///
	xlabel(0(200)1600, gmin gmax format(%8.0fc)) ///
	ylabel(0(.25)2, gmin gmax) ///
	xtitle("{bf:Sale Price (thousands)}") ///
	ytitle("{bf:Assessed-Sale Ratio}") ///
	legend(rows(1) size(2) nobox fcolor() region(fcolor(none) lpattern(blank)) symy(2) symx(3) position(6)) ///
	name("assessed_sales", replace)
	graph save assessed_sales "$FIGPATH/assessed_sales_relaxed.gph", replace	
	graph export "$FIGPATH/assessed_sales_relaxed.pdf", name("assessed_sales") replace

	
gen town = city
	
binscatter assd_to_sale last_salepr, n(20) by(relaxed) absorb(city) ///
	graphregion(fc(white) lcolor(white)) plotregion(fc(white) margin(zero)) ///
	xlabel(0(200)1600, gmin gmax format(%8.0fc)) ///
	ylabel(0(.25)2, gmin gmax) ///
	xtitle("{bf:Sale Price (thousands)}") ///
	ytitle("{bf:Assessed-Sale Ratio}") ///
	legend(rows(1) size(2) nobox fcolor() region(fcolor(none) lpattern(blank)) symy(2) symx(3) position(6)) ///
	name("assessed_sales", replace)
	graph save "assessed_sales" "$FIGPATH/assessed_sales_town.gph",  replace	
	graph export "$FIGPATH/assessed_sales_town.pdf", name("assessed_sales") replace




