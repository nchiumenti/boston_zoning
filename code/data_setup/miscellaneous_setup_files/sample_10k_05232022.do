* exports a subset sample of the final dataset

* sample selection

set seed 1234

use "/home/a1nfc04/Documents/boston_zoning_sdrive/data/final_dataset_10-28-2021.dta", clear

bysort prop_id (fy):  keep if _n == _N

keep prop_id warren_latitude warren_longitude

sample 10000, count

save "/home/a1nfc04/Documents/boston_zoning_sdrive/data/sample_10k_05232022.dta"
