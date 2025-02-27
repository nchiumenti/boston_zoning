********************************************************************************
** data setup file for RD graphs
********************************************************************************
* load the main dataset
// clear all

// use "$DATAPATH/final_dataset_10-28-2021.dta", clear

drop if res_type==. // drop non-residential props

drop if fy < 2010 | fy > 2018 // report focuz is 2010 to 2018

drop if boundary_using_id == . // drop properties without an assigned boundary

drop costar_rent costar_status	

gen year = fy

* summarize loaded data set
tab fy

tab res_type

* merge on file with distance to closest school/river/road
merge m:1 prop_id using "$DATAPATH/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta", keepusing(closest_*)
	drop if _merge==2
	drop _merge

* convert house prices into 2019 prices: Deflated House Prices
merge m:1 year using "$DATAPATH/fred_cpi/CPI_2019.dta" // NFC - changed to m:1 merge
	drop if _merge == 2 // NFC - not all years match
	drop _merge 

* merge in Co-Star variables
destring costar_id, replace

merge m:1 costar_id using "$DATAPATH/costar/costar_mf_destring.dta" 
	drop if _merge==2 // NFC - not all CoStar properties match
	drop _merge 
	
	* add historic rents and replace when not missing
	merge m:1 fy costar_id using "$DATAPATH/costar/costar_rent_hist.dta" , keepusing(costar_rent)
		drop if _merge==2
		drop _merge
		
	destring costar_rent, replace
	
	replace AvgAskingUnit = costar_rent if costar_rent!=.
	
	
replace AvgAskingUnit = AvgAskingUnit/fred_cpi

* merge in ACS Data
gen GEOID = substr(warren_GEOID_full,1,12) // NFC

gen census_tract2010 = substr(warren_GEOID_full,6,6) // NFC

destring census_tract2010, replace // NFC

merge m:1 GEOID year using "$DATAPATH/acs/acs_amenities.dta" 
	drop if _merge==2 // NFC - not all geoids match
	drop _merge 

	
********************************************************************************
** Variable Setup
********************************************************************************
gen def_houseprice = assd_totval/fred_cpi

decode res_type, generate(res_typex)

gen fam23_1 = 0 if res_typex=="Single Family Res"
replace fam23_1 = 1 if (res_typex=="Two Family Res" | res_typex=="Three Family Res" ) 

gen fam4plus_1 = 0 if res_typex=="Single Family Res"
replace fam4plus_1 = 1 if (res_typex=="4-8 Unit Res" | res_typex=="9+ Unit Res" ) 

gen MU_2 = 0 if (res_typex!="Mixed-Use, Primairly Non-Residential" | res_typex!="Mixed-Use, Primarily Residential")
replace MU_2 = 1 if (res_typex=="Mixed-Use, Primairly Non-Residential" | res_typex=="Mixed-Use, Primarily Residential")

* impute units if 0 for cases where it's clear
replace num_units = 1 if res_typex == "Single Family Res" & num_units == 0

replace num_units = 2 if res_typex == "Two Family Res" & num_units == 0

replace num_units = 3 if res_typex == "Three Family Res" & num_units == 0

* encode string variables
encode build_style, gen(build_style1)

encode condition, gen(condition1)

encode ext_cover, gen(ext_cover1)

encode fuel_type, gen(fuel_type1)

encode heat_type, gen(heat_type1)

encode roof_type, gen(roof_type1)

* standardize height and dupac
gen height = home_mxht_eff // NFC
gen dupac = home_dupac_eff // NFC
gen mf_allowed = home_mulfam // NFC

sum height
local a = r(mean)
local b = r(sd)
gen std_he = (height - `a')/`b'
label var std_he "Standardized height"
sum dupac 
local a = r(mean)
local b = r(sd)
gen std_du = (dupac - `a')/`b'
label var std_du "Standardized DUPAC"

replace height = height/10 // show in units of 10 feet

*gen height_2 = height^2
gen dupac_2 = dupac^2

gen lot_acres = lot_sizesqft/43560

gen byright_he = 0 if height==0 
replace byright_he = 1 if height!=0 

gen byright_du = 0 if dupac==0 
replace byright_du = 1 if dupac!=0 

gen lam_seg = boundary_using_id
by lam_seg boundary_side, sort : gen blah = _n ==1 
by lam_seg, sort : egen blah_sum = total(blah) 
tab blah_sum

keep if blah_sum==2   // Drop the boundaries where the other side has no observations

* NFC - theta_sf and theta_gd
gen theta_sf = density_sf 
gen theta_gd = density_gentle
gen theta_hd = density_hard

* NFC - regulation variables
gen mf_delta = home_mulfam - nn_mulfam  
gen he_delta = home_mxht_eff - nn_mxht_eff
gen du_delta = home_dupac_eff - nn_dupac_eff 

gen only_mf = mf_delta != 0 & he_delta == 0 & du_delta == 0
gen only_he = he_delta != 0 & mf_delta == 0 & du_delta == 0
gen only_du = du_delta != 0 & he_delta == 0 & mf_delta == 0 
gen mf_he = mf_delta != 0 & he_delta != 0 & du_delta == 0
gen mf_du = mf_delta != 0 & he_delta == 0 & du_delta != 0
gen du_he = mf_delta == 0 & he_delta != 0 & du_delta != 0
gen mf_he_du = mf_delta != 0 & he_delta != 0 & du_delta != 0

*definition of which side of the boundary is relaxed
*treatment is: relaxing the regulation
*height (more height = relaxed)
*du (more density = relaxed)
*mf (allowing mf = relaxed)

gen own_du = home_dupac_eff // NFC
gen other_du = nn_dupac_eff // NFC

gen own_he = home_mxht_eff // NFC
gen other_he = nn_mxht_eff // NFC

sum own_du
local a = r(mean)
local b = r(sd)
gen std_du_own = (own_du - `a')/`b'
sum own_he
local a = r(mean)
local b = r(sd)
gen std_he_own = (own_he - `a')/`b'

sum other_du
local a = r(mean)
local b = r(sd)
gen std_du_other = (other_du - `a')/`b'
sum other_he
local a = r(mean)
local b = r(sd)
gen std_he_other = (other_he - `a')/`b'

*easy cases and letting MF allowed dominating other regulations
gen relaxed = 0
 
replace relaxed = 1 if only_he == 1 & he_delta>0
replace relaxed = 1 if only_du == 1 & du_delta>0
replace relaxed = 1 if only_mf == 1 & mf_delta==1

replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed = 1 if mf_du == 1 & mf_delta == 1 & du_delta<0   // flip this in relaxed2

*multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed = 1 if mf_he == 1 & mf_delta == 1 & he_delta<0

*this is only the clear case
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

*when two of 3 are relaxed, count as relaxed
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0

*letting height and dupac dominate mf allowed
gen relaxed2 = 0
replace relaxed2 = 1 if only_he == 1 & he_delta>0
replace relaxed2 = 1 if only_du == 1 & du_delta>0
replace relaxed2 = 1 if only_mf == 1 & mf_delta==1

replace relaxed2 = 1 if du_he == 1 & he_delta>0 & du_delta>0
replace relaxed2 = 1 if du_he == 1 & he_delta>0 & du_delta<0 & (abs(std_du_own - std_du_other)<abs(std_he_own-std_he_other))
replace relaxed2 = 1 if du_he == 1 & he_delta<0 & du_delta>0 & (abs(std_du_own - std_du_other)>abs(std_he_own-std_he_other))

replace relaxed2 = 1 if mf_du == 1 & mf_delta == 1 & du_delta>0
replace relaxed2 = 1 if mf_du == 1 & mf_delta == -1 & du_delta>0  

*multifamily x height are too few boundaries for us to look at, so probably skip in practice
replace relaxed2 = 1 if mf_he == 1 & mf_delta == 1 & he_delta>0
replace relaxed2 = 1 if mf_he == 1 & mf_delta == -1 & he_delta>0

*this is only the clear case
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta>0

*when two of 3 are relaxed, count as relaxed
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta>0 & du_delta<0
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == 1 & he_delta<0 & du_delta>0
replace relaxed2 = 1 if mf_he_du == 1 & mf_delta == -1 & he_delta>0 & du_delta>0

*differential running var on either side (SUBSTITUTE RELAXED OR RELAXED2 DEPENDING ON whAT WE DECIDE)
gen dist = boundary_dist
gen dist_1 = boundary_dist // NFC
gen dist_2 = boundary_dist^2 // NFC

gen dist_both = dist if relaxed == 1
	replace dist_both = (-1)*dist if relaxed == 0

gen strict = 1 if relaxed == 0
	replace strict = 0 if relaxed == 1

gen r_dist_both = strict*dist_both

gen dist_both2 = dist if relaxed2 == 1
	replace dist_both2 = (-1)*dist if relaxed2 == 0

gen r_dist_both2 = strict*dist_both2

egen dist_group = cut(dist_both), at(-0.5(0.02)0.5)
egen dist3 = group(dist_group), label

egen dist_group2 = cut(dist_both2), at(-0.5(0.02)0.5)
egen dist3_2 = group(dist_group2), label

encode RentType , gen(RentType1)
encode MarketSegment  , gen(MarketSegment1)
encode SubmarketName  , gen(SubmarketName1)
encode SubmarketCluster , gen(SubmarketCluster1)
encode BuildingClass , gen(BuildingClass1)

gen rent10001499 = (B25056021+B25056020)/B25056002
gen rent1999 = B25056022/B25056002
gen renta2000 = B25056023/B25056002


********************************************************************************
** Housing Costs
********************************************************************************
* convert house prices into rental value
/* divide by number of units (def_houseprice*0.0629)/ 
(num_units *12) make sure single-fam is 1 
*/
gen house_rent = ((def_houseprice/num_units)*0.0629)/12 

gen log_houseprice = log(house_rent)

********************************************************************************
** Combining housing prices pt 1
*******************************************************************************
gen comb_rent1 = AvgAskingUnit 
	replace comb_rent1 = house_rent if comb_rent1==.

egen comb1_99 = pctile(comb_rent1) if (res_typex!= "Single Family Res"), p(99)
	replace comb_rent1 = . if comb_rent1>comb1_99

gen comb_rent2 = AvgAskingUnit if (res_typex!= "Single Family Res")
	replace comb_rent2 = house_rent if (comb_rent2==.  & res_typex!= "Single Family Res")

egen comb2_99 = pctile(comb_rent2) , p(99)
	replace comb_rent2 = . if comb_rent2>comb2_99

********************************************************************************
** Histograms
********************************************************************************
* edit ACS rent data for 2019
preserve 

use "$DATAPATH/acs/ACS_2019_rent.dta", replace
	keep if unitsstr>=5
	keep if statefip == 25
	keep if rent>0

	gen acs2019 = 1

	keep acs2019 rent

	tempfile acs2019
	save `acs2019', replace
	clear

restore

* append acs 2019
append using `acs2019'

* Combine estimated rent with Co-star rental data 
quietly reg AvgAskingUnit SHARE_WHT SHARE_WHT_RENT SHARE_UNDER15 SHARE_PUBLICTRANS SHARE_COMM_U15 SHARE_INC_OVER200K ///
		SHARE_INC_PUBASSIST SHARE_WORKING_OVER16 SHARE_RENTER_HU SHARE_RENT_1BED SHARE_RENT_2BED ///
		A18009_001  B19113001 B25092001 rent10001499 rent1999 renta2000 ///
		i.StarRating NumberOfUnits i.RentType1 i.MarketSegment1 ClosestTransitStopDistmi ///
		NumberOfElevators NumberOfStories RBA TypicalFloorSize i.year_built i.year i.BuildingClass1 ///
		lot_sizesqft i.res_type  i.SubmarketName1 	
	
predict pred_rent_costar

gen imp_rent =  AvgAskingUnit

replace imp_rent = pred_rent_costar if (imp_rent==. &  pred_rent_costar>0 )

gen pred_cstar =  pred_rent_costar if ( AvgAskingUnit ==. &  pred_rent_costar>0)

* Histogram 1
// twoway (histogram AvgAskingUnit,  color(red%30)) (histogram pred_cstar if pred_cstar>0,  color(green%30)), ///
// 	legend(order(1 "CoStar Rent" 2 "Imputed (CoStar)" )) graphregion(color(white))
//
// graph export "$FIGPATH/Histogram_imputed_costar_rent.pdf", replace

* Predicted non-costar rent
quietly reg AvgAskingUnit SHARE_WHT SHARE_WHT_RENT SHARE_UNDER15 SHARE_PUBLICTRANS SHARE_COMM_U15 SHARE_INC_OVER200K ///
		SHARE_INC_PUBASSIST SHARE_WORKING_OVER16 SHARE_RENTER_HU SHARE_RENT_1BED SHARE_RENT_2BED ///
		A18009_001  B19113001 B25092001 rent10001499 rent1999 renta2000 ///
		i.year_built i.year lot_sizesqft i.res_type i.census_tract2010	

predict pred_rent_nocstar

gen imp_rent1 =  imp_rent
replace imp_rent1 = pred_rent_nocstar if (imp_rent1==. &  pred_rent_nocstar > 0 &  res_typex != "Single Family Res" )
gen pred_nocstar =  pred_rent_nocstar if ( imp_rent ==. & pred_rent_nocstar >0 &  res_typex != "Single Family Res")


egen imp1_99 = pctile(imp_rent1), p(99)
replace imp_rent1 = . if imp_rent1>imp1_99


* Histogram 2
// twoway (histogram AvgAskingUnit,  color(red%30)) (histogram pred_cstar if pred_cstar>0,  color(green%30)) ///
// 		(histogram pred_nocstar if (pred_nocstar > 0 & pred_nocstar<10000  ), color(blue%30))  ///
// 		(histogram comb_rent1 if (res_typex!= "Single Family Res" ) ,  color(purple%30)) ///
// 		(histogram rent if acs2019==1 & rent>0, color(yellow%30)), ///
// 		 legend(order(1 "CoStar Rent" 2 "Imputed (CoStar)" 3 "Imputed (ACS)" 4 "Imputed (6.29%)" 5 "ACS 2018")) graphregion(color(white))
//
// graph export "$FIGPATH/Histogram_imputed_rent_6pct.pdf", replace


********************************************************************************
** Combining housing prices pt 2
*******************************************************************************
gen comb_rent3 = AvgAskingUnit 
	replace comb_rent3 = pred_rent_costar if (comb_rent3==. &  pred_rent_costar>0 )
	replace comb_rent3 = house_rent if comb_rent3==.
	replace comb_rent3 = . if comb_rent3>comb1_99 

// gen comb_rent2 = AvgAskingUnit if (res_typex!= "Single Family Res")
//
// replace comb_rent2 = house_rent if (comb_rent2==.  & res_typex!= "Single Family Res")
//
// egen comb2_99 = pctile(comb_rent2) , p(99)
//
// replace comb_rent2 = . if comb_rent2>comb2_99

* Logging housing costs
gen log_combrent1 = log(comb_rent1)

gen log_combrent2 = log(comb_rent2)

gen log_combrent3 = log(comb_rent3)

gen log_mfrent = log_combrent2 // NFC

* Gen number of floors and units
gen num_floors1 = num_floors if num_floors !=0

gen num_units1 = num_units if num_units !=0

********************************************************************************
** Sum stats
********************************************************************************
tab year, missing

* drop excess variables
drop TOWN_ID mfallow siteplan mfspga mfattach mfmixed mfconvert mfparcel mfminlot unitarea townhous mfsenior onlyold zonedist ///
agelimit overlay resdist agezone zoneweb accesapt aaspga aafamily  clbuilt clspga cladopt clamend clbonus cltype clparcel ///
clminlot clopen incstruc inclieu incbonus increlax incadopt incdevs incunits growrate grownum phasing phunits growadpt growtemp ///
 growexp exsenior exafford exopen exlodens exinfra exother capfirm mlaexclud mlacba mlapct shaprule shapenum htcalc front150 longzone ///
 maxfront frontout maxbuild subdrule subadopt subamend subdweb maxlength pavewid1 pavewid2 typeroad rghtway1 curb sidewalk sidewide ///
 maxgrade maxgrad2 wetbylaw wetadopt wetamend ccadopt wetonline vernpool vernlist buffpool pooldefn vernwide maxjuris buffisol isolwide ///
 floodexp addterms termdefn bufflsf lsfdefn nobuild nogowide delaycert septrule septdate septweb grndmin roomflow housflow bedcount ///
 maxperc leachsiz propback wetback wellback perctest septtime noshare pctsewer iipartic iiratio iicash sewerfee passed Community ///
 CensusYearRoundHousingU TotalDevelopmentUnits SHIUnits frac_aff_2017 Adoption_HomeRuleCharter ModelCityCharter ChiefMunicipalOfficial ///
 PolicyBoard NumBoardMem LegislativeBody NumLegMem population violentcrime propertycrime LEAID1 area_frac1 LEAID2 area_frac2 LEAID3 ///
 area_frac3 LEAID4 area_frac4 LEAID5 area_frac5 LEAID6 area_frac6 LEAID7 area_frac7 LEAID8 area_frac8 LEAID9 area_frac9 LEAID10 area_frac10 ///
 LEAID11 area_frac11 LEAID12 area_frac12 LEAID13 area_frac13 LEAID14 area_frac14 LEAID15 area_frac15 LEAID16 area_frac16 LEAID17 ///
 area_frac17 LEAID18 area_frac18 LEAID19 area_frac19 LEAID20 area_frac20 LEAID21 area_frac21 LEAID22 area_frac22 LEAID23 area_frac23 ///
 LEAID24 area_frac24 LEAID25 area_frac25 LEAID26 area_frac26 LEAID27 area_frac27 LEAID28 area_frac28 LEAID29 area_frac29 LEAID30 ///
 area_frac30 LEAID31 area_frac31 LEAID32 area_frac32


** END OF SETUP FILE **
