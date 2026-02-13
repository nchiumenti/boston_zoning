*=============================================
*Figure A.6
*=============================================

*Figure A6a involves plotting polylines_feasible.shp 
*Figure A6b involves plotting polylines_feasible.shp and mapc_minus_muni_minus_river_minus_roads_new.shp2dta
*Figure A6c involves plotting mapc_minus_muni_minus_river_minus_roads_new.shp and mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp
*Figure A6d involves plotting mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp and mt_orthogonal_lines.shp
*Boundary lengths and numbers are calculated below

clear

*Count boundary segment length 

*Figure A.6a (length)
tempfile figA6a
shp2dta using "$DATAPATH/boundary_selection/polylines_feasible_new.shp", database(`figA6a') coordinates(`figA6a') replace

use `figA6a'

sum LENGTH

clear

*Figure A.6b (length)
tempfile figA6b
shp2dta using "$DATAPATH/boundary_selection/mapc_minus_muni_minus_river_minus_roads_new.shp", database(`figA6b') coordinates(`figA6b') replace

use `figA6b'

sum LENGTH

clear


*Figure A.6c (length)
tempfile figA6c
shp2dta using "$DATAPATH/boundary_selection/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp", database(`figA6c') coordinates(`figA6c') replace

use `figA6c'

sum LENGTH

clear


*Figure A.6d (length) mt_orthogonal_lines.shp
tempfile figA6d
shp2dta using "$DATAPATH/boundary_selection/mt_orthogonal_lines.shp", database(`figA6d') coordinates(`figA6d') replace

use "$DATAPATH/data/mt_orthogonal_lines/mt_orthogonal_lines/mt_orthogonal_lines.dta"

sum LENGTH / 1609.344

clear