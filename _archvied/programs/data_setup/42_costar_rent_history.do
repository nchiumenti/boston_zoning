clear all

** S: DRIVE VERSION **

********************************************************************************
* File name:		42_costar_rent_history.do
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		
*
* Inputs:		
*
* Outputs:		
*
* Created:		10/23/2021
* Last updated:		11/07/2022
********************************************************************************


********************************************************************************
** load crosswalk data
********************************************************************************
use "$DATAPATH/costar/costar_warren_xwalk.dta", clear

sum costar_match_type
assert `r(N)' ==  8823
assert `r(sum_w)' ==  8823
assert `r(mean)' ==  1.653292530885186
assert `r(Var)' ==  1.911405786893877
assert `r(sd)' ==  1.382535998407954
assert `r(min)' ==  1
assert `r(max)' ==  6
assert `r(sum)' ==  14587

tab costar_match_type

* results from 11.17.2022 run:
*                costar_match_type |      Freq.     Percent        Cum.
* ---------------------------------+-----------------------------------
*             direct address match |      7,092       80.38       80.38
* closest match within boundary id |         19        0.22       80.60
*    closest match ONLY (<=.01 mi) |        432        4.90       85.49
*   highest similscore ONLY (>=.9) |        276        3.13       88.62
*            similscore ONLY (<.9) |        967       10.96       99.58
*           no warren<->NHPD match |         37        0.42      100.00
* ---------------------------------+-----------------------------------
*                            Total |      8,823      100.00

* create a unique dataset of costar ids
bysort costar_id (costar_match_type): keep if _n == 1

* check for validity
destring costar_id, gen(destring_id)
sum destring_id
assert `r(N)' ==  6709
assert `r(sum_w)' ==  6709
assert `r(mean)' ==  7770017.335370398
assert `r(Var)' ==  7568278785748.555
assert `r(sd)' ==  2751050.487677126
assert `r(min)' ==  9001
assert `r(max)' ==  12041048
assert `r(sum)' ==  52129046303

* temp save for merge with rent history data
tempfile match_types
save `match_types', replace


********************************************************************************
** load rent history data
********************************************************************************
import excel "$DATAPATH/costar/costar_rent_hist.xlsx", sheet("Sheet1") firstrow case(upper) allstring clear

rename REF_ID costar_id

gen fy = substr(QUARTER,1,4)
gen quarter = substr(QUARTER,6,2)

keep if quarter == "Q4"

rename ASKINGRENTPERUNIT costar_rent

rename STATUS costar_status

keep fy costar_id costar_rent costar_status
order fy costar_id costar_rent costar_status

destring costar_rent, replace

destring fy, replace

merge m:1 costar_id using `match_types', keepusing(costar_match_type)

	* confirm merge results
	sum _merge
	assert `r(N)' ==  38509
	assert `r(sum_w)' ==  38509
	assert `r(mean)' ==  2.857383988158612
	assert `r(Var)' ==  .138847846238888
	assert `r(sd)' ==  .3726229276881496
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  110035

	drop if _merge==2	
	drop _merge

destring costar_id, replace

sum fy 
assert `r(N)' ==  33655
assert `r(sum_w)' ==  33655
assert `r(mean)' ==  2010.574030604665
assert `r(Var)' ==  36.99564101588153
assert `r(sd)' ==  6.08240421345717
assert `r(min)' ==  2000
assert `r(max)' ==  2020
assert `r(sum)' ==  67665869

sum costar_id
assert `r(N)' ==  33655
assert `r(sum_w)' ==  33655
assert `r(mean)' ==  6981724.700549696
assert `r(Var)' ==  7145184949390.286
assert `r(sd)' ==  2673047.876374512
assert `r(min)' ==  41723
assert `r(max)' ==  12040769
assert `r(sum)' ==  234969944797

sum costar_rent
assert `r(N)' ==  33652
assert `r(sum_w)' ==  33652
assert `r(mean)' ==  1691.438116363911
assert `r(Var)' ==  566882.2898372054
assert `r(sd)' ==  752.9158584046463
assert `r(min)' ==  330.333333333333
assert `r(max)' ==  8678.33695652174
assert `r(sum)' ==  56920275.49187833

sum costar_match_type
assert `r(N)' ==  33336
assert `r(sum_w)' ==  33336
assert `r(mean)' ==  1.880999520038397
assert `r(Var)' ==  2.498302837737883
assert `r(sd)' ==  1.580602049137569
assert `r(min)' ==  1
assert `r(max)' ==  6
assert `r(sum)' ==  62705


********************************************************************************
** end
********************************************************************************
save "$DATAPATH/costar/costar_rent_hist.dta", replace

clear all

