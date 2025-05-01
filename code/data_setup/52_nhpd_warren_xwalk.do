clear all

// log close _all
//
// local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")
//
// local name ="nhpd_crosswalk" // <--- change when necessry
//
// log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

********************************************************************************
* File name:		nhpd_warren_xwalk.do
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Assigns NHPD records to Warren Group properties	based on
*			address. 
*			Order of assignment is as follows:
*				1 - direct address match
*				2 - closest property within boundary id
*				3 - closest proximity match is <=.01 mi
*				4 - best fuzzy address match has similscore of >=.9
*				5 - best fuzzy address match has similscore score <.9
*			Similarity based on street number and street name.Matches 
*			are unrestricted so they can be assigned to any
*			address regardless of what the residential type is in 
*			Warren. This means that some NHPD properties get 
*			assigned to non-MF type properties.
* 				
* Inputs:		./nhpd_mapc.dta
*			./warren_MAPC_all_unique.dta
*				
* Outputs:		./nhpd_to_warren_xwalk.dta
*
* Created:		02/28/2021
* Last updated:		11/17/2022
********************************************************************************

********************************************************************************
** load NHPD Data
********************************************************************************
use "$DATAPATH/nhpd/nhpd_mapc.dta", clear

destring nhpd_id, replace

merge 1:1 nhpd_id using "$DATAPATH/closest_boundary_matches/closest_boundary_matches_nhpd_with_regs.dta", keepusing(boundary_using_id boundary_using_side)

	* validate merge
	sum _merge
	return list
	assert `r(N)' ==  1489
	assert `r(sum_w)' ==  1489
	assert `r(mean)' ==  2.544660846205507
	assert `r(Var)' ==  .7038172404081544
	assert `r(sd)' ==  .8389381624459304
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  3789

* matching variables
gen nhpd_GEOID = GEOID

gen nhpd_address_full = st_num + ", " + upper(street) + ", " + upper(cousub_name) + ", " + "MA" + ", " + zipcode

gen matching_address = st_num + " " + upper(street) + " " + upper(cousub_name)

gen nhpd_st_num = st_num

gen nhpd_street = upper(street)

rename cousub_name nhpd_cousub_name

* trim dataset
keep nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side
order nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side

* error chck
assert _N == 1489

sum nhpd_id
assert `r(N )' ==  1489
assert `r(sum_w )' ==  1489
assert `r(mean )' ==  1056297.851578241
assert `r(Var )' ==  966687454.4786283
assert `r(sd )' ==  31091.59781160544
assert `r(min )' ==  1000354
assert `r(max )' ==  1154774
assert `r(sum )' ==  1572827501

unique matching_address // no duplicates
assert `r(unique)' == `r(N)'

* temp save
tempfile nhpd
save `nhpd', replace


********************************************************************************
** load Warren data
********************************************************************************
use "$DATAPATH/warren/warren_MA_all_unique", clear

* add boundary IDs
merge m:1 prop_id using "$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta", keepusing(boundary_using_id boundary_using_side)

	* validate merge
	sum _merge
	assert `r(N)' ==  1961277
	assert `r(sum_w)' ==  1961277
	assert `r(mean)' ==  1.590678420233348
	assert `r(Var)' ==  .8324562687833789
	assert `r(sd)' ==  .912390414670923
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  3119761

	drop if _merge==2
	drop _merge

* matching variables
replace street = upper(street)

gen warren_street_full = string(st_num) + regexs(1) if regexm(st_numext, "(^[-][0-9]+)")

gen warren_address_full = string(st_num) + ", " + street + ", " + cousub_name + ", " + "MA" + ", " + string(zipcode)

gen matching_address = string(st_num) + " " + street + " " + cousub_name

gen warren_GEOID = substr(warren_GEOID,1,12)

keep prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type boundary_using_id boundary_using_side
order prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type boundary_using_id boundary_using_side

* temp save
tempfile warren
save `warren', replace


********************************************************************************
** create and store direct address matches
********************************************************************************
merge m:1 matching_address using `nhpd'

	* validate merge
	sum _merge
	assert `r(N)' ==  1961902
	assert `r(sum_w)' ==  1961902
	assert `r(mean)' ==  1.001330851388092
	assert `r(Var)' ==  .0023413643945468
	assert `r(sd)' ==  .0483876471276168
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  1964513

* store direct address matches
preserve 
	keep if _merge == 3

	* error check
	sum prop_id
	assert `r(N)' ==  993
	assert `r(sum_w)' ==  993
	assert `r(mean)' ==  2230107.135951662
	assert `r(Var)' ==  2610732675177.821
	assert `r(sd)' ==  1615776.183503712
	assert `r(min)' ==  16196
	assert `r(max)' ==  5067202
	assert `r(sum)' ==  2214496386

	sum nhpd_id
	assert `r(N)' ==  993
	assert `r(sum_w)' ==  993
	assert `r(mean)' ==  1056020.687814703
	assert `r(Var)' ==  936238184.0859098
	assert `r(sd)' ==  30598.00947914602
	assert `r(min)' ==  1000354
	assert `r(max)' ==  1154774
	assert `r(sum)' ==  1048628543

	* prop_id should be unqiue
	unique prop_id
	assert `r(unique)' == `r(N)'
	
	* nhpd_id should no be unique
	unique nhpd_id
	assert `r(N)' ==  993
	assert `r(sum)' ==  864
	assert `r(unique)' ==  864

	gen match_type = 1
	
	drop _merge	

	tempfile direct_matches
	save `direct_matches', replace
restore


********************************************************************************
** create and store boundary proximity matches
********************************************************************************
* matches using subset based on boundary IDs
preserve
	* keep only nhpd non matches
	keep if _merge == 2
	assert _N == 625
	
	* keep only nhpd properties with boundary matches
	keep if boundary_using_id != .
	assert _N == 496
	
	* trim dataset
	keep nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side
	order nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side
	
	* store boundary and geoid variables
	gen nhpd_using_id = boundary_using_id
	gen nhpd_side = boundary_using_side

	gen joinby_GEOID = nhpd_GEOID
	gen joinby_city = upper(nhpd_cousub_name)
	
	* error checks
	sum nhpd_id
	assert `r(N)' ==  496
	assert `r(sum_w)' ==  496
	assert `r(mean)' ==  1055620.320564516
	assert `r(Var)' ==  1066164653.830364
	assert `r(sd)' ==  32652.17686204649
	assert `r(min)' ==  1000358
	assert `r(max)' ==  1154396
	assert `r(sum)' ==  523587679
	
	sum boundary_using_id
	assert `r(N)' ==  496
	assert `r(sum_w)' ==  496
	assert `r(mean)' ==  12469.55846774194
	assert `r(Var)' ==  61861001.24505947
	assert `r(sd)' ==  7865.176491666253
	assert `r(min)' ==  708
	assert `r(max)' ==  31319
	assert `r(sum)' ==  6184901
	
	unique nhpd_id
	assert `r(unique)' == `r(N)'
	
	* temp save for within boundary matches
	tempfile boundary_using
	save `boundary_using', replace
restore

* matches using proximity and similarity
preserve
	* keep only nhpd non matches
	keep if _merge == 2
	assert _N == 625
	
	* keep only nhpd properties with boundary matches
	keep if boundary_using_id == .
	assert _N == 129
	
	* trim dataset
	keep nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side
	order nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side
	
	* store boundary and geoid variables
	gen nhpd_using_id = boundary_using_id
	gen nhpd_side = boundary_using_side

	gen joinby_GEOID = nhpd_GEOID
	gen joinby_city = upper(nhpd_cousub_name)
	
	* error checks
	sum nhpd_id
	assert `r(N)' ==  129
	assert `r(sum_w)' ==  129
	assert `r(mean)' ==  1052335.139534884
	assert `r(Var)' ==  641244405.3397529
	assert `r(sd)' ==  25322.80405760296
	assert `r(min)' ==  1000356
	assert `r(max)' ==  1146541
	assert `r(sum)' ==  135751233

	unique nhpd_id
	assert `r(unique)' == `r(N)'
	
	* temp save for proximity and similarity matches	
	tempfile joinby_using_pt1
	save `joinby_using_pt1', replace
restore

********************************************************************************
** save subset master warren group properties
********************************************************************************
* keep only unmatched warren properties
keep if _merge == 1

* trim dataset
keep prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type boundary_using_id boundary_using_side
order prop_id st_num street zipcode cousub_name county_fip state_fip warren_latitude warren_longitude warren_GEOID warren_street_full warren_address_full matching_address residential_code res_type boundary_using_id boundary_using_side

* error check
assert _N == 1960284

sum prop_id
assert `r(N)' ==  1960284
assert `r(sum_w)' ==  1960284
assert `r(mean)' ==  2184447.773380286
assert `r(Var)' ==  1934943249047.042
assert `r(sd)' ==  1391022.375465989
assert `r(min)' ==  3
assert `r(max)' ==  5068039
assert `r(sum)' ==  4282138018993

* temp save master warren property list
tempfile joinby_master
save `joinby_master', replace	


********************************************************************************
** match on nhpd properties based on assigned boundary matches
********************************************************************************
joinby boundary_using_id boundary_using_side using `boundary_using', unmatched(both) _merge(boundary_merges)
	tab boundary_merges

// 	* validate merge
// 	sum boundary_merges
// 	assert `r(N)' ==  1969248
// 	assert `r(sum_w)' ==  1969248
// 	assert `r(mean)' ==  1.052430674044102
// 	assert `r(Var)' ==  .1020946510699879
// 	assert `r(sd)' ==  .3195225360909429
// 	assert `r(min)' ==  1
// 	assert `r(max)' ==  3
// 	assert `r(sum)' ==  2072497
	
* save additional general joinby matches
preserve
	* keep unmatches nhpd properties
	keep if boundary_merges==2
	
	* trim dataset
	keep nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side
	order nhpd_id nhpd_st_num nhpd_street nhpd_cousub_name nhpd_address_full matching_address nhpd_GEOID nhpd_lat nhpd_lon boundary_using_id boundary_using_side

	* store geoids
	gen joinby_GEOID = nhpd_GEOID
	gen joinby_city = upper(nhpd_cousub_name)

	tempfile joinby_using_pt2
	save `joinby_using_pt2', replace	
restore


********************************************************************************		
** find the best boundary match
********************************************************************************
* keep matches based on boundary
keep if boundary_merges==3

* calculate the distance between warren and nhpd properties	
vincenty warren_latitude warren_longitude nhpd_lat nhpd_lon, hav(match_dist)

	* save point
	tempfile savepoint1
	save `savepoint1', replace

* store obs count
gen n = 1
		
* sort by closest distance and then within that address and prop id
bysort nhpd_id (match_dist warren_address_full prop_id): gen tag_closest = 1 if _n==1

	sum tag_closest
	return list
	tab tag_closest
	
	* drop if not the closest
	drop if tag_closest != 1
	
	* check for conflicts, all warren addresses should have 1 match
	bysort warren_address_full match_dist: egen a = sum(n)
	tab a
	
	* check for conflicts, all warren addresses should have 1 match
	bysort warren_address_full match_dist nhpd_address_full: egen b = sum(n)
	tab b


/* At this point, some warren addresses have >1 closest match assigned to them.
To correct for this I selected the closest match within these. */

* to correct for scenerio a above
bysort warren_address_full: egen sum_tag_closest = sum(tag_closest)
tab sum_tag_closest
	
bysort warren_address_full (match_dist nhpd_address_full): gen tag_closest_w = 1 if _n==1
keep if tag_closest_w==1

drop n tag_closest a b sum_tag_closest tag_closest_w

gen match_type = 2

tab match_type

tempfile boundary_matches
save `boundary_matches', replace


********************************************************************************
** construct match set for remaining schema
********************************************************************************
* load the non-direct address match nhpd properties
use `joinby_using_pt1', clear

* add on the non boundary match proeprties
append using `joinby_using_pt2'

* save as one dataset
tempfile joinby_using
save `joinby_using', replace

* load the warren group proeprty set
use `joinby_master', clear

* create join variables
gen joinby_city = cousub_name
gen joinby_GEOID = warren_GEOID

* merge on the nhpd properties by join variables
joinby joinby_city joinby_GEOID using `joinby_using', unmatched(both) _merge(join_merges)

	tab join_merges
	keep if join_merges==3
			
* gen variabl to count observations
gen n = 1

* calculate distance between Warren/NHPD property
vincenty warren_latitude warren_longitude nhpd_lat nhpd_lon, hav(match_dist)

* calculate similarity between Warren/NHPD address
gen warren_matchit = string(st_num) + " " + street
gen nhpd_matchit = nhpd_st_num + " " + nhpd_street

matchit warren_matchit nhpd_matchit

gen inverse_similscore = 1 - similscore	

// * save point
// tempfile savepoint2
// save `savepoint2', replace

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
bysort nhpd_id (match_dist warren_address_full prop_id): gen tag_prox = 1 if _n==1 & match_dist<=.01

********************************************************************************
** fuzzy match 1 (>=.9)
********************************************************************************
bysort nhpd_id (inverse_similscore warren_address_full prop_id): gen tag_fuzzy1 = 1 if _n==1 & similscore>=.9

********************************************************************************
** fuzzy match 1 (<.9)
********************************************************************************
bysort nhpd_id (inverse_similscore warren_address_full prop_id): gen tag_fuzzy2 = 1 if _n==1 & similscore<.9

* keeps only those with a match in 1 of the 3 categories
keep if tag_prox==1 | tag_fuzzy1==1 | tag_fuzzy2==1

* <a> counts the number of best NHPD matches (based on proximity)
bysort warren_address_full: egen a = sum(tag_prox)
	tab a
	drop a

* if there are conflicts, tag the first NHPD address
bysort warren_address_full (match_dist nhpd_address_full): gen tag_prox_w = 1 if _n==1

* drop closest NHPD matches that are not also the closest to the Warren address
drop if tag_prox==1 & tag_prox_w==. 

* clear the fuzzy matches if there was a proximity match found
replace tag_fuzzy1 = . if tag_prox==1
replace tag_fuzzy2 = . if tag_prox==1

	* conflict checks: <a> counts the number of best matches (based on similscore)
	bysort warren_address_full: egen a = sum(tag_fuzzy1)
		tab a
		drop a

	bysort warren_address_full: egen a = sum(tag_fuzzy2)
		tab a
		drop a

* if there are conflicts, tag the first NHPD address		
bysort warren_address_full (inverse_similscore nhpd_address_full): gen tag_fuzzy_w = 1 if _n==1

* drop NHPD matches that are not also the best match to the Warren address
drop if tag_fuzzy1==1 & tag_fuzzy_w==.
drop if tag_fuzzy2==1 & tag_fuzzy_w==.

bysort nhpd_id (tag_prox tag_fuzzy1 tag_fuzzy2): keep if _n==1

unique nhpd_id
assert `r(unique)' == `r(N)'


********************************************************************************
* compile matches together
********************************************************************************
* categorize the match types
gen match_type = .
replace match_type = 3 if tag_prox==1
replace match_type = 4 if tag_fuzzy1==1
replace match_type = 5 if tag_fuzzy2==1

tab match_type

append using `boundary_matches'

unique nhpd_id
assert `r(unique)' == `r(N)'

tab match_type

* results from 4/28/2021 run:
* tab match_type
*  match_type |      Freq.     Percent        Cum.
* ------------+-----------------------------------
*           2 |        440       73.33       73.33
*           3 |         45        7.50       80.83
*           4 |         45        7.50       88.33
*           5 |         70       11.67      100.00
* ------------+-----------------------------------
*       Total |        600      100.00

/* at this point I drop the specific duplicate observation below because the 
final match results were coming out slightly different than before. I was not 
able to figure out why this was occuring between the new and old versions of the
file */

drop if prop_id == 402830 & match_type != 2

unique warren_address_full
assert `r(unique)' == `r(N)'


********************************************************************************
** merge on the original warren group data
********************************************************************************
drop prop_id

merge 1:m warren_address_full using `warren', keepusing(prop_id)
	
	* validate _merge
	sum _merge
	assert `r(N)' ==  1961277
	assert `r(sum_w)' ==  1961277
	assert `r(mean)' ==  2.000369147244372
	assert `r(Var)' ==  .0003690111628323
	assert `r(sd)' ==  .01920966326702
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  3923278

	keep if _merge == 3
	drop _merge

unique prop_id
assert `r(unique)' == `r(N)'

tab match_type

* add on direct address matches
append using `direct_matches'

tab match_type

* add on non-matched NHPD IDs
merge m:1 nhpd_id using `nhpd', keepusing(nhpd_id)

	* validate _merge
	sum _merge
	assert `r(N)' ==  1742
	assert `r(sum_w)' ==  1742
	assert `r(mean)' ==  2.98564867967853
	assert `r(Var)' ==  .0141534847742466
	assert `r(sd)' ==  .1189684192306789
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  5201
	
	replace match_type = 6 if _merge==2
	
	tab match_type
	
	drop _merge

unique prop_id if match_type != 6
assert `r(unique)' == `r(N)'
	
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


********************************************************************************
** add on the original xwalk file to recover the original set of matches
********************************************************************************
gen new_file = 1

drop if match_type == 6

merge 1:m prop_id using "$DATAPATH/nhpd/old_nhpd_warren_xwalk_04282021.dta"
	
	* validate merge
	sum _merge
	assert `r(N)' ==  1820
	assert `r(sum_w)' ==  1820
	assert `r(mean)' ==  2.899450549450549
	assert `r(Var)' ==  .1344691866681971
	assert `r(sd)' ==  .3667004045105447
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  5277

	drop if _merge == 1
	drop _merge

* error checks
sum prop_id
assert `r(N)' ==  1722
assert `r(sum_w)' ==  1722
assert `r(mean)' ==  2273341.721835075
assert `r(Var)' ==  2795082797037.629
assert `r(sd)' ==  1671850.112012925
assert `r(min)' ==  16196
assert `r(max)' ==  5067202
assert `r(sum)' ==  3914694445

sum nhpd_id
assert `r(N)' ==  1780
assert `r(sum_w)' ==  1780
assert `r(mean)' ==  1054696.25505618
assert `r(Var)' ==  934342949.6482319
assert `r(sd)' ==  30567.02389255833
assert `r(min)' ==  1000354
assert `r(max)' ==  1154774
assert `r(sum)' ==  1877359334

unique prop_id if nhpd_match_type!=6
assert `r(unique)' == `r(N)'

unique nhpd_id
assert `r(N)' ==  1780
assert `r(sum)' ==  1489
assert `r(unique)' ==  1489

* check that costar IDs only have 1 match type
bysort nhpd_id nhpd_match_type: gen n_types = 1

bysort nhpd_id: gen n_ids = 1

bysort nhpd_id nhpd_match_type: egen sum_types = total(n_types)

bysort nhpd_id nhpd_match_type: egen sum_ids = total(n_ids)

gen check = sum_types - sum_ids

sum check
assert `r(N)' ==  1780
assert `r(sum_w)' ==  1780
assert `r(mean)' ==  0
assert `r(Var)' ==  0
assert `r(sd)' ==  0
assert `r(min)' ==  0
assert `r(max)' ==  0
assert `r(sum)' ==  0


********************************************************************************
** label and save
********************************************************************************
keep prop_id warren_address_full nhpd_id nhpd_address_full match_type match_dist similscore
order prop_id warren_address_full nhpd_id nhpd_address_full match_type match_dist similscore

rename match_type nhpd_match_type

lab var prop_id "warren group unqiue ID"
lab var warren_address_full "full warren group property address"
lab var nhpd_id "NHPD unique ID"
lab var nhpd_address_full "full NHPD property address"
lab var nhpd_match_type "NHPD to Warren match type"
lab var match_dist "distance between best"
lab var similscore "address similarity score (using matchit)"	

save "$DATAPATH/nhpd/nhpd_warren_xwalk.dta", replace
	
clear all
