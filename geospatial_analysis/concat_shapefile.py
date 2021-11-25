# -*- coding: utf-8 -*-
"""
NAME
    concat_shapefile  
PURPOSE
    The purpose of this script is to concat different shapefiles together that later
    can be used for other purposes, such as zonal stats
    
Input 
    prmname                       The input shapefiles  

Output 
                                  concated shapefile                                  
PROGRAMMER(S)
    Ala Bahrami
    
REVISION HISTORY
    20211124 -- Initial version created and posted online     
    
REFERENCES

"""
#%% import modules 
from pathlib import Path
import pandas as pd
import geopandas as gpd

#%% folder directory
folder = Path("C:/Users/alb129/OneDrive - University of Saskatchewan/programing/python/geospatial_analysis/input/fraser_shape/")
shapefiles = folder.glob("08*.shp")

#%% concat shapefiles and save it  
gdf = pd.concat([
    gpd.read_file(shp)
    for shp in shapefiles]).pipe(gpd.GeoDataFrame)

# set crs and export 
gdf = gdf.set_crs('EPSG:4269')
gdf.to_file(folder / 'Fraser_calib.shp')
