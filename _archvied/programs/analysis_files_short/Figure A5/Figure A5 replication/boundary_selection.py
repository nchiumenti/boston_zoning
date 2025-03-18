###################################
#Creating admissable boundaries####
###################################

#1. turn MAPC boundaries into polyline, left and right fid refer to mls polygons (NAME)
import arcpy
in_features = "C:/Users/kulka2/Downloads/Base Districts/zoning_atlas.shp"
out_feature_class = "C:/Users/kulka2/Downloads/zoning_atlas_polylines.shp"
neighbor_option = "IDENTIFY_NEIGHBORS"
arcpy.PolygonToLine_management(in_features,out_feature_class,neighbor_option)
print(arcpy.GetMessages())

#2. Keep only MA elem school attendance areas 
#school boundaries
#elementary 
#keep only MA
import arcpy
inFeatures = "C:/Users/kulka2/Downloads/SABS_1516_Primary.shp"
outFeatures = "U:/JMP/fifth_grade_shape/SABS_MA.shp"
tempLayer ="allbg"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","stAbbrev <> 'MA'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)

import arcpy
inFeatures = "X:/Kulka/Affordable housing/Education/SABS_1314_SchoolLevels/SABS_1314_Primary.shp"
outFeatures = "X:/Kulka/Affordable housing/Education/sabs13_MA.shp"
tempLayer ="ma"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","stAbbrev <> 'MA'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

#intersect road network with zoning atlas polylines
import arcpy
arcpy.analysis.Intersect([["X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/EOTROADS_ARC.shp",1],["X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries/zoning_atlas_polylines.shp",2]],"X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/roads_mapc.shp","ALL","15 meters","LINE")
print(arcpy.GetMessages())

#this is turned into roads_mapc_poly --> polygons that now need to be merged with original map

#combine these polygons (only able to construct polygons for the places that actually have fine grid networks, but check this later) with mapc type polygons and dissolve
import arcpy
arcpy.Union_analysis([["X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_poly.shp",1],["X:/Kulka/Affordable housing/MAPC/zoning_atlas_type.shp",2]],"X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union.shp","ALL","15 meters")
print(arcpy.GetMessages())

#dissolve by regulation type 
import arcpy
inputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union.shp"
outputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_dissolved.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#turn dissolved file into polylines and find eligible boundaries
#exclude the towns without attendance area info
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd.shp"
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
inputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd.shp"
outputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#turn this into polylines (can spatial merge this back to roads_mapc_union_sd to get additional fields apart from reg type)
#called polylines_feasible.shp
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#Match zo_usety and roads_mapc_union_sd_dissolved to municipalities
import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_muni.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_muni.shp", ["shape_1"])
print(arcpy.GetMessages())

import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_muni2.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_ONE","KEEP_ALL","","","","")
print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_muni2.shp", ["shape_1"])
print(arcpy.GetMessages())

import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved_muni.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved_muni.shp", ["shape_1"])
print(arcpy.GetMessages())



#3. Subtract municipal boundaries, rivers, roads, highways, school districts, school attendance areas
#convert to polylines
#municipalities
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/muni_polylines.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#school districts
import arcpy
in_features = "C:/Users/kulka2/Downloads/schooldistricts/SCHOOLDISTRICTS_POLY.shp"
out_feature_class = "C:/Users/kulka2/Downloads/sd_polylines.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#elementary school attendance areas
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/SABS_MA.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/attendance_line.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

import arcpy
in_features = "X:/Kulka/Affordable housing/Education/sabs13_MA.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/attendance13.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#updated attendance areas
import arcpy
in_features = "X:/Kulka/Affordable housing/Education/sabs_unique.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/attendance_line_unique.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#zoning boundaries 
import arcpy 
inputLayer = "X:/Kulka/Affordable housing/MAPC/zoning_atlas.shp"
outputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety.shp"
dissolveFields = ["zo_usety"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#convert into polylines
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_lines.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#a)subtract municipal boundaries
#intersect city boundaries with MAPC boundaries (now with only eligible towns)
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible.shp","X:/Kulka/Affordable housing/Boundary shapefiles/muni_polylines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_muni.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract city boundaries from mapc
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_muni.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#b)subtract rivers and streams
#intersect mapc-city-roads-school districts with rivers
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni.shp","X:/Kulka/Affordable housing/Boundary shapefiles/hydro100k/HYDRO100K_ARC.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_river.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract rivers
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_river.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#c)subtract major roads
#intersect mapc - city boundaries with roads
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river.shp","X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/EOTMAJROADS_ARC.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract intersection
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#d)subtract elementary school attendance areas (2015/2016)
#new updated boundaries
#intersect with attendance areas
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads.shp","X:/Kulka/Affordable housing/Boundary shapefiles/attendance_line_unique.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract school boundaries
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#intersect with attendance areas
#import arcpy
#in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads.shp","X:/Kulka/Affordable housing/Boundary shapefiles/attendance_line.shp"]
#out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance.shp"
#join_attributes = "ONLY_FID"
#cluster_tolerance = ""
#cluster_tolerance = "10 Meters"
#output_type = "LINE"
#arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
#print(arcpy.GetMessages())


#e)subtract school districts (this probably won't do very much additionally)
#intersect with school districts
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance.shp","X:/Kulka/Affordable housing/Education/sd_polylines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance_sd.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract roads mapc - city boundaries
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance_sd.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())

#f) subtract zoning boundaries (commercial/non commercial etc)
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd.shp","X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_lines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance_sd_zo.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "10 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract roads mapc - city boundaries
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_roads_river_attendance_sd_zo.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo.shp"
join_attributes = "ALL"
cluster_tolerance = "10 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#don't do this in the first stage 
#g) subtract school attendance boundaries for 2013
#Sabins 2013/14 boundaries
#import arcpy
#in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo.shp","X:/Kulka/Affordable housing/Boundary shapefiles/attendance13.shp"]
#out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_sabs13.shp"
#join_attributes = "ONLY_FID"
#cluster_tolerance = ""
#cluster_tolerance = "10 Meters"
#output_type = "LINE"
#arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
#print(arcpy.GetMessages())

#import arcpy
#in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo.shp"
#update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_sabs13.shp"
#out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance2_minus_sd_minus_zo.shp"
#join_attributes = "ALL"
#cluster_tolerance = "10 Meters"
#arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
#print(arcpy.GetMessages())


#count length of lines in different layers as we subtract boundaries
import arcpy 
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","") 
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","") 
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo.shp"
arcpy.AddGeometryAttributes_management(inFeatures,"LENGTH","MILES_US","","")
print(arcpy.GetMessages())





#clean up file and eliminate -1 boundaries
#eliminate -1 boundaries
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_minus_muni_minus_river_minus_roads_minus_attendance_minus_sd_minus_zo.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries.shp"
tempLayer ="temp6"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","LEFT_FID = -1 OR RIGHT_FID = -1")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

#delete unwanted fields   --> NEXT TIME KEEP FID_polyli
import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries.shp", ["FID_mapc_m", "FID_mapc_1", "FID_mapc_2", "FID_mapc_3", "FID_mapc_4", "FID_mapc_5", "FID_mapc_6", "FID_mapc_7", "FID_mapc_8", "FID_mapc_9", "FID_map_10", "FID_map_11", "FID_polyli", "FID_inters", "FID_inte_1", "FID_inte_2", "FID_inte_3", "FID_inte_4", "FID_inte_5", "FID_inte_6", "FID_poly_1", "FID_muni_p", "FID_HYDRO1", "FID_EOTMAJ", "FID_attend", "FID_sd_pol", "FID_zo_use", "FID_atte_1"])
print(arcpy.GetMessages())

#match these admissable boundaries spatially  with school districts, school attendance areas, zone types and municipalities to get their characteristics
#zoning type
import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/adm1.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

#municipality
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/adm1.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/adm2.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

import arcpy 
arcpy.DeleteField_management("X:/Kulka/Affordable housing/Boundary shapefiles/adm2.shp", ["objectid", "shape_1"])
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
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/adm2.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/adm3.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
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




###########################################################################
#Boundaries where regulation stays the same and municipality changes
#find convex hull of mapc polygon
# import system modules 
#dissolve by regulation type 
import arcpy
inputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved.shp"
outputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved_hull.shp"
arcpy.Dissolve_management(inputLayer,outputLayer,"","","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#turn hull into lines
#turn this into polylines (can spatial merge this back to roads_mapc_union_sd to get additional fields apart from reg type)
#called polylines_feasible.shp
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/roads_mapc_union_sd_dissolved.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible.shp"
# neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#keep only mapc towns with school info 
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni.shp"
tempLayer ="temp6"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","municipal <> 'Bellingham' AND municipal <> 'Braintree' AND municipal <> 'Burlington' AND municipal <> 'Concord' AND municipal <> 'Danvers' AND municipal <> 'Hamilton' AND municipal <> 'Hingham' AND municipal<> 'Ipswich' AND municipal <> 'Lynnfield' AND municipal <> 'Medford' AND municipal <> 'Melrose' AND municipal <> 'Natick' AND municipal <> 'Norwood' AND municipal <> 'Peabody' AND municipal <> 'Quincy' AND municipal <> 'Reading' AND municipal <> 'Saugus' AND municipal <> 'Stow' AND municipal <> 'Watertown' AND municipal <> 'Wenham' AND municipal <> 'Wilmington' AND municipal <> 'Winchester' AND municipal <> 'Woburn' AND municipal <> 'Acton' AND municipal <> 'Arlington' AND municipal <> 'Ashland' AND municipal <> 'Bedford' AND municipal <> 'Belmont' AND municipal <> 'Beverly' AND municipal <> 'Bolton' AND municipal <> 'Boston' AND municipal <> 'Boxborough' AND municipal <> 'Brookline' AND municipal <> 'Cambridge' AND municipal <> 'Canton' AND municipal <> 'Carlisle' AND municipal <> 'Chelsea' AND municipal <> 'Cohasset' AND municipal <> 'Dedham' AND municipal <> 'Dover' AND municipal <> 'Duxbury' AND municipal <> 'Essex' AND municipal <> 'Everett' AND municipal <> 'Foxborough' AND municipal <> 'Framingham' AND municipal <> 'Franklin' AND municipal <> 'Gloucester' AND municipal <> 'Hanover' AND municipal <> 'Holbrook' AND municipal <> 'Holliston' AND municipal <> 'Hopkinton' AND municipal <> 'Hudson' AND municipal <> 'Hull' AND municipal <> 'Lexington' AND municipal <> 'Lincoln' AND municipal <> 'Littleton' AND municipal <> 'Lynn' AND municipal <> 'Malden' AND municipal <> 'Manchester' AND municipal <> 'Marblehead' AND municipal <> 'Marlborough' AND municipal <> 'Marshfield' AND municipal <> 'Maynard' AND municipal <> 'Medfield' AND municipal <> 'Medway' AND municipal <> 'Middleton' AND municipal <> 'Milford' AND municipal <> 'Millis' AND municipal <> 'Milton' AND municipal <> 'Nahant' AND municipal <> 'Needham' AND municipal <> 'Newton' AND municipal <> 'Norfolk' AND municipal <> 'North Reading' AND municipal <> 'Norwell' AND municipal <> 'Pembroke' AND municipal <> 'Randolph' AND municipal <> 'Revere' AND municipal <> 'Rockland' AND municipal <> 'Rockport' AND municipal <> 'Salem' AND municipal <> 'Scituate' AND municipal <> 'Sharon' AND municipal <> 'Sherborn' AND municipal <> 'Somerville' AND municipal <> 'Southborough' AND municipal <> 'Stoneham' AND municipal <> 'Stoughton' AND municipal <> 'Sudbury' AND municipal <> 'Swampscott' AND municipal <> 'Topsfield' AND municipal <> 'Wakefield' AND municipal <> 'Walpole' AND municipal <> 'Waltham' AND municipal <> 'Wayland' AND municipal <> 'Wellesley' AND municipal <> 'Weston' AND municipal <> 'Westwood' AND municipal <> 'Weymouth' AND municipal <> 'Winthrop' AND municipal <> 'Wrentham'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

#arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","municipal <> 'Acton' AND municipal <> 'Arlington' AND municipal <> 'Ashland' AND municipal <> 'Bedford' AND municipal <> 'Belmont' AND municipal <> 'Beverly' AND municipal <> 'Bolton' AND municipal <> 'Boston' AND municipal <> 'Boxborough' AND municipal <> 'Brookline' AND municipal <> 'Cambridge' AND municipal <> 'Canton' AND municipal <> 'Carlisle' AND municipal <> 'Chelsea' AND municipal <> 'Cohasset' AND municipal <> 'Dedham' AND municipal <> 'Dover' AND municipal <> 'Duxbury' AND municipal <> 'Essex' AND municipal <> 'Everett' AND municipal <> 'Foxborough' AND municipal <> 'Framingham' AND municipal <> 'Franklin' AND municipal <> 'Gloucester' AND municipal <> 'Hanover' AND municipal <> 'Holbrook' AND municipal <> 'Holliston' AND municipal <> 'Hopkinton' AND municipal <> 'Hudson' AND municipal <> 'Hull' AND municipal <> 'Lexington' AND municipal <> 'Lincoln' AND municipal <> 'Littleton' AND municipal <> 'Lynn' AND municipal <> 'Malden' AND municipal <> 'Manchester' AND municipal <> 'Marblehead' AND municipal <> 'Marlborough' AND municipal <> 'Marshfield' AND municipal <> 'Maynard' AND municipal <> 'Medfield' AND municipal <> 'Medway' AND municipal <> 'Middleton' AND municipal <> 'Milford' AND municipal <> 'Millis' AND municipal <> 'Milton' AND municipal <> 'Nahant' AND municipal <> 'Needham' AND municipal <> 'Newton' AND municipal <> 'Norfolk' AND municipal <> 'North Reading' AND municipal <> 'Norwell' AND municipal <> 'Pembroke' AND municipal <> 'Randolph' AND municipal <> 'Revere' AND municipal <> 'Rockland' AND municipal <> 'Rockport' AND municipal <> 'Salem' AND municipal <> 'Scituate' AND municipal <> 'Sharon' AND municipal <> 'Sherborn' AND municipal <> 'Somerville' AND municipal <> 'Southborough' AND municipal <> 'Stoneham' AND municipal <> 'Stoughton' AND municipal <> 'Sudbury' AND municipal <> 'Swampscott' AND municipal <> 'Topsfield' AND municipal <> 'Wakefield' AND municipal <> 'Walpole' AND municipal <> 'Waltham' AND municipal <> 'Wayland' AND municipal <> 'Wellesley' AND municipal <> 'Weston' AND municipal <> 'Westwood' AND municipal <> 'Weymouth' AND municipal <> 'Winthrop' AND municipal <> 'Wrentham'")

#turn into polylines --> left and right fid can be matched to fid in "X:/Kulka/Affordable housing/Boundary shapefiles/municipalities/municipalities.shp"
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni_lines.shp"
neighbor_option = "IDENTIFY_NEIGHBORS"
arcpy.PolygonToLine_management(in_features,out_feature_class,neighbor_option)
print(arcpy.GetMessages())

#All cities polylines
#called polylines_feasible_all.shp
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/mapc_dissolved.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible_alltowns.shp"
#neighbor_option = "IDENTIFY_NEIGHBORS" #don't need this here because we don't care about neighbors
arcpy.PolygonToLine_management(in_features,out_feature_class)
print(arcpy.GetMessages())

#intersect city boundaries with MAPC boundaries (with all towns)
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/polylines_feasible_alltowns.shp","X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni_lines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_boundaries_mapc_muni_all.shp"
join_attributes = "ALL"
#cluster_tolerance = ""
cluster_tolerance = "1 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())
#keep only intersections, where both city and density change, don't keep places where zoning is continuous 


#subtract mapc from city boundaries
#import arcpy
#in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni_lines.shp"
#update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_boundaries_mapc_muni_all.shp"
#out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/muni_minus_mapc.shp"
#join_attributes = "ALL"
#cluster_tolerance = "1 Meters"
#arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
#print(arcpy.GetMessages())

#intersect with highways 
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_boundaries_mapc_muni_all.shp","X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/EOTMAJROADS_ARC.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_muni_roads.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "1 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract highway intersections
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_boundaries_mapc_muni_all.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_muni_roads.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/muni_minus_mapc_minus_roads.shp"
join_attributes = "ALL"
cluster_tolerance = "1 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#intersect with rivers
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/muni_minus_mapc_minus_roads.shp","X:/Kulka/Affordable housing/Boundary shapefiles/hydro100k/HYDRO100K_ARC.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_muni_rivers.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "1 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract rivers
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/muni_minus_mapc_minus_roads.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/intersect_muni_rivers.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/muni_minus_mapc_minus_roads_minus_rivers.shp"
join_attributes = "ALL"
cluster_tolerance = "1 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#eliminate -1 boundaries
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/muni_minus_mapc_minus_roads_minus_rivers.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/TownBoundaries/boundaries_for_town_analysis_new.shp"
tempLayer ="temp"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","LEFT_FID = -1 OR RIGHT_FID = -1")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())




#not needed because not done in the literature 
#intersect with zone use type 
import arcpy
in_features = ["X:/Kulka/Affordable housing/Boundary shapefiles/muni_minus_mapc_minus_roads_minus_rivers.shp","X:/Kulka/Affordable housing/Boundary shapefiles/zo_usety_lines.shp"]
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_muni_zouse.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "1 Meters"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract zone types
import arcpy
in_features = "X:/Kulka/Affordable housing/Boundary shapefiles/muni_minus_mapc_minus_roads_minus_rivers.shp"
update_features = "X:/Kulka/Affordable housing/Boundary shapefiles/intersect_muni_zouse.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/muni_minus_mapc_minus_roads_minus_rivers_minus_zouse.shp"
join_attributes = "ALL"
cluster_tolerance = "1 Meters"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#clean up file and eliminate -1 boundaries
#eliminate -1 boundaries
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/muni_minus_mapc_minus_roads_minus_rivers_minus_zouse.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/boundaries_for_town_analysis.shp"
tempLayer ="temp"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","LEFT_FID = -1 OR RIGHT_FID = -1")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())








############################################################################################################################################
#Prepare map of zoning boundaries


import arcpy
joinFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries/mapc_minus_muni_minus_roads_minus_sd_minus_rivers_minus_attendance.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries.shp"
out_feature_class = "X:/Kulka/Affordable housing/Boundary shapefiles/map_prep.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())


#############################################################################################################################################



#e)subtract elementary school attendance areas
#intersect mapc-city-roads with school districts
import arcpy
in_features = ["C:/Users/kulka2/Downloads/mapc_minus_muni_minus_roads_minus_sd_minus_rivers.shp","X:/Kulka/Affordable housing/Boundary shapefiles/attendance_line.shp"]
out_feature_class = "C:/Users/kulka2/Downloads/intersect_boundaries_mapc_roads_sd_river_attendance.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "1 Meter"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract roads mapc - city boundaries
import arcpy
in_features = "C:/Users/kulka2/Downloads/mapc_minus_muni_minus_roads_minus_sd_minus_rivers.shp"
update_features = "C:/Users/kulka2/Downloads/intersect_boundaries_mapc_roads_sd_river_attendance.shp"
out_feature_class = "C:/Users/kulka2/Downloads/mapc_minus_muni_minus_roads_minus_sd_minus_rivers_minus_attendance.shp"
join_attributes = "ALL"
cluster_tolerance = "1 Meter"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())


#dissolve by main land use featuers
import arcpy
inputLayer = "X:/Kulka/Affordable housing/MAPC/zoning_atlas_type.shp"
outputLayer = "C:/Users/kulka2/Downloads/dissolved.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","MULTI_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#first explode
import arcpy
arcpy.MultipartToSinglepart_management("X:/Kulka/Affordable housing/MAPC/zoning_atlas.shp","C:/Users/kulka2/Downloads/explode.shp")
print(arcpy.GetMessages())

import arcpy
inputLayer = "C:/Users/kulka2/Downloads/explode_type.shp"
outputLayer = "C:/Users/kulka2/Downloads/dissolved_new.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","MULTI_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

import arcpy
buildings = "C:/Users/kulka2/Downloads/explode_type.shp"
#roads = ""
output = "C:/Users/kulka2/Downloads/explode_type_agg.shp"
#output_table = "C:/data/county.gdb/BldgAggBarrierPartition_Tbl"
arcpy.AggregatePolygons_cartography(buildings, output, "20 Meters", "", "", "ORTHOGONAL","","")
print(arcpy.GetMessages())

import arcpy
arcpy.EliminatePolygonPart_management("C:/Users/kulka2/Downloads/dissolved.shp", "C:/Users/kulka2/Downloads/eliminate.shp", "PERCENT","",5,"ANY")
print(arcpy.GetMessages())

import arcpy
arcpy.EliminatePolygonPart_management("C:/Users/kulka2/Downloads/dissolved.shp", "C:/Users/kulka2/Downloads/eliminate.shp", "PERCENT","",5,"")
print(arcpy.GetMessages())

import arcpy
arcpy.CopyFeatures_management("C:/Users/kulka2/Downloads/explode_type.shp", "C:/Users/kulka2/Downloads/explode_type_copy.shp")
arcpy.Integrate_management("C:/Users/kulka2/Downloads/explode_type_copy.shp")


import arcpy
from arcpy import env
# Set local variables
inCover = "X:/Kulka/Affordable housing/MAPC/zoning_atlas_type.shp"
outCover = "C:/Users/kulka2/Downloads/dissolved_lines.shp"
dissolveItem = "reg_type"
featureType = "LINE"
# Execute Dissolve
arcpy.Dissolve_arc(inCover, outCover, dissolveItem, featureType)

import arcpy
inputLayer = "C:/Users/kulka2/Downloads/Base Districts/zoning_atlas.shp"
outputLayer = "C:/Users/kulka2/Downloads/dissolved.shp"
dissolveFields = ["mxht_eff","dupac_eff","mulfam2"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","SINGLE_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())



############################################
#suburb type heterogeneity##################
############################################

import arcpy
in_table = "X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni.shp"
arcpy.management.AddField(in_table, "county_fip", "SHORT")
print(arcpy.GetMessages())

import arcpy
input = "X:/Kulka/Affordable housing/Boundary shapefiles/only_mapc_muni.shp"
fields_in_cursor = ["municipal","county_fip"]  

with arcpy.da.UpdateCursor(input,fields_in_cursor) as cursor:
	for row in cursor:
		if row[0] == "Arlington":
			row[1] = 1
		if row[0] == "Belmont":
			row[1] = 1
		if row[0] == "Boston":
			row[1] = 1
		if row[0] == "Brookline":
			row[1] = 1
		if row[0] == "Cambridge":
			row[1] = 1
		if row[0] == "Chelsea":
			row[1] = 1
		if row[0] == "Everett":
			row[1] = 1
		if row[0] == "Malden":
			row[1] = 1
		if row[0] == "Medford":
			row[1] = 1
		if row[0] == "Melrose":
			row[1] = 1
		if row[0] == "Newton":
			row[1] = 1
		if row[0] == "Revere":
			row[1] = 1
		if row[0] == "Somerville":
			row[1] = 1
		if row[0] == "Waltham":
			row[1] = 1
		if row[0] == "Watertown":
			row[1] = 1
		if row[0] == "Winthrop":
			row[1] = 1
		if row[0] == "Beverly":
			row[1] = 2	
		if row[0] == "Framingham":
			row[1] = 2
		if row[0] == "Gloucester":
			row[1] = 2
		if row[0] == "Lynn":
			row[1] = 2
		if row[0] == "Marlborough":
			row[1] = 2
		if row[0] == "Milford":
			row[1] = 2
		if row[0] == "Salem":
			row[1] = 2
		if row[0] == "Woburn":
			row[1] = 2
		if row[0] == "Acton":
			row[1] = 3			
		if row[0] == "Bedford":
			row[1] = 3
		if row[0] == "Canton":
			row[1] = 3
		if row[0] == "Concord":
			row[1] = 3
		if row[0] == "Dedham":
			row[1] = 3
		if row[0] == "Duxbury":
			row[1] = 3
		if row[0] == "Hingham":
			row[1] = 3
		if row[0] == "Holbrook":
			row[1] = 3
		if row[0] == "Hull":
			row[1] = 3
		if row[0] == "Lexington":
			row[1] = 3
		if row[0] == "Lincoln":
			row[1] = 3
		if row[0] == "Marblehead":
			row[1] = 3
		if row[0] == "Marshfield":
			row[1] = 3
		if row[0] == "Maynard":
			row[1] = 3
		if row[0] == "Medfield":
			row[1] = 3
		if row[0] == "Milton":
			row[1] = 3
		if row[0] == "Nahant":
			row[1] = 3
		if row[0] == "Natick":
			row[1] = 3
		if row[0] == "Needham":
			row[1] = 3
		if row[0] == "North Reading":
			row[1] = 3
		if row[0] == "Pembroke":
			row[1] = 3
		if row[0] == "Randolph":
			row[1] = 3
		if row[0] == "Scituate":
			row[1] = 3
		if row[0] == "Sharon":
			row[1] = 3
		if row[0] == "Southborough":
			row[1] = 3
		if row[0] == "Stoneham":
			row[1] = 3
		if row[0] == "Stoughton":
			row[1] = 3
		if row[0] == "Sudbury":
			row[1] = 3
		if row[0] == "Swampscott":
			row[1] = 3
		if row[0] == "Wakefield":
			row[1] = 3
		if row[0] == "Wayland":
			row[1] = 3
		if row[0] == "Wellesley":
			row[1] = 3
		if row[0] == "Weston":
			row[1] = 3
		if row[0] == "Westwood":
			row[1] = 3			
		if row[0] == "Weymouth":
			row[1] = 3
		if row[0] == "Bolton":
			row[1] = 4
		if row[0] == "Boxborough":
			row[1] = 4
		if row[0] == "Carlisle":
			row[1] = 4
		if row[0] == "Cohasset":
			row[1] = 4
		if row[0] == "Dover":
			row[1] = 4
		if row[0] == "Essex":
			row[1] = 4
		if row[0] == "Foxborough":
			row[1] = 4
		if row[0] == "Franklin":
			row[1] = 4
		if row[0] == "Hanover":
			row[1] = 4
		if row[0] == "Holliston":
			row[1] = 4
		if row[0] == "Hopkinton":
			row[1] = 4
		if row[0] == "Hudson":
			row[1] = 4
		if row[0] == "Littleton":
			row[1] = 4
		if row[0] == "Manchester":
			row[1] = 4
		if row[0] == "Medway":
			row[1] = 4
		if row[0] == "Middleton":
			row[1] = 4
		if row[0] == "Millis":
			row[1] = 4
		if row[0] == "Norfolk":
			row[1] = 4
		if row[0] == "Rockland":
			row[1] = 4
		if row[0] == "Rockport":
			row[1] = 4
		if row[0] == "Sherborn":
			row[1] = 4
		if row[0] == "Stow":
			row[1] = 4
		if row[0] == "Topsfield":
			row[1] = 4
		if row[0] == "Walpole":
			row[1] = 4
		if row[0] == "Wrentham":
			row[1] = 4
		cursor.updateRow(row)
print(arcpy.GetMessages())		

#export shapefile as only_mapc_muni_suburbs.shp


######################
#Train Station Maps###
######################


#keep only stations we use in counterfactual
#MBTA 
import arcpy
inFeatures = "X:/Kulka/Affordable housing/MBTA/MBTA_NODE.shp"
outFeatures = "X:/Kulka/Affordable housing/MBTA/only_mbta.shp"
tempLayer ="temp1"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","STATION <> 'Shawmut' AND STATION <> 'Ashmont' AND STATION <> 'Beaconsfield' AND STATION <> 'Fairbanks Street' AND STATION <> 'Newton Highlands' AND STATION <> 'Eliot' AND STATION <> 'Capen Street'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

#TRAINS
import arcpy
inFeatures = "X:/Kulka/Affordable housing/MBTA/TRAINS_NODE.shp"
outFeatures = "X:/Kulka/Affordable housing/MBTA/only_trains.shp"
tempLayer ="temp2"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","STATION <> 'CANTON CENTER' AND STATION <> 'PORTER SQUARE' AND STATION <> 'MALDEN CENTER' AND STATION <> 'WALTHAM' AND STATION <> 'SOUTH ACTON' AND STATION <> 'NEEDHAM HEIGHTS' AND STATION <> 'SWAMPSCOTT' AND STATION <> 'WELLESLEY HILLS' AND STATION <> 'CANTON JUNCTION' AND STATION <> 'LINCOLN' AND STATION <> 'SHARON' AND STATION <> 'WELLESLEY SQUARE' AND STATION <> 'EAST WEYMOUTH' AND STATION <> 'WEYMOUTH LANDING/EAST BRAINTREE' AND STATION <> 'MANCHESTER' AND STATION <> 'NORFOLK' AND STATION <> 'FRANKLIN/DEAN COLLEGE'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())


#MERGE 
import arcpy
arcpy.Merge_management(["X:/Kulka/Affordable housing/MBTA/only_mbta.shp","X:/Kulka/Affordable housing/MBTA/only_trains.shp"], "X:/Kulka/Affordable housing/MBTA/counterfactual_stops.shp")
print(arcpy.GetMessages())

#keep only one of each station 
import arcpy
inFeatures = "X:/Kulka/Affordable housing/MBTA/counterfactual_stops.shp"
outFeatures = "X:/Kulka/Affordable housing/MBTA/counterfactual_stops_unique.shp"
tempLayer ="temp5"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","(STATION = 'SWAMPSCOTT' AND MAP_STA = 'Y') OR (STATION = 'WELLESLEY HILLS' AND MAP_STA = 'Y') OR (STATION = 'WELLESLEY SQUARE' AND MAP_STA = 'Y') OR (STATION = 'MANCHESTER' AND MAP_STA = 'Y') OR (STATION = 'CANTON JUNCTION' AND LINE_BRNCH = 'STOUGHTON BRANCH') OR (STATION = 'CANTON JUNCTION' AND MAP_STA = 'Y') OR (STATION = 'LINCOLN' AND MAP_STA = 'Y') OR (STATION = 'PORTER SQUARE' AND MAP_STA = 'Y') OR (STATION = 'SHARON' AND MAP_STA = 'Y')")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())



#########################################################################################################
#OLD CODE
#keep only sommerville as a trial
import arcpy
inFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/EOTROADS_ARC.shp"
outFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/somerville.shp"
tempLayer ="allbg"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","MGIS_TOWN <> 'SOMERVILLE'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

import arcpy
arcpy.analysis.Intersect([["X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/somerville.shp",1],["X:/Kulka/Affordable housing/Boundary shapefiles/admissable_boundaries/zoning_atlas_polylines.shp",2]],"X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/somerville_match.shp","ALL","15 meters","LINE")
print(arcpy.GetMessages())


######
import arcpy
arcpy.Union_analysis([["X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/poly_try.shp",1],["X:/Kulka/Affordable housing/MAPC/zoning_atlas_type.shp",2]],"X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/somerville_union.shp","ALL","15 meters")
print(arcpy.GetMessages())

import arcpy
inputLayer = "X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/somerville_union.shp"
outputLayer = "C:/Users/kulka2/Downloads/somerville_union_dissolve.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","MULTI_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())
####

#turn this into polygon

#join updated polygons with zoning atlas
import arcpy
joinFeatures = "X:/Kulka/Affordable housing/MAPC/zoning_atlas_type.shp"
targetFeatures = "X:/Kulka/Affordable housing/Boundary shapefiles/MassDOT_Roads_SHP/poly_try.shp"
out_feature_class = "C:/Users/kulka2/Downloads/somerville_ply.shp"
arcpy.SpatialJoin_analysis(targetFeatures,joinFeatures, out_feature_class,"JOIN_ONE_TO_MANY","KEEP_ALL","","","","")
print(arcpy.GetMessages())

#dissolve
import arcpy
inputLayer = "C:/Users/kulka2/Downloads/somerville_ply.shp"
outputLayer = "C:/Users/kulka2/Downloads/somerville_dissolve.shp"
dissolveFields = ["reg_type"]
arcpy.Dissolve_management(inputLayer,outputLayer,dissolveFields,"","MULTI_PART","DISSOLVE_LINES")
print(arcpy.GetMessages())

#intersect city boundaries with MAPC boundaries
import arcpy
in_features = ["C:/Users/kulka2/Downloads/zoning_atlas_polylines.shp","C:/Users/kulka2/Downloads/muni_polylines.shp"]
out_feature_class = "C:/Users/kulka2/Downloads/intersect_boundaries_mapc_muni.shp"
join_attributes = "ONLY_FID"
#cluster_tolerance = ""
cluster_tolerance = "1 Meter"
output_type = "LINE"
arcpy.Intersect_analysis(in_features,out_feature_class,join_attributes,cluster_tolerance,output_type)
print(arcpy.GetMessages())

#subtract city boundaries from mapc
import arcpy
in_features = "C:/Users/kulka2/Downloads/zoning_atlas_polylines.shp"
update_features = "C:/Users/kulka2/Downloads/intersect_boundaries_mapc_muni.shp"
out_feature_class = "C:/Users/kulka2/Downloads/mapc_minus_muni.shp"
join_attributes = "ALL"
cluster_tolerance = "1 Meter"
arcpy.SymDiff_analysis(in_features,update_features,out_feature_class,join_attributes,cluster_tolerance)
print(arcpy.GetMessages())



############################
#Relevant county boundaries#
############################
import arcpy
inFeatures = "X:/Kulka/Affordable housing/County shapefiles/COUNTIES_POLY.shp"
outFeatures = "X:/Kulka/Affordable housing/County shapefiles/mapc_counties.shp"
tempLayer ="temp1"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","COUNTY = 'BARNSTABLE' OR COUNTY = 'BERKSHIRE' OR COUNTY = 'BRISTOL' OR COUNTY = 'DUKES' OR COUNTY = 'FRANKLIN' OR COUNTY = 'HAMPDEN' OR COUNTY = 'HAMPSHIRE' OR COUNTY = 'NANTUCKET'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())


import arcpy
inFeatures = "X:/Kulka/Affordable housing/County shapefiles/COUNTIES_POLY.shp"
outFeatures = "X:/Kulka/Affordable housing/County shapefiles/mapc_counties_no_worcester.shp"
tempLayer ="temp1"
#make copy of features
arcpy.CopyFeatures_management(inFeatures, outFeatures)
#turn feature into layer
arcpy.MakeFeatureLayer_management(outFeatures,tempLayer)
#select which features to delete
arcpy.SelectLayerByAttribute_management(tempLayer,"NEW_SELECTION","COUNTY = 'WORCESTER' OR COUNTY = 'BARNSTABLE' OR COUNTY = 'BERKSHIRE' OR COUNTY = 'BRISTOL' OR COUNTY = 'DUKES' OR COUNTY = 'FRANKLIN' OR COUNTY = 'HAMPDEN' OR COUNTY = 'HAMPSHIRE' OR COUNTY = 'NANTUCKET'")
if int(arcpy.GetCount_management(tempLayer).getOutput(0))>0: arcpy.DeleteFeatures_management(tempLayer)
print(arcpy.GetMessages())

