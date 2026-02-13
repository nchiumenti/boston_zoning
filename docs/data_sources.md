<a id="top"></a>

# Data Sources Guide

[🔙 Return to 'Start Here'](./README.md) | [🏠 Go to main page](/)

**Table of Contents:**
- [Non-public data sources](#non-public-data-sources)
    - [Warren Group](#warren-group)
    - [Costar](#costar)
- [Public data sources](#non-public-data-sources)
    - [American Community Survey (ACS)](#american-community-survey-acs)
    - [Chapter 40B](#chapter-40b)
    - [City centers (centroids)](#city-centers-centroids)
    - [Consumer Price Index](#consumer-price-index)
    - [Green Space](#green-space)
    - [Major and Minor Roadways](#major-and-minor-roadways)
    - [Municipality Boundaries](#municipality-boundaries)
    - [Metropolitan Area Planning Council (MAPC) Zoning Atlas](#metropolitan-area-planning-council-mapc-zoning-atlas)
    - [National Housing Preservation Database (NHPD)](#national-housing-preservation-database-nhpd)
    - [School Attendance Boundaries](#school-attendance-boundaries)
    - [School Districts](#school-districts)
    - [Soil Quality Data](#soil-quality-data)
    - [Train Stations & Transit Distances](#train-stations--transit-distances)
    - [Walk Score (Walkability)](#walk-score-walkability)
    - [Water Features (hydrography)](#water-features-hydrography)


---

We detail below the data sources used for the paper. To the best of our ability 
we have listed all sources of data used in the report. If gaps exist please 
reach out so we may update this repository with the missing information.

Any data that we are able to share publicly through this repository is located 
in the [/data](/data) directory. 

>[!IMPORTANT]
> We are unable to share sources of data that were made available through the 
> author's prior professional associations with the Federal Reserve Bank of 
> Boston. These specifically relate to the Warren Group's property tax 
> assessment records data, and the CoStar rental property history data. In both
> cases, the Federal Reserve Bank of Boston and/or the Federal Reserve System is
> the holder of these data license agreements.

<br>
<br>

## Non-public data sources

### Warren Group
**Source:**

https://www.thewarrengroup.com/

**Description:**

The Warren Group data is a time series of property tax assessment records for 
all cities and towns in Massachusetts. The raw data is under a data license 
agreement and cannot be shared publicly.

**Directory location:**

[/data/warren](/data/warren)

---

### Costar
**Source:** 

https://www.costar.com/

**Description:**

The CoStar data is property-level real-estate records encompassing the rental 
market in Greater Boston. Data is primarily for 4+ unit structures and is 
aggregated from a variety of source by CoStar, as well as compiled through their
own survey efforts. The raw data is under a data license agreement and cannot 
be shared publicly. For CoStar, property level data had to be hand scraped in 
batches of 100-1000 records, depending on if it pertained to the property data 
or the rental history data.

**Directory location:**

[/data/costar](/data/costar)

<br>
<br>

## Public data sources

Below we have provide links to the source files were original raw input data was
downloaded from and/or provided directory path links to the corresponding raw 
files in the repo.

### American Community Survey (ACS)

**Source:**

ACS 5-year 2009&ndash;2018 downloaded from [Social Explorer](https://www.socialexplorer.com/home/data-library)

ACS 5-year 2019 downloaded [IPUMS](www.ipums.org)

**Description:**

ACS data at the block group data was downloaded and cleaned, and then compiled 
into the final `acs_amenities.dta` file. The code for cleaning the raw data 
downloads are in `/data/acs/RAW DATA/` under their corresponding year 
sub-directories.

**Directory location:**

[/data/acs](/data/acs)

---

### Chapter 40B

**Source:**

From a data request to the [Massachusetts Department of Housing and Community 
Development](https://www.mass.gov/orgs/executive-office-of-housing-and-livable-communities)
in late 2020. Also see [Chapter 40B Planning and Information](https://www.mass.gov/chapter-40b-planning-and-information)
for details.

**Description:**

The Chapter 40B data covers properties in the state's subsidized housing 
inventory and that are constructed or qualify under the 1969/1970 statue 
requiring minimum affordable housing inventory for municipalities in the state. 
While this data is no longer used in any analysis, it remains a part of the 
setup code files and so is documented here.

An initial partial list of CH40B properties was received back in December 2020. 
We received an updated full list of properties in May of 2021.

**Directory location:**

[/data/chapter40B](/data/chapter40B/)

---

### City centers (centroids)

**Source:**

[U.S. Census Cartographic Boundary Files](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html)

**Description:**

The cartographic boundary files are simplified representations of selected 
geographic areas from the Census Bureau’s Master Address File/Topologically 
Integrated Geographic Encoding and Referencing (MAF/TIGER) System. These 
boundary files are specifically designed for small scale thematic mapping. 
Variables `_CX` and `_CY` denote polygon centers and were used to identify 
city/town centers.

**Directory location:**

[/data/city_centroid](/data/city_centroids/)

---

### Consumer Price Index

**Source:**

[St. Louis Fed Federal Reserve Economic Data, CPI All Urban Consumers](https://fred.stlouisfed.org/series/CPI)

**Description:**

Basic CPI data covering the 2010&ndash;2018 period of the analysis used to adjust
prices to 2019.

**Directory location:**

[/data/fred_cpi](/data/fred_cpi/)

---

### Green Space

**Source:**

[Metropolitan Area Planning Council Zoning Atlas](https://zoningatlas.mapc.org/)

**Description:**

The source file for this [MAPC Zoning Atlas](#mapc-zoning-atlas). Identifying 
green/open space is based on the variable `zo_usety`. Code for creating the
output file `green_space.dta` file is included under 
[80_amenity_datasets.do](/code/data_setup/80_amenity_datasets.do). 
Additional hand-coded green space records are found in `green_space_save.dta`.

**Directory location:**

[/data/green_space/](/data/green_space/)

> [!NOTE]
> The source files use the cartesian coordinates system. The versions provided 
> were converted to degrees (lat/lon) using Python and EPSG 4269.

---

### Major and Minor Roadways

**Source:**

[MassGIS Data: MassGIS-MassDOT Roads](https://www.mass.gov/info-details/massgis-data-massgis-massdot-roads#downloads)

**Description:**

This layer is the official state-maintained street transportation dataset
available from MassGIS. The layer is a hybrid set of linework, most coming from
MassDOT with some additional attributes and linework added by MassGIS. This layer
represents all the public and many of the private roadways in Massachusetts,
including designations for Interstate, U.S. and State routes.

**Directory location:**

[/data/roads/](/data/roads/)

> [!NOTE]
> The source files use the cartesian coordinates system. The versions provided 
> were converted to degrees (lat/lon) using Python and EPSG 4269.

---

### Municipality Boundaries

**Source:**

[MassGIS Data: Municipalities](https://www.mass.gov/info-details/massgis-data-municipalities)

**Description:**

This layer is the most accurate representation of Massachusetts' municipal 
(city and town) boundaries; this representation is based on the legislatively 
approved record of municipal boundaries. Authoritative determination of 
municipal boundary locations can only be provided by a licensed land surveyor. 
MassGIS regularly makes corrections or refinements to this data layer as 
information becomes available; the list of those changes is at the bottom of 
this web page.

**Directory location:**

[/data/municipalities/](/data/municipalities/)

---

### Metropolitan Area Planning Council (MAPC) Zoning Atlas

**Source:** 

[Metropolitan Area Planning Council Zoning Atlas](https://zoningatlas.mapc.org/)

**Description:**

The MAPC Zoning Atlas is a web-based mapping archive tool that documents the
zoning regulations at the municipal level. It covers about 100 cities and towns
in eastern Massachusetts and was developed between 2010 and 2018. The towns 
included in this atlas fall under MAPC's general service region, as one of the
regional planning commissions in the State.

**Directory location:**

[/data/zoning_boundaries/](/data/zoning_boundaries/) (raw data)
[/data/regulation_data/](/data/regulation_data/) (regulations only)

> [!NOTE]
> This is a core component of the analysis in the paper and many derivative 
> outputs were created from it. The data files under `/data/regulation_data` are
> a prime example.

---

### National Housing Preservation Database (NHPD)

**Source:** 

[National Housing Preservation Database (NHPD)](https://preservationdatabase.org/)

**Description:**

The NHPD is an address-level inventory of federally assisted rental housing in 
the US. The agencies and departments that fund these programs have data on the 
individual programs that they manage, but there is no central location where all 
of these data are integrated. This makes it difficult to get a clear picture of 
the current stock of public and affordable housing in a community. It also means 
those who wish to preserve public and affordable housing in their community, 
cannot easily get the information they need about particular properties. 
By creating the NHPD, the PAHRC and NLIHC hope to address these issues.

As with the Chapter 40B data, this data source is no longer used in any analysis.
However, it is a core component of the initial setup files and so is included here.

**Directory location:**

[/data/nhpd/](/data/nhpd/)

---

### School Attendance Boundaries

**Source:**

[NCES School Attendance Boundary Survey (SABS)](https://nces.ed.gov/programs/edge/sabs)

**Description:**

The School Attendance Boundary Survey (SABS) was an experimental survey 
conducted by NCES’ EDGE program with assistance from the U.S. Census Bureau to 
collect school attendance boundaries for the 2013-2014 and 2015-2016 school 
years. The shapefiles include feature geometry for elementary, middle, and high 
school boundaries as well the name, ID, grade span, and other attributes for 
each school.

**Directory location:**

[/data/schools/](/data/schools/)

---

### School Districts

**Source:**

[MassGIS Data: Public School Districts](https://www.mass.gov/info-details/massgis-data-public-school-districts)

**Description:**

These polygon data layers depict the boundaries of public school districts in 
the Commonwealth of Massachusetts.

**Directory location:**

[/data/schools/](/data/schools/)

---

### Soil Quality Data
**Source:**

[MassGIS: Soils SSURGO-Certified NRCS](https://www.mass.gov/info-details/massgis-data-soils-ssurgo-certified-nrcs)

**Description:**

NRCS SSURGO-certified soils data for Massachusetts. The raw shapefile data is 
highly detailed, containing many overlapping layers. The data on this repo was 
flatten to combine multiple measures of soil quality. The file 
`Soil_Parcel_data_Shape.shp` is this flattened version as the original raw 
download was too large to include.

**Directory location:**

[/data/soil](/data/soil/)

> [!NOTE]
> An RA cleaned up the initial input dataset in order to make it a flat shape 
> file. Then [soil_quality_quality_matching.ipynb](code/data_setup/python_programs/soil_quality_data) 
> matches the soil quality data to the property lots found in Warren Group.

---

### Train Stations & Transit Distances

**Source:**

[MassGIS: MBTA Rapid Transit](https://www.mass.gov/info-details/massgis-data-mbta-rapid-transit); [MassGIS: Trains](https://www.mass.gov/info-details/massgis-data-trains)

**Description:**

There are two components to this data. The MBTA rapid transit layers 
(`MBTA_NODE.shp` and `MBTA_ARC.shp`) represent the core subway system lines and
stations within the Greater Boston area. The rail linework and station points 
(`TRAINS_NODE.shp` and `TRIANS_ARC.shp`) are for passenger, freight, and Amtrak 
and MBTA Commuter Rail trains.

**Directory location:**

[/data/train_stops](/data/train_stops)

---

### Walk Score (Walkability)

**Source:**

[EPA walkability Score](https://www.epa.gov/smartgrowth/smart-location-mapping#walkability)

**Description:**

The National Walkability Index is a nationwide geographic data resource that 
ranks block groups according to their relative walkability. The national dataset 
includes walkability scores for all block groups as well as the underlying 
attributes that are used to rank the block groups.

**Directory location:**

[/data/walkability](/data/walkability)

---

### Water Features (hydrography)

**Source:**

[MassGIS Data: Major Ponds and Major Streams](https://www.mass.gov/info-details/massgis-data-major-ponds-and-major-streams)

[MassGIS Data: Hydrography (1:100,000)](https://www.mass.gov/info-details/massgis-data-hydrography-1100000)

**Description:**

The Major Ponds and Major Streams data layers represent a subset of hydrographic
features from the Hydrography (1:100,000) layer. Large water bodies and rivers
are included in these two layers, respectively, and are meant to be used for
plotting small-scale maps. The layers are named MAJPOND_POLY and MAJSTRM_ARC.

**Directory location:**

[/data/rivers/](/data/rivers/)

> [!NOTE]
> The source files use the cartesian coordinates system. The versions provided 
> were converted to degrees (lat/lon) using Python and EPSG 4269.


<br>
<br>

<a href="#top">Back to Top</a>



