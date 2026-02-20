## Introduction
This repository contains the code, data and output underlying the paper *Under 
the (Neighbor)Hood: Understanding Interactions Among Zoning Regulations*, 
published in the *Review of Economics and Statistics*, by Amrita Kulka, 
Aradhya Sood and Nicholas Chiumenti.

[SSRN Link](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4082457)

## Authors
Amrita Kulka  
amrita.kulka@warwick.ac.uk  
https://sites.google.com/site/kulkaamrita/home  

Aradhya Sood  
aradhya.sood@rotman.utoronto.ca  
https://sites.google.com/view/aradhyasood  

Nicholas Chiumenti  
nick.chiumenti@gmail.com  
https://nchiumenti.github.io/



## Paper abstract
We study how various zoning regulations combine to affect housing supply, prices,
and rents of single- and multifamily homes using novel lot-level zoning data from
Greater Boston and a cross-sectional boundary discontinuity design at regulation
boundaries. Looser density restrictions, alone or with other less restrictive regula-
tions, are most effective in increasing supply and reducing per-housing-unit rents
and prices. We theoretically and empirically show that restrictive zoning regula-
tions shift housing stock towards larger units, increasing prices per housing unit.
Counterfactual simulations imply that a recent Massachusetts law increasing build-
ing density near transit can reduce long-run rents and prices, particularly in sub-
urbs.

## Acknowledgements
For their helpful and insightful comments, we thank Treb Allen, Nate Baum-Snow, 
Kirill Borusyak, Leah Brooks, Ingrid Gould Ellen, Fernando Ferreira, Lucie Gadenne, 
Jeffrey Lin, Jenny Schuetz, Will Strange, Jeff Thompson, Matt Turner, Paul Willen, 
and Jeff Zabel as well as seminar participants at various institutions. We also 
thank Can Ay, Levi Berger, Hope Bodenschatz, Mike Corbett, and Eli Inkelas for 
providing invaluable research and coding assistance.


## Repository overview
It is recommended you familiarize yourself with the documentation provided in 
this repository before attempting to run any code or replicate any results.
Refer to the [documentation](/docs/) folder for details, or click the link below
to follow the walkthrough guide.

💫[Start Here!](./docs/README.md)

### Directory structure

- `/code` – Contains all coding files used for data setup and analysis.

    - `/code/analysis_files` – Contains programs associated with final output
analysis.

    - `/code/data_setup_files` Contains programs associated with data cleaning and
initial setup.

- `/data` – Contains raw input data, intermediate data files, final data files.

- `/docs` – Contains repo associated .md files, guides, walkthroughs, codebooks, etc.

### Software requirements
This project is primarily coded in [Stata](https://www.stata.com/). 
[Python](https://www.python.org/) is also required to run many data setup 
processes, particularly around the spatial matching of property records to 
zoning boundaries. It is recommended to have access to ArcGIS or an equivalent 
geospatial analysis tool to view or work with with the source .shp files. 

Suggested program versions are given below:
-   Stata v16.0 or later.
-   Python 3.9 or later
-   Jupyter Notebooks v6.0 or later (recommended)
-   ArcPro v3.6 (or equivalent)

