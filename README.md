to dos for the final replication package
    
    - Figure 1 from AK
    
    - Walkthrough is NC
    
    - For Can...fork the repo and have him go through the analysis files and have him comment on what produced what, and highlight any excess code we *do not* needed (like regressions) that we can delete
    
    - goal is two repos, (internal) for us and then a public one we share with whomever publishes it
    


# Boston Zoning Project
This repo stores all of the current working versions of data setup and analysis
files used in the paper \<itle here\>. It is managed by Nicholas Chiumenti. The
data files are not stored here because of their size and priopriatary nature.

## Table of Contents

1. [Overview](#overview)
2. [Data Sources](#data-sources)
3. [Code](#code)
<!-- 4. [Output](#output)-->
<!-- 5. [Walkthrough](#walkthrough) -->

## Overview


## Data Sources
### Public Datasets
1.  ✅<ins>Soil data</ins>
    - **Source:** [MassGIS: Soils SSURGO-Certified NRCS](https://www.mass.gov/info-details/massgis-data-soils-ssurgo-certified-nrcs)
    - **Raw file(s):** Soil_Parcel_data_Shape.shp
    - **Final file(s):** soil_quality_matches.dta
    - **Method/Code:** An RA cleaned up the initial input dataset in order to make it a 
    flat shape file. Then [soil_quality_quality_matchin.ipynb](code/data_setup/python_programs/soil_quality_data) matches the soil 
    quality data to the property lots found in Warren Group.
    - **Notes:** Unfortunately, historic versions of the soil data do not appear to be
    accessible, and so the source file is not longer available.

2.  ⚠️<ins>Walk Score</ins>
    - **Source:** [EPA Walkabiltiy Score](https://www.epa.gov/smartgrowth/smart-location-mapping#walkability)
    - **Raw file(s):** Natl_WI.gdb
    - **Final file(s):** warren_group_walkability.dta
    - **Method/Code:** unknown
    - **Notes:** This dataset was made in early 2024 so much have been done with .R
    and not stata. I think at this point the code is lost, but it should have been just
    a straight forward spatial match of property points to polygons.

3.  ⚠️<ins>Zoning Atlas</ins>
    - **Source:** [MAPC](https://zoningatlas.mapc.org/)
    - **Raw file(s):** zoning_atlas.shp
    - **Final file(s):** adm3_latlong.shp --> adm3_latlong.dta & adm3_latlong_shp.dta
    - **Method/Code:** Manual process of removing the zoning boundaries that overlap with
    various other boundaries like towns, rivers, roads, etc.
    - **Notes:** Work done by Amrita.

4.  ✅<ins>Train Stations & Transit Disances</ins>
    - **Source:** [MassGIS: MBTA Rapid Transit](https://www.mass.gov/info-details/massgis-data-mbta-rapid-transit), [MassGIS: Trains](https://www.mass.gov/info-details/massgis-data-trains)
    - **Raw file(s):** MBTA_NODE.shp, TRAINS_NODE.shp 
    - **Method/Code(s):** all_stations.csv, transit_distance.csv, dist_to_south_station.csv
    - **Method:** Python program all_stations.ipynb takes the shape file data and combines to a list
    of mbta and commuter rail train stops. 
    [dist_prop_to_station.ipynb](code/data_setup/python_programs/transit_distances) matches to warren group properties and calculates the distance to nearest train stop. [station_boundary_dist.ipynb](code/data_setup/python_programs/transit_distances) calculates the distance of train stops to their nearest zoning boundary.
    - **Notes:** See #8 for the distance to south station/central boston calculation.

5.  ⚠️<ins>American Community Survey (ACS)</ins>
    - **Source:** ACS data downloaded from IPUMS for 5 MA counties (25009, 25017, 25021, 25023, 25025) at Census block group level or Census block level , blocks_2010, ACS_2019_rent
    - **Raw file(s):** blocks_2010.dta
    - **Final file(s):** acs_amenities.dta
    - **Method/Code:** unknown right now how the final acs amenities is made
    - **Notes:** I think acs_amenities.dta is a renamed version of what bg_amenities.dta
    which is created by [bg_amenitites.do](code/data_setup/miscellaneous_setup_files), but I can't be sure. Aradhya and Amrita might
    have alternative .do files.

6.  ✅<ins>Walking Distance</ins>
    - **Source:** Warren Group Data
    - **Raw file(s):** walking_distance_inputs.csv
    - **Final file(s):** walking_distance_outputs.csv
    - **Method/Code:** Main walking distances file made with walking_distance_osrm.ipynb
    - **Notes:** I am 99% sure the inputs_csv. file is what is created by
    [effective_dist_export.do](code/data_setup/miscellaneous_setup_files). However, the input and output files names are different. I think this was done just to make code references to them easier to read/interpret. 

7.  ✅<ins>Highways, rivers, schools, open space, city centroids</ins>
    - **Source:** Mass GIS [Highways]() and [Rivers](), school attendance area bounds from [NCES](https://nces.ed.gov/programs/edge/sabs), open space is from the zoning atlas data, city centroids is from [census shape files](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html).
    - **Raw file(s):** HYDRO100K_ARC.shp,  EOTMAJROADS_ARC.shp, zoning_atla.shp (zo_usetype == 4), SCHOOLS_PT.shp, cb_2018_25_cousub_500k.shp.
    - **Final file(s):** roads.dta, rivers.dta, green_space.dta, schools.dta, city_centroids.dta, warren_MAPC_all_unique_closest_stuff.dta
    - **Method/Code:** [80_amenity_datasets.do](code/data_setup) sets and saves and merges all of these into the final warren data matched dataset. Some of these files were converted from cartesian and lat/lon coordinates and are tagged with the file name suffix _latlong. This was done in python or ArcGIS and not tracked.
    - **Notes:**

8.  ✅<ins>Distance to central Boston</ins>
    - **Source:** see #4
    - **Raw file(s):** all_stations.csv
    - **Final file(s):** dist_south_station_2022_09_29.csv
    - **Method/Code:** [dist_to_south_station.ipynb]((code/data_setup/python_programs/transit_distances))
    - **Notes:** The full distance to south station from the property is calculated using the distance to the station plus the train station distance to south station.

### Propietary Datasets

## Code

## Output

## Walkthrough

