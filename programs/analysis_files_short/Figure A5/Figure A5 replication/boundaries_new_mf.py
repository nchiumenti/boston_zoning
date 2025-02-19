####################################################
#Admissable boundaries - different MF definition####
####################################################
#MF is now 0 if MF banned or only by special permit, if any kind of MF is by-right it's 1

#combine these polygons (only able to construct polygons for the places that actually have fine grid networks, but check this later) with mapc type polygons and dissolve
import arcpy
arcpy.Union_analysis([["X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_poly.shp",1],["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/zoning_atlas_type_new.shp",2]],"X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_new.shp","ALL","15 meters")
print(arcpy.GetMessages())

#turn dissolved file into polylines and find eligible boundaries
#exclude the towns without attendance area info
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_new.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_new.shp"
tempLayer ="temp5"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","muni = 'Bellingham' OR muni = 'Braintree' OR muni = 'Burlington' OR muni = 'Concord' OR muni = 'Danvers' OR muni = 'Hamilton' OR muni = 'Hingham' OR muni= 'Ipswich' OR muni = 'Lynnfield' OR muni = 'Medford' OR muni = 'Melrose' OR muni = 'Natick' OR muni = 'Norwood' OR muni = 'Peabody' OR muni = 'Quincy' OR muni = 'Reading' OR muni = 'Saugus' OR muni = 'Stow' OR muni = 'Watertown' OR muni = 'Wenham' OR muni = 'Wilmington' OR muni = 'Winchester' OR muni = 'Woburn'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

#dissolve these places now with only eligible towns
import arcpy
inputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_new.shp"
outputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_dissolved_new.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#turn this into polylines (can spatial merge this back to roads_mapc_union_sd to get additional fields apart from reg type)
#called polylines_feasible.shp
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_dissolved_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/polylines_feasible_new.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_dissolved_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_dissolved_muni_new.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/roads_mapc_union_sd_dissolved_muni_new.shp", ["shape_1"])
print(arcpy.GetMessages())



#3. Subtract municipal boundaries, rivers, roads, highways, school districts, school attendance areas
#a)subtract municipal boundaries
#intersect city boundaries with MAPC boundaries (now with only eligible towns)
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/polylines_feasible_new.shp","X:/Kulka/Affordable housing/Boundary shapefiles/muni_polylines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_muni_new.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract city boundaries from mapc
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/polylines_feasible_new.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_muni_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#b)subtract rivers and streams
#intersect mapc-city-roads-school districts with rivers
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_new.shp","X:/Kulka/Affordable housing/Boundary shapefiles/hydro100k/HYDRO100K_ARC.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_river_new.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract rivers
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_new.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_river_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#c)subtract major roads
#intersect mapc - city boundaries with roads
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_new.shp","X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/EOTMAJROADS_ARC.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_new.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract intersection
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_new.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#d)subtract elementary school attendance areas (2015/2016)
#new updated boundaries
#intersect with attendance areas
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_new.shp","X:/Kulka/Affordable housing/Boundary shapefiles/attendance_line_unique.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_river_attendance_new.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract school boundaries
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_new.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_river_attendance_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#e)subtract school districts (this probably won't do very much additionally)
#intersect with school districts
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp","X:/Kulka/Affordable housing/Education/sd_polylines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_river_attendance_sd_new.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract roads mapc - city boundaries
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_new.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_river_attendance_sd_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#f) subtract zoning boundaries (commercial/non commercial etc)
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp","X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_lines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_river_attendance_sd_zo_new.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract roads mapc - city boundaries
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_new.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/intersect_boundaries_mapc_roads_river_attendance_sd_zo_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#count length of lines in different layers as we subtract boundaries
#import arcpy 
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","") 
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","") 
#inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo.shp"
#arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
#print(arcpy.GetMessages())





#clean up file and eliminate -1 boundaries
#eliminate -1 boundaries
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo_new.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/admissable_boundaries_new.shp"
tempLayer ="temp6"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","LEFT_FID = -1 OR RIGHT_FID = -1")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

#delete unwanted fields  
import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/admissable_boundaries_new.shp", ["FID_mapc_m", "FID_mapc_1", "FID_mapc_2", "FID_mapc_3", "FID_mapc_4", "FID_mapc_5", "FID_mapc_6", "FID_mapc_7", "FID_mapc_8", "FID_mapc_9", "FID_map_10", "FID_map_11", "FID_inters", "FID_inte_1", "FID_inte_2", "FID_inte_3", "FID_inte_4", "FID_inte_5", "FID_inte_6", "FID_poly_1", "FID_muni_p", "FID_HYDRO1", "FID_EOTMAJ", "FID_attend", "FID_sd_pol", "FID_zo_use", "FID_atte_1"])
print(arcpy.GetMessages())

#match these admissable boundaries spatially  with school districts, school attendance areas, zone types and municipalities to get their characteristics
#zoning type
import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/admissable_boundaries_new.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm1.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

#municipality
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm1.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm2.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm2.shp", ["objectid", "shape_1"])
print(arcpy.GetMessages())

#school districts (don't need this because included in attendance areas)
#joinFeatures = "X:/Kulka/Affordable housing/Education/SCHOOLDISTRICTS_POLY.shp"
#targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/adm2.shp"
#out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/adm3.shp"
#arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
#print(arcpy.GetMessages())

#import arcpy 
#arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/adm3.shp", ["SHAPE_AREA", "SHAPE_LEN"])
#print(arcpy.GetMessages())

#school attendance area
joinFeatures = "X:/Kulka/Affordable housing/Education/sabs_unique.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm2.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm3.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
arcpy.management.Rename("X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/adm3.shp","X:/Kulka/Affordable housing/Boundary shapefiles/new_mf_definition/final_boundaries_new_mf.shp")
print(arcpy.GetMessages())

#joinFeatures = "X:/Kulka/Affordable housing/Education/sabs13_MA.shp"
#targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/adm3.shp"
#out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/admissable_final.shp"
#arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
#print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/admissable_final.shp", ["SHAPE_AREA", "SHAPE_LEN"])
print(arcpy.GetMessages())



#now can use LEFT_FID and RIGHT_FID to match this back to regulation types 

