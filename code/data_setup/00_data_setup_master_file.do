********************************************************************************
* File name:		"replication_package_master_analysis.do"
*
* Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
*					Zoning Regulations
*
* Description:		This .do file is a master .do file that calls all relevant
*                   analysis files in the order they should be run. It is meant
*                   to unify the disparate analysis files in one place and make 
*                   it easier to run. 
* 				
* Inputs:           None		
*				
* Outputs:		    None
*
* Created:		    01/21/2025
* Updated:		    01/31/2026
********************************************************************************
clear all
log close _all
set more off, perm
set type double
set seed 123456
set linesize 255
pause off
set graphics on

* set paths, passed to called .do files
global DATAPATH "<LOCAL FILE PATH>/data"

global LOGPATH = "<LOCAL FILE PATH>/logs"

global DOPATH "<LOCAL FILE PATH>/code/data_setup"

global SHAPEPATH "<LOCAL FILE PATH>/data/shapefiles"

cd "$DOPATH" 