clear all
global DOPATH_2024 "/shared/boston_zoning/working_paper/CURRENT_DOS"
global SETUP_DOS_2024 "$DOPATH_2024/setup_files"

cd $DOPATH

#delimit ; 
local BZ_FILE_ROOTS
	bindingness
	external_effects
	means
	predicted_prices_mtlines
	rd_amenities_mtlines
	rd_amenities_muni_boundary
	prd_chars_mtlines
	rd_main_mtlines
	rd_main_noroads
	rd_robustness_mtlines
	vacant_parcelsmap
	regulation_map_mtlines
	Within_Town_mtlines
	within_town_setup
;
#delimit cr
 
// #delimit ; 
// local BZ_SETUP_FILES
// postREStat_Within_Town_mtlines
// postREStat_within_town_setup
// ;
// #delimit cr



	









