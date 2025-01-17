********************************************************************************
* File name:		'12_res_types.do'		
*
* Project title:	Boston Affordable Housing Project (visiting scholar)
*
* Description:		Fills in missing property use codes for the annual 
*			assessor file and creates a new residential property 
*			type variable that identifies only dwelling unit 
*			properties in warren data. Drops any other observations 
*			that are non-residential.
* 				
* Inputs:		none			
* Outputs:		none
*
* Created:		02/26/2021
* Last updated:		10/18/2022
********************************************************************************

********************************************************************************
** add in missing use codes (changes in annual file only)
********************************************************************************
tab prop_usage if usecode == ""
assert `r(N)' == 7427308
assert `r(r)' == 5

* assign use codes to missing but identifiable properties
local pairs `" "101_1-Fam Res" "117_1-4 Fam Res" "104_2-Fam Res" "105_3-Fam Res" "102_Condominium" "'

foreach pair of local pairs {
	local CODE = substr("`pair'",1,3)
	local TYPE = substr("`pair'",5,.)
	
	noisily display "Adding usecode = '`CODE'' if property type is '`TYPE''"
	replace usecode = "`CODE'" if prop_usage == "`TYPE'"
}

drop if usecode == ""


********************************************************************************
** create a residential property only use code
********************************************************************************
* gen property use code type
gen residential_code = ""

* replace with residential and mixed use residential codes
replace residential_code = usecode if regexm(usecode,"^[0]?[1][0-9]$")==1 // mixed-use, primarily residential
replace residential_code = usecode if regexm(usecode,"^[0]?[1-9][1]$")==1 // mixed-use, primarily non-residential
replace residential_code = usecode if regexm(usecode,"^[1][0-9][0-9]$")==1 // residential use codes

* replace with miscallaneous residential property codes
replace residential_code = "959" if usecode=="959" // charitable housing
replace residential_code = "970" if usecode=="970" // housing authority
replace residential_code = "973" if usecode=="973" // housing authority, vacant

destring residential_code, replace

* define value label
#delimit ;
lab define residential_code_lbl
	10 "Mixed-Use, (1) Residential, (2) Unknown"
	13 "Mixed-Use, (1) Residential, (2) Commercial"
	14 "Mixed-Use, (1) Residential, (2) Industrial"
	16 "Mixed-Use, (1) Residential, (2) Forest"
	17 "Mixed-Use, (1) Residential, (2) Agriculture"
	18 "Mixed-Use, (1) Residential, (2) Recreational"
	19 "Mixed-Use, (1) Residential, (2) Exempt"
	21 "Mixed-Use, (1) Open-Space, (2) Residential"
	31 "Mixed-Use, (1) Commercial, (2) Residential"
	41 "Mixed-Use, (1) Industrial, (2) Residential"
	61 "Mixed-Use, (1) Forest, (2) Residential"
	71 "Mixed-Use, (1) Agriculture, (2) Residential"
	81 "Mixed-Use, (1) Recreation, (2) Residential"

	100 "Possible New Construction"
	101 "Single Family"
	102 "Condominium"
	103 "Mobile Home"
	104 "Two-Family"
	105 "Three-Family"
	106 "Accessory Land + Improvements"
	107 "(Intentionally Left Blank) Res Other"
	108 "(Intentionally Left Blank) Dock Condo"
	109 "Multuple Homes, One Parcel"
	110 "Not listed (Apartment Bldng?)"
	111 "4-8 Units Res"
	112 "9+ Units Res"
	114 "Aff. Units >50% units qualifying (see prop class)" 

	115 "Apartment Use Other (from Warren)"
	116 "Residential Parking Garage (from Warren)"
	117 "1-4 Family Residence (from Warren)"
	118 "Elderly Home (from Warren)"
	119 "Apartment Building (from Warren)"
	120 "2-5 Family Residence (from Warren)"

	121 "Rooming and Boarding Houses"
	122 "Fraternity and Sorority Houses"
	123 "Residence Halls and Dormitories"
	124 "Rectories, Convents, Monasteries"
	125 "Other Congregate Housing incl. non transient"

	126 "Subsidized Housing (from Warren)"
	129 "<129> unknown code"
	130 "Residential Developable Land"
	131 "Residential Potentially Developable Land"
	132 "Residential Undevelopable Land"
	140 "Child Care (from Warren)"
	160 "<160> unknown code"
	172 "Condo Parking Garage (from Warren)"
	182 "Deeded Slip (from Warren)"
	199 "Condo Building (from Warren)"

	959 "Charitable Service, Housing, Other"
	970 "Housing Authority"
	973 "Housing Authority, Vacant" ;
#delimit cr
lab val residential_code residential_code_lbl
lab var residential_code "prop use codes (residential only)"

* drop missing residential codes
drop if residential_code==.
	
* error checks
sum residential_code
assert `r(N)' ==  25802641
assert `r(sum_w)' ==  25802641
assert `r(mean)' ==  102.2893652630364
assert `r(Var)' ==  710.6202428384247
assert `r(sd)' ==  26.65746129770096
assert `r(min)' ==  10
assert `r(max)' ==  973
assert `r(sum)' ==  2639335770
	
	
********************************************************************************
** re-assign residential codes from select groups
********************************************************************************
* define codes to be reassigned
local reassigns 109 115 117 119 120

* store value labels
local vlabs: value label residential_code

foreach x in `reassigns'{
	local vlab: label `vlabs' `x'

	display "Reassigning '`vlab'' properties based on unit count..."
	
	replace residential_code = 101 if residential_code==`x' & num_units==1 // reassign as single family
	
	replace residential_code = 104 if residential_code==`x' & num_units==2 // reassign as two family
	
	replace residential_code = 105 if residential_code==`x' & num_units==3 // reassign as three family
	
	replace residential_code = 111 if residential_code==`x' & num_units>=4 & num_units<=8 // reassign as 4-8 unit
	
	replace residential_code = 112 if residential_code==`x' & num_units>=9	// reassign as 9+ unit
}

* adjust number of units to conform with residential code
replace num_units = 1 if residential_code == 101 // single-fam should have 1 unit
replace num_units = 2 if residential_code == 104 // two-fam should have 2 units
replace num_units = 3 if residential_code == 105 // three-fam should have 3 units
replace num_units = 4 if residential_code == 111 & num_units < 4 // set floor at 4 units
replace num_units = 8 if residential_code == 111 & num_units > 8 // set cap at 8 units
replace num_units = 9 if residential_code == 112 & num_units < 9 // set floor at 9 units

replace num_units = 2 if residential_code == 120 & num_units < 2 // set ceiling at 2 units
replace num_units = 5 if residential_code == 120 & num_units > 5 // set floor at 5 units

* error checks
sum residential_code
assert `r(N)' ==  25802641
assert `r(sum_w)' ==  25802641
assert `r(mean)' ==  102.2695303554392
assert `r(Var)' ==  710.4981032381846
assert `r(sd)' ==  26.65517029092451
assert `r(min)' ==  10
assert `r(max)' ==  973
assert `r(sum)' ==  2638823977


********************************************************************************
** Condensed res type variable for use in analysis
********************************************************************************
* create new collapsed residential type variable
gen res_type = .	

lab define res_type_lbl ///
	1 "Single Family Res" ///
	2 "Two Family Res" ///
	3 "Three Family Res" ///
	4 "4-8 Unit Res" ///
	5 "9+ Unit Res" ///
	6 "Condominiums" ///
	7 "Mixed-Use, Primarily Residential" ///
	8 "Mixed-Use, Primairly Non-Residential" ///
	9 "Subsidized/Affordable Housing" ///
	10 "Elderly Housing" ///
	11 "Non-transient Housing", replace
	
lab val res_type res_type_lbl

* res_type: single-family assignment
local res_type_1 101
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_1'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 1
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 1 if residential_code==`x'
}

* res_type two-family assignment
local res_type_2 104
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_2'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 2
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 2 if residential_code==`x'
}

* res_type three-family assignment
local res_type_3 105
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_3'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 3
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 3 if residential_code==`x'
}

* res_type 4-8 unit assignment
local res_type_4 111
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_4'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 4
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 4 if residential_code==`x'
}

* res_type 9+ unit assignment
local res_type_5 112
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_5'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 5
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 5 if residential_code==`x'
}

* res_type Condominium assignment
local res_type_6 102 199
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_6'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 6
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 6 if residential_code==`x'
}

* res_type Mixed-Use, Primarily Residential
local res_type_7 10 13 14 18 19
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_7'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 7
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 7 if residential_code==`x'
}

* res_type Mixed-Use, Primairly Non-Residential
local res_type_8 21 31 41 81
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_8'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 8
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 8 if residential_code==`x'
}

* res_type Subsidized/Affordable Housing assignment
local res_type_9 114 126 959 970
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_9'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 9
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 9 if residential_code==`x'
}

* res_type Elderly Housing assignment
local res_type_10 118

foreach x in `res_type_10'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 10
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 10 if residential_code==`x'
}

* res_type Non-transient housing assignment
local res_type_11 121 125
local old_vlabs: value label residential_code
local new_vlabs: value label res_type

foreach x in `res_type_11'{
	
	local old_vlab: label `old_vlabs' `x'
	local new_vlab: label `new_vlabs' 11
	
	display "Reassigning '`old_vlab'' properties as `new_vlab'..."
	
	replace res_type = 11 if residential_code==`x'
}

* error checks
sum res_type
assert `r(N)' ==  25031254
assert `r(sum_w)' ==  25031254
assert `r(mean)' ==  2.035133597381897
assert `r(Var)' ==  3.670072695896832
assert `r(sd)' ==  1.915743379447475
assert `r(min)' ==  1
assert `r(max)' ==  11
assert `r(sum)' ==  50941946

*** END OF 12_res_types.do ***
