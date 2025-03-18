clear all

** S:/ Drive Version **

********************************************************************************
* File name:		62_ch40b_warren_xwalk.do
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Assigns Chapter 40B records to Warren Group properties	
*			based on address. 
*			Order of assignment is as follows:
*				1 - direct address match
*				2 - closest property within boundary id
*				3 - closest proximity match is <=.01 mi
*				4 - best fuzzy address match has similscore of >=.9
*				5 - best fuzzy address match has similscore score <.9
*			Similarity based on street number and street name.Matches 
*			are unrestricted so they can be assigned to any
*			address regardless of what the residential type is in 
*			Warren. This means that some CH40B properties get 
*			assigned to non-MF type properties.
*
*			In the CH40B dataset there are some records that do not
*			match to specific addreses but instead are assigned to 
*			all addresses on a street. These are mostly sub-developments
*			where CH40B was used to help qualify the whole development.
* 				
* Inputs:		./chapter40b_clean.dta
*			./warren_MA_all_unique.dta
*				
* Outputs:		./ch40b_to_warren_xwalk.dta
*
* Created:		02/28/2021
* Last updated:		11/21/2022
********************************************************************************

********************************************************************************
* load Chapter 40B data
********************************************************************************
use "$DATAPATH/chapter40B/chapter40b_mapc.dta", clear

* check observation count
assert _N == 1932

merge 1:1 unique_id using "$DATAPATH/closest_boundary_matches/closest_boundary_matches_ch40b_with_regs.dta", keepusing(boundary_using_id boundary_using_side)

	* validate merge
	sum _merge
	return list
	assert `r(N)' ==  1932
	assert `r(sum_w)' ==  1932
	assert `r(mean)' ==  2.152173913043478
	assert `r(Var)' ==  .9773489743993875
	assert `r(sd)' ==  .9886096167847992
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  4158

* gen address matching variables
replace ch40b_address = upper(ch40b_address)

replace ch40b_city = upper(ch40b_city)

drop if regexm(ch40b_address, "[;]")==1 // drops lingering combo addresses (drops 4)

replace ch40b_address = strtrim(ch40b_address) // trims whitespace

list ch40b_address if regexm(ch40b_address, "^[\*]")==1

replace ch40b_address = regexr(ch40b_address, "(RUSSEL PL)$","RUSSELL PL")

gen matching_address = ch40b_address + " " + ch40b_city

* trim dataset
keep unique_id ch40b_id ch40b_address matching_address ch40b_city MUNI state_fip county_fip census_tract block_group ch40b_lat ch40b_lon boundary_using_id boundary_using_side SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued 
order unique_id ch40b_id ch40b_address matching_address ch40b_city MUNI state_fip county_fip census_tract block_group ch40b_lat ch40b_lon boundary_using_id boundary_using_side SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued 

* store the multi-address matches separately (these will count as direct address matches)
preserve

	keep if regexm(ch40b_address, "^[\*]")==1

	gen street = ch40b_address

	replace street = regexr(street, "^(\* )","")

	replace street = strtrim(street)

	gen cousub_name = ch40b_city

	gen match_type = "99"

	assert _N == 33

	* temp save
	tempfile multi_address
	save `multi_address', replace

restore

* merge back on the multi address matches
merge 1:1 unique_id using `multi_address'

	* validate merge
	sum _merge
	assert `r(N)' ==  1928
	assert `r(sum_w)' ==  1928
	assert `r(mean)' ==  1.034232365145228
	assert `r(Var)' ==  .0673277965233082
	assert `r(sd)' ==  .259476003752386
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  1994
	
	* drop multi_address observations
	drop if _merge==3
	drop _merge

* keep unique addresses
bysort matching_address (unique_id): keep if _n==_N

* error check
assert _N == 1894

unique unique_id
assert `r(unique)' == `r(N)'

sum unique_id
assert `r(N)' ==  1894
assert `r(sum_w)' ==  1894
assert `r(mean)' ==  1705.739176346357
assert `r(Var)' ==  1032750.552114694
assert `r(sd)' ==  1016.243352802218
assert `r(min)' ==  1
assert `r(max)' ==  3475
assert `r(sum)' ==  3230670

* temp save
tempfile ch40b
save `ch40b', replace


********************************************************************************
** load Warren data
********************************************************************************
use "$DATAPATH/warren/warren_MAPC_all_unique", clear

* add boundary IDs
merge m:1 prop_id using "$DATAPATH/closest_boundary_matches/closest_boundary_matches_with_regs.dta", keepusing(boundary_using_id boundary_using_side)

	* validate merge
	sum _merge
	assert `r(N)' ==  821237
	assert `r(sum_w)' ==  821237
	assert `r(mean)' ==  2.410657337650398
	assert `r(Var)' ==  .8313615633623175
	assert `r(sd)' ==  .911790306683679
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  1979721

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
** direct address matches
********************************************************************************
* merge on chapter40b addresses	
merge m:1 matching_address using `ch40b'

	* validate merge
	sum _merge
	assert `r(N)' ==  822342
	assert `r(sum_w)' ==  822342
	assert `r(mean)' ==  1.003897405215835
	assert `r(Var)' ==  .0064359053194274
	assert `r(sd)' ==  .0802240943820957
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  825547

	drop match_type

* store direct address matches
preserve
	
	keep if _merge==3
	
	keep prop_id unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat matching_address warren_address_full
	
	order prop_id unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat matching_address warren_address_full
	
	gen match_type = "1"
	
	* error check
	assert _N == 1050
	
	* temp save
	tempfile direct_matches
	save `direct_matches', replace

restore

* store unmatched ch40b properties
preserve
	
	keep if _merge==2
	
	keep unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued boundary* matching_address
	
	order unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued boundary* matching_address
	
	replace boundary_using_side = "NO BOUNDARY" if boundary_using_id==.
	
	assert _N == 1105
	
	* temp save
	tempfile round2
	save `round2', replace

restore


********************************************************************************
* multi address merge
********************************************************************************
keep if _merge==1

drop _merge unique_id ch40b_id ch40b_address ch40b_city census_tract block_group ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued MUNI

replace street = upper(street)

replace cousub_name = upper(cousub_name)

merge m:1 street cousub_name using `multi_address', // hastings way not matched

	* validate merge
	sum _merge
	assert `r(N)' ==  820188
	assert `r(sum_w)' ==  820188
	assert `r(mean)' ==  1.003163908762381
	assert `r(Var)' ==  .006316595674842
	assert `r(sd)' ==  .079477013499766
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  822783

* store additional multi-matches
preserve

	keep if _merge==3

	keep prop_id unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued matching_address match_type

	order prop_id unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued matching_address match_type

	append using `direct_matches'

	save `direct_matches', replace
	
restore


********************************************************************************
** keep remaining warren group properties for secondary matches
********************************************************************************
keep if _merge==1

drop _merge unique_id ch40b_id ch40b_address ch40b_city census_tract block_group ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued MUNI

gen w_boundary_using_id = boundary_using_id 

gen w_boundary_using_side = boundary_using_side

joinby boundary_using_id boundary_using_side using `round2', unmatched(both) _merge(join_merge)
	
	* validate joinby
	sum join_merge
	assert `r(N)' ==  849833
	assert `r(sum_w)' ==  849833
	assert `r(mean)' ==  1.21451626378359
	assert `r(Var)' ==  .3824450498021493
	assert `r(sd)' ==  .6184214176450791
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  1032136
	
	tab join_merge

* store remaining unmatched ch40b properties
preserve

	keep if join_merge==2

	keep unique_id ch40b_id ch40b_address ch40b_lat ch40b_lon boundary_using_id boundary_using_side
	order unique_id ch40b_id ch40b_address ch40b_lat ch40b_lon boundary_using_id boundary_using_side
	
	merge 1:1 unique_id using "$DATAPATH/chapter40B/chapter40b_mapc.dta", keepusing(state_fip county_fip census_tract block_group ch40b_city)
	
		* validate merge
		sum _merge
		assert `r(N)' ==  1932
		assert `r(sum_w)' ==  1932
		assert `r(mean)' ==  2.251035196687371
		assert `r(Var)' ==  .1881138941515408
		assert `r(sd)' ==  .4337209865242179
		assert `r(min)' ==  2
		assert `r(max)' ==  3
		assert `r(sum)' ==  4349

	gen cousub_name = upper(ch40b_city)
	
	gen matching_geoid = state_fip+county_fip+census_tract+block_group
	
	keep if _merge==3 
	
	drop _merge
	
	tempfile round3
	save `round3', replace
	
restore

// stop
// tempfile save_point
// save `save_point', replace


********************************************************************************		
** closest within boundary match 
** among non direct matches, find the closest and best proxy
********************************************************************************
preserve
	
	keep if join_merge==3

	* calculate distance between properties
	vincenty warren_latitude warren_longitude ch40b_lat ch40b_lon, hav(match_dist)

	* gen a count variable 
	gen n = 1

	* gen full warren address variable	
	gen warren_address = string(st_num) + " " + upper(street) + " " + upper(cousub_name)
		
	* sort the closest match, than the first address, than the first prop_id
	bysort unique_id (match_dist warren_address prop_id): gen tag_closest = 1 if _n==1

		tab tag_closest
		
		drop if tag_closest!=1
		
		* check for conflicts
		bysort warren_address match_dist: egen a = sum(n)
		
		tab a
		
		bysort warren_address match_dist ch40b_address: egen b = sum(n)
		
		tab b
		
		* before finding the best match, I will need to sort by the first ch40b address
		bysort warren_address: egen sum_tag_closest = sum(tag_closest)	
		
		tab sum_tag_closest
		
		bysort warren_address (match_dist ch40b_address): gen tag_closest_w = 1 if _n==1

		keep if tag_closest_w==1

		drop n tag_closest a b sum_tag_closest tag_closest_w
		
		drop match_type
		
		gen match_type = "2"

		tab match_type
		
		* error check
		sum prop_id
		assert `r(N)' ==  493
		assert `r(sum_w)' ==  493
		assert `r(mean)' ==  1572518.673427992
		assert `r(Var)' ==  2689805098408.436
		assert `r(sd)' ==  1640062.528810544
		assert `r(min)' ==  30094
		assert `r(max)' ==  5049383
		assert `r(sum)' ==  775251706

		sum unique_id
		assert `r(N)' ==  493
		assert `r(sum_w)' ==  493
		assert `r(mean)' ==  1580.202839756592
		assert `r(Var)' ==  831221.6173089925
		assert `r(sd)' ==  911.7135609987341
		assert `r(min)' ==  1
		assert `r(max)' ==  3475
		assert `r(sum)' ==  779040
		
	tempfile boundary_matches
	save `boundary_matches', replace

restore


********************************************************************************		
** closest within city match
** among non direct matches, find the closest and best proxy
********************************************************************************
keep if join_merge==1

drop join_merge unique_id ch40b_id ch40b_address ch40b_city ch40b_lon ch40b_lat SHIUnits CompPermit YrEnd OwnorRent SubsidizingAgency DateCompPermitIssued

joinby cousub_name using `round3', unmatched(both) _merge(join_merge)
	
	* validate merge
	sum join_merge
	assert `r(N)' ==  4979860
	assert `r(sum_w)' ==  4979860
	assert `r(mean)' ==  2.916045832613768
	assert `r(Var)' ==  .160860064853074
	assert `r(sd)' ==  .4010736401872778
	assert `r(min)' ==  1
	assert `r(max)' ==  3
	assert `r(sum)' ==  14521500

	tab join_merge
	keep if join_merge==3

* gen geoid
gen ch40b_geoid = state_fip+county_fip+census_tract+block_group
	
* gen full warren address
gen warren_address = string(st_num) + " " + upper(street)
		
* gen property distance
vincenty warren_latitude warren_longitude ch40b_lat ch40b_lon, hav(match_dist)

* gen similarity score
matchit warren_address ch40b_address

gen inverse_similscore = 1 - similscore	

// stop
// tempfile save_point
// save `save_point', replace


/* Proximity and similarity matching overview:
CH40B records are tagged to their closest Warren record if the distance is <=.01 miles.
If a Warren record has multiple closest CH40B matches, the best (closest) is used,
with the rest being dropped. 

For the remaining matches, they are classified as the most similar based with a 
similscore>=.9 (fuzzy1) and similscore<.9 (fuzzy2). As before if a Warren record
has multple similar CH40B matches, the best is used (highest similscore). 

To avoid conflicts when an CH40B property is an equal shortest distance or has 
the same close score between two Warren addresses the first address or property ID
is used. So within NHPD matches, they are sorted first by distance then by 
warren_address_full then by prop_id. Likewise if a Warren address has two
conflicts. The first CH40B address is used. 

This ensures the results of the match are the same every time. 
*/

********************************************************************************
** proximity match
********************************************************************************
bysort unique_id (match_dist warren_address prop_id): gen tag_prox = 1 if _n==1 & match_dist<=.1

********************************************************************************
** fuzzy match 1 (>=.9)
********************************************************************************
bysort unique_id (inverse_similscore warren_address prop_id): gen tag_fuzzy1 = 1 if _n==1 & similscore>=.9

********************************************************************************
** fuzzy match 1 (<.9)
********************************************************************************
bysort unique_id (inverse_similscore warren_address prop_id): gen tag_fuzzy2 = 1 if _n==1 & similscore<.9

* keeps only those with a match in 1 of the 3 categories
keep if tag_prox==1 | tag_fuzzy1==1 | tag_fuzzy2==1


* <a> counts the number of best CH40B matches (based on proximity)
bysort warren_address: egen a = sum(tag_prox)
	tab a
	drop a

* if there are conflicts, tag the first CH40B address
bysort warren_address (match_dist ch40b_address): gen tag_prox_w = 1 if _n==1

* drop closest CH40B matches that are not also the closest to the Warren address
drop if tag_prox==1 & tag_prox_w==. 

* clear the fuzzy matches if there was a proximity match found
replace tag_fuzzy1 = . if tag_prox==1
replace tag_fuzzy2 = . if tag_prox==1

* conflict checks: <a> counts the number of best matches (based on similscore)
bysort warren_address: egen a = sum(tag_fuzzy1)
	tab a
	drop a

bysort warren_address: egen a = sum(tag_fuzzy2)
	tab a
	drop a
	
* if there are conflicts, tag the first NHPD address		
bysort warren_address (inverse_similscore ch40b_address): gen tag_fuzzy_w = 1 if _n==1

* drop NHPD matches that are not also the best match to the Warren address
drop if tag_fuzzy1==1 & tag_fuzzy_w==.
drop if tag_fuzzy2==1 & tag_fuzzy_w==.

bysort unique_id (tag_prox tag_fuzzy1 tag_fuzzy2): keep if _n==1

* categorize the match types
replace match_type = "3" if tag_prox==1
replace match_type = "4" if tag_fuzzy1==1
replace match_type = "5" if tag_fuzzy2==1

tab match_type

* error checks
assert _N == 462

unique unique_id
assert `r(unique)' == `r(N)'

unique prop_id
assert `r(unique)' == `r(N)'

sum prop_id
assert `r(N)' ==  462
assert `r(sum_w)' ==  462
assert `r(mean)' ==  1423591.073593074
assert `r(Var)' ==  2268067492467.552
assert `r(sd)' ==  1506010.455630223
assert `r(min)' ==  4437
assert `r(max)' ==  5057638
assert `r(sum)' ==  657699076

sum unique_id
assert `r(N)' ==  462
assert `r(sum_w)' ==  462
assert `r(mean)' ==  1687.619047619048
assert `r(Var)' ==  1039365.221154839
assert `r(sd)' ==  1019.492629279309
assert `r(min)' ==  9
assert `r(max)' ==  3474
assert `r(sum)' ==  779680


********************************************************************************
** add on direct address and boundary matches
********************************************************************************
append using `direct_matches'

append using `boundary_matches'


********************************************************************************
** data clean up and labeling
********************************************************************************
* code up direct address match
replace match_type = "1" if match_type=="direct address match"

destring match_type, replace
	
* code up the multi-address matches as direct matches
replace match_type = 1 if match_type==99

* check that these are unique
bysort prop_id (match_type): keep if _n==1

* value label match typ variable
label define match_type_lbl ///
	1 "direct address match" ///
	2 "closest match within boundary id" ///
	3 "closest match ONLY (<=.01 mi)" ///
	4 "highest similscore ONLY (>=.9)" ///
	5 "similscore ONLY (<.9)" ///
	6 "no warren<->CH40B match" ///
	99 "multi-direct address match", replace

lab val match_type match_type_lbl

tab match_type
	
* results from older original run of program (10/26/2021??)
*                       match_type |      Freq.     Percent        Cum.
* ---------------------------------+-----------------------------------
*             direct address match |      2,347       71.08       71.08
* closest match within boundary id |        493       14.93       86.01
*    closest match ONLY (<=.01 mi) |        269        8.15       94.16
*   highest similscore ONLY (>=.9) |         47        1.42       95.58
*            similscore ONLY (<.9) |        146        4.42      100.00
* ---------------------------------+-----------------------------------
*                            Total |      3,302      100.00


********************************************************************************
** error checks
********************************************************************************
sum prop_id
assert `r(N)' ==  3302
assert `r(sum_w)' ==  3302
assert `r(mean)' ==  2840983.576014536
assert `r(Var)' ==  3909746425602.423
assert `r(sd)' ==  1977307.873246456
assert `r(min)' ==  2774
assert `r(max)' ==  5066249
assert `r(sum)' ==  9380927768

sum unique_id
assert `r(N)' ==  3302
assert `r(sum_w)' ==  3302
assert `r(mean)' ==  1708.752574197456
assert `r(Var)' ==  1233581.526462623
assert `r(sd)' ==  1110.667153769582
assert `r(min)' ==  1
assert `r(max)' ==  3475
assert `r(sum)' ==  5642301

sum match_type
assert `r(N)' ==  3302
assert `r(sum_w)' ==  3302
assert `r(mean)' ==  1.531798909751666
assert `r(Var)' ==  1.028222088602265
assert `r(sd)' ==  1.0140128641207
assert `r(min)' ==  1
assert `r(max)' ==  5
assert `r(sum)' ==  5058


********************************************************************************
** end
********************************************************************************
* keep and order variables
rename match_type ch40b_match_type 	
keep prop_id unique_id ch40b_id ch40b_address ch40b_lat ch40b_lon warren_address ch40b_match_type match_dist similscore
order prop_id unique_id ch40b_id ch40b_address ch40b_lat ch40b_lon warren_address ch40b_match_type match_dist similscore

lab var prop_id "warren group unqiue ID"
lab var unique_id "constructed unique ch40b ID"
lab var ch40b_id "ch40b property ID"
lab var ch40b_match_type "ch40b to Warren match type"
lab var match_dist "distance between best"
lab var similscore "address similarity score (using matchit)"	

save "$DATAPATH/chapter40B/chapter40b_warren_xwalk.dta", replace

clear all
