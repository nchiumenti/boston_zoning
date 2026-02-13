# Start Here

[🏠 Return to main page](/)

The purpose of this `README.md` is to aid future users who wish to replicate the analysis found in 
[*Under the (Neighbor)Hood: Understanding Interactions Among Zoning Regulations*](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4082457). 

## Overview

We ***strongly*** advise users to familiarize themselves with the 
documentation provided in this repository before attempting to run any code or 
replicate any results. Any and all relavent documentation is located in the
[/docs](/docs) directory.

The repository is structured as follows:

- `/code` – Contains all coding files used for data setup and analysis.

    - `/code/analysis_files` – Contains programs associated with final output
analysis.

    - `/code/data_setup_files` Contains programs associated with data cleaning and
initial setup.

- `/data` – Contains raw input data, intermediate data files, final data files.

- `/docs` – Contains repo associated .md files, guides, walkthroughs, codebooks, etc.

> [!IMPORTANT]
> **A note about data availability**
> 
> To the extent possible we have provided raw input, intermediate, and final 
> versions of data files in this repository. However, we are limited in what we 
> are able to share in this repository in two (2) major ways.
>
> 1) **Data license limitations** - We are unable to data files that 
> were made available through the Federal Reserve Bank of Boston. These include 
> any source files of the Warren Group's property tax assessment records data, 
> and the CoStar rental property history data. In both cases, the Federal 
> Reserve Bank of Boston and/or the Federal Reserve System is the holder of 
> these data license agreements. This limitation extends to any derived output,
> except for aggregated output, included matching and crosswalk files.
>
> 2) **Data file size limits** - GitHub limits file size uploads to to 
> 100MB. We are not able to upload and share large files that exceed this limit
> but they are available upon request. When possible, files have been compressed
> into .zip files to facilitate upload. All files we are able to share, 
> regardless of size, were uploaded the [*Review of Economics and Statistics Dataverse*](https://dataverse.harvard.edu/dataverse/restat).
>

**Placeholder files** are located throughout this repository to illustrate where 
original data files should be located if they were unable to be shared via this 
repository. These placeholder files follow the format of 
`<original_filename>.txt` and include text information within them. 

For example, the original file `MA_assessor_annual_expanded.dta` cannot be 
shared because it is under a license agreement. It would be located at the 
following file path:

`/data/warren/originals/MA_assessor_annual_expanded.dta`

In its place is the following:

`/data/warren/originals/MA_assessor_annual_expanded.dta.txt`

If opened in a text editor, it displays the following:

```
Source: MA_assessor_annual_expanded.dta

This is a placeholder file illustrating where the source file is located within the directory structure.

Cannot be shared due to data license agreement.
```

**Directory tree** files called `_tree.txt` have been added throughout the 
`/data` directory and list all files and subfolder that should be located within 
them, even if they are not available through this repository.

For example if `/data/walkability/_tree.txt` is opened in a text editor it displays
the following:

```
Folder PATH listing for volume OS
Volume serial number is F054-B23E
C:.
    .gitignore
    National Walkability Index_Methodology and User Guide_June2021.pdf
    Natl_WI.gdb.zip
    Natl_WI.gdb.zip.txt
    tree.txt
    warren_group_walkability.dta
    
No subfolders exist 
```

In `/data/walkability/_tree.txt` the file `Natl_WI.gdb.zip` is listed. However, 
it is not available in this repository because it's file size (416MB) exceeds 
the 100MB limit. In its place is `Natl_WI.gdb.zip.txt`, which when viewed in a 
text editor displays the following:

```
Source: Natl_WI.gdb.zip

This is a placeholder file illustrating where the source file is located within the directory structure.

Not uploaded to GitHub due to file size exceeding upload limit.
```

## Next Steps
Proceed to one of the following for more information:

The [Data Sources Guide](data_sources.md) provides information and links to the various
data sources used in the paper.

The [Data Setup Guide](data_setup_files.md) details the files involved in the data setup process.

The [Analysis Guide](analysis_files.md) details the files involved in the analysis. 
Users can refer here to find the process that creates a particular figure or 
table in the paper.

The [Walkthrough](walkthrough.md) guide details the steps that should be taken to go from raw data
to final results.