********************************************************************************
* File name:		'13_condo_collapse.do'		
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Collapses the condo records into one property record if 
*			they share an address. For condo properties that share 
*			addresses the first record in the set is kept so 
*			owenership and unit details may be inaccurate but total 
*			unit counts will be estimated as either the max number 
*			of units, or total count, whichever is greater.
* 				
* Inputs:		none			
* Outputs:		none
*
* Created:		02/26/2021
* Last updated:		10/18/2022
********************************************************************************

********************************************************************************
** create unique condo unit record ID
********************************************************************************
sort fy city zipcode street st_num

* create unique ID per condo address record
egen condo_id = group(city zipcode street st_num) if res_type==6

replace condo_id = . if res_type!=6

********************************************************************************
** estimate condo unit totals
********************************************************************************
egen condo_units_max = max(num_units), by(fy condo_id) // maximum number of units listed

replace condo_units_max=. if condo_id==.

egen condo_units_count = count(num_units), by(fy condo_id) // total count of records (1 unit per record)

replace condo_units_count=. if condo_id==.

* take the max condo units or total count, which ever is bigger
egen condo_units_total = rowmax(condo_units_max condo_units_count)

replace condo_units_total=. if condo_id==.

********************************************************************************
** drop excess condo records
********************************************************************************
* number condo records in order of prop_id
bysort fy condo_id (prop_id): gen condo_recnum = _n

replace condo_recnum = . if condo_id==.

* drop if no condo record num does not equal 1
drop if condo_recnum != 1 & condo_recnum != .

* replace num units equals total number of condo units
replace num_units = condo_units_total if res_type==6
	
* error checks
count if res_type == 6
assert `r(N)' == 1498259

sum res_type
assert `r(N)' ==  22523394
assert `r(sum_w)' ==  22523394
assert `r(mean)' ==  1.593666833693004
assert `r(Var)' ==  2.133466039032931
assert `r(sd)' ==  1.46063891466472
assert `r(min)' ==  1
assert `r(max)' ==  11
assert `r(sum)' ==  35894786

sum num_units if res_type == 6	
assert `r(N)' ==  1498259
assert `r(sum_w)' ==  1498259
assert `r(mean)' ==  3.295723236102703
assert `r(Var)' ==  182.209623379805
assert `r(sd)' ==  13.49850448678686
assert `r(min)' ==  1
assert `r(max)' ==  744
assert `r(sum)' ==  4937847

*** END OF 13_condo_collapse.do ***
