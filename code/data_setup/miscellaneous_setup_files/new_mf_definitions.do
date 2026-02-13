********************************************************************************
*NEW ADMISSABLE BOUNDARIES WITH DIFFERENT MF DEFINITION*************************
********************************************************************************
clear 
set more off 


*=================================
*1. prepare zoning atlas
*=================================

*mapc atlas shapefile
global DATAPATH "<LOCAL FILE PATH>/data"

unzipfile "$DATAPATH/zoning_boundaries/originals/zoning_atlas.zip"

spshape2dta "$DATAPATH/zoning_boundaries/originals/zoning_atlas.shp", replace

use "$DATAPATH/boundary_selection/originals zoning_atlas.dta"

gen POLID = _ID - 1

gen mulfam_type = .
replace mulfam_type = 0 if mulfam2 == 0 & mulfam3 == 0 & mulfam5 == 0  & mulfam20 == 0
replace mulfam_type = 1 if mulfam_type==. & (mulfam2 <=1 & mulfam3 <=1 &  mulfam5 <=1  & mulfam20 <=1)
replace mulfam_type = 2 if mulfam2 == 1 & mulfam3 == 1 & mulfam5 == 1  & mulfam20 == 1
replace mulfam_type = 3 if mulfam_type==. & (mulfam2 >=1 & mulfam3 >=1 &  mulfam5 >=1  & mulfam20 >=1)
replace mulfam_type = 4 if mulfam2 == 2 & mulfam3 == 2 & mulfam5 == 2  & mulfam20 == 2

*new mulfam definition
gen mulfam = . 
replace mulfam = 1 if mulfam_type == 3 | mulfam_type == 4
replace mulfam = 0 if mulfam_type == 0 | mulfam_type == 1 | mulfam_type == 2

egen reg_type = group(mulfam mxht_eff dupac_eff zo_usety)

tab mulfam mulfam_old

*preserve 
keep POLID dupac_eff mxht_eff mulfam zo_usety reg_type 

export dbase using "$DATAPATH/boundary_selection/reg_type_newmf.dbf", replace

*===================================
*2. prepare school boundaries
*===================================
*check school districts 
clear 

tempfile schools

unzipfile "$DATAPATH/schools/SABS_MA.zip"

shp2dta using "$DATAPATH/schools/SABS_MA.shp", database(`schools') coordinates(`schools') replace

*add zoning atlas info
use `schools'

egen type = group(gslo gshi)

*keep only schools in Zoning Atlas towns and drop overlapping boundaries
keep if ncessch=="250333000457" | ncessch == "250696001014" | ncessch == "250240000131" | ncessch == "250639000922" | ncessch == "250639000924" | ncessch == "250750001152" | ncessch == "251134001876" | ncessch == "250690001009" | ncessch == "250690001183" | ncessch == "250684001000" | ncessch == "250684000473" | ncessch == "250732001135" | ncessch == "250639000925" | ncessch == "250732001631" | ncessch == "250732001130" | ncessch == "251098001761" | ncessch == "250210000072" | ncessch == "250624001172" | ncessch == "250786001238"| ncessch == "250630000916 "| ncessch =="250759001185"| ncessch == "250792001252"| ncessch == "250864000317"| ncessch == "251197002563"| ncessch == "251197001235" | ncessch == "251197001961" | ncessch == "251197001960" | ncessch == "250753000114" |ncessch == "251329002255" | leaid == "2502250" | leaid == "2509930" | ncessch == "250798001259"| ncessch == "250615000880" | leaid == "2512840" | ncessch == "250642000932" | ncessch == "250378000520" | leaid == "2510560" | leaid == "2509030" | ncessch == "251017001708" | leaid == "2505790" | leaid == "2509420"| ncessch == "250441000593" | leaid == "2507350" | leaid == "2505280" | ncessch == "251020002533" | leaid == "2508820" | ncessch == "250783002588" | ncessch == "251167001929" | leaid == "2502640" | ncessch == "250822002394" | ncessch == "251038000773" | ncessch == "250726099991" | ncessch == "250726001120" | ncessch == "250726001123" | ncessch == "250726001119" | ncessch == "251143001883" | ncessch == "250711001077" | ncessch == "250711002527" | ncessch == "250711099991" | ncessch == "250711001087" | ncessch == "250711001068" | ncessch == "250711001072" | ncessch == "250711001073" | ncessch == "250711001085" | ncessch == "250711001084" | ncessch == "250711001075" | ncessch == "250711001081" | ncessch == "250711001061" | ncessch == "250711001074" | ncessch == "250711001079" | ncessch == "250711002658" | ncessch == "250711001068" | ncessch == "250711001062" | (leaid == "2507110" & ncessch != "250711002801") | ncessch == "250822002394" | ncessch == "251317001665" | ncessch == "250279099991"| ncessch == "250279000011" | ncessch == "250279000312" | ncessch == "250354000235" | ncessch == "250477099991" | ncessch == "250477000631" | ncessch == "250477002038" | ncessch == "250477001521" | ncessch == "250477002038" | ncessch == "250477002118" | ncessch == "250477002033" | ncessch == "250477001520" | ncessch == "250717001344" | leaid == "2511910" | leaid == "2511220" | ncessch == "251275002085" | leaid == "2506840" | leaid == "2512000" | leaid == "2501980" | leaid == "2502490" | ncessch == "251089000891" | ncessch == "250327000020" | ncessch == "250279000213" | ncessch == "250279099991" | ncessch == "250405000550" | ncessch == "250405000552" | ncessch == "250405000546" | ncessch == "250405000554" | leaid == "2508370" | leaid == "2508610" | leaid == "2512270" | ncessch == "250426000573" | ncessch == "250753000114" | ncessch == "251071001709" | ncessch == "250498000714" | leaid == "2507320" | leaid == "2506390" | leaid == "2511340" | ncessch == "251221002008" | ncessch == "251221002007" | ncessch == "250690001009" | ncessch == "251275002089" | ncessch == "250240000131" | ncessch == "250498000714" | ncessch == "251098001761" | ncessch == "250624001172" | ncessch == "250786001238" | ncessch == "250630000916" | ncessch == "250753000114" | ncessch == "251329002255" | ncessch == "250633000918" | ncessch == "250624001172" | ncessch == "250786001238" | ncessch == "250786001237" | leaid == "2505010" | ncessch == "250864000317" | ncessch == "250753000114" | ncessch == "250495000724" | ncessch == "250495000864" | ncessch == "250495000710" | ncessch == "251062001702" | ncessch == "251062001704" | ncessch == "251062001703" | ncessch == "251125001861" | ncessch == "251125001858" | ncessch == "251125001862" | ncessch == "251125001866" | ncessch == "250330000452" | ncessch == "250330000455" | ncessch == "250330000454" | ncessch == "250330099991" | ncessch == "251281002096" | ncessch == "251281002099" | ncessch == "251281000794" | ncessch == "251281002098" | ncessch == "251281002101" | ncessch == "250315000418" | ncessch == "250315000422" | ncessch == "250315000423" | ncessch == "250315000418" | ncessch == "250315000419" | ncessch == "250315000417" | ncessch == "250315000421" | ncessch == "250315000420" | ncessch == "251005001629" | ncessch == "251005001962" | ncessch == "251005001633" | ncessch == "251005001975" | ncessch == "251005001618" | ncessch == "251005001629" | ncessch == "250726001121" | ncessch == "251125001863" | ncessch == "251005001619"

drop if ncessch == "250579000832" | ncessch == "251275002089" | ncessch == "250711002527"

export dbase using "$DATAPATH/boundary_selection/sabs_MA_nooverlap.dbf", replace







