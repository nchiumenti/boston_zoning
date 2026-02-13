********************************************************************************
* File name:		analysis_town_comparisons_setup.do
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		A secondary setup file used solely for the 
*					amenities_muni_boundary.do analysis. The main analysis 
*					compares across zoning boundaries. This file compares
*					across town boundaries
*
* Inputs:			none, see amenities_muni_boundary.do
*			
* Outputs:			none, see amenities_muni_boundary.do
*
* Created:		    09/21/2021
* Updated:		    01/12/2026
********************************************************************************

noisily display "Running analysis_town_comparisons_setup.do..."
noisily display "If called with <run> this file will run quietly and not display in log."
noisily display "Call with <do> to show the output in log file."

* confirm that all of the input data actually exists
confirm file "/shared/boston_zoning/working_paper/data/final_dataset_10-28-2021.dta"
confirm file "/shared/boston_zoning/working_paper/data/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta"
confirm file "/shared/boston_zoning/working_paper/data/warren/warren_sales_data.dta"
confirm file "/shared/boston_zoning/working_paper/data/fred_cpi/CPI_2019.dta"
confirm file "/shared/boston_zoning/working_paper/data/costar/costar_mf_destring.dta"
confirm file "/shared/boston_zoning/working_paper/data/costar/costar_rent_hist.dta"


********************************************************************************
** Load town comparisons dataset
/* comment out the <use> statement unless running this setup file by itself */
********************************************************************************
// use "$DATAPATH/final_dataset_town_comparisons.dta", clear


********************************************************************************
** Trim the input dataset
********************************************************************************
noisily display "Trimming input dataset..."

* drop non residential property types
drop if res_type == .

* drop properties outside of study period
keep if fy >= 2010 & fy <= 2018

* drop if properties are not assigned to any boundary
destring boundary_using_id, replace
drop if boundary_using_id == .

* gen year variable
gen year = fy

* summarize variables to ensure consistency across runs
sum fy


********************************************************************************
** Merge on closest stuff dataset
********************************************************************************
noisily display "Merging on closest stuff dataset..."

* merge on file with distance to closest school/river/road
local data_file_path = "/shared/boston_zoning/working_paper/data/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta"

merge m:1 prop_id using `data_file_path', keepusing(closest_*)

	* tab _merge and drop non-matches from using
	tab _merge
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** Merge on CPI dataset
********************************************************************************
noisily display "Merging on CPI dataset..."

* merge con CPI data to adjust rents/prices into 2019 dollars
local data_file_path = "/shared/boston_zoning/working_paper/data/fred_cpi/CPI_2019.dta"

merge m:1 year using `data_file_path'

	* tab _merge and drop non-matches from using
	tab _merge
	drop if _merge == 2
	drop _merge

		
********************************************************************************
** Merge on Co-Star variables

/* Two merges occur, first is the overall property characteristics, the second 
is the rent history file. */
********************************************************************************
noisily display "Merging on CoStar datasets..."

drop costar_rent costar_status  // <-- drop these variables so they update properly in the merge
destring costar_id, replace

* merge on multifamily property characteristics
local data_file_path = "/shared/boston_zoning/working_paper/data/costar/costar_mf_destring.dta"

merge m:1 costar_id using `data_file_path'

	* tab _merge and drop non-matches from using
	tab _merge
	drop if _merge == 2  // NFC comment: not all CoStar properties match
	drop _merge
	
* merge on historic rents and replace when not missing
local data_file_path = "/shared/boston_zoning/working_paper/data/costar/costar_rent_hist.dta"

merge m:1 fy costar_id using `data_file_path', keepusing(costar_rent)

	* tab _merge and drop non-matches from using
	tab _merge
	drop if _merge == 2  // NFC comment: not all CoStar properties match
	drop _merge

* clean up some costar variables
destring costar_rent, replace

replace AvgAskingUnit = costar_rent if costar_rent!=.  // <-- use the historic rent in place of asking rent if present
	
	
********************************************************************************
** merge on sales data
********************************************************************************
noisily display "Merging on warren group sales price data..."

* merge on sales data
local data_file_path = "/shared/boston_zoning/working_paper/data/warren/warren_sales_data.dta"

merge 1:1 prop_id fy using `data_file_path', keep(1 3)

	* tab _merge and drop non-matches from using
	tab _merge
	drop if _merge == 2
	drop _merge


********************************************************************************
** Building and neighborhood characteristics variable setup
********************************************************************************
noisily display "Generating building and neighborhood characteristics..."

* string version of res_type
decode res_type, generate(res_typex)

* gentle-density and high-density identifiers
gen fam23_1 = 0 if res_typex == "Single Family Res"
	replace fam23_1 = 1 if (res_typex == "Two Family Res" | res_typex == "Three Family Res") 

gen fam4plus_1 = 0 if res_typex == "Single Family Res"
	replace fam4plus_1 = 1 if (res_typex == "4-8 Unit Res" | res_typex == "9+ Unit Res" ) 

* mixed-use property identifeir
gen MU_2 = 0 if (res_typex != "Mixed-Use, Primairly Non-Residential" | res_typex != "Mixed-Use, Primarily Residential")
	replace MU_2 = 1 if (res_typex == "Mixed-Use, Primairly Non-Residential" | res_typex= = "Mixed-Use, Primarily Residential")

* impute units if 0 for cases where it's clear
replace num_units = 1 if res_typex == "Single Family Res" & num_units == 0
replace num_units = 2 if res_typex == "Two Family Res" & num_units == 0
replace num_units = 3 if res_typex == "Three Family Res" & num_units == 0

* gen number of floors and units
gen num_floors1 = num_floors if num_floors !=0
gen num_units1 = num_units if num_units !=0

* encode string variables
encode build_style, gen(build_style1)
encode condition, gen(condition1)
encode ext_cover, gen(ext_cover1)
encode fuel_type, gen(fuel_type1)
encode heat_type, gen(heat_type1)
encode roof_type, gen(roof_type1)

* gen lot size in terms of acres
gen lot_acres = lot_sizesqft/43560

* gen neighborhood density variables
gen theta_sf = density_sf 
gen theta_gd = density_gentle
gen theta_hd = density_hard

	
********************************************************************************
** Zoning regulation variable setup
********************************************************************************
noisily display "Generating zoning regulation variables..."

* reassign the home regulation variables
gen height = home_mxht_eff
gen dupac = home_dupac_eff
gen mf_allowed = home_mulfam

* standardize height and dupac variables
sum height
gen std_he = (height - `r(mean)')/`r(sd)'
label var std_he "Standardized height"

sum dupac 
gen std_du = (dupac - `r(mean)')/`r(sd)'
label var std_du "Standardized DUPAC"

* put height var in terms of flooras (10 feet per floor)
replace height = height/10

* gen square of height and density
gen height_2 = dupac^2
gen dupac_2 = dupac^2

* gen height and dupac by right variables
gen byright_he = 0 if height == 0 
replace byright_he = 1 if height != 0 

gen byright_du = 0 if dupac == 0 
replace byright_du = 1 if dupac != 0 

* gen regulation change across boundary variables
gen mf_delta = home_mulfam - nn_mulfam  
gen he_delta = home_mxht_eff - nn_mxht_eff
gen du_delta = home_dupac_eff - nn_dupac_eff 

* gen indicators for which regulation is changing
gen only_mf = mf_delta != 0 & he_delta == 0 & du_delta == 0
gen only_he = he_delta != 0 & mf_delta == 0 & du_delta == 0
gen only_du = du_delta != 0 & he_delta == 0 & mf_delta == 0 
gen mf_he = mf_delta != 0 & he_delta != 0 & du_delta == 0
gen mf_du = mf_delta != 0 & he_delta == 0 & du_delta != 0
gen du_he = mf_delta == 0 & he_delta != 0 & du_delta != 0
gen mf_he_du = mf_delta != 0 & he_delta != 0 & du_delta != 0

* gen variables for home and neighboring zoning regulations
gen own_du = home_dupac_eff
gen other_du = nn_dupac_eff

gen own_he = home_mxht_eff
gen other_he = nn_mxht_eff

* create standardized versions of own_ and other_
sum own_du
gen std_du_own = (own_du - `r(mean)')/`r(sd)'

sum own_he
gen std_he_own = (own_he - `r(mean)')/`r(sd)'

sum other_du
gen std_du_other = (other_du - `r(mean)')/`r(sd)'

sum other_he
gen std_he_other = (other_he - `r(mean)')/`r(sd)'


********************************************************************************
** Lam_seg variable creations and drop
********************************************************************************
noisily display "Calculating blah_sum, dropping if blah_sum == 1..."

* gen the boundary segment identifer variable
gen lam_seg = boundary_using_id

* gen blah_sum ( identifies if there is a comparison property)
by lam_seg boundary_side, sort : gen blah = _n == 1 

by lam_seg, sort : egen blah_sum = total(blah)

tab blah_sum

* drop if blah_sum indicates no observations on the other side
keep if blah_sum == 2  // <-- 1,450,261 drops

	
********************************************************************************
** Relaxed side of the boundary indicators
* Definition of which side of the boundary is relaxed. Treatment is relaxing the 
* regulation where:
*   - height (more height = relaxed)
*   - du (more density = relaxed)
*   - mf (allowing mf = relaxed)
********************************************************************************
noisily display "Generating relaxed side of boundary indicators..."

** <relaxed> easy cases and letting MF allowed dominating other regulations
gen relaxed = 0
 
replace relaxed = 1 if only_he == 1 & he_delta>0
replace relaxed = 1 if only_du == 1 & du_delta>0
replace relaxed = 1 if only_mf == 1 & mf_delta==1

replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta<0   // flip this in relaxed2

* multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta<0

* this is only the clear case
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

* when two of 3 are relaxed, count as relaxed
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0

** <relaxed2> letting height and dupac dominate mf allowed
gen relaxed2 = 0
replace relaxed2 = 1 if only_he == 1 & he_delta>0
replace relaxed2 = 1 if only_du == 1 & du_delta>0
replace relaxed2 = 1 if only_mf == 1 & mf_delta==1

replace relaxed2 = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed2 = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed2 = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed2 = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed2 = 1 if mf_du == 1 & mf_delta == -1 & du_delta>0  

* multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed2 = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed2 = 1 if mf_he == 1 & mf_delta == -1 & he_delta>0

* this is only the clear case
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

* when two of 3 are relaxed, count as relaxed
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0

** <relaxed3> du dominates du_he, mf dominates mf_he mf_du 
* relaxed 3: only 1 reg changes
gen relaxed3 = 0
replace relaxed3 = 1 if only_he == 1 & he_delta > 0
replace relaxed3 = 1 if only_du == 1 & du_delta > 0
replace relaxed3 = 1 if only_mf == 1 & mf_delta == 1

* relaxed 3: mf_du 
replace relaxed3 = 1 if mf_du == 1 & mf_delta == 1 & du_delta > 0
replace relaxed3 = 1 if mf_du == 1 & mf_delta == -1 & du_delta > 0 

* relaxed 3: du_he
replace relaxed3 = 1 if du_he == 1 & he_delta>0 & du_delta > 0
replace relaxed3 = 1 if du_he == 1 & he_delta<0 & du_delta > 0 

* relaxed 3: mf_he 
replace relaxed3 = 1 if mf_he == 1 & mf_delta == 1 & he_delta > 0
replace relaxed3 = 1 if mf_he == 1 & mf_delta == -1 & he_delta > 0

** <relaxed4> height dominates du_he, mf dominates mf_he mf_du   // FLAG new in mc version
* relaxed 4: only 1 reg changes  // FLAG new in mc version
gen relaxed4 = 0
replace relaxed4 = 1 if only_he == 1 & he_delta > 0
replace relaxed4 = 1 if only_du == 1 & du_delta > 0
replace relaxed4 = 1 if only_mf == 1 & mf_delta == 1

* relaxed 4: mf_du   // FLAG new in mc version
replace relaxed4 = 1 if mf_du == 1 & mf_delta == 1 & du_delta > 0
replace relaxed4 = 1 if mf_du == 1 & mf_delta == -1 & du_delta > 0 

* relaxed 4: du_he (here the second line is the only change compared to relaxed 3 above)  // FLAG new in mc version
replace relaxed4 = 1 if du_he == 1 & he_delta>0 & du_delta > 0
replace relaxed4 = 1 if du_he == 1 & he_delta>0 & du_delta < 0 

* relaxed 4: mf_he   // FLAG new in mc version
replace relaxed4 = 1 if mf_he == 1 & mf_delta == 1 & he_delta > 0
replace relaxed4 = 1 if mf_he == 1 & mf_delta == -1 & he_delta > 0

* clear boundaries (du dominates du_he, mf dominates mf_he mf_du)
gen clear_relaxed_strict_lam = 0 
replace clear_relaxed_strict_lam = 1 if (only_du == 1 | only_he == 1 | only_mf == 1) // only one reg changes
replace clear_relaxed_strict_lam = 1 if mf_du == 1 & mf_delta == 1 & du_delta > 0 // mf_du
replace clear_relaxed_strict_lam = 1 if mf_he == 1 & mf_delta == 1 & he_delta > 0 //mf_he
replace clear_relaxed_strict_lam = 1 if du_he == 1 & he_delta > 0 & du_delta > 0 //du_he


********************************************************************************
** Distance from the boundary variables
********************************************************************************
noisily display "Generating distance to boundary variables..."

* HB Note: replaced boundary_dist with boundary_using_dist 
gen dist = boundary_using_dist
gen dist_1 = boundary_using_dist
gen dist_2 = boundary_using_dist^2

* distance based on <relaxed>
gen dist_both = dist if relaxed == 1
replace dist_both = (-1)*dist if relaxed == 0

gen strict = 1 if relaxed == 0
replace strict = 0 if relaxed == 1

gen r_dist_both = strict*dist_both

* distance based on <relaxed2>
gen dist_both2 = dist if relaxed2 == 1
replace dist_both2 = (-1)*dist if relaxed2 == 0

gen r_dist_both2 = strict*dist_both2

* distance group variables for <dist_both>
egen dist_group = cut(dist_both), at(-0.5(0.02)0.5)
egen dist3 = group(dist_group), label

* distance group variables for <dist_both2>
egen dist_group2 = cut(dist_both2), at(-0.5(0.02)0.5)
egen dist3_2 = group(dist_group2), label

* relaxed3 distance variable
gen dist_both3 = dist if relaxed3 == 1
	replace dist_both3 = (-1)*dist if relaxed3 == 0
	
gen strict3 = 1 if relaxed3 == 0
	replace strict3 = 0 if relaxed3 == 1	

gen r_dist_both3 = strict3*dist_both3

egen dist_group3 = cut(dist_both3), at(-0.5(0.02)0.5)
egen dist3_3 = group(dist_group3), label

	
********************************************************************************
** Housing costs: Rents, house prices, last sales price
********************************************************************************
noisily display "Generating rents and house price variables..."

* adjsut costar rents for inflation
replace AvgAskingUnit = AvgAskingUnit/fred_cpi

* adjust assessed value for inflation 
gen def_houseprice = assd_totval/fred_cpi

* calc house rent based on assessed value
gen house_rent = ((def_houseprice/num_units)*0.0629)/12 

* gen log of house rent
gen log_houseprice = log(house_rent)

** Rents
* gen combination rent #1: costar + assessed value house rent for all properties
gen comb_rent1 = AvgAskingUnit 
replace comb_rent1 = house_rent if comb_rent1==.

	* code 99th percentiles as missing
	egen comb1_99 = pctile(comb_rent1) if (res_typex != "Single Family Res"), p(99)
	replace comb_rent1 = . if comb_rent1 > comb1_99

* gen combination rent #2: costar + assessed value house rent for non sinle family properties
gen comb_rent2 = AvgAskingUnit if (res_typex != "Single Family Res")
replace comb_rent2 = house_rent if (comb_rent2 == . & res_typex != "Single Family Res")
	
	* code 99th percentiles as missing
	egen comb2_99 = pctile(comb_rent2) , p(99)
	replace comb_rent2 = . if comb_rent2 > comb2_99
	
* gen the logs of rents
gen log_combrent1 = log(comb_rent1)

gen log_combrent2 = log(comb_rent2) if comb_rent2>0

gen log_mfrent = log_combrent2 // <-- NFC comment: this is the final rent variable we use

** Sales price
* calculate percentiles of sale and assessed price for single family properties only
egen sale_pct = xtile(last_salepr) if res_typex == "Single Family Res", by(year) n(100)
egen ass_pct = xtile(assd_totval), by(year) n(100)

sum sale_pct
sum ass_pct

* drop top and bottom 2% of sales pices
drop if (sale_pct<=2 | sale_pct>=98) & sale_pct !=. & res_typex == "Single Family Res" // NOTE! we do not drop the top/bottom 2% of assessed values

* adjuste last sales price for inflation
gen def_saleprice = last_salepr / fred_cpi

* log sales prices
gen log_saleprice = ln(def_saleprice) if last_salepr > 0

	
********************************************************************************
** End
********************************************************************************
tab year 

noisily display "Done!"
noisily display "** END OF SETUP FILE **"