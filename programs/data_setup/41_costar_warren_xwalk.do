clear all

// log close _all
//
// local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")
//
// local name ="costar_crosswalk" // <--- change when necessry
//
// log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

********************************************************************************
* File name:		40_costar_warren_xwalk.do
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Assigns CoStar properties to warren group properties
*			based on address. Order of assignment is as follows:
*				1 - direct address match
*				2 - property is both closest and has highest
*					similarity score
*				3 - closest proximity match is <=.01 mi
*				4 - best fuzzy address match has similarity
*					score of >=.9
*			Matches are unrestricted so they can be assigned to any
*			address regardless of what the residential type is in 
*			warren. This means that some CoStar properties get 
*			assigned to non-MF type properties.
* 				
* Inputs:		./costar_mf_all.dta
*			./warren_MA_all_unique.dta
*
* Outputs:		./costar_warren_xwalk.dta
*
* Created:		02/28/2021
* Last updated:		11/10/2022
********************************************************************************

********************************************************************************
** create costar matching file
********************************************************************************
use "$DATAPATH/costar/costar_mf_all.dta", clear

keep if BuildingStatus == "Existing"

* matching variables
gen address_full = upper(PropertyAddress) + ", " + upper(costar_city) + ", " + "MA" + ", " + substr(Zip,1,5)

gen matching_address = costar_stnum + " " + upper(costar_street) + " " + costar_city

keep costar_id costar_stnum costar_street costar_city costar_GEOID costar_lat costar_long address_full matching_address
order costar_id costar_stnum costar_street costar_city costar_GEOID costar_lat costar_long address_full matching_address

rename address_full costar_address_full

/* Note from NFC on 11/10/2022: the original version of this .do file used the
<duplicates drop matching_address, force> command to get a unique set of costar 
property and address pairs. However, this command is dependent on the sort order
of the input dataset. Because I never specified the sort order, the unique 
costar properties that are selected are different than the original version, 
which causes the crosswalk to be slightly different accross ~17 costar 
properties. In order to avoid having this effect the final dataset results I 
instead created a dataset ./costar_selections.dta that preserves the original 
selection and merges on here to recreate the original seleciton of unique pairs.

Ultimately this is a weakness in the code that could be improved upon, but since
costar properties are merged within very small geographic areas it shouldn't 
impact the final results. */

* select original unique sample of costar properies
merge 1:1 costar_id using "$DATAPATH/costar/costar_selections.dta", keepusing(original_selection)

	* validate merge results
	sum _merge
	assert `r(N)' ==  6748
	assert `r(sum_w)' ==  6748
	assert `r(mean)' ==  2.988441019561352
	assert `r(Var)' ==  .0229877574515763
	assert `r(sd)' ==  .1516171410216415
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  20166

	keep if _merge == 3
	drop _merge

* data validity checks
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

sum costar_lat
assert `r(N)' ==  6709
assert `r(sum_w)' ==  6709
assert `r(mean)' ==  42.35533191453272
assert `r(Var)' ==  .0085763964519672
assert `r(sd)' ==  .092608835712189
assert `r(min)' ==  42.0168212
assert `r(max)' ==  42.686828
assert `r(sum)' ==  284161.9218146

sum costar_long
assert `r(N)' ==  6709
assert `r(sum_w)' ==  6709
assert `r(mean)' ==  -71.09085978032493
assert `r(Var)' ==  .0177327635363757
assert `r(sd)' ==  .1331644229378691
assert `r(min)' ==  -71.5978686
assert `r(max)' ==  -70.612543
assert `r(sum)' ==  -476948.5782662

drop destring_*

tempfile costar
save `costar', replace


********************************************************************************
** create warren matching file (1,961,277 obs)
********************************************************************************
use "$DATAPATH/warren/warren_MA_all_unique", clear

* matching variables
replace street = upper(street)

gen warren_street_full = string(st_num) + regexs(1) if regexm(st_numext, "(^[-][0-9]+)")

gen warren_address_full = string(st_num) + ", " + street + ", " + cousub_name + ", " + "MA" + ", " + string(zipcode)

gen matching_address = string(st_num) + " " + street + " " + cousub_name

gen warren_GEOID = substr(warren_GEOID,1,12)

keep prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type 
order prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type

* data validity check
sum prop_id
assert `r(N)' ==  1961277
assert `r(sum_w)' ==  1961277
assert `r(mean)' ==  2184470.890842548
assert `r(Var)' ==  1935285127142.365
assert `r(sd)' ==  1391145.257384133
assert `r(min)' ==  3
assert `r(max)' ==  5068039
assert `r(sum)' ==  4284352515379

sum warren_latitude
assert `r(N)' ==  1961277
assert `r(sum_w)' ==  1961277
assert `r(mean)' ==  42.23080289006162
assert `r(Var)' ==  .09912400360065
assert `r(sd)' ==  .3148396474408044
assert `r(min)' ==  41.24239349365234
assert `r(max)' ==  42.88520812988281
assert `r(sum)' ==  82826302.39981137

sum warren_longitude
assert `r(N)' ==  1961277
assert `r(sum_w)' ==  1961277
assert `r(mean)' ==  -71.33712933247958
assert `r(Var)' ==  .4530866461357559
assert `r(sd)' ==  .6731171117537839
assert `r(min)' ==  -73.48712921142578
assert `r(max)' ==  -69.93846893310547
assert `r(sum)' ==  -139911871.0058176

tempfile warren
save `warren', replace


********************************************************************************
** create and store direct address matches
********************************************************************************
merge m:1 matching_address using `costar'

	* merge check
	sum _merge
	assert `r(N)' ==  1962404
	assert `r(sum_w)' ==  1962404
	assert `r(mean)' ==  1.007802165099541
	assert `r(Var)' ==  .0149691684379615
	assert `r(sd)' ==  .1223485530685242
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  1977715

preserve 
	keep if _merge == 3
	
	drop _merge
	
	gen match_type = 1
	
	unique prop_id
	assert `r(N)' == `r(unique)'
	
	tempfile direct_matches
	save `direct_matches', replace
restore


********************************************************************************
** create proximity and fuzzy address match scores
********************************************************************************
preserve
	keep if _merge == 2
	
	drop _merge
	
	keep costar_id costar_stnum costar_street costar_city costar_GEOID costar_lat costar_long costar_address_full matching_address
	order costar_id costar_stnum costar_street costar_city costar_GEOID costar_lat costar_long costar_address_full matching_address
	
	gen joinby_GEOID = costar_GEOID
	gen joinby_city = upper(costar_city)
	
	tempfile joinby_using
	save `joinby_using', replace
restore

keep if _merge == 1

keep prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type
order prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type

gen joinby_GEOID  = warren_GEOID
gen joinby_city = upper(cousub_name)

joinby joinby_GEOID joinby_city using `joinby_using', unmatched(both) _merge(join_merge)

	* merge check
	sum join_merge
	assert `r(N)' ==  2046761
	assert `r(sum_w)' ==  2046761
	assert `r(mean)' ==  1.282719379546513
	assert `r(Var)' ==  .4855053286907084
	assert `r(sd)' ==  .696782124261744
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  2625420

	keep if join_merge==3

* calculate distance between Warren/NHPD property
vincenty warren_latitude warren_longitude costar_lat costar_long, hav(match_dist)

* calculate similarity between Warren/NHPD address
gen warren_matchit = string(st_num) + " " + upper(street)

gen nhpd_matchit = upper(costar_stnum) + " " + upper(costar_street)

matchit warren_matchit nhpd_matchit

gen inverse_similscore = 1 - similscore	

* check results for consistency
sum match_dist 
assert `r(N)' ==  289326
assert `r(sum_w)' ==  289326
assert `r(mean)' ==  .4076666143762995
assert `r(Var)' ==  .1772980890181414
assert `r(sd)' ==  .4210677962254314
assert `r(min)' ==  .0002312539881288
assert `r(max)' ==  4.15262208131265
assert `r(sum)' ==  117948.5508710372

sum similscore
assert `r(N)' ==  289326
assert `r(sum_w)' ==  289326
assert `r(mean)' ==  .1755009251851345
assert `r(Var)' ==  .0400986013684842
assert `r(sd)' ==  .2002463516983122
assert `r(min)' ==  0
assert `r(max)' ==  .985184366143778
assert `r(sum)' ==  50776.98068011423

// tempfile savepoint2
// save `savepoint2', replace
// stop	

********************************************************************************
** match based on proximity and address similarity
********************************************************************************	
/* Proximity and similarity matching overview:
NHPD records are tagged to their closest Warren record if the distance is <=.01 miles.
If a Warren record has multiple closest NHPD matches, the best (closest) is used,
with the rest being dropped. 

For the remaining matches, they are classified as the most similar based with a 
similscore>=.9 (fuzzy1) and similscore<.9 (fuzzy2). As before if a Warren record
has multple similar NHPD matches, the best is used (highest similscore). 

To avoid conflicts when an NHPD property is an equal shortest distance or has 
the same close score between two Warren addresses the first address or property ID
is used. So within NHPD matches, they are sorted first by distance then by 
warren_address_full then by prop_id. Likewise if a Warren address has two
conflicts. The first NHPD address is used. 

This ensures the results of the match are the same every time. 
*/

********************************************************************************
** proximity match
********************************************************************************
bysort costar_id (match_dist warren_address_full prop_id): gen tag_prox = 1 if _n==1 & match_dist<=.01

********************************************************************************
** fuzzy match 1 (>=.9)
********************************************************************************
bysort costar_id (inverse_similscore warren_address_full prop_id): gen tag_fuzzy1 = 1 if _n==1 & similscore>=.9

********************************************************************************
** fuzzy match 1 (<.9)
********************************************************************************
bysort costar_id (inverse_similscore warren_address_full prop_id): gen tag_fuzzy2 = 1 if _n==1 & similscore<.9

* keeps only those with a match in 1 of the 3 categories
keep if tag_prox==1 | tag_fuzzy1==1 | tag_fuzzy2==1

* <a> counts the number of best NHPD matches (based on proximity)
bysort warren_address_full: egen a = sum(tag_prox)
	
	* error check
	sum a
	assert `r(N)' ==  1396
	assert `r(sum_w)' ==  1396
	assert `r(mean)' ==  .2421203438395415
	assert `r(Var)' ==  .1922317733205985
	assert `r(sd)' ==  .4384424401453383
	assert `r(min)' ==  0
	assert `r(max)' ==  2
	assert `r(sum)' ==  338
	
	tab a
	* results from last check on 11.7.2022:
	*           a |      Freq.     Percent        Cum.
	* ------------+-----------------------------------
	*           0 |      1,064       76.22       76.22
	*           1 |        326       23.35       99.57
	*           2 |          6        0.43      100.00
	* ------------+-----------------------------------
	*       Total |      1,396      100.00
	
	drop a

* if there are conflicts, tag the first NHPD address
bysort warren_address_full (match_dist costar_address_full): gen tag_prox_w = 1 if _n==1

* drop closest NHPD matches that are not also the closest to the Warren address
drop if tag_prox==1 & tag_prox_w==. 

* run again and all conflicts should be gone; <a> counts the number of best NHPD matches (based on proximity)
bysort warren_address_full: egen a = sum(tag_prox)

	* error check
	sum a
	assert `r(N)' ==  1393
	assert `r(sum_w)' ==  1393
	assert `r(mean)' ==  .2361809045226131
	assert `r(Var)' ==  .180529082192572
	assert `r(sd)' ==  .4248871405356628
	assert `r(min)' ==  0
	assert `r(max)' ==  1
	assert `r(sum)' ==  329
	
	tab a
	* results from last check on 11.7.2022:
	*           a |      Freq.     Percent        Cum.
	* ------------+-----------------------------------
	*           0 |      1,064       76.38       76.38
	*           1 |        329       23.62      100.00
	* ------------+-----------------------------------
	*       Total |      1,393      100.00

	drop a

gen tag_both = 1 if tag_prox==1 & tag_fuzzy1==1
		
* if there are conflicts, tag the first NHPD address		
bysort warren_address_full (inverse_similscore costar_address_full): gen tag_fuzzy_w = 1 if _n==1

* drop NHPD matches that are not also the best match to the Warren address
drop if tag_fuzzy1==1 & tag_fuzzy_w==.

drop if tag_fuzzy2==1 & tag_fuzzy_w==.
	
	* conflict checks: <a> counts the number of best matches (based on similscore)
	bysort warren_address_full: egen a = sum(tag_fuzzy1)
		
		* error check
		sum a 
		assert `r(N)' ==  1358
		assert `r(sum_w)' ==  1358
		assert `r(mean)' ==  .272459499263623
		assert `r(Var)' ==  .1983713966635663
		assert `r(sd)' ==  .4453890396760638
		assert `r(min)' ==  0
		assert `r(max)' ==  1
		assert `r(sum)' ==  370

		tab a
		* results from last check on 11.7.2022:		
		*           a |      Freq.     Percent        Cum.
		* ------------+-----------------------------------
		*           0 |        988       72.75       72.75
		*           1 |        370       27.25      100.00
		* ------------+-----------------------------------
		*       Total |      1,358      100.00
		
		drop a

	bysort warren_address_full: egen a = sum(tag_fuzzy2)
		
		* error check
		sum a
		assert `r(N)' ==  1358
		assert `r(sum_w)' ==  1358
		assert `r(mean)' ==  .5287187039764359
		assert `r(Var)' ==  .2493588581760641
		assert `r(sd)' ==  .4993584465852802
		assert `r(min)' ==  0
		assert `r(max)' ==  1
		assert `r(sum)' ==  718
		
		tab a
		* results from last check on 11.7.2022:		
		*           a |      Freq.     Percent        Cum.
		* ------------+-----------------------------------
		*           0 |        640       47.13       47.13
		*           1 |        718       52.87      100.00
		* ------------+-----------------------------------
		*       Total |      1,358      100.00

		drop a

bysort costar_id (tag_both tag_prox tag_fuzzy1 tag_fuzzy2): keep if _n==1

* categorize the match types
gen match_type = .
	replace match_type = 2 if tag_both==1 & match_type==.
	replace match_type = 3 if tag_prox==1 & match_type==.
	replace match_type = 4 if tag_fuzzy1==1 & match_type==.
	replace match_type = 5 if tag_fuzzy2==1 & match_type==.

* check results for consistency and error	
unique costar_id
assert `r(N)' == `r(unique)'
	
sum match_type
assert `r(N)' ==  1092
assert `r(sum_w)' ==  1092
assert `r(mean)' ==  4.173076923076923
assert `r(Var)' ==  .7720334202918988
assert `r(sd)' ==  .8786543235493118
assert `r(min)' ==  2
assert `r(max)' ==  5
assert `r(sum)' ==  4557
	
tab match_type

* results from 4/28/2021 run:
*  match_type |      Freq.     Percent        Cum.
* ------------+-----------------------------------
*           2 |         11        1.01        1.01
*           3 |        310       28.39       29.40
*           4 |        250       22.89       52.29
*           5 |        521       47.71      100.00
* ------------+-----------------------------------
*       Total |      1,092      100.00

* all warren addresses should be unique, drop based on rank of type, distance, similscore if not
unique warren_address_full
assert `r(unique)' == 1090
assert `r(N)' == 1092

bysort warren_address_full (match_type match_dist inverse_similscore): keep if _n==1

unique warren_address_full
assert `r(unique)' == `r(N)'


********************************************************************************
** merge on main warren data file
********************************************************************************
drop prop_id // must be dropped otherwise not all property IDs are recorded

merge 1:m warren_address_full using `warren', keep(3) keepusing(prop_id)
	
	* check merge results
	sum _merge
	assert `r(N)' ==  1694
	assert `r(sum_w)' ==  1694
	assert `r(mean)' ==  3
	assert `r(Var)' ==  0
	assert `r(sd)' ==  0
	assert `r(min)' ==  3
	assert `r(max)' ==  3
	assert `r(sum)' ==  5082
	
	drop if _merge == 2	
	drop _merge

unique costar_id
assert `r(N)' == 1694
assert `r(unique)' == 1090

unique warren_address_full
assert `r(N)' == 1694
assert `r(unique)' == 1090

append using `direct_matches'

sum match_type
assert `r(N)' ==  8786
assert `r(sum_w)' ==  8786
assert `r(mean)' ==  1.634987480081949
assert `r(Var)' ==  1.839545230349779
assert `r(sd)' ==  1.356298355948933
assert `r(min)' ==  1
assert `r(max)' ==  5
assert `r(sum)' ==  14365

tab match_type

* results from 4.28.2021 run:
*  match_type |      Freq.     Percent        Cum.
* ------------+-----------------------------------
*           1 |      7,092       80.72       80.72
*           2 |         19        0.22       80.94
*           3 |        432        4.92       85.85
*           4 |        276        3.14       88.99
*           5 |        967       11.01      100.00
* ------------+-----------------------------------
*       Total |      8,786      100.00

* add on non-matched CoStar IDs
merge m:1 costar_id using `costar', keepusing(costar_id)
	
	* confirm merge results
	sum _merge
	assert `r(N)' ==  8823
	assert `r(sum_w)' ==  8823
	assert `r(mean)' ==  2.99580641505157
	assert `r(Var)' ==  .0041764721556232
	assert `r(sd)' ==  .0646256307947801
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  26432
	
	replace match_type = 6 if _merge==2

tab match_type

unique prop_id if match_type!=6 // all property IDs should be unique
assert `r(N)' == `r(unique)'
	
* assign labels to match_typs
label define match_type_lbl ///
	1 "direct address match" ///
	2 "closest match within boundary id" ///
	3 "closest match ONLY (<=.01 mi)" ///
	4 "highest similscore ONLY (>=.9)" ///
	5 "similscore ONLY (<.9)" ///
	6 "no warren<->NHPD match"
	
lab val match_type match_type_lbl

tab match_type
* results from 4/28/2021 run:
*                       match_type |      Freq.     Percent        Cum.
* ---------------------------------+-----------------------------------
*             direct address match |      7,092       80.38       80.38
* closest match within boundary id |         19        0.22       80.60
*    closest match ONLY (<=.01 mi) |        432        4.90       85.49
*   highest similscore ONLY (>=.9) |        276        3.13       88.62
*            similscore ONLY (<.9) |        967       10.96       99.58
*           no warren<->NHPD match |         37        0.42      100.00
* ---------------------------------+-----------------------------------
*                            Total |      8,823      100.00


********************************************************************************
** label and error checks
********************************************************************************
rename match_type costar_match_type

notes drop _all
notes: Description: Crosswalk for CoStar to warren records
notes: Source: CoStar
notes: Source Page: www.costar.com
notes: Author: Nicholas Chiumenti
notes: TS

lab var prop_id "warren group unqiue ID"
lab var warren_address_full "full warren group property address"
lab var costar_id "CoStar unique ID"
lab var costar_address_full "full CoStar property address"
lab var costar_match_type "CoStar to Warren match type"
lab var match_dist "distance between best"
lab var similscore "address similarity score (using matchit)"	

* final error checks
sum costar_match_type
assert `r(N)' ==  8823
assert `r(sum_w)' ==  8823
assert `r(mean)' ==  1.653292530885186
assert `r(Var)' ==  1.911405786893877
assert `r(sd)' ==  1.382535998407954
assert `r(min)' ==  1
assert `r(max)' ==  6
assert `r(sum)' ==  14587

unique prop_id if costar_match_type!=6
assert `r(N)' ==  8786
assert `r(sum)' ==  8786
assert `r(unique)' ==  8786

sum prop_id
assert `r(N)' ==  8786
assert `r(sum_w)' ==  8786
assert `r(mean)' ==  2437039.896767585
assert `r(Var)' ==  3100346035375.476
assert `r(sd)' ==  1760779.95086708
assert `r(min)' ==  3078
assert `r(max)' ==  5067588
assert `r(sum)' ==  21411832533

sum match_dist
assert `r(N)' ==  1694
assert `r(sum_w)' ==  1694
assert `r(mean)' ==  .1102864408617049
assert `r(Var)' ==  .0371861965185819
assert `r(sd)' ==  .1928372280411172
assert `r(min)' ==  .0002312539881288
assert `r(max)' ==  2.096820816840552
assert `r(sum)' ==  186.8252308197282

destring costar_id, gen(destring_id)
sum destring_id
assert `r(N)' ==  8823
assert `r(sum_w)' ==  8823
assert `r(mean)' ==  7806471.798821263
assert `r(Var)' ==  7434817034998.797
assert `r(sd)' ==  2726686.09029327
assert `r(min)' ==  9001
assert `r(max)' ==  12041048
assert `r(sum)' ==  68876500681

sum similscore
assert `r(N)' ==  1694
assert `r(sum_w)' ==  1694
assert `r(mean)' ==  .615368874623221
assert `r(Var)' ==  .0983768198853073
assert `r(sd)' ==  .3136507928976225
assert `r(min)' ==  0
assert `r(max)' ==  .985184366143778
assert `r(sum)' ==  1042.434873611736

unique costar_id
assert `r(N)' ==  8823
assert `r(sum)' ==  6709
assert `r(unique)' ==  6709

* check that costar IDs only have 1 match type
bysort costar_id costar_match_type: gen n_types = 1
bysort costar_id: gen n_ids = 1
bysort costar_id costar_match_type: egen sum_types = total(n_types)
bysort costar_id costar_match_type: egen sum_ids = total(n_ids)

gen check = sum_types - sum_ids

sum check // all values should be zero
assert `r(N)' ==  8823
assert `r(sum_w)' ==  8823
assert `r(mean)' ==  0
assert `r(Var)' ==  0
assert `r(sd)' ==  0
assert `r(min)' ==  0
assert `r(max)' ==  0
assert `r(sum)' ==  0
	
assert sum_types == sum_ids


********************************************************************************
** end
********************************************************************************
keep prop_id warren_address_full costar_id costar_address_full costar_match_type match_dist similscore
order prop_id warren_address_full costar_id costar_address_full costar_match_type match_dist similscore

save "$DATAPATH/costar/costar_warren_xwalk.dta", replace

clear all
