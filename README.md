
# Boston Zoning Project
This repo stores all of the current working versions of data setup and analysis
files used in the paper \<itle here\>. It is managed by Nicholas Chiumenti. The
data files are not stored here because of their size and priopriatary nature.

## Table of Contents

1. [Overview](#overview)
2. [Data](#data)
3. [Code](#code)
4. [Output](#output)
5. [Walkthrough](#walkthrough)

## Overview


## Data Sources
### Public Datasets
1.  ✅<ins>Soil data</ins>
    - **Source:** [MassGIS: Soils SSURGO-Certified NRCS](#https://www.mass.gov/info-details/massgis-data-soils-ssurgo-certified-nrcs)
    - **Raw file(s):** Soil_Parcel_data_Shape.shp
    - **Final file(s):** soil_quality_matches.dta
    - **Method:** An RA cleaned up the initial input dataset in order to make it a 
    flat shape file. Then soil_quality_quality_matchin.ipynb matches the soil 
    quality data to the property lots found in Warren Group.
    - **Notes:** Unfortunately, historic versions of the soil data do not appear to be
    accessible, and so the source file is not longer available.

2.  ❓<ins>Walk Score</ins>
    - **Source:** [EPA Walkabiltiy Score](#https://www.epa.gov/smartgrowth/smart-location-mapping#walkability)
    - **Raw file(s):** 
    - **Final file(s):** warren_group_walkability.dta
    - **Method:**
    - **Notes:**

3.  ❓<ins>Zoning Atlas</ins>
    - **Source:**
    - **Raw file(s):**
    - **Final file(s):** adm3_latlong.shp; xxx.dta
    - **Method:** Manual process of removing the zoning boundaries that overlap with
    various other boundaries like towns, rivers, roads, etc.
    - **Notes:** Work done by Amrita.

4.  ✅<ins>Train Stations & Transit Disances</ins>
    - **Source:** [MassGIS: MBTA Rapid Transit](#https://www.mass.gov/info-details/massgis-data-mbta-rapid-transit), [MassGIS: Trains](#https://www.mass.gov/info-details/massgis-data-trains)
    - **Raw file(s):** MBTA_NODE.shp, TRAINS_NODE.shp 
    - **Final file(s):** all_stations.csv, transit_distance.csv, dist_to_south_station.csv
    - **Method:** Python program all_stations.ipynb takes the shape file data and combines to a list
    of mbta and commuter rail train stops. 
    dist_prop_to_station.ipynb matches to warren group properties and calculates the distance to nearest train stop. station_boundary_dist.ipynb calculates the distance of train stops to their nearest zoning boundary.
    - **Notes:** See #8 for the distance to south station/central boston calculation.

5.  ❓<ins>American Community Survey (ACS)</ins>
    - **Source:** ACS data downloaded from IPUMS for 5 MA counties (25009, 25017, 25021, 25023, 25025) at Census block group level or Census block level , blocks_2010, ACS_2019_rent
    - **Raw file(s):** blocks_2010.dta
    - **Final file(s):** acs_amenities.dta
    - **Method:** unknown right now how the final acs amenities is made
    - **Notes:** look what makes acs_amenities.dta

6.  ❓<ins>Walking Distance</ins>
    - **Source:** Warren Group Data
    - **Raw file(s):** walking_distance_inputs.csv
    - **Final file(s):** walking_distance_outputs.csv
    - **Method:** Main walking distances file made with walking_distance_osrm.ipynb
    - **Notes:** unknown how to make the inputs file right now

7.  ✅<ins>Highways, rivers, schools, open space, city centroids</ins>
    - **Source:** Mass GIS [Highways](#) and [Rivers](#), school attendance area bounds from (NCES)[#https://nces.ed.gov/programs/edge/sabs], open space is from the zoning atlas data, city centroids is from [census shape files](#https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html).
    - **Raw file(s):** HYDRO100K_ARC.shp,  EOTMAJROADS_ARC.shp, zoning_atla.shp (zo_usetype == 4), SCHOOLS_PT.shp, cb_2018_25_cousub_500k.shp.
    - **Final file(s):** roads.dta, rivers.dta, green_space.dta, schools.dta, city_centroids.dta, warren_MAPC_all_unique_closest_stuff.dta
    - **Method:** 80_amenity_datasets.do sets and saves and merges all of these into the final warren data matched dataset. Some of these files were converted from cartesian and lat/lon coordinates and are tagged with the file name suffix _latlong. This was done in python or ArcGIS and not tracked.
    - **Notes:**

8.  ✅<ins>Distance to central Boston</ins>
    - **Source:** see #4
    - **Raw file(s):** all_stations.csv
    - **Final file(s):** dist_south_station_2022_09_29.csv
    - **Method:** dist_to_south_station.ipynb, the full distance to south station from the 
    property is calculated using the distance to the station plus the train station distance
    to south station.
    - **Notes:**

### Propietary Datasets

## Code

## Output

## Walkthrough

