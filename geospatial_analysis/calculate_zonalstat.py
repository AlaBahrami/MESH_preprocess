# -*- coding: utf-8 -*-
"""
NAME
    calculate zonal stats 
PURPOSE
    The purpose of this script is to calculate zonal status which finally can be 
    used for the purpose of ditributed parameters
    
Input 
    prmname                       The input file   

Output 
                                  ouput                                 
PROGRAMMER(S)
    Ala Bahrami
    
REVISION HISTORY
    20211105 -- Initial version created and posted online     
    
REFERENCES

"""
#%% import modules 
import rasterio
from rasterio.plot import show
from rasterstats import zonal_stats
import geopandas as gpd
import pandas as pd
import numpy as np
import xarray as xs
from   datetime import date

#%% I/O files 
input_raster  = 'input/domain_Sand1.tif'
input_shape   = 'input/bow_distributed.shp'
input_ddb     = 'input/BowBanff_MESH_drainage_database.nc'
out_parameter = 'output/MESH_parameters.nc'

#%% reading the inputs 
data = rasterio.open(input_raster)
BowBanff = gpd.read_file(input_shape)
drainage_db = xs.open_dataset(input_ddb)

# %% extract indices of lc based on the drainage database
n = len(drainage_db.hruid)
ind = []
hruid =  drainage_db.variables['hruid']

for i in range(n):
    fid = np.where(np.int32(BowBanff['COMID'].values) == hruid[i].values)[0]
    ind = np.append(ind, fid)

ind = np.int32(ind)    

#%% Read the raster values
sand = data.read(1)

# Get the affine
affine = data.transform

#%% plotting subbasin over data 
ax = BowBanff.plot(facecolor='None', edgecolor='red', linewidth=2) 

# Visualize the soil texture
show((data, 1), ax=ax)

#%% calculate zonal status 
zs = zonal_stats(BowBanff, sand, affine=affine, stats='mean')
zs  = pd.DataFrame(zs)

# reorder the zonal stats from Rank1 to RankN
zs_reorder = zs.values[ind] 

# %% convert the distributed parameters as a dataset and save it as netcdf
lon = drainage_db['lon'].values
lat = drainage_db['lat'].values
tt = drainage_db['time'].values

dist_param =  xs.Dataset(
    {
        "Sand1": (["subbasin", "gru"], zs_reorder),
    },
    coords={
        "lon": (["subbasin"], lon),
        "lat": (["subbasin"], lat),
        "time": tt,
    },
)

# meta data attributes 
dist_param.attrs['Conventions'] = 'CF-1.6'
dist_param.attrs['License']     = 'The data were written by Ala Bahrami'
dist_param.attrs['history']     = 'Created on November, 2021'
dist_param.attrs['featureType'] = 'point'          

# editing lat attribute
dist_param['lat'].attrs['standard_name'] = 'latitude'
dist_param['lat'].attrs['units'] = 'degrees_north'
dist_param['lat'].attrs['axis'] = 'Y'
 
# editing lon attribute
dist_param['lon'].attrs['standard_name'] = 'longitude'
dist_param['lon'].attrs['units'] = 'degrees_east'
dist_param['lon'].attrs['axis'] = 'X'

# editing time attribute
# dist_param['time'].attrs.update(standard_name = 'time', 
#                                  units = ('days since %s 00:00:00' % date.today().strftime('%Y-%m-%d')), 
#                                  axis = 'T')

# coordinate system
dist_param['crs'] = drainage_db['crs'].copy()

dist_param.to_netcdf(out_parameter)
