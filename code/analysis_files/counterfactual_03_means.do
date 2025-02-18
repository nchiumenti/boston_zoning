clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postrestat_means" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************
* File name:		"postrestat_means.do"
*
* Project title:	Boston Zoning Project
*
* Description:		
* 				
* Inputs:		
*				
* Outputs:			postQJE_means_lpm.dta
*               	postQJE_means_property_lvl.dta
*					postQJE_means_town_lvl_tomerge.dta
*					postQJE_means_town_train_stations.dta
*
* Created:			11/10/2021
* Updated:			02/17/2025
********************************************************************************

* create a save directory if none exists
global EXPORTPATH "$DATAPATH/postQJE_data_exports/`name'_`date_stamp'"

capture confirm file "$EXPORTPATH"

if _rc!=0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

cd $EXPORTPATH


********************************************************************************
** load the mt lines data
********************************************************************************
use "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load final dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
// run "$DOPATH/postQJE_within_town_setup.do"

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear  // <-- use mikes post setup working file


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
	
	* check merge for errors
	sum _merge
	assert `r(N)' ==  3400297
	assert `r(sum_w)' ==  3400297
	assert `r(mean)' ==  2.940873106084557
	assert `r(Var)' ==  .0556309206919615
	assert `r(sd)' ==  .235862079809285
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9999842
	
	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties


********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year


********************************************************************************
** define mean variables
********************************************************************************
gen side = ""
replace side = "relaxed" if relaxed == 1
replace side = "strict" if relaxed == 0

* gen boundary type var
gen boundary_type = ""
	replace boundary_type = "only_mf" if only_mf == 1
	replace boundary_type = "only_he" if only_he == 1
	replace boundary_type = "only_du" if only_du == 1
	replace boundary_type = "mf_he" if mf_he == 1
	replace boundary_type = "mf_du" if mf_du == 1
	replace boundary_type = "du_he" if du_he == 1
	replace boundary_type = "mf_he_du" if mf_he_du == 1

* units prices rents variables
gen units = num_units1 if year_built>=1918 & year==2018 & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"
gen rent = comb_rent2 if (year>=2010 & year<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex!="Condominiums"
gen price = def_saleprice if (last_saleyr>=2010 & last_saleyr<=2018) & (dist_both<=0.21 & dist_both>=-0.2) & res_typex=="Single Family Res"

* fam 2-3 4+ and single fam variables
/* note, these are the same definitions used in within_town_setup */
gen fam23_1918 = 0 if res_typex == "Single Family Res" & (year_built >= 1918 & year == 2018)
	replace fam23_1918 = 1 if (res_typex == "Two Family Res" | res_typex == "Three Family Res") & (year_built >= 1918 & year == 2018)

gen fam23_1956 = 0 if res_typex == "Single Family Res" & (year_built >= 1956 & year == 2018)
	replace fam23_1956 = 1 if (res_typex == "Two Family Res" | res_typex == "Three Family Res") & (year_built >= 1956 & year == 2018)

gen fam4plus_1918 = 0 if res_typex == "Single Family Res" & (year_built >= 1918 & year == 2018)
	replace fam4plus_1918 = 1 if (res_typex == "4-8 Unit Res" | res_typex == "9+ Unit Res") & (year_built >= 1918 & year == 2018)

gen fam4plus_1956 = 0 if res_typex == "Single Family Res" & (year_built >= 1956 & year == 2018)
	replace fam4plus_1956 = 1 if (res_typex == "4-8 Unit Res" | res_typex == "9+ Unit Res") & (year_built >= 1956 & year == 2018)
	
gen singlefam = (res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018))
	replace singlefam = . if (last_saleyr < 2010 | last_saleyr > 2018)

* error check
sum units
	// assert `r(N)' ==  53926
	// assert `r(sum_w)' ==  53926
	// assert `r(mean)' ==  1.466917627860401
	// assert `r(Var)' ==  41.80136265272328
	// assert `r(sd)' ==  6.465397331388325
	// assert `r(min)' ==  1
	// assert `r(max)' ==  601
	// assert `r(sum)' ==  79105

sum rent
	// assert `r(N)' ==  149042
	// assert `r(sum_w)' ==  149042
	// assert `r(mean)' ==  1190.58200293449
	// assert `r(Var)' ==  442463.4875743266
	// assert `r(sd)' ==  665.179289796613
	// assert `r(min)' ==  0
	// assert `r(max)' ==  4995.37758772267
	// assert `r(sum)' ==  177446722.8813623

sum price
	// assert `r(N)' ==  88425
	// assert `r(sum_w)' ==  88425
	// assert `r(mean)' ==  586028.3923129035
	// assert `r(Var)' ==  113294638707.3995
	// assert `r(sd)' ==  336592.689622635
	// assert `r(min)' ==  2731.73488174657
	// assert `r(max)' ==  2099133.386838418
	// assert `r(sum)' ==  51819560590.26849
	
sum fam23_1918 
	// assert `r(N)' ==  72535
	// assert `r(sum_w)' ==  72535
	// assert `r(mean)' ==  .0770800303301854
	// assert `r(Var)' ==  .0711396800179769
	// assert `r(sd)' ==  .2667202279880115
	// assert `r(min)' ==  0
	// assert `r(max)' ==  1
	// assert `r(sum)' ==  5591

sum fam23_1956 
	// assert `r(N)' ==  44671
	// assert `r(sum_w)' ==  44671
	// assert `r(mean)' ==  .0289449531015648
	// assert `r(Var)' ==  .0281077720089473
	// assert `r(sd)' ==  .1676537264988384
	// assert `r(min)' ==  0
	// assert `r(max)' ==  1
	// assert `r(sum)' ==  1293

sum fam4plus_1918 
	// assert `r(N)' ==  67678
	// assert `r(sum_w)' ==  67678
	// assert `r(mean)' ==  .0108454741570377
	// assert `r(Var)' ==  .0107280083627929
	// assert `r(sd)' ==  .1035760993800833
	// assert `r(min)' ==  0
	// assert `r(max)' ==  1
	// assert `r(sum)' ==  734

sum fam4plus_1956 
	// assert `r(N)' ==  43712
	// assert `r(sum_w)' ==  43712
	// assert `r(mean)' ==  .0076409224011713
	// assert `r(Var)' ==  .0075827121758369
	// assert `r(sd)' ==  .0870787699490349
	// assert `r(min)' ==  0
	// assert `r(max)' ==  1
	// assert `r(sum)' ==  334

sum singlefam
	// assert `r(N)' ==  171104
	// assert `r(sum_w)' ==  171104
	// assert `r(mean)' ==  .7039110716289508
	// assert `r(Var)' ==  .2084214929654413
	// assert `r(sd)' ==  .4565320284114153
	// assert `r(min)' ==  0
	// assert `r(max)' ==  1
	// assert `r(sum)' ==  120442

sum height
	// assert `r(N)' ==  962015
	// assert `r(sum_w)' ==  962015
	// assert `r(mean)' ==  3.449134576903687
	// assert `r(Var)' ==  .6153669665846871
	// assert `r(sd)' ==  .7844532915251788
	// assert `r(min)' ==  0
	// assert `r(max)' ==  35.6
	// assert `r(sum)' ==  3318119.2

sum dupac
	// assert `r(N)' ==  962015
	// assert `r(sum_w)' ==  962015
	// assert `r(mean)' ==  9.719478386511645
	// assert `r(Var)' ==  217.705447898112
	// assert `r(sd)' ==  14.754844895766
	// assert `r(min)' ==  0
	// assert `r(max)' ==  349
	// assert `r(sum)' ==  9350284

sum mf_allow
	// assert `r(N)' ==  962015
	// assert `r(sum_w)' ==  962015
	// assert `r(mean)' ==  .5402472934413705
	// assert `r(Var)' ==  .2483804135583165
	// assert `r(sd)' ==  .4983777819669698
	// assert `r(min)' ==  0
	// assert `r(max)' ==  1
	// assert `r(sum)' ==  519726

	
********************************************************************************
** calculate means for single, 2-3 unit, 4+ unit for >=1918 and >=1956 at
** property level
********************************************************************************
preserve

* collapse to calc means
collapse (mean) mean_fam23_1918 = fam23_1918 ///
		mean_fam23_1956 = fam23_1956 ///
		mean_fam4plus_1918 = fam4plus_1918 ///
		mean_fam4plus_1956 = fam4plus_1956 ///
		mean_singlefam = singlefam ///
	(sum) n_fam23_1918 = fam23_1918 ///
		n_fam23_1956 = fam23_1956 ///
		n_fam4plus_1918 = fam4plus_1918 ///
		n_fam4plus_1956 = fam4plus_1956 ///
		n_singlefam = singlefam ///
		if (dist_both<=0.21 & dist_both>=-0.2) ///
		, by(boundary_type side)

drop if boundary_type == ""

* label export variables
lab var side "relaxed/strict boundary side"

lab var mean_fam23_1918 "mean share of props 2-3 units >=1918 in 2018"
lab var mean_fam23_1956 "mean share of props 2-3 units >=1956 in 2018"
lab var mean_fam4plus_1918 "mean share of props 4+ units >=1918 in 2018"
lab var mean_fam4plus_1956 "mean share of props 4+ units >=1956 in 2018"
lab var mean_singlefam "mean share of props single fam last sale year 2010 to 2018"

lab var n_fam23_1918 "count of props 2-3 units >=1918 in 2018"
lab var n_fam23_1956 "count of props 2-3 units >=1956 in 2018"
lab var n_fam4plus_1918 "count of props 4+ units >=1918 in 2018"
lab var n_fam4plus_1956 "count of props 4+ units >=1956 in 2018"
lab var n_singlefam "count of props single fam last sale year 2010 to 2018"
	
* save as .dta file
save "postQJE_means_lpm.dta", replace

* display output in log file
tabdisp boundary_type, cell(mean_*)

restore
	
	
********************************************************************************
** calc property level means for units, prices, rents
********************************************************************************
preserve

* collapse to calc means
collapse (mean) mean_units=units mean_rent=rent mean_price=price ///
	(count) n_units=units n_rent=rent n_price=price ///
	, by(boundary_type side)

* export data as a .dta file
drop if boundary_type == ""

* label export variables
lab var boundary_type "regulation boundary type"
lab var mean_units "avg. number of units"
lab var mean_rent "avg. rent"
lab var mean_price "avg sales price"
lab var n_units "count of properties used in mean_units"
lab var n_rent "count of properties used in mean_rent"
lab var n_price "count of properties used in mean_price"

* save as .dta file
save "postQJE_means_property_lvl.dta", replace

* display output in log file
di "Property level MEANS for units, rent, prices"
tabdisp boundary_type side, cell(mean_units mean_rent mean_price)

di "Property level COUNTS for units, rent, prices"
tabdisp boundary_type side, cell(n_units n_rent n_price)

restore


********************************************************************************
** calc boundary level means for height, dupac, mf allowed
********************************************************************************
preserve

unique lam_seg boundary_side boundary_type height dupac mf_allow

* error check uniuqe vals
assert `r(N)' ==  962015
assert `r(sum)' ==  3431
assert `r(unique)' ==  3431

bysort lam_seg boundary_side boundary_type: keep if _n==1

* error check
assert _N == 3431

* collapse to calc means
collapse (mean) mean_height=height mean_dupac=dupac mean_mfallow=mf_allow ///
	(count) n_height=height n_dupac=dupac n_mfallow=mf_allow ///
	, by(boundary_type side)

drop if boundary_type == ""

* error check
assert _N == 14

* label export variables
lab var boundary_type "regulation boundary type"
lab var mean_height "avg. height regulation"
lab var mean_dupac "avg dupac regulation"
lab var mean_mfallow "avg share allowing mf"
lab var n_height "count of boundaries used in mean_height"
lab var n_dupac "count of boundaries used in mean_dupac"
lab var n_mfallow "count of boundaries used in mean_mfallow"

save "postQJE_means_boundary_lvl.dta", replace

* display output in log
di "Boundary level MEANS for height, dupac, mf_allow"
tabdisp boundary_type side, cell(mean_height mean_dupac mean_mfallow)

di "Boundary level COUNTS for height, dupac, mf_allow"
tabdisp boundary_type side, cell(n_height n_dupac n_mfallow)
	
restore

********************************************************************************
** gen and export town level means for units, rents, prices by relaxed/strict
********************************************************************************
preserve

unique cousub_name boundary_type side
	assert `r(N)' ==  962015
	assert `r(sum)' ==  400
	assert `r(unique)' ==  400
	
collapse (mean) mean_units=units mean_rent=rent mean_price=price ///
	(mean) mean_fam23_1918 = fam23_1918 ///
		mean_fam23_1956 = fam23_1956 ///
		mean_fam4plus_1918 = fam4plus_1918 ///
		mean_fam4plus_1956 = fam4plus_1956 ///
		mean_singlefam = singlefam ///
	(count) n_units=units n_rent=rent n_price=price ///
	(count) n_fam23_1918 = fam23_1918 ///
		n_fam23_1956 = fam23_1956 ///
		n_fam4plus_1918 = fam4plus_1918 ///
		n_fam4plus_1956 = fam4plus_1956 ///
		n_singlefam = singlefam ///
	, by(cousub_name boundary_type side)

drop if boundary_type == ""
	
* error check
assert _N == 395
	
* export data as a .dta file

lab var cousub_name "municipality name"
lab var boundary_type "regulation boundary type"
lab var side "strict vs. relaxed"
lab var mean_units "avg. number of units"
lab var mean_rent "avg. rent"
lab var mean_price "avg sales price"
lab var n_units "count of properties used in mean_units"
lab var n_rent "count of properties used in mean_rent"
lab var n_price "count of properties used in mean_price"

save "postQJE_means_town_lvl.dta", replace

restore


********************************************************************************
** create one final means file with town and train station means
********************************************************************************
/* NOTE: this will require some work with Mike to figure out directory paths */

* begin by loading the town means file
use "postQJE_means_town_lvl.dta", clear 

* rename variables so the merge works correctly
rename (mean_units mean_rent mean_price n_units n_rent n_price) (mean_units_town mean_rent_town mean_price_town n_units_town n_rent_town n_price_town)

* save
save "postQJE_means_town_lvl_tomerge.dta", replace

* load the train station means file
use "<PATH>/postREStat_train_station_means.dta", clear

* merge on down means
merge m:1 cousub_name boundary_type side using "postQJE_means_town_lvl_tomerge.dta"

drop mean_units mean_rent mean_saleprice _merge

rename (mean_units_town mean_rent_town mean_price_town)(mean_units mean_rent mean_saleprice)

// save "$dir\postQJE_means_town_lvl_tomerge.dta", replace  // <-- old save file name pre 2/17/2025
save "postQJE_means_town_train_stations.dta", replace  // new save file name 2/17/2025


********************************************************************************
** end
********************************************************************************
log close
clear all
