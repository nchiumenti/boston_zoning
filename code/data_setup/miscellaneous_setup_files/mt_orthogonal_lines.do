clear all

log close _all

local date_stamp : di %tdCY-N-D date("$S_DATE","DMY")

local name ="mt_orthogonal_lines" // <--- change when necessry

cd "/home/a1nfc04/Documents/boston_zoning_sdrive/data/mt_orthogonal_lines"

global LOGPATH "/home/a1nfc04/Documents/boston_zoning_sdrive/data/mt_orthogonal_lines/logs"

log using "$LOGPATH/`name'_log_`date_stamp'.log", replace


********************************************************************************

copy "/home/a1nfc04/Documents/boston_zoning_sdrive/python_programs/closest_boundary_matches/closest_boundary_matches_mtlines.csv" "mt_orthogonal_dist_100m_07-01-22.csv", replace

import delimited "mt_orthogonal_dist_100m_07-01-22.csv", clear stringcols(_all)

unique prop_id

destring left_dist_m right_dist_m, replace

* define straight line boundary identifier
gen straight_line = (left_dist_m <= 15 & right_dist_m <= 15)
replace straight_line = . if unique_id == ""

tab straight_line, missing

drop if unique_id == ""

save "mt_orthogonal_dist_100m_07-01-22_v2.dta", replace

log off
log close
