clear all

log close _all

set linesize 255

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="postQJE_Within_Town_mtlines" // <--- change when necessry

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
* Only difference to otherwise same-named file: this file runs robust standard 
* errors only
* 				
* Inputs:		
*				
* Outputs:		
*
* Created:		09/21/2021
* Updated:		09/20/2022
********************************************************************************
********************************************************************************
** load the mt lines data
********************************************************************************
*RESTAT NC CHECK - DO WE NEED TO USE NEW VERSION HERE?
use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_v2.dta", clear
*or
*use "$DATAPATH/mt_orthogonal_lines/mt_orthogonal_dist_100m_07-01-22_moreregs.dta", clear

destring prop_id, replace

tempfile mtlines
save `mtlines', replace


********************************************************************************
** load final dataset
********************************************************************************
use "$DATAPATH/final_dataset_10-28-2021.dta", clear


********************************************************************************
** run postQJE within town setup file
********************************************************************************
run "$DOPATH/postQJE_within_town_setup.do"

// use "$DATAPATH/postQJE_Within_Town_data.dta", clear
********************************************************************************
** merge on mt lines to keep straight line properties
********************************************************************************
*NC Check POSTRESTAT should we do this here? 
merge m:1 prop_id using `mtlines', keepusing(straight_line home_minlotsize nn_minlotsize)
	
	* check merge for errors
	sum _merge
	assert `r(N)' ==  3400297
	assert `r(sum_w)' ==  3400297
	assert `r(mean)' ==  2.940873106084557
	assert `r(Var)' ==  .0556309206919615
	assert `r(sd)' ==  .235862079809285
	assert `r(min)' ==  2
	assert `r(max)' ==  3
	assert `r(sum)' ==  9999842
	
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
local distance_varlist4 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4"
local distance_varlist5 = "r_dist_relax r_dist_strict r_dist_relax2 r_dist_strict2 r_dist_relax3 r_dist_strict3 r_dist_relax4 r_dist_strict4 r_dist_relax5 r_dist_strict5"

********************************************************************************
** Part 1: DIRECT EFFECT RENTS BASELINE
* 1aa: rents baseline @ .02 miles
* 1a: rents baseline @ .05 miles
* 1b: rents baseline @ .10 miles
* 1c: rents baseline @ .15 miles
* 1d: rents baseline @ .20 miles
********************************************************************************

** 1aa: rents baseline @ .02 miles Linear 
{
*loop over different degrees of distance polynomial trends
forvalues i=1/5{ 
	
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year ///
		if (only_mf == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year ///
		if (only_he == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (only_du == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_du == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (du_he == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he_du == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 1aa: rents baseline @ 0.02 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 1a: rents baseline @ .05 miles
{
*loop over different degrees of distance polynomial trends
forvalues i=1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year ///
		if (only_mf == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year ///
		if (only_he == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (only_du == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_du == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (du_he == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he_du == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 1a: rents baseline @ 0.05 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 1b: rents baseline @ .10 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year ///
		if (only_mf == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year ///
		if (only_he == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (only_du == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_du == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (du_he == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he_du == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 1b: rents baseline @ 0.10 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 1c: rents baseline @ .15 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year ///
		if (only_mf == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year ///
		if (only_he == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (only_du == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_du == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (du_he == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he_du == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 1c: rents baseline @ 0.15 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 1d: rents baseline @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i =1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year ///
		if (only_mf == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year ///
		if (only_he == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (only_du == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_du == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (du_he == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year ///
		if (mf_he_du == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 1d: rents baseline @ 0.20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}


********************************************************************************
** Part 2: DIRECT EFFECT RENTS W/ i.YEAR_BUILT
* 2aa: rents w/ i.year_built @ .02 miles
* 2a: rents w/ i.year_built @ .05 miles
* 2b: rents w/ i.year_built @ .10 miles
* 2c: rents w/ i.year_built @ .15 miles
* 2d: rents w/ i.year_built @ .20 miles
********************************************************************************

** 2aa: rents baseline @ .02 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_mf == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_he == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_du == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_du == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (du_he == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he_du == 1 & dist <= 0.02 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 2aa: rents w/ i.year_built @ 0.02 miles (distance polynomial trends degree `i')") 		
	eststo clear
} 
}

** 2a: rents baseline @ .05 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_mf == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_he == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_du == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_du == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (du_he == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he_du == 1 & dist <= 0.05 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 2a: rents w/ i.year_built @ 0.05 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 2b: rents baseline @ .10 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_mf == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_he == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_du == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_du == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (du_he == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he_du == 1 & dist <= 0.10 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 2b: rents w/ i.year_built @ 0.10 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 2c: rents baseline @ .15 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_mf == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_he == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_du == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_du == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (du_he == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he_du == 1 & dist <= 0.15 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 2c: rents w/ i.year_built @ 0.15 miles (distance polynomial trends degree `i')") 		
	eststo clear 
}
}

** 2d: rents baseline @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_mfrent i.mf_allowed i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_mf == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_mfrent height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_he == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_mfrent dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (only_du == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_mfrent i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_mfrent i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_du == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_mfrent c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (du_he == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_mfrent i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.year i.year_built ///
		if (mf_he_du == 1 & dist <= 0.20 & res_typex != "Condominiums" & (year >= 2010 & year <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Year f.e.=*year" "Year built f.e.=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 2d: rents w/ i.year_built @ 0.20 miles (distance polynomial trends degree `i')") 		
	eststo clear 
}
}


********************************************************************************
** Part 3: DIRECT EFFECT HOUSE PRICES BASELINE
* 3aa: house prices baseline @ .02 miles
* 3a: house prices baseline @ .05 miles
* 3b: house prices baseline @ .10 miles
* 3c: house prices baseline @ .15 miles
* 3d: house prices baseline @ .20 miles
********************************************************************************

** 3aa: house prices baseline @ .02 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_mf == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_he == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_du == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_du == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (du_he == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he_du == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 3aa: house prices baseline @ 0.02 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

	** 3a: house prices baseline @ .05 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_mf == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_he == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_du == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_du == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (du_he == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he_du == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 3a: house prices baseline @ 0.05 miles (distance polynomial trends degree `i')") 		
	eststo clear 
}
}

** 3b: house prices baseline @ .10 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_mf == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_he == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_du == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_du == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (du_he == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he_du == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 3b: house prices baseline @ 0.10 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 3c: house prices baseline @ .15 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_mf == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_he == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_du == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_du == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (du_he == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he_du == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 3c: house prices baseline @ 0.15 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 3d: house prices baseline @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_mf == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (only_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (du_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr ///
		if (mf_he_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 3d: house prices baseline @ 0.20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}


********************************************************************************
** Part 4: DIRECT EFFECT HOUSE PRICES W/ i.YEAR_BUILT
* 4aa: house prices i.year_built @ .02 miles
* 4a: house prices i.year_built @ .05 miles
* 4b: house prices i.year_built @ .10 miles
* 4c: house prices i.year_built @ .15 miles
* 4d: house prices i.year_built @ .20 miles
********************************************************************************

** 4aa: house prices w/ i.year_built @ .02 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{	
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_mf == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_he == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_du == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_du == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (du_he == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he_du == 1 & dist <= 0.02 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr" "Year built f.e=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 4aa: house prices w/ i.year_built @ 0.02 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 4a: house prices w/ i.year_built @ .05 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_mf == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_he == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_du == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_du == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (du_he == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he_du == 1 & dist <= 0.05 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr" "Year built f.e=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 4a: house prices w/ i.year_built @ 0.05 miles (distance polynomial trends degree `i')") 
		
	eststo clear
} 
}

** 4d: house prices w/ i.year_built @ .10 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_mf == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_he == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_du == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_du == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (du_he == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he_du == 1 & dist <= 0.10 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr" "Year built f.e=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 4b: house prices w/ i.year_built @ 0.10 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 4c: house prices w/ i.year_built @ .15 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_mf == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_he == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_du == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_du == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (du_he == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he_du == 1 & dist <= 0.15 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr" "Year built f.e=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 4c: house prices w/ i.year_built @ 0.15 miles (distance polynomial trends degree `i')") 
		
	eststo clear
} 
}

** 4d: house prices w/ i.year_built @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg log_saleprice i.mf_allowed i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_mf == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo A

	* B: only_he
	quietly reg log_saleprice height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo B

	* C: only_du
	quietly reg log_saleprice dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (only_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 
		
		eststo C

	* D: mf_he
	quietly reg log_saleprice i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo D

		* ttest Height
		test height 1.mf_allowed#c.height

		* ttest mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg log_saleprice i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust) 

		eststo E

	* F: du_he
	quietly reg log_saleprice c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (du_he == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)
		
		eststo F

		*dupac 
		test dupac c.height#c.dupac

		*height
		test height c.height#c.dupac

	* G: all (MF, Height and DUPAC)
	quietly reg log_saleprice i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' i.last_saleyr i.year_built ///
		if (mf_he_du == 1 & dist <= 0.20 & res_typex == "Single Family Res" & (last_saleyr >= 2010 & last_saleyr <= 2018)), vce(robust)

		eststo G	

		* ttest all
		test 1.mf_allowed height dupac 1.mf_allowed#c.height#c.dupac
		test 1.mf_allowed height 1.mf_allowed#c.height 
		test 1.mf_allowed dupac 1.mf_allowed#c.dupac
		test height dupac c.height#c.dupac

		* dupac
		test dupac c.height#c.dupac 1.mf_allowed#c.dupac 1.mf_allowed#c.height#c.dupac

		* height
		test height c.height#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

		* mf allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac 1.mf_allowed#c.height 1.mf_allowed#c.height#c.dupac

	* combine results
	esttab A B C D E F G, se r2 nobase indicate("Boundary f.e.=*lam_seg" "Last sale yr f.e.=*last_saleyr" "Year built f.e=*year_built") interaction(" X ") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 4d: house prices w/ i.year_built @ 0.20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}


********************************************************************************
** Part 5: SUPPLY EFFECT NUMBER OF UNITS  BASELINE
* 5a: number of units baseline after 1918 @ .20 miles
* 5b: number of units baseline after 1956 @ .20 miles
********************************************************************************
** 5a: number of units baseline after 1918 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
		eststo A

	* B: only_he
	quietly reg num_units1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 

		eststo B				

	* C: only_du
	quietly reg num_units1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 		

		eststo C

	* D: mf_he
	quietly reg num_units1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)
		
		eststo E

	* F: mf du, relaxed 2
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* G: du_he
	quietly reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* H: all (mf du he)
	quietly reg num_units1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
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

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 5a: number of units baseline after 1918 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}

** 5b: number of units baseline after 1956 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
		eststo A

	* B: only_he
	quietly reg num_units1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 

		eststo B				

	* C: only_du
	quietly reg num_units1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 		

		eststo C

	* D: mf_he
	quietly reg num_units1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* E: mf_du
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)
		
		eststo E

	* F: mf du, relaxed 2
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* G: du_he
	quietly reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* H: all (mf du he)
	quietly reg num_units1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
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

	* combine results
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg") ///
		label mtitles("only_mf" "only_he" "only_du" "mf_he" "mf_du" "du_he" "All") ///
		title("Part 5b: number of units baseline after 1956 @ .20 miles (distance polynomial trends degree `i')") 
		
	eststo clear 
}
}


********************************************************************************
** Part 6: SUPPLY EFFECT GENTLE DENSITY BASELINE
* 6a: gentle density baseline after 1918 @ .20 miles
* 6b: gentle density baseline after 1956 @ .20 miles
********************************************************************************
** 6a: gentle density baseline after 1918 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
		eststo A
	*POSTRESTAT
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"


	* B: only_he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 

		eststo B
	*POSTRESTAT
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"

	* C: only_du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 		

		eststo C
	*POSTRESTAT
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* D: mf_he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 					

		eststo D	
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
	*POSTRESTAT
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)
		
		eststo E
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* F: mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo G	

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

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
forvalues i = 1/5{
	* A: only_mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
		eststo A
	
	*POSTRESTAT
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"	

	* B: only_he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 

		eststo B
		
	*POSTRESTAT
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* C: only_du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 		

		eststo C
		
	*POSTRESTAT
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
		
	*POSTRESTAT
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam23_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)
		
		eststo E
		
	*POSTRESTAT
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
		
	*POSTRESTAT
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
		
	*POSTRESTAT
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
********************************************************************************
** 7a: high density baseline after 1918 @ .20 miles
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 
		
		eststo A
		
	*POSTRESTAT
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* B: only_he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 

		eststo B	
	
	*POSTRESTAT
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"		

	* C: only_du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 		

		eststo C
		
	*POSTRESTAT
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* D: mf_he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)
		
		eststo E
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* F: mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_du == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* G: du_he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist <= 0.2 & year_built >= 1918 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac
		
	*POSTRESTAT
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if du_he == 1 & year==2018 & year_built>=1918 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

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
forvalues i = 1/5{
	* A: only_mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 
		
		eststo A
		
	*POSTRESTAT
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_mf == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* B: only_he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 

		eststo B	
		
	*POSTRESTAT
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if only_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* C: only_du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust) 		

		eststo C
		
	*POSTRESTAT
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
		
	*POSTRESTAT
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0.02 & dist_both>0) & res_typex!="Condominiums"
	sum fam4plus_1 if mf_he == 1 & year==2018 & year_built>=1956 & (dist_both<=0 & dist_both>-0.02) & res_typex!="Condominiums"			

	* E: mf_du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist <= 0.2 & year_built >= 1956 & year == 2018, vce(robust)
		
		eststo E
		
	*POSTRESTAT
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
		
	*POSTRESTAT
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
		
	*POSTRESTAT
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


** END OF MAIN ANALYSIS **


********************************************************************************
** Another Endogeneity Check
** up to 0.2 miles from boundary, before 1918 and 1956
********************************************************************************
** 2-3 family buildings before 1918 endogeneity check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust) 
		
		eststo A

	*only he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 		

		eststo C

	* mf he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust) 
		
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

	* 2-3 family, before 1918, endogeneity check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("2-3 family, before 1918, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}

** 2-3 family buildings before 1956 endogeneity check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust) 
		
		eststo A

	*only he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust) 

		eststo B				

	*only du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust) 		

		eststo C

	* mf he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg fam23_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust) 
		
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

	* 2-3 family, before 1956, endogeneity  check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("2-3 family, before 1956, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}

** 4+ family buildings before 1918 endogeneity  check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 
		
		eststo A

	*only he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust) 		

		eststo C

	* mf he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 
		
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

	* 4+ family, before 1918, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("4+ family, before 1918, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}

** 4+ family buildings before 1956 robustness check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 
		
		eststo A

	*only he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year_built<1956 & year == 2018, vce(robust) 		

		eststo C

	* mf he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg fam4plus_1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 
		
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

	* 4+ family, before 1956, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("4+ family, before 1956, endogeneity check (distance polynomial trends degree `i')")
	eststo clear
} 
}

** Number of units, before 1918 endogeneity check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 
		
		eststo A

	*only he
	quietly reg num_units1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg num_units1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year_built<1918 & year == 2018, vce(robust) 		

		eststo C

	* mf he
	quietly reg num_units1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg num_units1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2 & year_built<1918 & year == 2018 , vce(robust) 
		
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

	* Number of units, before 1918, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("Number of units, before 1918, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}

** Number of units before 1956 endogeneity check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 
		
		eststo A

	*only he
	quietly reg num_units1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg num_units1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 		

		eststo C

	* mf he
	quietly reg num_units1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg num_units1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_he_du == 1 & dist<=0.2 & year_built<1956 & year == 2018 , vce(robust) 
		
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

	* Number of units, before 1956, endogeneity  check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("Number of units, before 1956, endogeneity check (distance polynomial trends degree `i')")
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
forvalues i = 1/5{
	* only mf
	quietly reg fam23_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2 & year == 2018, vce(robust) 
		
		eststo A

	*only he
	quietly reg fam23_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2 & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg fam23_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2 & year == 2018 , vce(robust) 		

		eststo C

	* mf he
	quietly reg fam23_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2  & year == 2018, vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018, vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg fam23_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018, vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg fam23_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018, vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

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
forvalues i = 1/5{
	* only mf
	quietly reg fam4plus_1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2  & year == 2018 , vce(robust) 
		
		eststo A

	*only he
	quietly reg fam4plus_1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2  & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg fam4plus_1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2  & year == 2018, vce(robust) 		

		eststo C

	* mf he
	quietly reg fam4plus_1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2  & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg fam4plus_1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg fam4plus_1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

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

	* 4+ family, no year-built restriction, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("4+ family, no year-built restriction, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}


** Number of units, no year-built restriction endogeneity check
{
*loop over different degrees of distance polynomial trends
forvalues i = 1/5{
	* only mf
	quietly reg num_units1 i.mf_allowed i.lam_seg `distance_varlist`i'' ///
		if only_mf == 1 & dist<=0.2  & year == 2018 , vce(robust) 
		
		eststo A

	*only he
	quietly reg num_units1 height i.lam_seg `distance_varlist`i'' ///
		if only_he == 1 & dist<=0.2  & year == 2018 , vce(robust) 

		eststo B				

	*only du
	quietly reg num_units1 dupac i.lam_seg `distance_varlist`i'' ///
		if only_du == 1 & dist<=0.2  & year == 2018, vce(robust) 		

		eststo C

	* mf he
	quietly reg num_units1 i.mf_allowed##c.height i.lam_seg `distance_varlist`i'' ///
		if mf_he == 1 & dist<=0.2 & year == 2018 , vce(robust) 					

		eststo D
		
		* height
		test height 1.mf_allowed#c.height
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.height

	* mf du
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(robust)
		
		eststo E

	* mf du, relaxed 2
	quietly reg num_units1 i.mf_allowed##c.dupac i.lam_seg `distance_varlist`i'' ///
		if mf_du == 1 & dist<=0.2  & year == 2018 , vce(robust)

		eststo F

		* dupac
		test dupac 1.mf_allowed#c.dupac
		
		* mf_allowed
		test 1.mf_allowed 1.mf_allowed#c.dupac

	* du he
	quietly reg num_units1 c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
		if du_he == 1 & dist<=0.2  & year == 2018 , vce(robust)

		eststo G

		* dupac 
		test dupac c.height#c.dupac
		
		* height
		test height c.height#c.dupac

	* all (mf du he)
	quietly reg num_units1 i.mf_allowed##c.height##c.dupac i.lam_seg `distance_varlist`i'' ///
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

	* Number of units, before 1918, robustness check				
	esttab A B C D E F G H, se r2 nobase indicate("Boundary f.e.=*lam_seg" ) label ///
		mtitles("Only MF" "Only height" "Only DUPAC" "MF and height" "MF and DUPAC" "MFDU, relaxed2" "DUPAC and height" "All") ///
		title("Number of units, no year-built restriction, endogeneity check (distance polynomial trends degree `i')")
	eststo clear 
}
}



********************************************************************************
** end
********************************************************************************
display "Done!"
log close
clear
