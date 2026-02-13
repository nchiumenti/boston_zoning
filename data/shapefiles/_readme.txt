./originals - contains all '.zip' file downloads and extracts

./standardized - contains all '.shp' files in lat/long format espg:4269 and their Stata conversions ('.dta' and '_shp.dta')


Some of the shape files use a cartesian coordinate system that won't map to the latitudes and longitudes used in the Warren Group data and other shape files. The python programs remedy this by using the 'geopandas' library to convert all of the coordinate systems to one standardized spatial reference system. ESPG:4269/NAD83 is used because this reference system is used by the Census Bureau for all of their catographic mapping shape files.
	- see: https://epsg.io/4269

################
Python programs:
***currently only works through an interpreter like Jupyter Notebook***
################
'extract_zips.py' - loops over all '.zip' files in ./originals and extracts then to the same directory

'latlong_convert.py' - takes the extracted shape files and converts their coordinate system to lat/long format espg:4269. Saves the conversions in ./standardized
	- program runs through all shape files regardless of their current coordinate system

##################
Stata '.do' files:
##################
'shp2dta.do' - converts the converted '.shp' files to stata format where...
	- '<filename>.dta' is the database file
	- '<filename>_shp.dta' is the coordinates file

'shpmisc.do' - has some miscellaneous code for overlaying shape files and checking coverage