clear all

********************************************************************************
* File name:		"80_amentiy_datasets.do"
*
* Project title:	Boston Affordable Housing project (visting scholar porject)
*
* Description:		Compiles a bunch of datasets for various amenties:
*				- rivers
*				- major roads
*				- green spaces
*				- schools
*				- city centers
*			 			
*			The file first exports db and coor files from shape files
*			cleans these up and then finds the distance between a 
*			warren property and its closest amenity feature. This is 
*			primarily used for robustness checks later in the analysis
*
* Inputs:		$SHAPEPATH/rivers/HYDRO100K_ARC_latlong.shp
*			$SHAPEPATH/roads/EOTMAJROADS_ARC_latlong
*			$SHAPEPATH/green_space/zoning_atlas_latlong.shp
*			$SHAPEPATH/schools/SCHOOLS_PT_latlong.dta
*			$SHAPEPATH/city_centroids/cb_2018_25_cousub_500k.shp
*			$DATAPATH/warren/warren_MAPC_all_unique.dta
*
* Outputs:		$DATAPATH/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta
*
* Created:		10/22/2021
* Updated:		09/22/2022
********************************************************************************

********************************************************************************
** convert rivers shapefiles, save as .dta
********************************************************************************
* set path
cd "$SHAPEPATH/rivers"

* convert shapefile to .dta
spshape2dta "HYDRO100K_ARC_latlong.shp", replace

* load raw data
use "HYDRO100K_ARC_latlong.dta", clear

* merge on coordinates file
merge 1:m _ID using "HYDRO100K_ARC_latlong_shp.dta", keepusing(_X _Y)
	
	* keep matches only
	drop if _merge!=3
	drop _merge
	
	* drop un-plotted coordinate obs
	drop if _X==.
	drop if _Y==.

	rename _X lon // <-- longitude point coordinate
	rename _Y lat // <-- latitude point coordinate
	
	gen new_id = _n // <-- create new unique identifier

* error checks
noisily assert _N == 261621

sum lon
noisily assert `r(N)' ==  261621
noisily assert `r(sum_w)' ==  261621
noisily assert `r(mean)' ==  -71.80803276162275
noisily assert `r(Var)' ==  .6622777853182688
noisily assert `r(sd)' ==  .8138045129625842
noisily assert `r(min)' ==  -73.49757008256772
noisily assert `r(max)' ==  -69.9537428607613
noisily assert `r(sum)' ==  -18786489.33912851

sum lat
noisily assert `r(N)' ==  261621
noisily assert `r(sum_w)' ==  261621
noisily assert `r(mean)' ==  42.27120244074551
noisily assert `r(Var)' ==  .0896023738727272
noisily assert `r(sd)' ==  .299336556191734
noisily assert `r(min)' ==  41.24316988858398
noisily assert `r(max)' ==  42.8863089778432
noisily assert `r(sum)' ==  11059034.25375028

* save final dataset
save "rivers.dta", replace
clear all


********************************************************************************
** convert roads shapefiles, save as .dta
********************************************************************************
* set path
cd "$SHAPEPATH/roads"

* convert shapefile to .dta
spshape2dta "EOTMAJROADS_ARC_latlong.shp", replace

* load raw data
use "EOTMAJROADS_ARC_latlong.dta", clear

* merge on coordinates file
merge 1:m _ID using "EOTMAJROADS_ARC_latlong_shp.dta", keepusing(_X _Y)
	
	* keep matches only
	drop if _merge!=3
	drop _merge
	
	* drop unplotted coordinates
	drop if _X==.
	drop if _Y==.
	
	rename _X lon // <-- longitude point coordinate
	rename _Y lat // <-- latitude point coordinate
	
	gen new_id = _n // <-- create new unique identifier

* error checks
noisily assert _N == 728857

sum lon
noisily assert `r(N)' ==  728857
noisily assert `r(sum_w)' ==  728857
noisily assert `r(mean)' ==  -71.61882987376714
noisily assert `r(Var)' ==  .5981454014466869
noisily assert `r(sd)' ==  .7733986045026762
noisily assert `r(min)' ==  -73.49726538303904
noisily assert `r(max)' ==  -69.93678688058009
noisily assert `r(sum)' ==  -52199885.4853043

sum lat
noisily assert `r(N)' ==  728857
noisily assert `r(sum_w)' ==  728857
noisily assert `r(mean)' ==  42.27134561618625
noisily assert `r(Var)' ==  .0895799527026415
noisily assert `r(sd)' ==  .29929910240868
noisily assert `r(min)' ==  41.26199604178809
noisily assert `r(max)' ==  42.88459599826236
noisily assert `r(sum)' ==  30809766.15177666

* save final dataset
save "major_roads.dta", replace
clear all

********************************************************************************
** convert green space shapefiles, save as .dta
********************************************************************************
* set path
cd "$SHAPEPATH/green_space"

* convert shapefile to .dta
spshape2dta "zoning_atlas_latlong.shp", replace

* load raw data
use "zoning_atlas_latlong.dta", clear

/* I hand coded obvious green spaces such as parks and conservation land and 
then saved it all as green_space_save.dta */

* merge on green space identifier
keep if zo_usety==4

merge 1:1 _ID using "green_space_save", keepusing(green_space)

replace green_space = 1 in 161

keep if green_space==1

keep _ID zo_usety zo_usede green_space

* merge on coordinates file
merge 1:m _ID using "zoning_atlas_latlong_shp.dta", keepusing(_X _Y)
	drop if _merge!=3
	drop _merge
	drop if _X==.
	drop if _Y==.
	
rename _X lon
rename _Y lat

gen new_id = _n

* error checks
noisily assert _N == 163720

sum lon
noisily assert `r(N)' ==  163720
noisily assert `r(sum_w)' == 163720
noisily assert `r(mean)' == -71.02423063073053
noisily assert `r(Var)' == .0517041887875596
noisily assert `r(sd)' == .2273855509647867
noisily assert `r(min)' == -71.65028502607838
noisily assert `r(max)' == -70.60956079757617
noisily assert `r(sum)' == -11628087.0388632

sum lat
noisily assert `r(N)' == 163720
noisily assert `r(sum_w)' == 163720
noisily assert `r(mean)' == 42.2602034806256
noisily assert `r(Var)' == .0159099748313533
noisily assert `r(sd)' == .1261347487069019
noisily assert `r(min)' == 42.00241908891756
noisily assert `r(max)' == 42.52939312457077
noisily assert `r(sum)' == 6918840.513848023

* save final dataset
save "green_space.dta", replace
clear all


********************************************************************************
** convert schools shapefiles, save as .dta
********************************************************************************
* set path
cd "$SHAPEPATH/schools"

* convert shapefile to .dta
spshape2dta "SCHOOLS_PT_latlong.shp", replace

* load raw data
use "SCHOOLS_PT_latlong.dta", clear
	
	keep if TYPE=="ELE"
	
	* town name formatting
	gen cousub_name = upper(TOWN)

	replace cousub_name = regexr(cousub_name,"( TOWN| CITY)+","")

	replace cousub_name = regexr(cousub_name, "(BOROUGH)$","BORO")

	replace cousub_name = "MOUNT WASHINGTON" if cousub_name=="MT WASHINGTON"

	replace cousub_name = "MANCHESTER" if cousub_name=="MANCHESTER-BY-THE-SEA"

* merge on coordinates file
merge 1:m _ID using "SCHOOLS_PT_latlong_shp.dta", keepusing(_X _Y)
		drop if _merge!=3
		drop _merge
		drop if _X==.
		drop if _Y==.
		
		rename _X lon
		rename _Y lat

		gen new_id = _n

* error checks
noisily assert _N == 1126

sum lon
noisily assert `r(N)' == 1126
noisily assert `r(sum_w)' == 1126
noisily assert `r(mean)' == -71.43210325426215
noisily assert `r(Var)' == .4193592354210359
noisily assert `r(sd)' == .6475795205386253
noisily assert `r(min)' == -73.41595418079029
noisily assert `r(max)' == -69.96159058427394
noisily assert `r(sum)' == -80432.54826429917

sum lat
noisily assert `r(N)' == 1126
noisily assert `r(sum_w)' == 1126
noisily assert `r(mean)' == 42.2812165140373
noisily assert `r(Var)' == .0753486609777351
noisily assert `r(sd)' == .2744971055908151
noisily assert `r(min)' == 41.26950575218223
noisily assert `r(max)' == 42.8656339383973
noisily assert `r(sum)' == 47608.649794806

* save final dataset
save "schools.dta", replace
clear all


********************************************************************************
** convert city centers shapefiles, save as .dta
********************************************************************************
* set path
cd "$SHAPEPATH/city_centroids"

* convert shapefile to .dta
spshape2dta "cb_2018_25_cousub_500k.shp", replace

* merge on coordinates file
use "cb_2018_25_cousub_500k.dta", clear
	
	* town name formatting
	gen cousub_name = upper(NAME)

	replace cousub_name = regexr(cousub_name,"( TOWN| CITY)+","")

	replace cousub_name = regexr(cousub_name, "(BOROUGH)$","BORO")

	replace cousub_name = "MOUNT WASHINGTON" if cousub_name=="MT WASHINGTON"

	replace cousub_name = "MANCHESTER" if cousub_name=="MANCHESTER-BY-THE-SEA"
		
	rename _CX lon
	rename _CY lat

	gen new_id = _n

	
* error checks
noisily assert _N == 351

sum lon
noisily assert `r(N)' == 351
noisily assert `r(sum_w)' == 351
noisily assert `r(mean)' == -71.68263998972033
noisily assert `r(Var)' == .7166534827768939
noisily assert `r(sd)' == .8465538865169151
noisily assert `r(min)' == -73.46616803262842
noisily assert `r(max)' == -69.96745264663275
noisily assert `r(sum)' == -25160.60663639184

sum lat
noisily assert `r(N)' == 351
noisily assert `r(sum_w)' == 351
noisily assert `r(mean)' == 42.2804021179453
noisily assert `r(Var)' == .0962835297079267
noisily assert `r(sd)' == .3102958744616607
noisily assert `r(min)' == 41.28313945692871
noisily assert `r(max)' == 42.85297020329736
noisily assert `r(sum)' == 14840.4211433988

* save final dataset
save "city_centroids.dta", replace
clear all


********************************************************************************
** calculate distance to closest river, road, greenspace, school, city
********************************************************************************
use "$DATAPATH/warren/warren_MAPC_all_unique.dta", clear

keep prop_id cousub_name warren_latitude warren_longitude

order prop_id cousub_name warren_latitude warren_longitude

drop if warren_latitude==. | warren_longitude==.

* closest river
preserve
	local nborfile = "$SHAPEPATH/rivers/rivers.dta"
	geonear prop_id warren_latitude warren_longitude using `nborfile' , neighbors(new_id lat lon) long nearcount(1) miles

	gen closest_river_dist = mi_to_new_id

	tempfile river
	save `river', replace
restore

* closest roads
preserve
	local nborfile = "$SHAPEPATH/roads/major_roads.dta"
	geonear prop_id warren_latitude warren_longitude using `nborfile' , neighbors(new_id lat lon) long nearcount(1) miles

	gen closest_road_dist = mi_to_new_id

	tempfile road
	save `road', replace
restore


* closest green space
preserve
	local nborfile = "$SHAPEPATH/green_space/green_space.dta"
	geonear prop_id warren_latitude warren_longitude using `nborfile' , neighbors(new_id lat lon) long nearcount(1) miles
	
	sum mi_to_new_id
	
	gen closest_green_dist = mi_to_new_id

	tempfile green_space
	save `green_space', replace
restore

* closest school
preserve
	local nborfile = "$SHAPEPATH/schools/schools.dta"
	joinby cousub_name using `nborfile', unmatched(both)
		tab _merge // all masters should match
		drop if _merge==2
		drop _merge
		
	geodist warren_latitude warren_longitude lat lon, gen(mi_to_new_id) miles
	
	bysort prop_id (mi_to_new_id): keep if _n==1
	
	sum mi_to_new_id

	gen closest_school_dist = mi_to_new_id
	
	keep prop_id new_id mi_to_new_id closest_school_dist
	
	tempfile school
	save `school', replace
restore


* city centroid distance
preserve
	local nborfile = "$SHAPEPATH/city_centroids/city_centroids.dta"
	merge m:1 cousub_name using `nborfile'
		tab _merge // all masters should match	
		drop if _merge==2
		drop _merge
		
	geodist warren_latitude warren_longitude lat lon, gen(mi_to_new_id) miles
	
	bysort prop_id (mi_to_new_id): keep if _n==1
	
	sum mi_to_new_id

	gen closest_city_dist = mi_to_new_id
	
	keep prop_id new_id mi_to_new_id closest_city_dist
	
	tempfile city
	save `city', replace
restore


* merge everything together
merge 1:1 prop_id using `river', keepusing(closest_*)
	drop _merge
merge 1:1 prop_id using `road', keepusing(closest_*)
	drop _merge
merge 1:1 prop_id using `green_space', keepusing(closest_*)
	drop _merge
merge 1:1 prop_id using `school', keepusing(closest_*)
	drop _merge
merge 1:1 prop_id using `city', keepusing(closest_*)
	drop _merge


* error checks
assert _N == 821237

sum prop_id
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == 1452949.470121293
noisily assert `r(Var)' == 2059756671999.198
noisily assert `r(sd)' == 1435185.239611667
noisily assert `r(min)' == 264
noisily assert `r(max)' == 5068039
noisily assert `r(sum)' == 1193215863994

sum warren_latitude 
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == 42.34497606268065
noisily assert `r(Var)' == .0206936729659946
noisily assert `r(sd)' == .1438529560558094
noisily assert `r(min)' == 41.41189956665039
noisily assert `r(max)' == 42.81657028198242
noisily assert `r(sum)' == 34775261.10678767

sum warren_longitude 
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == -71.12217941056406
noisily assert `r(Var)' == .0407077150089496
noisily assert `r(sd)' == .2017615300520632
noisily assert `r(min)' == -73.35544
noisily assert `r(max)' == -70.50852966308594
noisily assert `r(sum)' == -58408165.25259339

sum closest_river_dist 
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == .4787115607239661
noisily assert `r(Var)' == .2264697910352192
noisily assert `r(sd)' == .4758884228842084
noisily assert `r(min)' == .0003516040687919
noisily assert `r(max)' == 4.202775209309007
noisily assert `r(sum)' == 393135.6459942677

sum closest_road_dist 
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == .1742136710126441
noisily assert `r(Var)' == .0424289245359561
noisily assert `r(sd)' == .2059828258276794
noisily assert `r(min)' == 1.72747426600e-08
noisily assert `r(max)' == 2.366944243676206
noisily assert `r(sum)' == 143070.7125414108

sum closest_green_dist 
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == 2.380342104939461
noisily assert `r(Var)' == 10.89457859518655
noisily assert `r(sd)' == 3.300693653641087
noisily assert `r(min)' == .0000277426118012
noisily assert `r(max)' == 90.12730961550979
noisily assert `r(sum)' == 1954825.009234168

sum closest_school_dist 
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == .6783289660965274
noisily assert `r(Var)' == .4213891073176291
noisily assert `r(sd)' == .6491449047151407
noisily assert `r(min)' == .0026939883860453
noisily assert `r(max)' == 116.0422663420865
noisily assert `r(sum)' == 557068.8451302139

sum closest_city_dist
noisily assert `r(N)' == 821237
noisily assert `r(sum_w)' == 821237
noisily assert `r(mean)' == 1.575557404374882
noisily assert `r(Var)' == 1.086356554163523
noisily assert `r(sd)' == 1.042284296228012
noisily assert `r(min)' == .0002640671829246
noisily assert `r(max)' == 117.0484208805614
noisily assert `r(sum)' == 1293906.036096615


********************************************************************************
** save and clear
********************************************************************************
save "$DATAPATH/warren/closest_stuff/warren_MAPC_all_unique_closest_stuff.dta", replace
clear all
