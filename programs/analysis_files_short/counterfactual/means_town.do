********************************************************************************
*			Policy value calculations for:
*		How to Increase Housing Affordability? Understanding
*		  Local Deterrents to Building Multifamily Housing
*	
*	Author: Maxi Machado
*	e-mail: maxi.machado@mail.utoronto.ca
*	RA to prof. Aradhya Sood
********************************************************************************

********************************************************************************
* This dofile gets means by town  
*
********************************************************************************

*-------------------------------------------------------------------------------

global dir "C:\Users\macha116\Dropbox\PhD\Research\RA_IO_Urban\postQJE_Spatial_ReducedForm_mtlines_2022-09-30\test"

use "$dir\postQJE_means_town_lvl.dta", clear 

rename (mean_units mean_rent mean_price n_units n_rent n_price) (mean_units_town mean_rent_town mean_price_town n_units_town n_rent_town n_price_town)

save "$dir\postQJE_means_town_lvl_tomerge.dta", replace

use "$dir\postQJE_train_station_means_w_townnames.dta", clear

merge m:1 cousub_name boundary_type side using "$dir\postQJE_means_town_lvl_tomerge.dta"

drop mean_units mean_rent mean_saleprice _merge
rename (mean_units_town mean_rent_town mean_price_town)(mean_units mean_rent mean_saleprice)

save "$dir\postQJE_means_town_lvl_tomerge.dta", replace
