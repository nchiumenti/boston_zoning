clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postQJE_Spatial_Heterogeneity_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES SETUP VERSION **

** NO CLUSTERING **

********************************************************************************
* File name:		"postQJE_Spatial_Heterogeneity.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		runs full spatial heterogeneity file w/ mt lines and 
*			sales prices instead of assessed value
*			loops through distance polynomials ^2 - ^5 
* 				
* Inputs:		various
*				
* Outputs:		postQJE_spatial_price_coeff_MAPCdefinition.dta
*			postQJE_spatial_supply_coeff_MAPCdefinition.dta
*
* Created:		09/21/2021
* Updated:		10/14/2022
********************************************************************************

* create a save directory if none exists
global EXPORTPATH "$DATAPATH/postQJE_data_exports/`name'_`date_stamp'"

capture confirm file "$EXPORTPATH"

if _rc!=0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

cd $EXPORTPATH

// ********************************************************************************
// ** load the mt lines data
// ********************************************************************************
// use "$SHAPEPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear
//
// destring prop_id, replace
//
// tempfile mtlines
// save `mtlines', replace
//
//
// ********************************************************************************
// ** load final dataset
// ********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear
//
//
// ********************************************************************************
// ** run postQJE within town setup file
// ********************************************************************************
// run "$DOPATH/postQJE_within_town_setup.do"
//
//
// ********************************************************************************
// ** merge on mt lines to keep straight line properties
// ********************************************************************************
// merge m:1 prop_id using `mtlines', keepusing(straight_line)
// 	drop if _merge == 2
// 	drop _merge
//
// keep if straight_line == 1 // <-- drops non-straight line properties
//
// tab year // <-- used to verify future runs of the data

use "$DATAPATH/postQJE_data_exports/postQJE_sample_data_2022-10-07/postQJE_testing_full.dta", clear

********************************************************************************
** For regressions 1A + 1B keep only years 2010-2018
********************************************************************************
keep if (year>=2010 & year<=2018)

drop log_saleprice

gen house_salesrent = ((def_saleprice/num_units)*0.0629)/12 

gen log_saleprice = log(house_salesrent)

******************************************************
/* Market Definitions  */
******************************************************
replace city = upper(city)

*Basic ring defition
#delimit ;
gen def_1 = 1 if (city=="ARLINGTON" | 
			city=="BELMONT" | 
			city=="BOSTON" | 
			city=="BROOKLINE" | 
			city=="CAMBRIDGE" | 
			city=="CHELSEA" |
			city=="EVERETT" | 
			city=="MALDEN" | 
			city=="MEDFORD" | 
			city=="MELROSE" | 
			city=="NEWTON" | 
			city=="REVERE" | 
			city=="SOMERVILLE" | 
			city=="WALTHAM" | 
			city=="WATERTOWN" | 
			city=="WINTHROP") ;
				   
replace def_1 = 2 if (city=="BEVERLY" | 
			city=="FRAMINGHAM" | 
			city=="GLOUCESTER"| 
			city=="LYNN" | 
			city=="MARLBORO" | 
			city=="MILFORD" | 
			city=="SALEM" | city=="WOBURN") ;
				   
replace def_1 = 3 if (city=="ACTON" | 
			city=="BEDFORD" | 
			city=="CANTON"| 
			city=="CONCORD" | 
			city=="DEDHAM" | 
			city=="DUXBURY" |
			city=="HINGHAM" | 
			city=="HOLBROOK" | 
			city=="HULL" | 
			city=="LEXINGTON" | 
			city=="LINCOLN" | 
			city=="MARBLEHEAD" | 
			city=="MARSHFIELD" | 
			city=="MAYNARD" | 
			city=="MEDFIELD" | 
			city=="MILTON" | 
			city=="NAHANT"| 
			city=="NATICK" | 
			city=="NEEDHAM" | 
			city=="NORTH READING" | 
			city=="PEMBROKE" | 
			city=="RANDOLPH" | 
			city=="SCITUATE" |	
			city=="SHARON" | 
			city=="SOUTHBORO" |  
			city=="STONEHAM" | 
			city=="STOUGHTON" |  
			city=="SUDBURY" | 
			city=="SWAMPSCOTT" | 
			city=="WAKEFIELD" | 
			city=="WAYLAND" | 
			city=="WELLESLEY" | 
			city=="WESTON" | 
			city=="WESTWOOD" | 
			city=="WEYMOUTH") ;
				   
replace def_1 = 4 if (city=="BOLTON" | 
			city=="BOXBORO" | 
			city=="CARLISLE"| 
			city=="COHASSET" | 
			city=="DOVER" | 
			city=="ESSEX" | 
			city=="FOXBORO" | 
			city=="FRANKLIN" | 
			city=="HANOVER" | 
			city=="HOLLISTON" | 
			city=="HOPKINTON" | 
			city=="HUDSON" | 
			city=="LITTLETON" | 
			city=="MANCHESTER" | 
			city=="MEDWAY" | 
			city=="MIDDLETON" | 
			city=="MILLIS"| 
			city=="NORFOLK" | 
			city=="NORWELL" | 
			city=="ROCKLAND" | 
			city=="ROCKPORT" | 
			city=="SHERBORN" | 
			city=="STOW" | 
			city=="TOPSFIELD" | 
			city=="WALPOLE" | 
			city=="WRENTHAM" ) ;
#delimit cr			


gen def_name = "Inner Core" if def_1 == 1 /* Blue  */
replace def_name = "Regional Urban" if def_1 == 2 /* Grey  */
replace def_name = "Mature Suburbs" if def_1 == 3 /* Green  */
replace def_name = "Developing Suburbs" if def_1 == 4 /* Yellow  */

rename county_fip orig_county_fip
rename county orig_county

gen county_fip = def_1
gen county = def_name


********************************************************************************
**Define distance polynomial trends
********************************************************************************

gen r_dist_relax = relaxed*dist_both
gen r_dist_strict = strict*dist_both

gen r_dist_relax2 = r_dist_relax^2
gen r_dist_relax3 = r_dist_relax^3
gen r_dist_relax4 = r_dist_relax^4
gen r_dist_relax5 = r_dist_relax^5

gen r_dist_strict2 = r_dist_strict^2
gen r_dist_strict3 = r_dist_strict^3
gen r_dist_strict4 = r_dist_strict^4
gen r_dist_strict5 = r_dist_strict^5



********************************************************************************
** analysis below save point
********************************************************************************
// tempfile save_point
// save `save_point', replace
//
// stop

* notes just for Xiaoya to remember what to do
* c_r_c: renters; c_o_c: owners; s_r_c: standard error; dupac/height; 
* clean some misnamed coefficient variables
* remove theta_hd theta_gd  from summary statistics 
* Save t-stats/p-value directly in the regressions 
* add bandwidth loop for summary statistics for both positive and negative 
* add bandwidth loop & polynomials distance trends loop for regressions 
* create polynomials distance trends first:done


/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Regression 1 linear probability rents and prices                           */
/*                                                                            */
/*----------------------------------------------------------------------------*/


********************************************************************************
** define distance polynomial trends varlist
********************************************************************************
local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist2 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"
local distance_varlist4 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4"
local distance_varlist5 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4 r_dist_relax5 r_dist_strict5"


********************************************************************************
** county/community type regresstions for rents and sale prices
********************************************************************************
* by renters vs owners
preserve 

keep if only_du ==1 | du_he == 1| mf_du == 1 | only_mf == 1

** define coeff stores
* direct effects, only_du
quietly foreach var in 2 5 10 15 20 { 
	forvalues i = 1/5 {
		* direct Effects
		gen dupac_coeff_renters_c_`var'_x`i' = .
		gen dupac_coeff_owners_c_`var'_x`i' = .
		gen dupac_se_renters_c_`var'_x`i' = .
		gen dupac_se_owners_c_`var'_x`i' = .
	}
}

* direct effects, du_he
quietly foreach var in 2 5 10 15 20{ 
	forvalues i=1/5{
		* renters
		gen dupac_dXh_c_r_c_`var'_x`i' = .
		gen height_dXh_c_r_c_`var'_x`i' = .
		gen duXhe_dXh_c_r_c_`var'_x`i' = .
		gen dupac_dXh_s_r_c_`var'_x`i' = .
		gen height_dXh_s_r_c_`var'_x`i' = .
		gen duXhe_dXh_s_r_c_`var'_x`i' = .
		
		* owners
		gen dupac_dXh_c_o_c_`var'_x`i' = .
		gen height_dXh_c_o_c_`var'_x`i' = .
		gen duXhe_dXh_c_o_c_`var'_x`i' = .
		gen dupac_dXh_s_o_c_`var'_x`i' = .
		gen height_dXh_s_o_c_`var'_x`i' = .
		gen duXhe_dXh_s_o_c_`var'_x`i' = .
	}
}

* direct effects, mf_du
quietly foreach var in 2 5 10 15 20{ 
	forvalues i=1/5{
		* renters
		* mf_dXmf dupac_dXmf_c_r_02_x1_c
		gen dupac_dXmf_c_r_c_`var'_x`i' = .
		gen mf_dXmf_c_r_c_`var'_x`i' = .
		gen duXmf_dXmf_c_r_c_`var'_x`i' = .
		gen dupac_dXmf_s_r_c_`var'_x`i' = .
		gen mf_dXmf_s_r_c_`var'_x`i' = .
		gen duXmf_dXmf_s_r_c_`var'_x`i' = .

		* owners
		gen dupac_dXmf_c_o_c_`var'_x`i' = .
		gen mf_dXmf_c_o_c_`var'_x`i' = .
		gen duXmf_dXmf_c_o_c_`var'_x`i' = .
		gen dupac_dXmf_s_o_c_`var'_x`i' = .
		gen mf_dXmf_s_o_c_`var'_x`i' = .
		gen duXmf_dXmf_s_o_c_`var'_x`i' = .
	}
}

* direct effects, only_mf
quietly foreach var in 2 5 10 15 20 { 
	forvalues i = 1/5 {
		* direct Effects
		gen mf_coeff_renters_c_`var'_x`i' = .
		gen mf_coeff_owners_c_`var'_x`i' = .
		gen mf_se_renters_c_`var'_x`i' = .
		gen mf_se_owners_c_`var'_x`i' = .
	}
}

********************************************************************************
** Prices spatial heterogeneity
* Part 1: loop over bandwidths for means
* Part 2(a-c): loop over bandwidth x polynomials for rents
* Part 3(a-c): loop over bandwith x polynomials for sales prices
********************************************************************************
levelsof county, local(levels) 

foreach l of local levels {

	di ""
	di ""
	di "*** `l' ***"

	tab county if county == "`l'"
	
	********************************************************************************	
	** Part 1 means
	********************************************************************************
	*****loop over different bandwidth
	foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		di ""
		di "*** bandwidth `d' ***"
		di "********************************************************************************"
		di "** means for `l' at bandwidth `d'"
		di "********************************************************************************"
		
		* only_du
		di "means for `l' at bandwidth `d': ONLY_DU, RELAXED SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac if county == "`l'" & only_du == 1 & dist_both<=`d' & dist_both>=0
		
		di "means for `l' at bandwidth `d': ONLY_DU, STRICT SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac  if county == "`l'" & only_du == 1 & dist_both>=-`d' & dist_both<0
		
		di "means for `l' at bandwidth `d': ONLY_DU, BOTH SIDES"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac  if county == "`l'" & only_du == 1 & dist<=`d'

		* du_he
		di "means for `l' at bandwidth `d': DU_HE, RELAXED SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac height if county == "`l'" & du_he == 1 & dist_both<=`d' & dist_both>=0
		
		di "means for `l' at bandwidth `d': DU_HE, STRICT SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac height if county == "`l'" & du_he == 1 & dist_both>=-`d' & dist_both<0
		
		di "means for `l' at bandwidth `d': DU_HE, BOTH SIDES"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac height if county == "`l'" & du_he == 1 & dist<=`d'
		
		* mf_du
		di "means for `l' at bandwidth `d': MF_DU, RELAXED SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac mf_allowed if county == "`l'" & mf_du == 1 & dist_both<=`d' & dist_both>=0
		
		di "means for `l' at bandwidth `d': MF_DU, STRICT SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac mf_allowed if county == "`l'" & mf_du == 1 & dist_both>=-`d' & dist_both<0
		
		di "means for `l' at bandwidth `d': MF_DU, BOTH SIDES" 
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac mf_allowed if county == "`l'" & mf_du == 1 & dist<=`d'

		* only_mf
		di "means for `l' at bandwidth `d': ONLY_MF, RELAXED SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac if county == "`l'" & only_mf == 1 & dist_both<=`d' & dist_both>=0
		
		di "means for `l' at bandwidth `d': ONLY_MF, STRICT SIDE ONLY"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac  if county == "`l'" & only_mf == 1 & dist_both>=-`d' & dist_both<0
		
		di "means for `l' at bandwidth `d': ONLY_MF, BOTH SIDES"
		sum log_mfrent comb_rent2 house_rent log_saleprice theta_hd theta_gd dupac  if county == "`l'" & only_mf == 1 & dist<=`d'
	
	} // emd of bandwidth loop
	
	********************************************************************************	
	** Part 2: renter costs with only_du du_he mf_du only_mf(run quietly)
	********************************************************************************	
	di ""
	di "*** log_mfrent regressions ***"
	quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)
		
		********************************************************************************	
		** Part 2a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_mfrent only_du..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions 
			local regression_conditions only_du == 1 & dist <= `d' & res_typex != "Condominiums" & county == "`l'" & (year >= 2010 & year <= 2018)
			
			* tests if if there are observations run the regression
			count if (log_mfrent != .) & `regression_conditions'
			local a = r(N)
			
			if `a' > 1 {
				* run regression
				capture reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year if `regression_conditions' , vce(cluster lam_seg) 
				
				* display observation count
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_mfrent only_du == `e(N)'"
				
				** error checks
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_renters_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_renters_c_`var'_x`i' = _se[dupac] if county == "`l'"	
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_mfrent only_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_mfrent only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 406
		
		********************************************************************************	
		** Part 2a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_mfrent only_du..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions 
			local regression_conditions only_du == 1 & dist <= `d' & res_typex != "Condominiums" & county == "`l'" & (year >= 2010 & year <= 2018)
			
			* tests if if there are observations run the regression
			count if (log_mfrent != .) & `regression_conditions'
			local a = r(N)
			
			if `a' > 1 {
				* run regression
				capture reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year if `regression_conditions' , vce(cluster lam_seg) 
				
				* display observation count
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_mfrent only_du == `e(N)'"
				
				** error checks
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_renters_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_renters_c_`var'_x`i' = _se[dupac] if county == "`l'"	
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_mfrent only_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_mfrent only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 458	
		
		********************************************************************************	
		** Part 2b: du_he
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_mfrent du_he..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"
			
			* set regression conditions 
			local regression_conditions du_he == 1 & dist <= `d' & res_typex != "Condominiums" & county == "`l'" & (year >= 2010 & year <= 2018)

			* tests if if there are observations run the regression
			count if (log_mfrent != .) & `regression_conditions'
			local a = r(N)
			
			if `a' > 1 {	
				* run regression
				cap n reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year if `regression_conditions', vce(cluster lam_seg) 
				
				* display observation count			
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_mfrent du_he == `e(N)'"
				
				/* tab a bunch of stuff for Amrita */
				noisily unique lam_seg if (log_mfrent != .) & `regression_conditions'
				noisily tab height if (log_mfrent != .) & `regression_conditions'
				noisily tab dupac if (log_mfrent != .) & `regression_conditions'
				noisily tab dupac height if (log_mfrent != .) & `regression_conditions'

				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXh_c_r_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace height_dXh_c_r_c_`var'_x`i' = _b[height] if county == "`l'"
					replace duXhe_dXh_c_r_c_`var'_x`i' = _b[c.height#c.dupac] if county == "`l'"
					replace dupac_dXh_s_r_c_`var'_x`i' = _se[dupac] if county == "`l'"
					replace height_dXh_s_r_c_`var'_x`i' = _se[height] if county == "`l'"
					replace duXhe_dXh_s_r_c_`var'_x`i' = _se[c.height#c.dupac] if county == "`l'"
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_mfrent du_he, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_mfrent du_he, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 511
					
		********************************************************************************	
		** Part 2c: mf_du
		********************************************************************************					
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_mfrent mf_du..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"
		
			* set regression conditions 
			local regression_conditions mf_du == 1 & dist <= `d' & res_typex != "Condominiums" & county == "`l'" & (year >= 2010 & year <= 2018)

			* tests if if there are observations run the regression
			count if (log_mfrent != .) & `regression_conditions'
			local a = r(N)

			if `a'>1 {
				* run regression
				capture reg log_mfrent  i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year if `regression_conditions', vce(cluster lam_seg) 
					
				* display observation count			
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_mfrent mf_du == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXmf_c_r_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace mf_dXmf_c_r_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace duXmf_dXmf_c_r_c_`var'_x`i' = _b[1.mf_allowed#c.dupac] if county == "`l'"
					replace dupac_dXmf_s_r_c_`var'_x`i' = _se[dupac] if county == "`l'"
					replace mf_dXmf_s_r_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
					replace duXmf_dXmf_s_r_c_`var'_x`i' = _se[1.mf_allowed#c.dupac] if county == "`l'"
				}

				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_mfrent mf_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_mfrent mf_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 572
		
		********************************************************************************	
		** Part 2d: only_mf
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_mfrent only_mf..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions 
			local regression_conditions only_mf == 1 & dist <= `d' & res_typex != "Condominiums" & county == "`l'" & (year >= 2010 & year <= 2018)
			
			* tests if if there are observations run the regression
			count if (log_mfrent != .) & `regression_conditions'
			local a = r(N)
			
			if `a' > 1 {
				* run regression
				capture reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year if `regression_conditions' , vce(cluster lam_seg) 
				
				* display observation count
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_mfrent only_du == `e(N)'"
				
				** error checks
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace mf_coeff_renters_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace mf_se_renters_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"	
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_mfrent only_mf, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_mfrent only_mf, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 627
	} // end of bandwidth loop on line 397
	

	********************************************************************************	
	** Part 3: housing cost estimates with only_du du_he mf_du only_mf (NOTE! make sure to use log_saleprice)
	********************************************************************************	
	di ""
	di "*** log_saleprice regesssions ***"
	quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {

		* set local var name for bandwith
		local var = round(`d' * 100, 1)

		********************************************************************************	
		** Part 3a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_saleprice only_du..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_du == 1 & dist <= `d' & res_typex == "Single Family Res" & county == "`l'" & (last_saleyr >= 2010 & last_saleyr <= 2018)

			* tests if if there are observations run the regression
			count if (log_saleprice != .) & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {	

				* run regression
				capture reg  log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				
				* display observation count			
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_saleprice only_du == `e(N)'"
				
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_owners_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_owners_c_`var'_x`i' = _se[dupac] if county == "`l'"			
				}
					
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_saleprice only_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_saleprice only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 691

		********************************************************************************	
		** Part 3b: du_he
		********************************************************************************	
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_saleprice du_he..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"
	
			* set regression conditions
			local regression_conditions du_he == 1 & dist <= `d' & res_typex == "Single Family Res" & county == "`l'" & (last_saleyr >= 2010 & last_saleyr <= 2018)

			* tests if if there are observations run the regression
			count if (log_saleprice != .) & `regression_conditions'
			local a = r(N)

			if `a'>1 {
				
				* run regression
				cap n reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				 
				* display observation count			
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_saleprice du_he == `e(N)'"
									
				/* tab a bunch of stuff for Amrita */
				noisily unique lam_seg if `regression_conditions' & log_saleprice != .
				noisily tab dupac if `regression_conditions' & log_saleprice != .
				noisily tab height if `regression_conditions' & log_saleprice != .
				noisily tab dupac height if `regression_conditions' & log_saleprice != .
				
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXh_c_o_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace height_dXh_c_o_c_`var'_x`i' = _b[height] if county == "`l'"
					replace duXhe_dXh_c_o_c_`var'_x`i' = _b[c.height#c.dupac] if county == "`l'"
					replace dupac_dXh_s_o_c_`var'_x`i' = _se[dupac] if county == "`l'"
					replace height_dXh_s_o_c_`var'_x`i' = _se[height] if county == "`l'"
					replace duXhe_dXh_s_o_c_`var'_x`i' = _se[c.height#c.dupac] if county == "`l'"
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_saleprice du_he, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_saleprice du_he, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 742

		********************************************************************************	
		** Part 3c: mf_du
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_saleprice mf_du..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"
	
			* set regression conditions
			local regression_conditions mf_du == 1 & dist <= `d' & res_typex == "Single Family Res" & county == "`l'" & (last_saleyr >= 2010 & last_saleyr <= 2018)

			* tests if if there are observations run the regression
			count if (log_saleprice != .) & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {	
				
				* run regression
				capture reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				
				* display observation count			
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_saleprice mf_du == `e(N)'"
				
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXmf_c_o_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace mf_dXmf_c_o_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace duXmf_dXmf_c_o_c_`var'_x`i' = _b[1.mf_allowed#c.dupac] if county == "`l'"
					replace dupac_dXmf_s_o_c_`var'_x`i' = _se[dupac] if county == "`l'"
					replace mf_dXmf_s_o_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
					replace duXmf_dXmf_s_o_c_`var'_x`i' = _se[1.mf_allowed#c.dupac] if county == "`l'"

				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_saleprice mf_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_saleprice mf_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 804
		
		
		********************************************************************************	
		** Part 3d: only_mf
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for log_saleprice only_mf..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_mf == 1 & dist <= `d' & res_typex == "Single Family Res" & county == "`l'" & (last_saleyr >= 2010 & last_saleyr <= 2018)

			* tests if if there are observations run the regression
			count if (log_saleprice != .) & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {	

				* run regression
				capture reg  log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				
				* display observation count			
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg log_saleprice only_du == `e(N)'"
				
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					capture  replace mf_coeff_owners_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					
					if c(rc) != 0 {
						n di "error encountered r(`c(rc)'), no values stored for mf_coeff_owners_c_`var'_x`i'"
					}
					
					capture replace mf_se_owners_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
					
					if c(rc) != 0 {
						n di "error encountered r(`c(rc)'), no values stored for mf_se_owners_c_`var'_x`i'"
					}
				}
					
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg log_saleprice only_mf, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg log_saleprice only_mf, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
			
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 862
	} // end of bandwidth loop on line 682
} // end of county/community type loop on line 330

		

********************************************************************************
** t statistics
********************************************************************************
*loop over different bandwidth
quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2{ 
	local var = round(`d'*100,1)
	
	*loop over different polynomial distance trends
	forvalues i = 1/5{	

		gen t_dupac_coeff_renters_c_`var'_x`i' = dupac_coeff_renters_c_`var'_x`i'/dupac_se_renters_c_`var'_x`i'
		gen t_dupac_coeff_owners_c_`var'_x`i' = dupac_coeff_owners_c_`var'_x`i'/dupac_se_owners_c_`var'_x`i'

		gen t_dupac_dXh_c_r_c_`var'_x`i' = dupac_dXh_c_r_c_`var'_x`i'/dupac_dXh_s_r_c_`var'_x`i'
		gen t_height_dXh_c_r_c_`var'_x`i' = height_dXh_c_r_c_`var'_x`i'/height_dXh_s_r_c_`var'_x`i'
		gen t_duXhe_dXh_c_r_c_`var'_x`i' = duXhe_dXh_c_r_c_`var'_x`i'/duXhe_dXh_s_r_c_`var'_x`i'
		gen t_dupac_dXh_c_o_c_`var'_x`i' = dupac_dXh_c_o_c_`var'_x`i'/dupac_dXh_s_o_c_`var'_x`i'
		gen t_height_dXh_c_o_c_`var'_x`i' = height_dXh_c_o_c_`var'_x`i'/height_dXh_s_o_c_`var'_x`i'
		gen t_duXhe_dXh_c_o_c_`var'_x`i' = duXhe_dXh_c_o_c_`var'_x`i'/duXhe_dXh_s_o_c_`var'_x`i'

		gen t_dupac_dXmf_c_r_c_`var'_x`i' = dupac_dXmf_c_r_c_`var'_x`i'/dupac_dXmf_s_r_c_`var'_x`i'
		gen t_mf_dXmf_c_r_c_`var'_x`i' = mf_dXmf_c_r_c_`var'_x`i'/mf_dXmf_s_r_c_`var'_x`i'
		gen t_duXmf_dXmf_c_r_c_`var'_x`i' = duXmf_dXmf_c_r_c_`var'_x`i'/duXmf_dXmf_s_r_c_`var'_x`i'
		gen t_dupac_dXmf_c_o_c_`var'_x`i' = dupac_dXmf_c_o_c_`var'_x`i'/dupac_dXmf_s_o_c_`var'_x`i'
		gen t_mf_dXmf_c_o_c_`var'_x`i' = mf_dXmf_c_o_c_`var'_x`i'/mf_dXmf_s_o_c_`var'_x`i'
		gen t_duXmf_dXmf_c_o_c_`var'_x`i' = duXmf_dXmf_c_o_c_`var'_x`i'/duXmf_dXmf_s_o_c_`var'_x`i'
		
		gen t_mf_coeff_renters_c_`var'_x`i' = mf_coeff_renters_c_`var'_x`i'/mf_se_renters_c_`var'_x`i'
		gen t_mf_coeff_owners_c_`var'_x`i' = mf_coeff_owners_c_`var'_x`i'/mf_se_owners_c_`var'_x`i'
	}
}

/* save only these coefficients as separate data set to be able to make maps of 
spatial variation */

*keep only one observation per county
by county, sort: gen nvals = _n == 1
keep if nvals == 1

#delimit ;
	keep 
	county county_fip 
	t_dupac_coeff_renters_c_* dupac_coeff_renters_c_* dupac_se_renters_c_* 
	t_dupac_coeff_owners_c_* dupac_coeff_owners_c_* dupac_se_owners_c_*
	t_dupac_dXh_c_r_c_* dupac_dXh_c_r_c_* dupac_dXh_s_r_c_* 
	t_height_dXh_c_r_c_* height_dXh_c_r_c_* height_dXh_s_r_c_* 
	t_duXhe_dXh_c_r_c_* duXhe_dXh_c_r_c_* duXhe_dXh_s_r_c_* 
	t_dupac_dXh_c_o_c_* dupac_dXh_c_o_c_* dupac_dXh_s_o_c_* 
	t_height_dXh_c_o_c_* height_dXh_c_o_c_* height_dXh_s_o_c_* 
	t_duXhe_dXh_c_o_c_* duXhe_dXh_c_o_c_* duXhe_dXh_s_o_c_* 
	t_dupac_dXmf_c_r_c_* dupac_dXmf_c_r_c_* dupac_dXmf_s_r_c_* 
	t_mf_dXmf_c_r_c_* mf_dXmf_c_r_c_* mf_dXmf_s_r_c_* 
	t_duXmf_dXmf_c_r_c_* duXmf_dXmf_c_r_c_* duXmf_dXmf_s_r_c_*
	t_dupac_dXmf_c_o_c_* dupac_dXmf_c_o_c_* dupac_dXmf_s_o_c_* 
	t_mf_dXmf_c_o_c_* mf_dXmf_c_o_c_* mf_dXmf_s_o_c_* 
	t_duXmf_dXmf_c_o_c_* duXmf_dXmf_c_o_c_* duXmf_dXmf_s_o_c_* 
	t_mf_coeff_renters_c_* mf_coeff_renters_c_* mf_se_renters_c_* 
	t_mf_coeff_owners_c_* mf_coeff_owners_c_* mf_se_owners_c_*
;

***convert dataset to long format, each coefficient has 5(different bandwidth)*5(different polynomial trends)*4(counties) variations
reshape long t_dupac_coeff_renters_c dupac_coeff_renters_c dupac_se_renters_c 
	t_dupac_coeff_owners_c dupac_coeff_owners_c dupac_se_owners_c
	t_dupac_dXh_c_r_c dupac_dXh_c_r_c dupac_dXh_s_r_c 
	t_height_dXh_c_r_c height_dXh_c_r_c height_dXh_s_r_c 
	t_duXhe_dXh_c_r_c duXhe_dXh_c_r_c duXhe_dXh_s_r_c 
	t_dupac_dXh_c_o_c dupac_dXh_c_o_c dupac_dXh_s_o_c 
	t_height_dXh_c_o_c height_dXh_c_o_c height_dXh_s_o_c 
	t_duXhe_dXh_c_o_c duXhe_dXh_c_o_c duXhe_dXh_s_o_c
	t_dupac_dXmf_c_r_c dupac_dXmf_c_r_c dupac_dXmf_s_r_c
	t_mf_dXmf_c_r_c mf_dXmf_c_r_c mf_dXmf_s_r_c
	t_duXmf_dXmf_c_r_c duXmf_dXmf_c_r_c duXmf_dXmf_s_r_c
	t_dupac_dXmf_c_o_c dupac_dXmf_c_o_c dupac_dXmf_s_o_c 
	t_mf_dXmf_c_o_c mf_dXmf_c_o_c mf_dXmf_s_o_c
	t_duXmf_dXmf_c_o_c duXmf_dXmf_c_o_c duXmf_dXmf_s_o_c
	t_mf_coeff_renters_c mf_coeff_renters_c mf_se_renters_c 
	t_mf_coeff_owners_c mf_coeff_owners_c mf_se_owners_c, i(county) j(spec) s;

#delimit cr


********************************************************************************
** save output data 
** CHANGE PATH ACCORDINGLY HERE
********************************************************************************
save "postQJE_spatial_price_coeff_MAPCdefinition.dta", replace

restore


/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Regression 2 linear probability number of units 1918 and 1956              */
/*                                                                            */
/*----------------------------------------------------------------------------*/


********************************************************************************
** define distance polynomial trends varlist
********************************************************************************
local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist2 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"
local distance_varlist4 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4"
local distance_varlist5 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4 r_dist_relax5 r_dist_strict5"


********************************************************************************
** county/community type regresstions for units
********************************************************************************
preserve 

keep if year == 2018

keep if only_du ==1 | du_he == 1 | mf_du == 1 | only_mf == 1

* direct effects, only_du
quietly foreach var in 2 5 10 15 20 { 
	forvalues i = 1/5 {
		gen dupac_coeff_u18_c_`var'_x`i' = .
		gen dupac_se_u18_c_`var'_x`i' = .
		gen dupac_coeff_u56_c_`var'_x`i' = .
		gen dupac_se_u56_c_`var'_x`i' = .
	}
}

* direct effects, du_he
quietly foreach var in 2 5 10 15 20 { 
	forvalues i = 1/5 {
		*units (1918)
		gen dupac_dXh_c_u18_c_`var'_x`i' = .
		gen height_dXh_c_u18_c_`var'_x`i' = .
		gen duXhe_dXh_c_u18_c_`var'_x`i' = .
		gen dupac_dXh_s_u18_c_`var'_x`i' = .
		gen height_dXh_s_u18_c_`var'_x`i' = .
		gen duXhe_dXh_s_u18_c_`var'_x`i' = .

		*units (1918)
		gen dupac_dXh_c_u56_c_`var'_x`i' = .
		gen height_dXh_c_u56_c_`var'_x`i' = .
		gen duXhe_dXh_c_u56_c_`var'_x`i' = .
		gen dupac_dXh_s_u56_c_`var'_x`i' = .
		gen height_dXh_s_u56_c_`var'_x`i' = .
		gen duXhe_dXh_s_u56_c_`var'_x`i' = .
	}
}

* direct effects, mf_du
quietly foreach var in 2 5 10 15 20 { 
	forvalues i = 1/5 {
		*units (1918)
		gen dupac_dXmf_c_u18_c_`var'_x`i' = .
		gen mf_dXmf_c_u18_c_`var'_x`i' = .
		gen duXmf_dXmf_c_u18_c_`var'_x`i' = .
		gen dupac_dXmf_s_u18_c_`var'_x`i' = .
		gen mf_dXmf_s_u18_c_`var'_x`i' = .
		gen duXmf_dXmf_s_u18_c_`var'_x`i' = .

		*units (1956)
		gen dupac_dXmf_c_u56_c_`var'_x`i' = .
		gen mf_dXmf_c_u56_c_`var'_x`i' = .
		gen duXmf_dXmf_c_u56_c_`var'_x`i' = .
		gen dupac_dXmf_s_u56_c_`var'_x`i' = .
		gen mf_dXmf_s_u56_c_`var'_x`i' = .
		gen duXmf_dXmf_s_u56_c_`var'_x`i' = .
	}
}

* direct effects, only_mf
quietly foreach var in 2 5 10 15 20 { 
	forvalues i = 1/5 {
		gen mf_coeff_u18_c_`var'_x`i' = .
		gen mf_se_u18_c_`var'_x`i' = .
		gen mf_coeff_u56_c_`var'_x`i' = .
		gen mf_se_u56_c_`var'_x`i' = .
	}
}

********************************************************************************
** Units spatial heterogeneity
* Part 4: loop over bandwidths for means >=1918
* Part 5(a-c): loop over bandwidth x polynomials for units >=1918
* Part 6: loop over bandwidths for means >=1956
* Part 7(a-c): loop over bandwith x polynomials for units >=1956
********************************************************************************
levelsof county, local(levels) 

foreach l of local levels {
	
	di ""
	di "*** `l' ***"

	tab county if county == "`l'"
	
	********************************************************************************
	** Part 4: units built after 1918 with dupac, height, mf allowed 
	********************************************************************************
	*****loop over different bandwidth
	foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		di ""
		di "*** bandwidth `d' ***"
		di "********************************************************************************"
		di "** means for `l' at bandwidth `d' >=1918"
		di "********************************************************************************"

		* only_du
		di "means for `l': ONLY_DU, RELAXED SIDE ONLY, year_built >= 1918"
		sum num_units1  if county == "`l'" & only_du == 1 & year_built >= 1918 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': ONLY_DU, STRICT SIDE ONLY, year_built >= 1918"
		sum num_units1  if county == "`l'" & only_du == 1 & year_built >= 1918 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': ONLY_DU, BOTH SIDES, year_built >= 1918"
		sum num_units1  if county == "`l'" & only_du == 1 & year_built >= 1918 & dist <= `d' 	

		* du_he
		di "means for `l': DU_HE, RELAXED SIDE ONLY, year_built >= 1918"
		sum num_units1 if county == "`l'" & du_he == 1 & year_built >= 1918 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': DU_HE, STRICT SIDE ONLY, year_built >= 1918"
		sum num_units1 if county == "`l'" & du_he == 1 & year_built >= 1918 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': DU_HE, BOTH SIDES, year_built >= 1918"	
		sum num_units1 if county == "`l'" & du_he == 1 & year_built >= 1918 & dist <= 0.2 	
		
		* mf_du
		di "means for `l': MF_DU, RELAXED SIDE ONLY, year_built >= 1918"
		sum num_units1 if county == "`l'" & mf_du == 1 & year_built >= 1918 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': MF_DU, STRICT SIDE ONLY, year_built >= 1918"
		sum num_units1 if county == "`l'" & mf_du == 1 & year_built >= 1918 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': MF_DU, BOTH SIDES, year_built >= 1918" 
		sum num_units1 if county == "`l'" & mf_du == 1 & year_built >= 1918 & dist <= `d'	

		* only_mf
		di "means for `l': ONLY_MF, RELAXED SIDE ONLY, year_built >= 1918"
		sum num_units1  if county == "`l'" & only_mf == 1 & year_built >= 1918 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': ONLY_MF, STRICT SIDE ONLY, year_built >= 1918"
		sum num_units1  if county == "`l'" & only_mf == 1 & year_built >= 1918 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': ONLY_MF, BOTH SIDES, year_built >= 1918"
		sum num_units1  if county == "`l'" & only_mf == 1 & year_built >= 1918 & dist <= `d'
	} // end of bandwith loop on line 1112
	
	********************************************************************************
	** Part 5: units with only_du du_he mf_du >= 1918 (run quietly)
	********************************************************************************
	** regressions for num_units1 w/ year_built >= 1918
	di ""
	di "*** num_units1 regressions >=1918***"
	quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)
		
		********************************************************************************
		** Part 5a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units1 only_du >=1918..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_du == 1 & dist <= `d' & year_built >= 1918 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
				
				* run regression
				capture reg num_units1 dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
				
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 only_du >=1918 == `e(N)'"
			
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_u18_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_u18_c_`var'_x`i' = _se[dupac] if county == "`l'"	
				}
			
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg num_units1 only_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg num_units1 only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1176
	
		********************************************************************************
		** Part 5b: du_he
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units du_he >=1918..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions du_he == 1 & dist <= `d' & year_built >= 1918 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
					
				* run regression
				capture reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
						
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 du_he >=1918 == `e(N)'"
						
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXh_c_u18_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace height_dXh_c_u18_c_`var'_x`i' = _b[height] if county == "`l'"
					replace duXhe_dXh_c_u18_c_`var'_x`i' = _b[c.height#c.dupac] if county == "`l'"
					replace dupac_dXh_s_u18_c_`var'_x`i' = _se[dupac] if county == "`l'"
					replace height_dXh_s_u18_c_`var'_x`i' = _se[height] if county == "`l'"
					replace duXhe_dXh_s_u18_c_`var'_x`i' = _se[c.height#c.dupac] if county == "`l'"
				}
						
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg num_units1 du_he, l==`l', d==`d', ^i==`i' >=1918: moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg num_units1 du_he, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1228
		
		********************************************************************************
		** Part 5c: mf_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units mf_du >=1918..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions mf_du == 1 & dist <= `d' & year_built >= 1918 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
					
			* run regression
			capture reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions' , vce(cluster lam_seg) 			
					
			* display observation count 
			n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 mf_du >=1918 == `e(N)'"
					
			* if no error, store coefficients and standard errors
			if c(rc) == 0 {
				replace dupac_dXmf_c_u18_c_`var'_x`i' = _b[dupac] if county == "`l'"
				replace mf_dXmf_c_u18_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
				replace duXmf_dXmf_c_u18_c_`var'_x`i' = _b[1.mf_allowed#c.dupac] if county == "`l'"
				replace dupac_dXmf_s_u18_c_`var'_x`i' = _se[dupac] if county == "`l'"
				replace mf_dXmf_s_u18_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
				replace duXmf_dXmf_s_u18_c_`var'_x`i' = _se[1.mf_allowed#c.dupac] if county == "`l'"
			}

			* else if error 2001, raise insufficient results error
			else if c(rc) == 2001 {
				n di as error "Insufficient results for reg num_units1 mf_du, l==`l', d==`d', ^i==`i' >=1918: moving on..."
			}

			* else, catch all other errors
			else {
				local rc = _rc			
				n di as error "reg num_units1 mf_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
			}
		}
			
		* else, not enough obs to run regression
		else {
			n di as error `"not enough observations to run `regression_conditions'"'
		}
	
		} // end of polynomial loop at line 1284
		
		********************************************************************************
		** Part 5d: only_mf
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units1 only_mf >=1918..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_mf == 1 & dist <= `d' & year_built >= 1918 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
				
				* run regression
				capture reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 							
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 only_mf >=1918 == `e(N)'"
			
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace mf_coeff_u18_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace mf_se_u18_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"	
				}
			
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg num_units1 only_mf, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg num_units1 only_mf, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1341
	} // end of bandwidth loop on line 1167
	
	********************************************************************************
	** Part 6: units built after 1956 with dupac, height, mf allowed 
	********************************************************************************
	*****loop over different bandwidth
	foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		di ""
		di "*** bandwidth `d' ***"
		di "********************************************************************************"
		di "** means for `l' at bandwidth `d' >=1956"
		di "********************************************************************************"

		* only_du
		di "means for `l': ONLY_DU, RELAXED SIDE ONLY, year_built >= 1956"
		sum num_units1  if county == "`l'" & only_du == 1 & year_built >= 1956 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': ONLY_DU, STRICT SIDE ONLY, year_built >= 1956"
		sum num_units1  if county == "`l'" & only_du == 1 & year_built >= 1956 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': ONLY_DU, BOTH SIDES, year_built >= 1956"
		sum num_units1  if county == "`l'" & only_du == 1 & year_built >= 1956 & dist <= `d' 	

		* du_he
		di "means for `l': DU_HE, RELAXED SIDE ONLY, year_built >= 1956"
		sum num_units1 if county == "`l'" & du_he == 1 & year_built >= 1956 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': DU_HE, STRICT SIDE ONLY, year_built >= 1956"
		sum num_units1 if county == "`l'" & du_he == 1 & year_built >= 1956 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': DU_HE, BOTH SIDES, year_built >= 1956"	
		sum num_units1 if county == "`l'" & du_he == 1 & year_built >= 1956 & dist <= 0.2 	
		
		* mf_du
		di "means for `l': MF_DU, RELAXED SIDE ONLY, year_built >= 1956"
		sum num_units1 if county == "`l'" & mf_du == 1 & year_built >= 1956 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': MF_DU, STRICT SIDE ONLY, year_built >= 1956"
		sum num_units1 if county == "`l'" & mf_du == 1 & year_built >= 1956 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': MF_DU, BOTH SIDES, year_built >= 1956" 
		sum num_units1 if county == "`l'" & mf_du == 1 & year_built >= 1956 & dist <= `d'
		
		* only_mf
		di "means for `l': ONLY_MF, RELAXED SIDE ONLY, year_built >= 1956"
		sum num_units1  if county == "`l'" & only_mf == 1 & year_built >= 1956 & (dist_both <= `d' & dist_both >= 0)
		
		di "means for `l': ONLY_MF, STRICT SIDE ONLY, year_built >= 1956"
		sum num_units1  if county == "`l'" & only_mf == 1 & year_built >= 1956 & (dist_both >= -`d' & dist_both < 0)
		
		di "means for `l': ONLY_MF, BOTH SIDES, year_built >= 1956"
		sum num_units1  if county == "`l'" & only_mf == 1 & year_built >= 1956 & dist <= `d' 	
	} // end of bandwith loop on line 1393
	
	********************************************************************************
	** Part 7: units with only_du du_he mf_du (run quietly) >=1956
	********************************************************************************
	** regressions for num_units1 w/ year_built >= 1956
	di ""
	di "*** num_units1 regressions >=1956***"
	quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)
		
		********************************************************************************
		** Part 7a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units1 only_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_du == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
				
				* run regression
				capture reg num_units1 dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
				
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 only_du >=1956 == `e(N)'"
			
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_u56_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_u56_c_`var'_x`i' = _se[dupac] if county == "`l'"	
				}
			
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg num_units1 only_du, l==`l', d==`d', ^i==`i' >=1956: moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg num_units1 only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1457
	
		********************************************************************************
		** Part 7b: du_he
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units du_he >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions du_he == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
					
				* run regression
				capture reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
						
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 du_he >=1956 == `e(N)'"
						
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXh_c_u56_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace height_dXh_c_u56_c_`var'_x`i' = _b[height] if county == "`l'"
					replace duXhe_dXh_c_u56_c_`var'_x`i' = _b[c.height#c.dupac] if county == "`l'"
					replace dupac_dXh_s_u56_c_`var'_x`i' = _se[dupac] if county == "`l'"
					replace height_dXh_s_u56_c_`var'_x`i' = _se[height] if county == "`l'"
					replace duXhe_dXh_s_u56_c_`var'_x`i' = _se[c.height#c.dupac] if county == "`l'"
				}
						
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg num_units1 du_he, l==`l', d==`d', ^i==`i' >=1956: moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg num_units1 du_he, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1509
		
		********************************************************************************
		** Part 7c: mf_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units mf_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions mf_du == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
					
			* run regression
			capture reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions' , vce(cluster lam_seg) 			
					
			* display observation count 
			n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 mf_du >=1956 == `e(N)'"
					
			* if no error, store coefficients and standard errors
			if c(rc) == 0 {
				replace dupac_dXmf_c_u56_c_`var'_x`i' = _b[dupac] if county == "`l'"
				replace mf_dXmf_c_u56_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
				replace duXmf_dXmf_c_u56_c_`var'_x`i' = _b[1.mf_allowed#c.dupac] if county == "`l'"
				replace dupac_dXmf_s_u56_c_`var'_x`i' = _se[dupac] if county == "`l'"
				replace mf_dXmf_s_u56_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
				replace duXmf_dXmf_s_u56_c_`var'_x`i' = _se[1.mf_allowed#c.dupac] if county == "`l'"
			}

			* else if error 2001, raise insufficient results error
			else if c(rc) == 2001 {
				n di as error "Insufficient results for reg num_units1 mf_du, l==`l', d==`d', ^i==`i' >=1956: moving on..."
			}

			* else, catch all other errors
			else {
				local rc = _rc			
				n di as error "reg num_units1 mf_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
			}
		}
			
		* else, not enough obs to run regression
		else {
			n di as error `"not enough observations to run `regression_conditions'"'
		}
		} // end of polynomial loop at line 1565	

		********************************************************************************
		** Part 7d: only_mf
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for num_units1 only_mf >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_mf == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)
	
			* tests if there are observations, if yes run regression
			count if num_units1 != . & `regression_conditions'
			local a = r(N)
				
			if `a'>1 {
				
				* run regression
				capture reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
				
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg num_units1 only_mf >=1956 == `e(N)'"
			
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace mf_coeff_u56_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace mf_se_u56_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"	
				}
			
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg num_units1 only_mf, l==`l', d==`d', ^i==`i' >=1956: moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg num_units1 only_mf, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1621
	} // end of bandwidth loop on line 1448
} // end of county/community type loop on line 1101


********************************************************************************
** t statistics
********************************************************************************
*loop over different bandwidth
quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2{ 
	local var = round(`d'*100,1)
	
	*loop over different polynomial distance trends
	forvalues i = 1/5{	
		gen t_dupac_coeff_u18_c_`var'_x`i' = dupac_coeff_u18_c_`var'_x`i'/dupac_se_u18_c_`var'_x`i'
		gen t_dupac_coeff_u56_c_`var'_x`i' = dupac_coeff_u56_c_`var'_x`i'/dupac_se_u56_c_`var'_x`i'

		gen t_dupac_dXh_c_u18_c_`var'_x`i' = dupac_dXh_c_u18_c_`var'_x`i'/dupac_dXh_s_u18_c_`var'_x`i'
		gen t_height_dXh_c_u18_c_`var'_x`i' = height_dXh_c_u18_c_`var'_x`i'/height_dXh_s_u18_c_`var'_x`i'
		gen t_duXhe_dXh_c_u18_c_`var'_x`i' = duXhe_dXh_c_u18_c_`var'_x`i'/duXhe_dXh_s_u18_c_`var'_x`i'
		gen t_dupac_dXh_c_u56_c_`var'_x`i' = dupac_dXh_c_u56_c_`var'_x`i'/dupac_dXh_s_u56_c_`var'_x`i'
		gen t_height_dXh_c_u56_c_`var'_x`i' = height_dXh_c_u56_c_`var'_x`i'/height_dXh_s_u56_c_`var'_x`i'
		gen t_duXhe_dXh_c_u56_c_`var'_x`i' = duXhe_dXh_c_u56_c_`var'_x`i'/duXhe_dXh_s_u56_c_`var'_x`i'

		gen t_dupac_dXmf_c_u18_c_`var'_x`i' = dupac_dXmf_c_u18_c_`var'_x`i'/dupac_dXmf_s_u18_c_`var'_x`i'
		gen t_mf_dXmf_c_u18_c_`var'_x`i' = mf_dXmf_c_u18_c_`var'_x`i'/mf_dXmf_s_u18_c_`var'_x`i'
		gen t_duXmf_dXmf_c_u18_c_`var'_x`i' = duXmf_dXmf_c_u18_c_`var'_x`i'/duXmf_dXmf_s_u18_c_`var'_x`i'
		gen t_dupac_dXmf_c_u56_c_`var'_x`i' = dupac_dXmf_c_u56_c_`var'_x`i'/dupac_dXmf_s_u56_c_`var'_x`i'
		gen t_mf_dXmf_c_u56_c_`var'_x`i' = mf_dXmf_c_u56_c_`var'_x`i'/mf_dXmf_s_u56_c_`var'_x`i'
		gen t_duXmf_dXmf_c_u56_c_`var'_x`i' = duXmf_dXmf_c_u56_c_`var'_x`i'/duXmf_dXmf_s_u56_c_`var'_x`i'
		
		gen t_mf_coeff_u18_c_`var'_x`i' = mf_coeff_u18_c_`var'_x`i'/mf_se_u18_c_`var'_x`i'
		gen t_mf_coeff_u56_c_`var'_x`i' = mf_coeff_u56_c_`var'_x`i'/mf_se_u56_c_`var'_x`i'
	}
}


/* save only these coefficients as separate data set to be able to make maps of 
spatial variation */

* keep only one observation per county
by county, sort: gen nvals = _n == 1
keep if nvals == 1

#delimit ;
	keep county county_fip 
	t_dupac_coeff_u18_c_* dupac_coeff_u18_c_* dupac_se_u18_c_* 
	t_dupac_coeff_u56_c_* dupac_coeff_u56_c_* dupac_se_u56_c_*  
	t_dupac_dXh_c_u18_c_* dupac_dXh_c_u18_c_* dupac_dXh_s_u18_c_* 
	t_height_dXh_c_u18_c_* height_dXh_c_u18_c_* height_dXh_s_u18_c_* 
	t_duXhe_dXh_c_u18_c_* duXhe_dXh_c_u18_c_* duXhe_dXh_s_u18_c_*
	t_dupac_dXh_c_u56_c_* dupac_dXh_c_u56_c_* dupac_dXh_s_u56_c_*
	t_height_dXh_c_u56_c_* height_dXh_c_u56_c_* height_dXh_s_u56_c_*
	t_duXhe_dXh_c_u56_c_* duXhe_dXh_c_u56_c_* duXhe_dXh_s_u56_c_* 
	t_dupac_dXmf_c_u18_c_* dupac_dXmf_c_u18_c_* dupac_dXmf_s_u18_c_* 
	t_mf_dXmf_c_u18_c_* mf_dXmf_c_u18_c_* mf_dXmf_s_u18_c_*
	t_duXmf_dXmf_c_u18_c_* duXmf_dXmf_c_u18_c_* duXmf_dXmf_s_u18_c_* 
	t_dupac_dXmf_c_u56_c_* dupac_dXmf_c_u56_c_* dupac_dXmf_s_u56_c_* 
	t_mf_dXmf_c_u56_c_* mf_dXmf_c_u56_c_* mf_dXmf_s_u56_c_*
	t_duXmf_dXmf_c_u56_c_* duXmf_dXmf_c_u56_c_* duXmf_dXmf_s_u56_c_*
	t_mf_coeff_u18_c_* mf_coeff_u18_c_* mf_se_u18_c_* 
	t_mf_coeff_u56_c_* mf_coeff_u56_c_* mf_se_u56_c_*;

***convert dataset to long format, each coefficient has 5(different bandwidth)*5(different polynomial trends)*4(counties) variations
reshape long 	t_dupac_coeff_u18_c dupac_coeff_u18_c dupac_se_u18_c
	t_dupac_coeff_u56_c dupac_coeff_u56_c dupac_se_u56_c
	t_dupac_dXh_c_u18_c dupac_dXh_c_u18_c dupac_dXh_s_u18_c
	t_height_dXh_c_u18_c height_dXh_c_u18_c height_dXh_s_u18_c
	t_duXhe_dXh_c_u18_c duXhe_dXh_c_u18_c duXhe_dXh_s_u18_c
	t_dupac_dXh_c_u56_c dupac_dXh_c_u56_c dupac_dXh_s_u56_c
	t_height_dXh_c_u56_c height_dXh_c_u56_c height_dXh_s_u56_c
	t_duXhe_dXh_c_u56_c duXhe_dXh_c_u56_c duXhe_dXh_s_u56_c
	t_dupac_dXmf_c_u18_c dupac_dXmf_c_u18_c dupac_dXmf_s_u18_c
	t_mf_dXmf_c_u18_c mf_dXmf_c_u18_c mf_dXmf_s_u18_c
	t_duXmf_dXmf_c_u18_c duXmf_dXmf_c_u18_c duXmf_dXmf_s_u18_c 
	t_dupac_dXmf_c_u56_c dupac_dXmf_c_u56_c dupac_dXmf_s_u56_c 
	t_mf_dXmf_c_u56_c mf_dXmf_c_u56_c mf_dXmf_s_u56_c
	t_duXmf_dXmf_c_u56_c duXmf_dXmf_c_u56_c duXmf_dXmf_s_u56_c
	t_mf_coeff_u18_c mf_coeff_u18_c mf_se_u18_c
	t_mf_coeff_u56_c mf_coeff_u56_c mf_se_u56_c, i(county) j(spec) s;

#delimit cr


********************************************************************************
** save output data 
** CHANGE PATH ACCORDINGLY HERE
********************************************************************************
save "postQJE_spatial_unit_coeff_MAPCdefinition.dta", replace
restore


/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Regression 2 linear probability 2-3 & 4+ unit 1918 and 1956                */
/*                                                                            */
/*----------------------------------------------------------------------------*/


********************************************************************************
** define distance polynomial trends varlist
********************************************************************************
local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist2 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"
local distance_varlist4 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4"
local distance_varlist5 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4 r_dist_relax5 r_dist_strict5"


********************************************************************************
** county/community type regresstions for units
********************************************************************************
preserve 

keep if year == 2018

keep if only_du ==1 | du_he == 1 | mf_du == 1 | only_mf == 1

* only_du Supply
quietly foreach var in 2 5 10 15 20{ 
	forvalues i=1/5{
		gen dupac_coeff_23_c_`var'_x`i' = .
		gen dupac_coeff_4_c_`var'_x`i' = . 
		gen dupac_se_23_c_`var'_x`i' = .
		gen dupac_se_4_c_`var'_x`i' = . 
	}
}

* du_he Supply
quietly foreach var in 2 5 10 15 20{ 
	forvalues i=1/5{
		gen dupac_dXh_c_23_c_`var'_x`i' = .
		gen height_dXh_c_23_c_`var'_x`i' = .
		gen duXhe_dXh_c_23_c_`var'_x`i' = .
		gen dupac_dXh_s_23_c_`var'_x`i' = .
		gen height_dXh_s_23_c_`var'_x`i' = .
		gen duXhe_dXh_s_23_c_`var'_x`i' = .
		gen dupac_dXh_c_4_c_`var'_x`i' = .
		gen height_dXh_c_4_c_`var'_x`i' = .
		gen duXhe_dXh_c_4_c_`var'_x`i' = .
		gen dupac_dXh_s_4_c_`var'_x`i' = .
		gen height_dXh_s_4_c_`var'_x`i' = .
		gen duXhe_dXh_s_4_c_`var'_x`i' = .
	}
}

* mf_du Supply
quietly foreach var in 2 5 10 15 20{ 
	forvalues i=1/5{
		gen dupac_dXmf_c_23_c_`var'_x`i' = .
		gen mf_dXmf_c_23_c_`var'_x`i' = .
		gen duXmf_dXmf_c_23_c_`var'_x`i' = .
		gen dupac_dXmf_s_23_c_`var'_x`i' = .
		gen mf_dXmf_s_23_c_`var'_x`i' = .
		gen duXmf_dXmf_s_23_c_`var'_x`i' = .
		gen dupac_dXmf_c_4_c_`var'_x`i' = .
		gen mf_dXmf_c_4_c_`var'_x`i' = .
		gen duXmf_dXmf_c_4_c_`var'_x`i' = .
		gen dupac_dXmf_s_4_c_`var'_x`i' = .
		gen mf_dXmf_s_4_c_`var'_x`i' = .
		gen duXmf_dXmf_s_4_c_`var'_x`i' = .	
	}
}

* only_mf Supply
quietly foreach var in 2 5 10 15 20{ 
	forvalues i=1/5{
		gen mf_coeff_23_c_`var'_x`i' = .
		gen mf_coeff_4_c_`var'_x`i' = . 
		gen mf_se_23_c_`var'_x`i' = .
		gen mf_se_4_c_`var'_x`i' = . 
	}
}


********************************************************************************
** Supply spatial heterogeneity
* Part 8: loop over bandwidths for means
* Part 9(a-c): loop over bandwidth x polynomials for 2-3 units (gentle density)
* Part 10(a-c): loop over bandwith x polynomials for 4+ units (high density)
********************************************************************************
* cycle through counties to store county-level coeff/se estimates
levelsof county, local(levels) 

foreach l of local levels {
	
	di ""
	di "*** `l' ***"

	tab county if county == "`l'"

	********************************************************************************	
	** Part 8: sum means county var stats
	********************************************************************************	
	*****loop over different bandwidth
	foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		di ""
		di "*** bandwidth `d' ***"
		di "********************************************************************************"
		di "** means for `l' at bandwidth `d'"
		di "********************************************************************************"

		* only_du
		di "means for `l': ONLY_DU, RELAXED SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac  if county == "`l'" & only_du == 1 & dist_both>=0 & dist_both<=`d'
		
		di "means for `l': ONLY_DU, STRICT SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac  if county == "`l'" & only_du == 1 & dist_both< 0 & dist_both>=-`d'
		
		di "means for `l': ONLY_DU, BOTH SIDES"
		sum fam23_1 fam4plus_1 dupac  if county == "`l'" & only_du == 1 &  dist <= `d'
		
		* du_he
		di "means for `l': DU_HE, RELAXED SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac height   if county == "`l'" & du_he == 1 & dist_both>=0 & dist_both<=`d'
		
		di "means for `l': DU_HE, STRICT SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac height   if county == "`l'" & du_he == 1 & dist_both< 0 & dist_both>=-`d'	
		
		di "means for `l': DU_HE, BOTH SIDES"
		sum fam23_1 fam4plus_1 dupac height   if county == "`l'" & du_he == 1 & dist <= `d'	
		
		* mf_du
		di "means for `l': MF_DU, RELAXED SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac mf_allowed   if county == "`l'" & mf_du == 1 & dist_both>=0 & dist_both<=`d'
		
		di "means for `l': MF_DU, STRICT SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac mf_allowed   if county == "`l'" & mf_du == 1 & dist_both< 0 & dist_both>=-`d'
		
		di "means for `l': MF_DU, BOTH SIDES" 
		sum fam23_1 fam4plus_1 dupac mf_allowed   if county == "`l'" & mf_du == 1 & dist <= `d'
		
		* only_mf
		di "means for `l': ONLY_MF, RELAXED SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac  if county == "`l'" & only_mf == 1 & dist_both>=0 & dist_both<=`d'
		
		di "means for `l': ONLY_MF, STRICT SIDE ONLY"
		sum fam23_1 fam4plus_1 dupac  if county == "`l'" & only_mf == 1 & dist_both< 0 & dist_both>=-`d'
		
		di "means for `l': ONLY_MF, BOTH SIDES"
		sum fam23_1 fam4plus_1 dupac  if county == "`l'" & only_mf == 1 &  dist <= `d'
	} // end of bandwith loop on line 1862
	
	
	********************************************************************************	
	** Part 9: gently density, 2-3 units
	********************************************************************************	
	** regressions for num_units1 w/ year_built >= 1956
	di ""
	di "*** fam23_1 regressions ***"
	quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)

		********************************************************************************		
		** Part 9a: fam23_1 only_du
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam23_1 only_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_du == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam23_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
					
				* run regression
				capture reg fam23_1 dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 
		
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam23_1 only_du == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_23_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_23_c_`var'_x`i' = _se[dupac] if county == "`l'"
				}
					
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam23_1 only_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam23_1 only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1927

		********************************************************************************		
		** Part 9b: fam23_1, du_he
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam23_1 only_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions du_he == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam23_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
				
				* run regression
				cap n reg fam23_1 c.height##c.dupac  i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg)   	
					
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam23_1 du_he == `e(N)'"
					
				* tab a bunch of stuff for Amrita
				noisily unique lam_seg if `regression_conditions' & fam23_1!= .
				noisily tab dupac if `regression_conditions' & fam23_1!=.
				noisily tab height if `regression_conditions' & fam23_1!=.
				noisily tab dupac height if `regression_conditions' & fam23_1!=.

				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXh_c_23_c_`var'_x`i' = _b[dupac] if county == "`l'" 
					replace height_dXh_c_23_c_`var'_x`i' = _b[height] if county == "`l'" 
					replace duXhe_dXh_c_23_c_`var'_x`i' = _b[c.height#c.dupac] if county == "`l'" 
					replace dupac_dXh_s_23_c_`var'_x`i' = _se[dupac] if county == "`l'" 
					replace height_dXh_s_23_c_`var'_x`i' = _se[height] if county == "`l'" 
					replace duXhe_dXh_s_23_c_`var'_x`i' = _se[c.height#c.dupac] if county == "`l'" 
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam23_1 du_he, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam23_1 du_he, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 1979
		
		********************************************************************************		
		** Part 9c: fam23_1, mf_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam23_1 mf_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions mf_du == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam23_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
						
				* run regression
				capture reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg)   	
					
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam23_1 mf_du == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXmf_c_23_c_`var'_x`i' = _b[dupac] if county == "`l'" 
					replace mf_dXmf_c_23_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'" 
					replace duXmf_dXmf_c_23_c_`var'_x`i' = _b[1.mf_allowed#c.dupac] if county == "`l'" 
					replace dupac_dXmf_s_23_c_`var'_x`i' = _se[dupac] if county == "`l'" 
					replace mf_dXmf_s_23_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'" 
					replace duXmf_dXmf_s_23_c_`var'_x`i' = _se[1.mf_allowed#c.dupac] if county == "`l'" 
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam23_1 mf_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam23_1 mf_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 2041
		
		********************************************************************************		
		** Part 9d: fam23_1 only_mf
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam23_1 only_mf >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_mf == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam23_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
					
				* run regression
				capture reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 
		
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam23_1 only_mf == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace mf_coeff_23_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace mf_se_23_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
				}
					
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam23_1 only_mf, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam23_1 only_mf, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 2097
	} // end of bandwith loop on line 1918
		
	********************************************************************************	
	** Part 10: high density, 4+ units
	********************************************************************************	
	** regressions for num_units1 w/ year_built >= 1956
	di ""
	di "*** fam4plus_1 regressions ***"
	quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)

		********************************************************************************		
		** Part 10a: fam4plus_1 only_du
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam4plus_1 only_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_du == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam4plus_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
					
				* run regression
				capture reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 
		
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam4plus_1 only_du == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_coeff_4_c_`var'_x`i' = _b[dupac] if county == "`l'"
					replace dupac_se_4_c_`var'_x`i' = _se[dupac] if county == "`l'"
				}
					
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam4plus_1 only_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam4plus_1 only_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 2161

		********************************************************************************		
		** Part 10b: fam4plus_1, du_he
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam4plus_1 only_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions du_he == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam4plus_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
				
				* run regression
				cap n reg fam4plus_1 c.height##c.dupac  i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg)   	
					
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam4plus_1 du_he == `e(N)'"
					
				* tab a bunch of stuff for Amrita
				noisily unique lam_seg if `regression_conditions' & fam4plus_1!= .
				noisily tab dupac if `regression_conditions' & fam4plus_1!=.
				noisily tab height if `regression_conditions' & fam4plus_1!=.
				noisily tab dupac height if `regression_conditions' & fam4plus_1!=.

				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXh_c_4_c_`var'_x`i' = _b[dupac] if county == "`l'" 
					replace height_dXh_c_4_c_`var'_x`i' = _b[height] if county == "`l'" 
					replace duXhe_dXh_c_4_c_`var'_x`i' = _b[c.height#c.dupac] if county == "`l'" 
					replace dupac_dXh_s_4_c_`var'_x`i' = _se[dupac] if county == "`l'" 
					replace height_dXh_s_4_c_`var'_x`i' = _se[height] if county == "`l'" 
					replace duXhe_dXh_s_4_c_`var'_x`i' = _se[c.height#c.dupac] if county == "`l'" 
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam4plus_1 du_he, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam4plus_1 du_he, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 2213
		
		********************************************************************************		
		** Part 10c: fam4plus_1, mf_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam4plus_1 mf_du >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions mf_du == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam4plus_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
						
				* run regression
				capture reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg)   	
					
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam4plus_1 mf_du == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace dupac_dXmf_c_4_c_`var'_x`i' = _b[dupac] if county == "`l'" 
					replace mf_dXmf_c_4_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'" 
					replace duXmf_dXmf_c_4_c_`var'_x`i' = _b[1.mf_allowed#c.dupac] if county == "`l'" 
					replace dupac_dXmf_s_4_c_`var'_x`i' = _se[dupac] if county == "`l'" 
					replace mf_dXmf_s_4_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'" 
					replace duXmf_dXmf_s_4_c_`var'_x`i' = _se[1.mf_allowed#c.dupac] if county == "`l'" 
				}
				
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam4plus_1 mf_du, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam4plus_1 mf_du, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 2275
		
		********************************************************************************		
		** Part 10d: fam4plus_1 only_mf
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1/5 {
			n di ""
			n di "********************************************************************************"
			n di "** Running regressions for fam4plus_1 only_mf >=1956..."
			n di "** in `l'"
			n di "** at bandwidth `d'"
			n di "** with polynomial ^`i'"
			n di "********************************************************************************"

			* set regression conditions
			local regression_conditions only_mf == 1 & dist <= `d' & year_built >= 1956 & county == "`l'" & (year == 2018)

			* tests if if there are observations run the regression
			count if fam4plus_1 != . & `regression_conditions'
			local a = r(N)
			
			if `a'>1 { 
					
				* run regression
				capture reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 
		
				* display observation count 
				n di "# of obs. for `l' at bandwith `d' with polynomial ^`i' for reg fam4plus_1 only_mf == `e(N)'"
					
				* if no error, store coefficients and standard errors
				if c(rc) == 0 {
					replace mf_coeff_4_c_`var'_x`i' = _b[1.mf_allowed] if county == "`l'"
					replace mf_se_4_c_`var'_x`i' = _se[1.mf_allowed] if county == "`l'"
				}
					
				* else if error 2001, raise insufficient results error
				else if c(rc) == 2001 {
					n di as error "Insufficient results for reg fam4plus_1 only_mf, l==`l', d==`d', ^i==`i': moving on..."
				}

				* else, catch all other errors
				else {
					local rc = _rc			
					n di as error "reg fam4plus_1 only_mf, l==`l', d==`d', ^i==`i' caused error r(`rc')"
				}
			}
				
			* else, not enough obs to run regression
			else {
				n di as error `"not enough observations to run `regression_conditions'"'
			}
		} // end of polynomial loop at line 2331
	} // end of bandwith loop on line 2152
} // end of county/community type loop on line 1851
		
			
********************************************************************************
** t statistics
********************************************************************************
*loop over different bandwidth
quietly foreach d of numlist 0.02 0.05 0.1 0.15 0.2 { 
	local var = round(`d'*100,1)
	
	*loop over different polynomial distance trends
	forvalues i = 1/5 {	
		*loop over different polynomial distance trends
		gen t_dupac_coeff_23_c_`var'_x`i' = dupac_coeff_23_c_`var'_x`i'/dupac_se_23_c_`var'_x`i'
		gen t_dupac_coeff_4_c_`var'_x`i' = dupac_coeff_4_c_`var'_x`i'/dupac_se_4_c_`var'_x`i'

		gen t_dupac_dXh_c_23_c_`var'_x`i' = dupac_dXh_c_23_c_`var'_x`i'/dupac_dXh_s_23_c_`var'_x`i'
		gen t_height_dXh_c_23_c_`var'_x`i' = height_dXh_c_23_c_`var'_x`i'/height_dXh_s_23_c_`var'_x`i'
		gen t_duXhe_dXh_c_23_c_`var'_x`i' = duXhe_dXh_c_23_c_`var'_x`i'/duXhe_dXh_s_23_c_`var'_x`i'
		gen t_dupac_dXh_c_4_c_`var'_x`i' = dupac_dXh_c_4_c_`var'_x`i'/dupac_dXh_s_4_c_`var'_x`i'
		gen t_height_dXh_c_4_c_`var'_x`i' = height_dXh_c_4_c_`var'_x`i'/height_dXh_s_4_c_`var'_x`i'
		gen t_duXhe_dXh_c_4_c_`var'_x`i' = duXhe_dXh_c_4_c_`var'_x`i'/duXhe_dXh_s_4_c_`var'_x`i'

		gen t_dupac_dXmf_c_23_c_`var'_x`i' = dupac_dXmf_c_23_c_`var'_x`i'/dupac_dXmf_s_23_c_`var'_x`i'
		gen t_mf_dXmf_c_23_c_`var'_x`i' = mf_dXmf_c_23_c_`var'_x`i'/mf_dXmf_s_23_c_`var'_x`i'
		gen t_duXmf_dXmf_c_23_c_`var'_x`i' = duXmf_dXmf_c_23_c_`var'_x`i'/duXmf_dXmf_s_23_c_`var'_x`i'
		gen t_dupac_dXmf_c_4_c_`var'_x`i' = dupac_dXmf_c_4_c_`var'_x`i'/dupac_dXmf_s_4_c_`var'_x`i'
		gen t_mf_dXmf_c_4_c_`var'_x`i' = mf_dXmf_c_4_c_`var'_x`i'/mf_dXmf_s_4_c_`var'_x`i'
		gen t_duXmf_dXmf_c_4_c_`var'_x`i' = duXmf_dXmf_c_4_c_`var'_x`i'/duXmf_dXmf_s_4_c_`var'_x`i'
		
		gen t_mf_coeff_23_c_`var'_x`i' = mf_coeff_23_c_`var'_x`i'/mf_se_23_c_`var'_x`i'
		gen t_mf_coeff_4_c_`var'_x`i' = mf_coeff_4_c_`var'_x`i'/mf_se_4_c_`var'_x`i'
	}
}

/* save only these coefficients as separate data set to be able to make maps of 
spatial variation */

* keep only one observation per county
by county, sort: gen nvals = _n == 1
keep if nvals == 1

#delimit ;
	keep 
	county county_fip 
	t_dupac_coeff_23_c_* dupac_coeff_23_c_* dupac_se_23_c_* 
	t_dupac_coeff_4_c_* dupac_coeff_4_c_* dupac_se_4_c_* 
	t_dupac_dXh_c_23_c_* dupac_dXh_c_23_c_* dupac_dXh_s_23_c_* 
	t_height_dXh_c_23_c_* height_dXh_c_23_c_* height_dXh_s_23_c_* 
	t_duXhe_dXh_c_23_c_* duXhe_dXh_c_23_c_* duXhe_dXh_s_23_c_*
	t_dupac_dXh_c_4_c_* dupac_dXh_c_4_c_* dupac_dXh_s_4_c_* 
	t_height_dXh_c_4_c_* height_dXh_c_4_c_* height_dXh_s_4_c_*
	t_duXhe_dXh_c_4_c_* duXhe_dXh_c_4_c_* duXhe_dXh_s_4_c_* 
	t_dupac_dXmf_c_23_c_* dupac_dXmf_c_23_c_* dupac_dXmf_s_23_c_* 
	t_mf_dXmf_c_23_c_* mf_dXmf_c_23_c_* mf_dXmf_s_23_c_*
	t_duXmf_dXmf_c_23_c_* duXmf_dXmf_c_23_c_* duXmf_dXmf_s_23_c_* 
	t_dupac_dXmf_c_4_c_* dupac_dXmf_c_4_c_* dupac_dXmf_s_4_c_* 
	t_mf_dXmf_c_4_c_* mf_dXmf_c_4_c_* mf_dXmf_s_4_c_*
	t_duXmf_dXmf_c_4_c_* duXmf_dXmf_c_4_c_* duXmf_dXmf_s_4_c_*
	t_mf_coeff_23_c_* mf_coeff_23_c_* mf_se_23_c_* 
	t_mf_coeff_4_c_* mf_coeff_4_c_* mf_se_4_c_*
;

reshape long t_dupac_coeff_23_c dupac_coeff_23_c dupac_se_23_c 
	t_dupac_coeff_4_c dupac_coeff_4_c dupac_se_4_c 
	t_dupac_dXh_c_23_c dupac_dXh_c_23_c dupac_dXh_s_23_c 
	t_height_dXh_c_23_c height_dXh_c_23_c height_dXh_s_23_c 
	t_duXhe_dXh_c_23_c duXhe_dXh_c_23_c duXhe_dXh_s_23_c
	t_dupac_dXh_c_4_c dupac_dXh_c_4_c dupac_dXh_s_4_c 
	t_height_dXh_c_4_c height_dXh_c_4_c height_dXh_s_4_c
	t_duXhe_dXh_c_4_c duXhe_dXh_c_4_c duXhe_dXh_s_4_c 
	t_dupac_dXmf_c_23_c dupac_dXmf_c_23_c dupac_dXmf_s_23_c 
	t_mf_dXmf_c_23_c mf_dXmf_c_23_c mf_dXmf_s_23_c
	t_duXmf_dXmf_c_23_c duXmf_dXmf_c_23_c duXmf_dXmf_s_23_c 
	t_dupac_dXmf_c_4_c dupac_dXmf_c_4_c dupac_dXmf_s_4_c 
	t_mf_dXmf_c_4_c mf_dXmf_c_4_c mf_dXmf_s_4_c
	t_duXmf_dXmf_c_4_c duXmf_dXmf_c_4_c duXmf_dXmf_s_4_c
	t_mf_coeff_23_c mf_coeff_23_c mf_se_23_c 
	t_mf_coeff_4_c mf_coeff_4_c mf_se_4_c, i(county) j(spec) s; 
#delimit cr

********************************************************************************
** save output data 
** CHANGE PATH ACCORDINGLY HERE
********************************************************************************
save "postQJE_spatial_supply_coeff_MAPCdefinition.dta", replace

restore


********************************************************************************
** END
********************************************************************************
log off
log close
clear all
