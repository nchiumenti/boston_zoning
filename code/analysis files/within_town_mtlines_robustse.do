* start here
clear all
log close _all
set linesize 255

local name ="within_town_mtlines_robustse"  // <--- change when necessry

* creates an output directory if none exists
global EXPORTPATH "$WORKINGDIR/analysis/`name'_output"

capture confirm file "$EXPORTPATH"

if _rc != 0 {
	di "making directory $EXPORTPATH"
	shell mkdir $EXPORTPATH
}

* start log file
local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

log using "$EXPORTPATH/`name'_log_`date_stamp'.log", replace

********************************************************************************
* File name:		within_town_mtlines_robustse.do
*
* Project title:	Boston Zoning Paper
*
* Description:		Runs specifications for gentle and high density units as 
*					well as some endogeneity checks. Similar to the other within 
*					town file but now with robust standard errors. Section part 
*					numbers are based on older versions and so are not 
*					consecutive but are preserved for references across files.
*
*					Contents:
*					Part 6: SUPPLY EFFECT GENTLE DENSITY BASELINE
*						6a: gentle density baseline after 1918 @ .20 miles
*						6b: gentle density baseline after 1956 @ .20 miles
*						6c: gentle density baseline after 1918 @ .20 miles w/ only clear boundaries
*					Part 7: SUPPLY EFFECT HIGH DENSITY BASELINE
*						7a: high density baseline after 1918 @ .20 miles
*						7b: high density baseline after 1956 @ .20 miles
*						7c: high density baseline after 1918 @ .20 miles w/ only clear boundaries
*					Another Endogeneity Check
*						On 2-3 unit structures
*						On 4+ unit structures* Inputs:
*		
* Inputs:			mt_orthogonal_dist_100m_07-01-22_moreregs.dta
*					within_town_analysis_data.dta
*				
* Outputs:			Log output only
*
* Created:			09/21/2021
* Updated:			03/18/2025
********************************************************************************


********************************************************************************
** load the mt lines data
********************************************************************************
use  "$DATAPATH/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** create working dataset
********************************************************************************
use "$DATAPATH/within_town_analysis_data.dta", clear


********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)
	
	* check merge for errors
	sum _merge	
	drop if _merge == 2
	drop _merge

keep if straight_line == 1  // <-- drops non-straight line properties


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
* loop over different degrees of distance polynomial trends
forvalues i = 1/3 {
	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
		eststo A

	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* B: only_he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 

		eststo B

	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* C: only_du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 		

		eststo C

	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* D: mf_he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 					

		eststo D	
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)
		
		eststo E

	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* F: mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo G	

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* H: all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
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
	
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 6a: gentle density baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}

** 6b: gentle density baseline after 1956 @ .20 miles
* loop over different degrees of distance polynomial trends
forvalues i = 1(1)1 {  // <- nfc: fix that I am not sure will work
	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
		eststo A
	
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* B: only_he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 

		eststo B
		
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* C: only_du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 		

		eststo C
		
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)
		
		eststo E
		
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* H: all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
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

	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	
	
	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 6b: gentle density baseline after 1956 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}


********************************************************************************
** Part 7: SUPPLY EFFECT HIGH DENSITY BASELINE
* 7a: high density baseline after 1918 @ .20 miles
* 7b: high density baseline after 1956 @ .20 miles
* 7c: high density baseline after 1918 @ .20 miles w/ only clear boundaries
********************************************************************************
** 7a: high density baseline after 1918 @ .20 miles
* loop over different degrees of distance polynomial trends
forvalues i = 1/3{

	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
		eststo A
		
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* B: only_he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 

		eststo B	
	
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* C: only_du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 		

		eststo C
		
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)
		
		eststo E
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* H: all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
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
		
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 7a: high density baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear
}

** 7b: high density baseline after 1956 @ .20 miles
* loop over different degrees of distance polynomial trends
forvalues i = 1(1)1 {  // <- nfc: fix that I am not sure will work
	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
		eststo A
		
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* B: only_he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 

		eststo B	
		
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* C: only_du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 		

		eststo C
		
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 					

		eststo D		
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)
		
		eststo E
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* H: all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
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
		
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 7b: high density baseline after 1956 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear
} 


********************************************************************************
** Another Endogeneity Check
** up to 0.2 miles from boundary, no year built restriction
********************************************************************************
** 2-3 family buildings, no year-built restriction
* loop over different degrees of distance polynomial trends
forvalues i = 1(1)1 {  // <- nfc: fix that I am not sure will work
	* only mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year == 2018, vce(robust) 
		
		eststo A
		
	sum fam23_1 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	*only he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year == 2018 , vce(robust) 

		eststo B
		
	sum fam23_1 if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum fam23_1 if height == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if height == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* only du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year == 2018 , vce(robust) 		

		eststo C

	sum fam23_1 if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	* mf he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2  & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	sum fam23_1 if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
		
	* mf du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018, vce(robust)
		
		eststo E
		
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* du he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	sum fam23_1 if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2  & year == 2018, vce(robust) 
		
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
		
	sum fam23_1 if mf_he_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* 2-3 family, before 1918, endogeneity check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("2-3 family, no year-built restriction, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}

** 4+ family buildings , no year-built restriction
* loop over different degrees of distance polynomial trends
forvalues i = 1(1)1 {  // <- nfc: fix that I am not sure will work
	* only mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2  & year == 2018 , vce(robust) 
		
		eststo A
		
	sum fam4plus_1 if only_mf == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* only he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2  & year == 2018 , vce(robust) 

		eststo B
		
	sum fam4plus_1 if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if only_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* only du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2  & year == 2018, vce(robust) 		

		eststo C
		
	sum fam4plus_1 if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if only_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2  & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	sum fam4plus_1 if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if mf_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(robust)
		
		eststo E
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if mf_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* du he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	sum fam4plus_1 if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum dupac if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum height if du_he == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2  & year == 2018 , vce(robust) 
		
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
		
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he_du == 1 & year==2018 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* 4+ family, no year-built restriction, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("4+ family, no year-built restriction, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}


********************************************************************************
** end
********************************************************************************
log off
log close
clear all
display "Done!"