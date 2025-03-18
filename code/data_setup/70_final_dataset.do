clear all

********************************************************************************
* File name:		"70_final_dataset.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Creates the final dataset before analysis stage. This 
*			files combines the warren property data, and boundary
*			matches, the costar, nhpd, and ch40b data, and the 
*			density measures into one final dataset that is used
*			as the basis for almost all analysis files.
*
*			Note 12/22/2022: the ch40b and nhpd data are not used
*			in the final working paper that was submitted but are
*			used in the fed research reports.
* 				
* Inputs:		$DATAPATH/warren/warren_MAPC_all_annual.dta
*			$DATAPATH/closest_boundar_matches/closest_boundary_matches_with_regs.dta
*			$DATAPATH/costar/costar_warren_xwalk.dta
*			$DATAPATH/nhpd/nhpd_warren_xwalk.dta
*			$DATAPATH/chapter40B/chapter40b_warren_xwalk.dta
*			$DATAPATH/costar/costar_rent_hist.dta
*			$DATAPATH/costar/costar_mf_all.dta
*			$DATAPATH/nhpd/nhpd_mapc.dta
*			$DATAPATH/chapter40B/chapter40b_mapc.dta
*				
* Outputs:		$DATAPATH/final_dataset.dta
*
* Created:		03/08/2021
* Last updated:		12/22/2022
********************************************************************************

********************************************************************************
** load warren data unique MAPC property set
********************************************************************************
use "$DATAPATH/warren/warren_MAPC_all_annual.dta", clear


********************************************************************************
** match zone boundary matches
********************************************************************************
merge m:1 prop_id using "$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta", ///
			keepusing(prop_id boundary_* home_* nn_*)

	* validate merge
	sum _merge
	assert `r(N)' ==  9654526
	assert `r(sum_w)' ==  9654526
	assert `r(mean)' ==  2.400264083394669
	assert `r(Var)' ==  .8397887505281696
	assert `r(sd)' ==  .9163998857093827
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  23173412

	drop if _merge == 2
	drop _merge


********************************************************************************
** merge density measures (1 mile radial distance)
********************************************************************************
merge 1:1 fy prop_id using "$DATAPATH/warren/warren_density_measures.dta", ///
			keepusing(proptype_* density_*)

	* validate merge
	sum _merge
	assert `r(N)' ==  9654526
	assert `r(sum_w)' ==  9654526
	assert `r(mean)' ==  2.343812839698189
	assert `r(Var)' ==  .8817928225933245
	assert `r(sd)' ==  .9390382434136133
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  22628402

	drop if _merge == 2
	drop _merge


********************************************************************************
** temp save on CoStar/NHPD/CH40B crosswalks
********************************************************************************
* CoStar
preserve
	use "$DATAPATH/costar/costar_warren_xwalk.dta", clear

	* drop low similscore matches and no matches
	keep if costar_match_type<=4
	
	assert _N == 7819
	
	* error checks
	unique costar_id
	assert `r(N)' == 7819
	assert `r(unique)' == 6152
	
	unique prop_id
	assert `r(N)' == `r(unique)'

	* temp save and restore
	tempfile costar
	save `costar', replace
restore

* NHPD
preserve
	use "$DATAPATH/nhpd/nhpd_warren_xwalk.dta", clear

	* drop low similscore matches and no matches
	keep if nhpd_match_type<=4
	
	assert _N == 1616

	* error checks
	unique nhpd_id
	assert `r(N)' == 1616
	assert `r(unique)' == 1377
	
	unique prop_id
	assert `r(N)' == `r(unique)'

	* temp save and restore
	tempfile nhpd
	save `nhpd', replace
restore

* CH40B
preserve
	use "$DATAPATH/chapter40B/chapter40b_warren_xwalk.dta", clear
	
	* drop low similscore matches and no matches
	keep if ch40b_match_type<=4
	
	assert _N == 3156
	
	* error checks
	unique unique_id
	assert `r(N)' == 3156
	assert `r(unique)' == 1630
	
	unique prop_id
	assert `r(N)' == `r(unique)'

	* temp save and restore
	tempfile ch40b
	save `ch40b', replace
restore


********************************************************************************
** merge on crosswalks
********************************************************************************
* CoStar
merge m:1 prop_id using `costar', keepusing(*_id *_match_type)

	* validate merge
	sum _merge
	assert `r(N)' ==  9654526
	assert `r(sum_w)' ==  9654526
	assert `r(mean)' ==  1.012953510094644
	assert `r(Var)' ==  .0257392294315426
	assert `r(sd)' ==  .1604345019986119
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  9779586

	drop if _merge == 2		
	drop _merge

* NHPD
merge m:1 prop_id using `nhpd', keepusing(*_id *_match_type)

	* validate merge
	sum _merge
	assert `r(N)' ==  9654526
	assert `r(sum_w)' ==  9654526
	assert `r(mean)' ==  1.002711474390353
	assert `r(Var)' ==  .0054155972482757
	assert `r(sd)' ==  .0735907415934623
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  9680704

	drop if _merge == 2		
	drop _merge

* CH40B
merge m:1 prop_id using `ch40b', keepusing(*_id *_match_type)

	* validate merge
	sum _merge
	assert `r(N)' ==  9654526
	assert `r(sum_w)' ==  9654526
	assert `r(mean)' ==  1.005652064119979
	assert `r(Var)' ==  .0112721835786951
	assert `r(sd)' ==  .1061705400697155
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  9709094

	drop if _merge == 2		
	drop _merge

	
********************************************************************************		
** add CoStar variables and impute res_types for missings	
********************************************************************************
* merge on rent history data
destring costar_id, replace

merge m:1 fy costar_id using "$DATAPATH/costar/costar_rent_hist.dta", keepusing(costar_rent costar_status)

* validate merge
sum _merge
assert `r(N)' ==  9675607
assert `r(sum_w)' ==  9675607
assert `r(mean)' ==  1.005000306440722
assert `r(Var)' ==  .0077968325884799
assert `r(sd)' ==  .0882996749058561
assert `r(min)' ==  1
assert `r(max)' ==  3
assert `r(sum)' ==  9723988

drop if _merge==2
drop _merge

* merge on multifamily data
tostring costar_id, replace

merge m:1 costar_id using "$DATAPATH/costar/costar_mf_all.dta", keepusing(NumberOfUnits)	

* validate merge
sum _merge
assert `r(N)' ==  9655443
assert `r(sum_w)' ==  9655443
assert `r(mean)' ==  1.0130472522079
assert `r(Var)' ==  .0258293039623256
assert `r(sd)' ==  .1607149774051119
assert `r(min)' ==  1
assert `r(max)' ==  3
assert `r(sum)' ==  9781420

drop if _merge==2
drop _merge

* imput res_types based on costar unit size		
destring NumberOfUnits, replace

replace num_units = NumberOfUnits if NumberOfUnits!=. & (num_units==0 | num_units==.)

* validation for res_type replacement
sum costar_match_type if res_type==.
assert `r(N)' ==  3332
assert `r(sum_w)' ==  3332
assert `r(mean)' ==  1.249099639855942
assert `r(Var)' ==  .5191375859860605
assert `r(sd)' ==  .7205120304242397
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  4162

replace res_type = 1 if costar_match_type!=. & (costar_status=="Existing" | costar_status=="") & res_type==. & num_units==1
replace res_type = 2 if costar_match_type!=. & (costar_status=="Existing" | costar_status=="") & res_type==. & num_units==2
replace res_type = 3 if costar_match_type!=. & (costar_status=="Existing" | costar_status=="") & res_type==. & num_units==3
replace res_type = 4 if costar_match_type!=. & (costar_status=="Existing" | costar_status=="") & res_type==. & num_units>=4 & num_units<=8
replace res_type = 5 if costar_match_type!=. & (costar_status=="Existing" | costar_status=="") & res_type==. & num_units>=9 & num_units!=.

* validation for res_type replacement
sum costar_match_type if res_type==.
assert `r(N)' ==  381
assert `r(sum_w)' ==  381
assert `r(mean)' ==  1.076115485564304
assert `r(Var)' ==  .2178753971543031
assert `r(sd)' ==  .4667712471375064
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  410

drop NumberOfUnits


********************************************************************************		
** add NHPD variables and impute res_types		
********************************************************************************		
tostring nhpd_id, replace

merge m:1 nhpd_id using "$DATAPATH/nhpd/nhpd_mapc.dta", keepusing(TOTALUNITS active_*)	

	* validate merge
	sum _merge
	assert `r(N)' ==  9654638
	assert `r(sum_w)' ==  9654638
	assert `r(mean)' ==  1.002723043577605
	assert `r(Var)' ==  .0054270721089094
	assert `r(sd)' ==  .0736686643621927
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  9680928

	drop if _merge==2
	drop _merge

* active year
gen nhpd_status = ""
forvalues yr = 2007(1)2019{
	di "`yr'"
	replace nhpd_status="active" if fy==`yr' & active_in_`yr'==1
}

drop active_*
			
* imput res_types based on costar unit size		
destring TOTALUNITS, replace

replace num_units = TOTALUNITS if TOTALUNITS!=. & (num_units==0 | num_units==.)

* validate res_type replacement
sum nhpd_match_type if res_type==.
assert `r(N)' ==  314
assert `r(sum_w)' ==  314
assert `r(mean)' ==  1.697452229299363
assert `r(Var)' ==  .2883640951547587
assert `r(sd)' ==  .5369954330855699
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  533

replace res_type = 1 if nhpd_match_type!=. & (nhpd_status=="active") & res_type==. & num_units==1
replace res_type = 2 if nhpd_match_type!=. & (nhpd_status=="active") & res_type==. & num_units==2
replace res_type = 3 if nhpd_match_type!=. & (nhpd_status=="active") & res_type==. & num_units==3
replace res_type = 4 if nhpd_match_type!=. & (nhpd_status=="active") & res_type==. & num_units>=4 & num_units<=8
replace res_type = 5 if nhpd_match_type!=. & (nhpd_status=="active") & res_type==. & num_units>=9 & num_units!=.

* validate res_type replacement
sum nhpd_match_type if res_type==.
assert `r(N)' ==  52
assert `r(sum_w)' ==  52
assert `r(mean)' ==  1.980769230769231
assert `r(Var)' ==  .3329562594268476
assert `r(sd)' ==  .5770236212035411
assert `r(min)' ==  1
assert `r(max)' ==  3
assert `r(sum)' ==  103

drop TOTALUNITS


********************************************************************************		
** add ch40b variables and impute res_types		
********************************************************************************		
merge m:1 unique_id using "$DATAPATH/chapter40B/chapter40b_mapc.dta", keepusing()	

	* validate _merge
	sum _merge
	assert `r(N)' ==  9654828
	assert `r(sum_w)' ==  9654828
	assert `r(mean)' ==  1.0056831670124
	assert `r(Var)' ==  .0113027571209748
	assert `r(sd)' ==  .1063144257425811
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  9709698

	drop if _merge==2
	drop _merge

* rename units
rename CompPermit ch40b_comp
rename SHIUnits ch40b_units
		
* active year
gen ch40b_startyr = substr(DateCompPermitIssued,-4,4)
	replace ch40b_startyr="" if ch40b_startyr =="able"
	tab ch40b_startyr
	destring ch40b_startyr, replace


gen ch40b_status = ""
forvalues yr = 2007(1)2019{
	di "`yr'"
	replace ch40b_status="active" if fy==`yr' & (`yr'>=ch40b_startyr | ch40b_startyr==.) & unique_id!=.
}

drop ch40b_startyr
			
* imput res_types based on costar unit size		
destring ch40b_units, replace

replace num_units = ch40b_units if ch40b_units!=. & (num_units==0 | num_units==.) & ch40b_status=="active"

* validate res type replacement
sum ch40b_match_type if res_type==.
assert `r(N)' ==  864
assert `r(sum_w)' ==  864
assert `r(mean)' ==  1.459490740740741
assert `r(Var)' ==  .6426212930775503
assert `r(sd)' ==  .8016366340665516
assert `r(min)' ==  1
assert `r(max)' ==  4
assert `r(sum)' ==  1261

replace res_type = 1 if ch40b_match_type!=. & (ch40b_status=="active") & res_type==. & num_units==1
replace res_type = 2 if ch40b_match_type!=. & (ch40b_status=="active") & res_type==. & num_units==2
replace res_type = 3 if ch40b_match_type!=. & (ch40b_status=="active") & res_type==. & num_units==3
replace res_type = 4 if ch40b_match_type!=. & (ch40b_status=="active") & res_type==. & num_units>=4 & num_units<=8
replace res_type = 5 if ch40b_match_type!=. & (ch40b_status=="active") & res_type==. & num_units>=9 & num_units!=.

* validate res type replacement
sum ch40b_match_type if res_type==.
assert `r(N)' ==  89
assert `r(sum_w)' ==  89
assert `r(mean)' ==  1.325842696629213
assert `r(Var)' ==  .4948927477017365
assert `r(sd)' ==  .7034861389549452
assert `r(min)' ==  1
assert `r(max)' ==  3
assert `r(sum)' ==  118


********************************************************************************		
** final error checks
********************************************************************************		
assert _N == 9654526

unique prop_id
assert `r(N)' ==  9654526
assert `r(unique)' ==  821237

unique fy prop_id
assert `r(unique)' == `r(N)'

sum prop_id
assert `r(N)' ==  9654526
assert `r(sum_w)' ==  9654526
assert `r(mean)' ==  1273062.482862338
assert `r(Var)' ==  1544427108478.022
assert `r(sd)' ==  1242749.81733172
assert `r(min)' ==  264
assert `r(max)' ==  5068039
assert `r(sum)' ==  12290814840419

sum fy
assert `r(N)' ==  9654526
assert `r(sum_w)' ==  9654526
assert `r(mean)' ==  2013.079435075321
assert `r(Var)' ==  13.6630678987579
assert `r(sd)' ==  3.696358735128113
assert `r(min)' ==  2007
assert `r(max)' ==  2019
assert `r(sum)' ==  19435327746

sum res_type
assert `r(N)' ==  9433055
assert `r(sum_w)' ==  9433055
assert `r(mean)' ==  1.737102031102331
assert `r(Var)' ==  2.505197381154993
assert `r(sd)' ==  1.582781532983941
assert `r(min)' ==  1
assert `r(max)' ==  11
assert `r(sum)' ==  16386179

sum boundary_using_id
assert `r(N)' ==  6759443
assert `r(sum_w)' ==  6759443
assert `r(mean)' ==  12895.4217665568
assert `r(Var)' ==  109151948.3403639
assert `r(sd)' ==  10447.58098032094
assert `r(min)' ==  4
assert `r(max)' ==  33615
assert `r(sum)' ==  87165868392


********************************************************************************
** save and end
********************************************************************************
save "$DATAPATH/final_dataset.dta", replace

clear all
