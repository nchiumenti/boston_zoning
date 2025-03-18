clear all
log close _all
set trace off
set linesize 255
local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")
local name ="postREStat_Within_Town_mtlines" // <--- change when necessry
log using "$LOGPATH/`name'_log_`date_stamp'.log", replace

** S: DRIVE VERSION **

** WORKING PAPER VERSION **

** MT LINES SETUP VERSION **

********************************************************************************
* File name:		"Final_Within_Town.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		within town trimmed down to just the final regressions and
*			using the mt lines dataset. 
*
*			uses a new within town setup file for postQJE analysis
*			uses .02-.20 mile buffer
*			loops through distance polynomials ^2 - ^5 
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		09/21/2021
* Updated:		08/16/2024
********************************************************************************
********************************************************************************
** load the mt lines data
********************************************************************************
*RESTAT NC CHECK - DO WE NEED TO USE NEW VERSION HERE?
// use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear
use  "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear    /*NEW POSTRESTAT - CHECK PATH*/


destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load final dataset
********************************************************************************
// use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postREStat within town setup file
********************************************************************************
// run "$DOPATH/postREStat_within_town_setup.do"  // $DOPATH is set within 00_wp_master.do
// run "$DOPATH/postREStat_within_town_setup_07102024.do"

// use "$DATAPATH/postQJE_Within_Town_data.dta", clear
use "$DATAPATH/postQJE_Within_Town_setup_data_07102024_mcgl.dta",clear


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
*NC Check POSTRESTAT should we do this here? 
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)
	
	* check merge for errors
	sum _merge
	//assert `r(N)' ==  3400297
	//assert `r(sum_w)' ==  3400297
	//assert `r(mean)' ==  2.940873106084557
	//assert `r(Var)' ==  .0556309206919615
	//assert `r(sd)' ==  .235862079809285
	//assert `r(min)' ==  2
	//assert `r(max)' ==  3
	//assert `r(sum)' ==  9999842
	
	drop if _merge == 2
	drop _merge

keep if straight_line == 1 // <-- drops non-straight line properties



********************************************************************************
** drop out of scope years
********************************************************************************
keep if (year >= 2010 & year <= 2018)

tab year

********************************************************************************
**Define distance polynomial trends
********************************************************************************

gen r_dist_relax = relaxed * dist_both
gen r_dist_strict = strict * dist_both

gen r_dist_relax2 = r_dist_relax ^ 2
gen r_dist_relax3 = r_dist_relax ^ 3
gen r_dist_relax4 = r_dist_relax ^ 4
gen r_dist_relax5 = r_dist_relax ^ 5

gen r_dist_strict2 = r_dist_strict ^ 2
gen r_dist_strict3 = r_dist_strict ^ 3
gen r_dist_strict4 = r_dist_strict ^ 4
gen r_dist_strict5 = r_dist_strict ^ 5

********************************************************************************
**Define distance polynomial trends varlist
********************************************************************************

local distance_varlist1 = "r_dist_relax r_dist_strict"
local distance_varlist2 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2"
local distance_varlist3 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3"

********************************************************************************
** Part 6: SUPPLY EFFECT GENTLE DENSITY BASELINE
* 6a: gentle density baseline after 1918 @ .20 miles
* 6b: gentle density baseline after 1956 @ .20 miles
* 6c: gentle density baseline after 1918 @ .20 miles w/ only clear boundaries
********************************************************************************
** 6a: gentle density baseline after 1918 @ .20 miles

{
*loop over different degrees of distance polynomial trends
forvalues i = 1/3{
	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
	*POSTRESTAT
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* B: only_he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 

		eststo B
	*POSTRESTAT
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* C: only_du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 		

		eststo C
	*POSTRESTAT
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* D: mf_he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 					

		eststo D	
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
	*POSTRESTAT
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)
		
		eststo E
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* F: mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)

		eststo G	

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* H: all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 
		
		eststo H
		
		test 1.mf_allowed height dupac
		test 1.mf_allowed height 
		test 1.mf_allowed dupac
		test height dupac	
		
		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
	
	*POSTRESTAT
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 6a: gentle density baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 6b: gentle density baseline after 1956 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1 {
	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
	
	*POSTRESTAT
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* B: only_he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 

		eststo B
		
	*POSTRESTAT
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* C: only_du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 		

		eststo C
		
	*POSTRESTAT
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	*POSTRESTAT
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg)
		
		eststo E
		
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* H: all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 
		
		eststo H
		
		test 1.mf_allowed height dupac
		test 1.mf_allowed height 
		test 1.mf_allowed dupac
		test height dupac	
		
		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	*POSTRESTAT
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	
	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 6b: gentle density baseline after 1956 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}


********************************************************************************
** Part 7: SUPPLY EFFECT HIGH DENSITY BASELINE
* 7a: high density baseline after 1918 @ .20 miles
* 7b: high density baseline after 1956 @ .20 miles
* 7c: high density baseline after 1918 @ .20 miles w/ only clear boundaries
********************************************************************************

** 7a: high density baseline after 1918 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/3{
	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
		
	*POSTRESTAT
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* B: only_he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 

		eststo B	
	
	*POSTRESTAT
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* C: only_du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 		

		eststo C
		
	*POSTRESTAT
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)
		
		eststo E
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* H: all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(cluster lam_seg) 
		
		eststo H
		
		test 1.mf_allowed height dupac
		test 1.mf_allowed height 
		test 1.mf_allowed dupac
		test height dupac	
		
		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 7a: high density baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear
}
}

** 7b: high density baseline after 1956 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1 {
	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
		
	*POSTRESTAT
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* B: only_he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 

		eststo B	
		
	*POSTRESTAT
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* C: only_du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 		

		eststo C
		
	*POSTRESTAT
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 					

		eststo D		
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg)
		
		eststo E
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* H: all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(cluster lam_seg) 
		
		eststo H
		
		test 1.mf_allowed height dupac
		test 1.mf_allowed height 
		test 1.mf_allowed dupac
		test height dupac	
		
		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 7b: high density baseline after 1956 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear
} 
}



********************************************************************************
*POSTRESTAT - this entire section is new
** Another Endogeneity Check
** up to 0.2 miles from boundary, no year built restriction
********************************************************************************
** 2-3 family buildings, no year-built restriction
{
*loop over different degrees of distance polynomial trends
forvalues i = 1 {
	* only mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year == 2018, vce(cluster lam_seg) 
		
		eststo A
		
	*POSTRESTAT
	sum fam23_1 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	*only he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year == 2018 , vce(cluster lam_seg) 

		eststo B
		
	*POSTRESTAT
	sum fam23_1 if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum fam23_1 if height == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if height == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	*only du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year == 2018 , vce(cluster lam_seg) 		

		eststo C

	*POSTRESTAT
	sum fam23_1 if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	* mf he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2  & year == 2018, vce(cluster lam_seg) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	*POSTRESTAT
	sum fam23_1 if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	* mf du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018, vce(cluster lam_seg)
		
		eststo E
		
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018, vce(cluster lam_seg)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* du he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018, vce(cluster lam_seg)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2  & year == 2018, vce(cluster lam_seg) 
		
		eststo H
		
		test 1.mf_allowed height dupac
		test 1.mf_allowed height 
		test 1.mf_allowed dupac
		test height dupac	
		
		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if mf_he_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* 2-3 family, before 1918, endogeneity check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("2-3 family, no year-built restriction, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}


** 4+ family buildings , no year-built restriction
{
*loop over different degrees of distance polynomial trends
forvalues i = 1 {
	* only mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg) 
		
		eststo A
		
	*POSTRESTAT
	sum fam4plus_1 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	*only he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg) 

		eststo B
		
	*POSTRESTAT
	sum fam4plus_1 if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	*only du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2  & year == 2018, vce(cluster lam_seg) 		

		eststo C
		
	*POSTRESTAT
	sum fam4plus_1 if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg)
		
		eststo E
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* du he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2  & year == 2018 , vce(cluster lam_seg) 
		
		eststo H
		
		test 1.mf_allowed height dupac
		test 1.mf_allowed height 
		test 1.mf_allowed dupac
		test height dupac	
		
		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* 4+ family, no year-built restriction, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("4+ family, no year-built restriction, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}


********************************************************************************
** end
********************************************************************************
display "Done!"
log close
clear
