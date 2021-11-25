# -*- coding: utf-8 -*-
"""
NAME
    clip_raster
PURPOSE
    The purpose of this script is to clip raster file based on polygon 
    
Input 
                              

Output 
                                   
PROGRAMMER(s): Ala Bahrami

REVISION HISTORY
    20211106 -- Initial version created and posted online     
       
REFERENCES
        https://automating-gis-processes.github.io/site/notebooks/Raster/clipping-raster.html

todo works:  

"""
#%% import modules
import rasterio
from rasterio.plot import show
from rasterio.plot import show_hist
from rasterio.mask import mask
from shapely.geometry import box
import geopandas as gpd
#from fiona.crs import from_epsg
#import pycrs
import os
#matplotlib inline
#%% reading input raster and displaying it  
input_raster = 'input/NALCMS_LC_2010_30M_clip_12class.tif'

data = rasterio.open(input_raster)
# Visualize the NIR band
show((data, 1), cmap='terrain')

#%% define the boundary 
minx, miny = -126, -124
maxx, maxy = 52, 53
bbox = box(minx, miny, maxx, maxy)

#%% create geodataframe 
gdf = gpd.GeoDataFrame({'geometry':bbox}, index=[0])
gdf = gdf.set_crs('EPSG:4269')

gdf.crs

#%% get the coordinates of the geometry
def getFeatures(gdf):
    """Function to parse features from GeoDataFrame in such a manner that rasterio wants them"""
    import json
    return [json.loads(gdf.to_json())['features'][0]['geometry']]

#%% 
coords = getFeatures(gdf)
print(coords)

#%% clip the raster 
# clip the raster with polygon 
clip_lc,out_transform = mask(dataset=data, shapes = coords, crop = True)

