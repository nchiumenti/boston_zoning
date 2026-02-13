################################################################################
# File name:        create_admissable_boundaries.py
#
# Project title:	Under the (Neighbor)Hood: Understanding Interactions Among 
#					Zoning Regulations
#
# Description:      This code cleans the Zoning Atlas boundaries and subtracts 
#                   overlapping boundaries with cities, large roads, school 
#                   catchment areas etc. Before running this code, need to run 
#                   new_mf_definitions.do which generates reg_type_newmf.dbf

# Inputs:           zoning_atlas.shp
#                   EOTMAJROADS_ARC.shp
#                   EOTROADS_ARC.shp
#                   municipalities.shp
#                   SCHOOLDISTRICTS_POLY.shp"
#                   SABS_1516_Primary.shp
#                   HYDRO100K_ARC.shp
#
# Outputs:          adm3.shp
#
# Created:          
# Updated:          02/04/2026
#
# Author:           Amrita Kulka
################################################################################

import arcpy
import shutil
import zipfile

# Copy over the source files needed to the boundary selection folder
# Alternatively, change the file paths throughout to reference the corresponding
# /data sub-directory

dir = "/data/boundary_files/"

src = "/data/roads/EOTMAJROADS_ARC.zip"

dst = "/data/boundary_files/EOTMAJROADS_ARC.zip"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

src = "/data/roads/EOTROADS_ARC.zip"

dst = "/data/boundary_files/EOTROADS_ARC.zip"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

src = "/data/schools/SCHOOLDISTRICTS_POLY.zip"

dst = "/data/boundary_files/SCHOOLDISTRICTS_POLY.zip"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

src = "/data/schools/SABS_1516_Primary.zip"

dst = "/data/boundary_files/SABS_1516_Primary.zip"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

src = "/data/rivers/HYDRO100K_ARC.zip"

dst = "/data/boundary_files/HYDRO100K_ARC.zip"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

src = "/data/shapefiles/municipalities.zip"

dst = "/data/boundary_files/municipalities.zip"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

src = "/data/zoning_boundaries/zoning_atlas.shp"

dst = "/data/boundary_files/zoning_atlas.shp"

shutil.copyfile(src, dst)

zip = ZipFile(dst)
zip.extractall('dir)
zip.close()

# This code cleans the Zoning Atlas boundaries and subtracts overlapping 
# boundaries with cities, large roads, school catchment areas etc before running 
# this code, need to run new_mf_definitions.do which generates 
# reg_type_newmf.dbf.

# change working directory here
arcpy.env.workspace = r"/data/boundary_selection"

# 1. turn MAPC boundaries into polyline, left and right fid refer to regulation 
# polygons from Zoning atlas

in_features = "zoning_atlas.shp"
out_feature_class = "zoning_atlas_polylines.shp"
neighbor_option = "IDENTIFY_NEIGHBORS"
arcpy.PolygonToLine_management(in_features,out_feature_class,neighbor_option)
print(arcpy.GetMessages())


# intersect road network with zoning atlas polylines, to deal with road slivers
arcpy.analysis.Intersect([["EOTROADS_ARC.shp",1],["zoning_atlas_polylines.shp",2]],"roads_mapc.shp","ALL","15 meters","LINE")
print(arcpy.GetMessages())

# this is turned into roads_mapc_poly (just convert into polygons) 
in_features = "roads_mapc.shp"
out_feature_class = "roads_mapc_poly.shp"
arcpy.management.FeatureToPolygon(in_features, out_feature_class)
print(arcpy.GetMessages())


# match reg_type_newmf to zoning_atlas to create zoning_atlas_type_new.shp

arcpy.env.qualifiedFieldNames = False
in_data = "zoning_atlas.shp"
join_table = "reg_type_newmf.dbf"
outFeature = "zoning_atlas_type_new.shp"

atlas_type = arcpy.management.AddJoin(in_data,"FID", join_table,"POLID")
result = arcpy.management.CopyFeatures(atlas_type, outFeature)

print(arcpy.GetMessages())


# combine these polygons (fills in fine street grids) with mapc type polygons 
# and dissolve
arcpy.Union_analysis([["roads_mapc_poly.shp",1],["zoning_atlas_type_new.shp",2]],"roads_mapc_union_new.shp","ALL","15 meters")
print(arcpy.GetMessages())

# turn dissolved file into polylines and find eligible boundaries, exclude the 
# towns without attendance area info
inFeatures = "roads_mapc_union_new.shp"
outFeatures = "roads_mapc_union_sd_new.shp"
tempLayer ="temp"

# make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)

# turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)

# select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","muni = 'Bellingham' OR muni = 'Braintree' OR muni = 'Burlington' OR muni = 'Concord' OR muni = 'Danvers' OR muni = 'Hamilton' OR muni = 'Hingham' OR muni= 'Ipswich' OR muni = 'Lynnfield' OR muni = 'Medford' OR muni = 'Melrose' OR muni = 'Natick' OR muni = 'Norwood' OR muni = 'Peabody' OR muni = 'Quincy' OR muni = 'Reading' OR muni = 'Saugus' OR muni = 'Stow' OR muni = 'Watertown' OR muni = 'Wenham' OR muni = 'Wilmington' OR muni = 'Winchester' OR muni = 'Woburn'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

# dissolve these places now with only eligible towns by regulation 
inputLayer = "roads_mapc_union_sd_new.shp"
outputLayer = "roads_mapc_union_sd_dissolved_new.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

# turn this into polylines
in_features = "roads_mapc_union_sd_dissolved_new.shp"
out_feature_class = "polylines_feasible_new.shp"
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

# merge on municipality information (for comparison with municipality boundaries only)
joinFeatures = "municipalities.shp"
targetFeatures = "roads_mapc_union_sd_dissolved_new.shp"
out_feature_class = "roads_mapc_union_sd_dissolved_muni_new.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

arcpy.DeleteField_management("roads_mapc_union_sd_dissolved_muni_new.shp", ["shape_1"])
print(arcpy.GetMessages())

# 3. Prepare polygons to subtract from Zoning Atlas boundaries
# municipalities
in_features = "municipalities.shp"
out_feature_class = "muni_polylines.shp"
arcpy.PolygonToLine_management(in_features,out_feature_class)

# school districts
in_features = "SCHOOLDISTRICTS_POLY.shp"
out_feature_class = "sd_polylines.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)

# elementary school attendance areas
# Keep only MA elem school attendance areas 
inFeatures = "SABS_1516_Primary.shp"
outFeatures = "SABS_MA.shp"
tempLayer ="temp_sabs"
# make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)

# turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)

# select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","stAbbrev <> 'MA'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)

# merge with sabs_MA_nooverlap.dbf created in stata program and save
arcpy.env.qualifiedFieldNames = False
in_data = "SABS_MA.shp"
join_table = "sabs_MA_nooverlap.dbf"
outFeature = "sabs_unique.shp"

unique_ed = arcpy.management.AddJoin(in_data,"ncessch", join_table,"ncessch", 0)
result = arcpy.management.CopyFeatures(unique_ed, outFeature)

# convert into lines
in_features = "sabs_unique.shp"
out_feature_class = "attendance_line_unique.shp"
arcpy.PolygonToLine_management(in_features,out_feature_class)

# broad zoning categories
inputLayer = "zoning_atlas.shp"
outputLayer = "zo_usety.shp"
dissolveFields = ["zo_usety"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

# convert into polylines
in_features = "zo_usety.shp"
out_feature_class = "zo_usety_lines.shp"
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

# 4. Subtract municipal boundaries, rivers, roads, highways, school districts, 
# school attendance areas

# a) subtract municipal boundaries 
# intersect city boundaries with MAPC boundaries 
in_features = ["polylines_feasible_new.shp","muni_polylines.shp"]
out_feature_class = "intersect_boundaries_mapc_muni_new.shp"
join_attributes = "ONLY_FID"

# cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

# subtract city boundaries from mapc
in_features = "polylines_feasible_new.shp"
update_features = "intersect_boundaries_mapc_muni_new.shp"
out_feature_class = "mapc_minus_muni_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

# b) subtract rivers and streams 
# intersect mapc-city-roads-school districts with rivers
in_features = ["mapc_minus_muni_new.shp","HYDRO100K_ARC.shp"]
out_feature_class = "intersect_boundaries_mapc_river_new.shp"
join_attributes = "ONLY_FID"
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

# subtract rivers
in_features = "mapc_minus_muni_new.shp"
update_features = "intersect_boundaries_mapc_river_new.shp"
out_feature_class = "mapc_minus_muni_minus_river_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#c) subtract major roads
# intersect mapc - city boundaries with roads
in_features = ["mapc_minus_muni_minus_river_new.shp","EOTMAJROADS_ARC.shp"]
out_feature_class = "intersect_boundaries_mapc_roads_new.shp"
join_attributes = "ONLY_FID"
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

# subtract intersection
in_features = "mapc_minus_muni_minus_river_new.shp"
update_features = "intersect_boundaries_mapc_roads_new.shp"
out_feature_class = "mapc_minus_muni_minus_river_minus_roads_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

# d) subtract elementary school attendance areas (2015/2016)
# new updated boundaries
# intersect with attendance areas
in_features = ["mapc_minus_muni_minus_river_minus_roads_new.shp","attendance_line_unique.shp"]
out_feature_class = "intersect_boundaries_mapc_roads_river_attendance_new.shp"
join_attributes = "ONLY_FID"
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

# subtract school boundaries
in_features = "mapc_minus_muni_minus_river_minus_roads_new.shp"
update_features = "intersect_boundaries_mapc_roads_river_attendance_new.shp"
out_feature_class = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


# e) subtract school districts 
# intersect with school districts
in_features = ["mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp","sd_polylines.shp"]
out_feature_class = "intersect_boundaries_mapc_roads_river_attendance_sd_new.shp"
join_attributes = "ONLY_FID"
# cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

# subtract roads mapc - city boundaries
in_features = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp"
update_features = "intersect_boundaries_mapc_roads_river_attendance_sd_new.shp"
out_feature_class = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

# f) subtract zoning boundaries (commercial/non commercial etc)
in_features = ["mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp","zo_usety_lines.shp"]
out_feature_class = "intersect_boundaries_mapc_roads_river_attendance_sd_zo_new.shp"
join_attributes = "ONLY_FID"

# cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

# subtract roads mapc - city boundaries
in_features = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp"
update_features = "intersect_boundaries_mapc_roads_river_attendance_sd_zo_new.shp"
out_feature_class = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

# length of lines in different layers as we subtract boundaries
inFeatures = "polylines_feasible_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "mapc_minus_muni_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "mapc_minus_muni_minus_river_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","") 
inFeatures = "mapc_minus_muni_minus_river_minus_roads_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","") 
inFeatures = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
print(arcpy.GetMessages())

# clean up file 
inFeatures = "mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp"
outFeatures = "admissable_boundaries_new.shp"
tempLayer ="clean_up"
arcpy.CopyFeatures_management(inFeatures, outFeatures)
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","LEFT_FID = -1 OR RIGHT_FID = -1")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

# delete unwanted fields  
arcpy.DeleteField_management("admissable_boundaries_new.shp", ["FID_mapc_m", "FID_mapc_1", "FID_mapc_2", "FID_mapc_3", "FID_mapc_4", "FID_mapc_5", "FID_mapc_6", "FID_mapc_7", "FID_mapc_8", "FID_mapc_9", "FID_map_10", "FID_map_11", "FID_inters", "FID_inte_1", "FID_inte_2", "FID_inte_3", "FID_inte_4", "FID_inte_5", "FID_inte_6", "FID_poly_1", "FID_muni_p", "FID_HYDRO1", "FID_EOTMAJ", "FID_attend", "FID_sd_pol", "FID_zo_use", "FID_atte_1"])
print(arcpy.GetMessages())

# match these admissable boundaries spatially  with school districts, school attendance areas, zone types and municipalities to get their characteristics and splitting boundaries
# zoning type
joinFeatures = "zo_usety.shp"
targetFeatures = "admissable_boundaries_new.shp"
out_feature_class = "adm1.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

# municipality
joinFeatures = "municipalities.shp"
targetFeatures = "adm1.shp"
out_feature_class = "adm2.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

arcpy.DeleteField_management("adm2.shp", ["objectid", "shape_1"])
print(arcpy.GetMessages())

# school attendance area
joinFeatures = "sabs_unique.shp"
targetFeatures = "adm2.shp"
out_feature_class = "adm3.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())
