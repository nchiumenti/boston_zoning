
** FORMERLY CALLED postQJE_within_town_setup_no_roads.do **

********************************************************************************
* File name:		analysis_noroads_setup.do
*
* Project title:	Boston Zoning Paper
*
* Description:	    this setup file is specific for no roads analysis, of which
*                   main_noroads.do is the only real analysis file run currently
* 				
* Inputs:	        
*
* Outputs:		
*
* Created:			09/21/2021
* Updated:			03/20/2025
********************************************************************************


noisily display "Running postQJE_within_town_setup_no_roads.do..."
noisily display "If called with <run> this file will run quietly and not display in log."
noisily display "Call with <do> to show the output in log file."

confirm file "/shared/boston_zoning/working_paper/data/closest_boundary_matches/closest_boundary_matches_noroads.csv"
confirm file "/shared/boston_zoning/working_paper/data/final_dataset_10-28-2021.dta"
confirm file "/shared/boston_zoning/working_paper/data/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta"



********************************************************************************
** load the no roads mt lines boundary matches
********************************************************************************
import delimited "/shared/boston_zoning/working_paper/data/closest_boundary_matches/closest_boundary_matches_noroads.csv", clear stringcols(_all)

destring prop_id unique_id dist_m home_* nn_* left_dist_m right_dist_m straight_line, replace

gen boundary_using_id = unique_id

gen boundary_dist = dist_m * 0.000621  // distance to boundary in miles

tempfile no_roads
save `no_roads', replace


********************************************************************************
** Load the main dataset
********************************************************************************
use "/shared/boston_zoning/working_paper/data/final_dataset_10-28-2021.dta", clear


********************************************************************************
/* added on 10.17.2022: code restructures the regualtion data to be no minor 
road matches for use in rd_main_no_roads */
********************************************************************************
drop boundary_* home_* nn_*

merge m:1 prop_id using `no_roads', keepusing(boundary_* home_* nn_* left_dist_m right_dist_m straight_line)

	* check merge
	sum _merge
	//noisily assert `r(N)' ==  9654526
	//noisily assert `r(sum_w)' ==  9654526
	//noisily assert `r(mean)' ==  2.414000645914673
	//noisily assert `r(Var)' ==  .8286035510076334
	//noisily assert `r(sd)' ==  .9102766343302642
	//noisily assert `r(min)' ==  1
	//noisily assert `r(max)' ==  3
	//noisily assert `r(sum)' ==  23306032
	
	* drop non-matches from using
	drop if _merge == 2
	drop _merge


********************************************************************************
** Trim the input dataset
********************************************************************************
noisily display "Trimming input dataset..."

* drop non residential property types
drop if res_type == .

* drop properties outside of study period
keep if fy >= 2010 & fy <= 2018

* drop if properties are not assigned to any boundary
drop if boundary_using_id == .

* gen year variable
gen year = fy

* summarize variables to ensure consistency across runs
sum fy

* error checks
//noisily assert `r(N)' == 4714809
//noisily assert `r(mean)' == 2014.035230907551
//noisily assert `r(min)' ==  2010
//noisily assert `r(max)' ==  2018


********************************************************************************
** Merge on closest stuff dataset
********************************************************************************
noisily display "Merging on closest stuff dataset..."

* merge on file with distance to closest school/river/road
local data_file_path = "/shared/boston_zoning/working_paper/data/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta"

merge m:1 prop_id using `data_file_path', keepusing(closest_*)
	
	* checks for errors in merge
	sum _merge
	//noisily assert `r(N)' ==  4981936
	//noisily assert `r(sum_w)' ==  4981936
	//noisily assert `r(mean)' ==  2.946380884860825
	//noisily assert `r(Var)' ==  .0507441158164885
	//noisily assert `r(sd)' ==  .2252645462927722
	//noisily assert `r(min)' ==  2
	//noisily assert `r(max)' ==  3
	//noisily assert `r(sum)' ==  14678681

	* drop non-matches from using
	drop if _merge == 2
	drop _merge

	
********************************************************************************
** Merge on CPI dataset
********************************************************************************
noisily display "Merging on CPI dataset..."

* merge con CPI data to adjust rents/prices into 2019 dollars
local data_file_path = "/shared/boston_zoning/working_paper/data/fred_cpi/CPI_2019.dta"

merge m:1 year using `data_file_path'
	
	* checks for errors in merge
	sum _merge
	//noisily assert `r(N)' ==  4714826
	//noisily assert `r(sum_w)' ==  4714826
	//noisily assert `r(mean)' ==  2.999996394352623
	//noisily assert `r(Var)' ==  3.60563514107e-06
	//noisily assert `r(sd)' ==  .0018988510054951
	//noisily assert `r(min)' ==  2
	//noisily assert `r(max)' ==  3
	//noisily assert `r(sum)' ==  14144461

	* tab _merge and drop non-matches from using
	drop if _merge == 2
	drop _merge

		
********************************************************************************
** Merge on Co-Star variables

/* Two merges occur, first is the overall property characteristics, the second 
is the rent history file. */
********************************************************************************
noisily display "Merging on CoStar datasets..."

drop costar_rent costar_status // <-- drop these variables so they update properly in the merge
destring costar_id, replace

* merge on multifamily property characteristics
local data_file_path = "/shared/boston_zoning/working_paper/data/costar/costar_mf_destring.dta"

merge m:1 costar_id using `data_file_path'

	* checks for errors in merge
	sum _merge
	//noisily assert `r(N)' ==  4717038
	//noisily assert `r(sum_w)' ==  4717038
	//noisily assert `r(mean)' ==  1.018014058822507
	//noisily assert `r(Var)' ==  .0352310764956211
	//noisily assert `r(sd)' ==  .1876994312607822
	//noisily assert `r(min)' ==  1
	//noisily assert `r(max)' ==  3
	//noisily assert `r(sum)' ==  4802011

	* tab _merge and drop non-matches from using
	drop if _merge == 2 // NFC comment: not all CoStar properties match
	drop _merge
	
* merge on historic rents and replace when not missing
local data_file_path = "/shared/boston_zoning/working_paper/data/costar/costar_rent_hist.dta"

merge m:1 fy costar_id using `data_file_path', keepusing(costar_rent)

	* checks for errors in merge
	sum _merge
	//noisily assert `r(N)' ==  4740070
	//noisily assert `r(sum_w)' ==  4740070
	//noisily assert `r(mean)' ==  1.009203450581953
	//noisily assert `r(Var)' ==  .0129929542098147
	//noisily assert `r(sd)' ==  .1139866404883253
	//noisily assert `r(min)' ==  1
	//noisily assert `r(max)' ==  3
	//noisily assert `r(sum)' ==  4783695

	* tab _merge and drop non-matches from using
	drop if _merge == 2 // NFC comment: not all CoStar properties match
	drop _merge

* clean up some costar variables
destring costar_rent, replace

replace AvgAskingUnit = costar_rent if costar_rent!=. // <-- use the historic rent in place of asking rent if present
	
	
********************************************************************************
** merge on sales data
********************************************************************************
noisily display "Merging on warren group sales price data..."

* merge on sales data
local data_file_path = "/shared/boston_zoning/working_paper/data/warren/warren_sales_data.dta"

merge 1:1 prop_id fy using `data_file_path', keep(1 3)

	* checks for errors in merge
	sum _merge
	//noisily assert `r(N)' ==  4714809
	//noisily assert `r(sum_w)' ==  4714809
	//noisily assert `r(mean)' ==  1.366873822460252
	//noisily assert `r(Var)' ==  .5991513703925171
	//noisily assert `r(sd)' ==  .7740486873527511
	//noisily assert `r(min)' ==  1
	//noisily assert `r(max)' ==  3
	//noisily assert `r(sum)' ==  6444549

	* tab _merge and drop non-matches from using
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

* error checking
sum fam23_1
//noisily assert `r(N)' ==  4133256
//noisily assert `r(sum_w)' ==  4133256
//noisily assert `r(mean)' ==  .1856212148485359
//noisily assert `r(Var)' ==  .1511660160197971
//noisily assert `r(sd)' ==  .3888007407654943
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  767220

sum fam4plus_1
//noisily assert `r(N)' ==  3449859
//noisily assert `r(sum_w)' ==  3449859
//noisily assert `r(mean)' ==  .0242975147679949
//noisily assert `r(Var)' ==  .0237071524160132
//noisily assert `r(sd)' ==  .1539712713983137
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  83823

sum MU_2
//noisily assert `r(N)' ==  4714809
//noisily assert `r(sum_w)' ==  4714809
//noisily assert `r(mean)' ==  .010572220422927
//noisily assert `r(Var)' ==  .0104604507968933
//noisily assert `r(sd)' ==  .1022763452460698
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  49846

sum num_units
//noisily assert `r(N)' ==  4714809
//noisily assert `r(sum_w)' ==  4714809
//noisily assert `r(mean)' ==  1.769662567455013
//noisily assert `r(Var)' ==  50.31480459846264
//noisily assert `r(sd)' ==  7.09329293054098
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1016
//noisily assert `r(sum)' ==  8343621

sum num_units1
//noisily assert `r(N)' ==  4701588
//noisily assert `r(sum_w)' ==  4701588
//noisily assert `r(mean)' ==  1.774638909236624
//noisily assert `r(Var)' ==  50.44746008730164
//noisily assert `r(sd)' ==  7.102637544412754
//noisily assert `r(min)' ==  1
//noisily assert `r(max)' ==  1016
//noisily assert `r(sum)' ==  8343621

sum num_floors1
//noisily assert `r(N)' ==  4618316
//noisily assert `r(sum_w)' ==  4618316
//noisily assert `r(mean)' ==  1.905845334100135
//noisily assert `r(Var)' ==  .437199749627032
//noisily assert `r(sd)' ==  .6612108208635367
//noisily assert `r(min)' ==  1
//noisily assert `r(max)' ==  59
//noisily assert `r(sum)' ==  8801796

sum lot_acres
//noisily assert `r(N)' ==  4714809
//noisily assert `r(sum_w)' ==  4714809
//noisily assert `r(mean)' ==  .5005930024517647
//noisily assert `r(Var)' ==  306.8205112547363
//noisily assert `r(sd)' ==  17.51629273718432
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  22956.84111570248
//noisily assert `r(sum)' ==  2360200.393296602

sum theta_sf	
//noisily assert `r(N)' ==  4465594
//noisily assert `r(sum_w)' ==  4465594
//noisily assert `r(mean)' ==  .7015487092596208
//noisily assert `r(Var)' ==  .109787601015278
//noisily assert `r(sd)' ==  .3313421207985457
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  3132831.706777507

sum theta_gd
//noisily assert `r(N)' ==  4465594
//noisily assert `r(sum_w)' ==  4465594
//noisily assert `r(mean)' ==  .2005026752572403
//noisily assert `r(Var)' ==  .0616976675564678
//noisily assert `r(sd)' ==  .248390151891068
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  895363.5436126809

sum theta_hd
//noisily assert `r(N)' ==  4465594
//noisily assert `r(sum_w)' ==  4465594
//noisily assert `r(mean)' ==  .038534911073208
//noisily assert `r(Var)' ==  .0101143318355342
//noisily assert `r(sd)' ==  .1005700344811227
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  172081.2676790511


	
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

* error checking
sum height
//noisily assert `r(N)' ==  4714809
//noisily assert `r(sum_w)' ==  4714809
//noisily assert `r(mean)' ==  3.465046473780804
//noisily assert `r(Var)' ==  .8851354555353893
//noisily assert `r(sd)' ==  .9408163771615529
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  35.6
//noisily assert `r(sum)' ==  16337032.3

sum dupac
//noisily assert `r(N)' ==  4714809
//noisily assert `r(sum_w)' ==  4714809
//noisily assert `r(mean)' ==  11.39916823778015
//noisily assert `r(Var)' ==  359.4843910034431
//noisily assert `r(sd)' ==  18.96007360226861
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  349
//noisily assert `r(sum)' ==  53744901

sum mf_allowed
//noisily assert `r(N)' ==  4714809
//noisily assert `r(sum_w)' ==  4714809
//noisily assert `r(mean)' ==  .5355618859639913
//noisily assert `r(Var)' ==  .2487354050228837
//noisily assert `r(sd)' ==  .4987338017649132
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  2525072


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
keep if blah_sum == 2 // <-- 1,450,261 drops

* error checking
sum lam_seg
//noisily assert `r(N)' ==  3269142
//noisily assert `r(sum_w)' ==  3269142
//noisily assert `r(mean)' ==  11725.22855874722
//noisily assert `r(Var)' ==  85492223.85502
//noisily assert `r(sd)' ==  9246.200509129141
//noisily assert `r(min)' ==  14
//noisily assert `r(max)' ==  29566
//noisily assert `r(sum)' ==  38331437141

	
********************************************************************************
** Relaxed side of the boundary indicators

/* Definition of which side of the boundary is relaxed:
	treatment is: relaxing the regulation
	height (more height = relaxed)
	du (more density = relaxed)
	mf (allowing mf = relaxed) */
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

* error checking
sum relaxed
//noisily assert `r(N)' ==  3269142
//noisily assert `r(sum_w)' ==  3269142
//noisily assert `r(mean)' ==  .4786937979445371
//noisily assert `r(Var)' ==  .2495461220877995
//noisily assert `r(sd)' ==  .4995459158954255
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  1564918

sum relaxed2
//noisily assert `r(N)' ==  3269142
//noisily assert `r(sum_w)' ==  3269142
//noisily assert `r(mean)' ==  .4873226675378433
//noisily assert `r(Var)' ==  .2498393616651709
//noisily assert `r(sd)' ==  .4998393358522025
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  1
//noisily assert `r(sum)' ==  1593127


********************************************************************************
** Distance from the boundary variables
********************************************************************************
noisily display "Generating distance to boundary variables..."

gen dist = boundary_dist
gen dist_1 = boundary_dist
gen dist_2 = boundary_dist^2

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

* error checking
sum dist
//noisily assert `r(N)' ==  3269142
//noisily assert `r(sum_w)' ==  3269142
//noisily assert `r(mean)' ==  .2175526448302992
//noisily assert `r(Var)' ==  .0995109909533737
//noisily assert `r(sd)' ==  .3154536272629841
//noisily assert `r(min)' ==  1.00012085414e-06
//noisily assert `r(max)' ==  3.950993674838329
//noisily assert `r(sum)' ==  711210.4884258138

sum dist_both
//noisily assert `r(N)' ==  3269142
//noisily assert `r(sum_w)' ==  3269142
//noisily assert `r(mean)' ==  -.0679115258830882
//noisily assert `r(Var)' ==  .1422281819450524
//noisily assert `r(sd)' ==  .3771315181008508
//noisily assert `r(min)' ==  -3.950993674838329
//noisily assert `r(max)' ==  2.269501636211704
//noisily assert `r(sum)' ==  -222012.4215484908

sum r_dist_both
//noisily assert `r(N)' ==  3269142
//noisily assert `r(sum_w)' ==  3269142
//noisily assert `r(mean)' ==  -.1427320853566937
//noisily assert `r(Var)' ==  .0999121141865813
//noisily assert `r(sd)' ==  .3160887757997447
//noisily assert `r(min)' ==  -3.950993674838329
//noisily assert `r(max)' ==  0
//noisily assert `r(sum)' ==  -466611.4549871523


********************************************************************************
** Housing costs: Rents, house prices, last sales price
********************************************************************************
noisily display "Generating rents and house price variables..."

* adjsut costar rents for inflation
replace AvgAskingUnit = AvgAskingUnit/fred_cpi

* adjust assessed value for inflation 
gen def_houseprice = assd_totval/fred_cpi // <-- NFC comment: this used to be the orginal house price variable

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
gen def_saleprice = last_salepr / fred_cpi // added 7/22/22, prior to this did not control for inflation

* log sales prices
gen log_saleprice = ln(def_saleprice) if last_salepr > 0

* error checking
sum def_houseprice
//noisily assert `r(N)' ==  3248645
//noisily assert `r(sum_w)' ==  3248645
//noisily assert `r(mean)' ==  571635.1845781986
//noisily assert `r(Var)' ==  1671101883787.988
//noisily assert `r(sd)' ==  1292711.059668009
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  333202639.2473357
//noisily assert `r(sum)' ==  1857039784204.042

sum log_combrent1
//noisily assert `r(N)' ==  3216731
//noisily assert `r(sum_w)' ==  3216731
//noisily assert `r(mean)' ==  7.551179714631945
//noisily assert `r(Var)' ==  .5038518413625331
//noisily assert `r(sd)' ==  .7098252188831651
//noisily assert `r(min)' ==  -3.695814127072944
//noisily assert `r(max)' ==  13.30508919358082
//noisily assert `r(sum)' ==  24290113.87462773


sum log_combrent2
//noisily assert `r(N)' ==  945322
//noisily assert `r(sum_w)' ==  945322
//noisily assert `r(mean)' ==  6.916669881042731
//noisily assert `r(Var)' ==  .5133347604097406
//noisily assert `r(sd)' ==  .7164738379101784
//noisily assert `r(min)' ==  -3.695814127072944
//noisily assert `r(max)' ==  8.526661255022331
//noisily assert `r(sum)' ==  6538480.205287077


sum def_saleprice
//noisily assert `r(N)' ==  577925
//noisily assert `r(sum_w)' ==  577925
//noisily assert `r(mean)' ==  679146.6827877515
//noisily assert `r(Var)' ==  4800447876188.894
//noisily assert `r(sd)' ==  2190992.440924636
//noisily assert `r(min)' ==  0
//noisily assert `r(max)' ==  361534066.403122
//noisily assert `r(sum)' ==  392495846650.1113


sum log_saleprice
//noisily assert `r(N)' ==  577761
//noisily assert `r(sum_w)' ==  577761
//noisily assert `r(mean)' ==  13.1540689361665
//noisily assert `r(Var)' ==  .4214520417710558
//noisily assert `r(sd)' ==  .6491933777935938
//noisily assert `r(min)' ==  .035919747181273
//noisily assert `r(max)' ==  19.70586683136967
//noisily assert `r(sum)' ==  7599908.022628491

	
********************************************************************************
** End
********************************************************************************

noisily display "Done!"
noisily display "** END OF SETUP FILE **"