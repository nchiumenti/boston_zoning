clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postrestat_Spatial_Heterogeneity_mtlines" // <--- change when necessry

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES SETUP VERSION **

** NO CLUSTERING **

********************************************************************************
* File name:		"postrestat_Spatial_Heterogeneity.do"
*
* Project title:	Boston Zoning Paper
*
* Description:		
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		09/21/2021
* Updated:		02/11/2025
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
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load final dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear <-- this is the OG dataset, it is commented out because a post setup version loaded on line 75


********************************************************************************
** run postQJE within town setup file
********************************************************************************
// run "$DOPATH/postQJE_within_town_setup.do"

// run "$DOPATH/postREStat_within_town_setup_07102024.do" <-- this is a newer one but i am unsure what if any differences it has

use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear  // <-- this is the output that happens after running line 65 and 73, use this to cut down on time.


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line)
drop if _merge == 2
drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties

tab year // <-- used to verify future runs of the data

// use "$DATAPATH/postQJE_data_exports/postQJE_sample_data_2022-10-07/postQJE_testing_full.dta", clear <-- this was a testing dataset, we can ignore it as of 1/31/2025 when Nick wrote this

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

drop if def_1 == 2


********************************************************************************
**Define distance polynomial trends
********************************************************************************

gen r_dist_relax = relaxed*dist_both
gen r_dist_strict = strict*dist_both

gen r_dist_relax2 = r_dist_relax^2
gen r_dist_relax3 = r_dist_relax^3

gen r_dist_strict2 = r_dist_strict^2
gen r_dist_strict3 = r_dist_strict^3


/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Regression 1 linear probability rents and prices                           */
/*                                                                            */
/*----------------------------------------------------------------------------*/

********************************************************************************
** define distance polynomial trends varlist
********************************************************************************
local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"


********************************************************************************
** county/community type regresstions for rents and sale prices
********************************************************************************
* by renters vs owners
preserve 

keep if only_du ==1 | du_he == 1| mf_du == 1 | only_mf == 1

** define coeff stores
* direct effects, only_du
gen dupac_coeff_renters_c_20_x1 = .
gen dupac_coeff_owners_c_20_x1 = .
gen dupac_se_renters_c_20_x1 = .
gen dupac_se_owners_c_20_x1 = .

gen dupac_coeff_renters_c_20_x3 = .
gen dupac_coeff_owners_c_20_x3 = .
gen dupac_se_renters_c_20_x3 = .
gen dupac_se_owners_c_20_x3 = .

* direct effects, du_he
* renters
gen dupac_dXh_c_r_c_20_x1 = .
gen height_dXh_c_r_c_20_x1 = .
gen duXhe_dXh_c_r_c_20_x1 = .
gen dupac_dXh_s_r_c_20_x1 = .
gen height_dXh_s_r_c_20_x1 = .
gen duXhe_dXh_s_r_c_20_x1 = .

gen dupac_dXh_c_r_c_20_x3 = .
gen height_dXh_c_r_c_20_x3 = .
gen duXhe_dXh_c_r_c_20_x3 = .
gen dupac_dXh_s_r_c_20_x3 = .
gen height_dXh_s_r_c_20_x3 = .
gen duXhe_dXh_s_r_c_20_x3 = .
	
* owners
gen dupac_dXh_c_o_c_20_x1 = .
gen height_dXh_c_o_c_20_x1 = .
gen duXhe_dXh_c_o_c_20_x1 = .
gen dupac_dXh_s_o_c_20_x1 = .
gen height_dXh_s_o_c_20_x1 = .
gen duXhe_dXh_s_o_c_20_x1 = .

gen dupac_dXh_c_o_c_20_x3 = .
gen height_dXh_c_o_c_20_x3 = .
gen duXhe_dXh_c_o_c_20_x3 = .
gen dupac_dXh_s_o_c_20_x3 = .
gen height_dXh_s_o_c_20_x3 = .
gen duXhe_dXh_s_o_c_20_x3 = .

* direct effects, mf_du
gen dupac_dXmf_c_o_c_20_x1 = .
gen mf_dXmf_c_o_c_20_x1 = .
gen duXmf_dXmf_c_o_c_20_x1 = .
gen dupac_dXmf_s_o_c_20_x1 = .
gen mf_dXmf_s_o_c_20_x1 = .
gen duXmf_dXmf_s_o_c_20_x1 = .

gen dupac_dXmf_c_o_c_20_x3 = .
gen mf_dXmf_c_o_c_20_x3 = .
gen duXmf_dXmf_c_o_c_20_x3 = .
gen dupac_dXmf_s_o_c_20_x3 = .
gen mf_dXmf_s_o_c_20_x3 = .
gen duXmf_dXmf_s_o_c_20_x3 = .

* direct effects, only_mf
* direct Effects
gen mf_coeff_owners_c_20_x1 = .
gen mf_se_owners_c_20_x1 = .

gen mf_coeff_owners_c_20_x3 = .
gen mf_se_owners_c_20_x3 = .


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
	foreach d of numlist 0.2 {
		
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
	quietly foreach d of numlist 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)
		
		********************************************************************************	
		** Part 2a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1(2)3 {
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
				capture noisily reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year if `regression_conditions' , vce(cluster lam_seg) 
				
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
		** Part 2b: du_he
		********************************************************************************	
		*loop over different polynomial distance trends
		forvalues i = 1(2)3 {
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
	** Part 3: housing cost estimates with only_du du_he mf_du only_mf (NOTE! make sure to use log_saleprice)
	********************************************************************************	
	di ""
	di "*** log_saleprice regesssions ***"
	quietly foreach d of numlist 0.2 {

		* set local var name for bandwith
		local var = round(`d' * 100, 1)

		********************************************************************************	
		** Part 3a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1(2)3 {
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
				capture noisily reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				
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
		forvalues i = 1(2)3 {
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
		forvalues i = 1(2)3 {
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
				capture noisily reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				
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
		forvalues i = 1(2)3 {
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
				capture noisily reg  log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr if `regression_conditions', vce(cluster lam_seg) 
				
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
}

// stop

********************************************************************************
** t statistics
********************************************************************************
*loop over different bandwidth
quietly foreach d of numlist 0.2{ 
	local var = round(`d'*100,1)
	
	*loop over different polynomial distance trends
	forvalues i = 1(2)3 {

		gen t_dupac_coeff_renters_c_`var'_x`i' = dupac_coeff_renters_c_`var'_x`i'/dupac_se_renters_c_`var'_x`i'
		gen t_dupac_coeff_owners_c_`var'_x`i' = dupac_coeff_owners_c_`var'_x`i'/dupac_se_owners_c_`var'_x`i'

		gen t_dupac_dXh_c_r_c_`var'_x`i' = dupac_dXh_c_r_c_`var'_x`i'/dupac_dXh_s_r_c_`var'_x`i'
		gen t_height_dXh_c_r_c_`var'_x`i' = height_dXh_c_r_c_`var'_x`i'/height_dXh_s_r_c_`var'_x`i'
		gen t_duXhe_dXh_c_r_c_`var'_x`i' = duXhe_dXh_c_r_c_`var'_x`i'/duXhe_dXh_s_r_c_`var'_x`i'
		gen t_dupac_dXh_c_o_c_`var'_x`i' = dupac_dXh_c_o_c_`var'_x`i'/dupac_dXh_s_o_c_`var'_x`i'
		gen t_height_dXh_c_o_c_`var'_x`i' = height_dXh_c_o_c_`var'_x`i'/height_dXh_s_o_c_`var'_x`i'
		gen t_duXhe_dXh_c_o_c_`var'_x`i' = duXhe_dXh_c_o_c_`var'_x`i'/duXhe_dXh_s_o_c_`var'_x`i'

		gen t_dupac_dXmf_c_o_c_`var'_x`i' = dupac_dXmf_c_o_c_`var'_x`i'/dupac_dXmf_s_o_c_`var'_x`i'
		gen t_mf_dXmf_c_o_c_`var'_x`i' = mf_dXmf_c_o_c_`var'_x`i'/mf_dXmf_s_o_c_`var'_x`i'
		gen t_duXmf_dXmf_c_o_c_`var'_x`i' = duXmf_dXmf_c_o_c_`var'_x`i'/duXmf_dXmf_s_o_c_`var'_x`i'
		
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

	t_dupac_dXmf_c_o_c_* dupac_dXmf_c_o_c_* dupac_dXmf_s_o_c_* 
	t_mf_dXmf_c_o_c_* mf_dXmf_c_o_c_* mf_dXmf_s_o_c_* 
	t_duXmf_dXmf_c_o_c_* duXmf_dXmf_c_o_c_* duXmf_dXmf_s_o_c_* 

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
	t_dupac_dXmf_c_o_c dupac_dXmf_c_o_c dupac_dXmf_s_o_c 
	t_mf_dXmf_c_o_c mf_dXmf_c_o_c mf_dXmf_s_o_c 
	t_duXmf_dXmf_c_o_c duXmf_dXmf_c_o_c duXmf_dXmf_s_o_c 
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
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"


********************************************************************************
** county/community type regresstions for units
********************************************************************************
preserve

keep if year == 2018

keep if only_du ==1 | du_he == 1 | mf_du == 1 | only_mf == 1

* direct effects, only_du
quietly foreach var of numlist 20 { 
	forvalues i = 1(2)3 {
		gen dupac_coeff_u18_c_`var'_x`i' = .
		gen dupac_se_u18_c_`var'_x`i' = .
	}
}

* direct effects, du_he
quietly foreach var of numlist 20 { 
	forvalues i = 1(2)3 {
		*units (1918)
		gen dupac_dXh_c_u18_c_`var'_x`i' = .
		gen height_dXh_c_u18_c_`var'_x`i' = .
		gen duXhe_dXh_c_u18_c_`var'_x`i' = .
		gen dupac_dXh_s_u18_c_`var'_x`i' = .
		gen height_dXh_s_u18_c_`var'_x`i' = .
		gen duXhe_dXh_s_u18_c_`var'_x`i' = .
	}
}

* direct effects, mf_du
quietly foreach var of numlist 20 { 
	forvalues i = 1(2)3 {
		*units (1918)
		gen dupac_dXmf_c_u18_c_`var'_x`i' = .
		gen mf_dXmf_c_u18_c_`var'_x`i' = .
		gen duXmf_dXmf_c_u18_c_`var'_x`i' = .
		gen dupac_dXmf_s_u18_c_`var'_x`i' = .
		gen mf_dXmf_s_u18_c_`var'_x`i' = .
		gen duXmf_dXmf_s_u18_c_`var'_x`i' = .

	}
}

* direct effects, only_mf
quietly foreach var of numlist 20 { 
	forvalues i = 1(2)3 {
		gen mf_coeff_u18_c_`var'_x`i' = .
		gen mf_se_u18_c_`var'_x`i' = .
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
	foreach d of numlist 0.2 {
		
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
	quietly foreach d of numlist 0.2 {
		
		* set local var name for bandwith
		local var = round(`d' * 100, 1)
		
		********************************************************************************
		** Part 5a: only_du
		********************************************************************************
		*loop over different polynomial distance trends
		forvalues i = 1(2)3 {
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
				capture noisily reg num_units1 dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
				
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
		forvalues i = 1(2)3 {
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
				capture noisily reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 			
						
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
		forvalues i = 1(2)3 {
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
			capture noisily reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' if `regression_conditions' , vce(cluster lam_seg) 			
					
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
		forvalues i = 1(2)3 {
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
				capture noisily reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' if `regression_conditions', vce(cluster lam_seg) 							
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
} // end of county/community type loop on line 1101


********************************************************************************
** t statistics
********************************************************************************
*loop over different bandwidth
quietly foreach var of numlist 20 { 
	forvalues i = 1(2)3 {

		gen t_dupac_coeff_u18_c_`var'_x`i' = dupac_coeff_u18_c_`var'_x`i'/dupac_se_u18_c_`var'_x`i'

		gen t_dupac_dXh_c_u18_c_`var'_x`i' = dupac_dXh_c_u18_c_`var'_x`i'/dupac_dXh_s_u18_c_`var'_x`i'
		gen t_height_dXh_c_u18_c_`var'_x`i' = height_dXh_c_u18_c_`var'_x`i'/height_dXh_s_u18_c_`var'_x`i'
		gen t_duXhe_dXh_c_u18_c_`var'_x`i' = duXhe_dXh_c_u18_c_`var'_x`i'/duXhe_dXh_s_u18_c_`var'_x`i'

		gen t_dupac_dXmf_c_u18_c_`var'_x`i' = dupac_dXmf_c_u18_c_`var'_x`i'/dupac_dXmf_s_u18_c_`var'_x`i'
		gen t_mf_dXmf_c_u18_c_`var'_x`i' = mf_dXmf_c_u18_c_`var'_x`i'/mf_dXmf_s_u18_c_`var'_x`i'
		gen t_duXmf_dXmf_c_u18_c_`var'_x`i' = duXmf_dXmf_c_u18_c_`var'_x`i'/duXmf_dXmf_s_u18_c_`var'_x`i'
		
		gen t_mf_coeff_u18_c_`var'_x`i' = mf_coeff_u18_c_`var'_x`i'/mf_se_u18_c_`var'_x`i'
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
	t_dupac_dXh_c_u18_c_* dupac_dXh_c_u18_c_* dupac_dXh_s_u18_c_* 
	t_height_dXh_c_u18_c_* height_dXh_c_u18_c_* height_dXh_s_u18_c_* 
	t_duXhe_dXh_c_u18_c_* duXhe_dXh_c_u18_c_* duXhe_dXh_s_u18_c_*
	t_dupac_dXmf_c_u18_c_* dupac_dXmf_c_u18_c_* dupac_dXmf_s_u18_c_* 
	t_mf_dXmf_c_u18_c_* mf_dXmf_c_u18_c_* mf_dXmf_s_u18_c_*
	t_duXmf_dXmf_c_u18_c_* duXmf_dXmf_c_u18_c_* duXmf_dXmf_s_u18_c_* 
	t_mf_coeff_u18_c_* mf_coeff_u18_c_* mf_se_u18_c_*;
	
***convert dataset to long format, each coefficient has 5(different bandwidth)*5(different polynomial trends)*4(counties) variations
reshape long t_dupac_coeff_u18_c dupac_coeff_u18_c dupac_se_u18_c 
	t_dupac_dXh_c_u18_c dupac_dXh_c_u18_c dupac_dXh_s_u18_c 
	t_height_dXh_c_u18_c height_dXh_c_u18_c height_dXh_s_u18_c 
	t_duXhe_dXh_c_u18_c duXhe_dXh_c_u18_c duXhe_dXh_s_u18_c
	t_dupac_dXmf_c_u18_c dupac_dXmf_c_u18_c dupac_dXmf_s_u18_c 
	t_mf_dXmf_c_u18_c mf_dXmf_c_u18_c mf_dXmf_s_u18_c
	t_duXmf_dXmf_c_u18_c duXmf_dXmf_c_u18_c duXmf_dXmf_s_u18_c 
	t_mf_coeff_u18_c mf_coeff_u18_c mf_se_u18_c, i(county) j(spec) s;
#delimit cr


********************************************************************************
** save output data 
** CHANGE PATH ACCORDINGLY HERE
********************************************************************************
save "postQJE_spatial_unit_coeff_MAPCdefinition.dta", replace



restore




********************************************************************************
** END
********************************************************************************
log off
log close
clear all
