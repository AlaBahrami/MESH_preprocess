# -*- coding: utf-8 -*-
"""
NAME
    climate_station_display 
PURPOSE
    The purpose of this script is to ECCC climate station locations and filter stations
    based on province and time window. 
    
Input 
    prmname                       The input parameter file includes metric results   

Output 
                                  ouput shape file                                
PROGRAMMER(S)
    Ala Bahrami
    
REVISION HISTORY
    20211105 -- Initial version created and posted online     
    20211105 -- clipping climate stations based fall inside the Fraser basin
    
REFERENCES

"""
#%% importing modules 
import pandas as pd
import numpy as np
import geopandas as gpd
import matplotlib.pyplot as plt

#%% Reading the input file
input_file = 'input/Station Inventory EN.csv'
input_shape = 'input/Fraser_Basin.shp'
station = pd.read_csv(input_file)

output = 'output/Fraser_climate_Station.shp'

#%% finding station based on the desired criteria 
r = np.where((station['Province'] == 'BRITISH COLUMBIA') & (station['First Year'] <=2000) & 
             (station['Last Year'] >=2017))

#%% create dataframe 
df = pd.DataFrame({'ClimateID':station['Climate ID'][r[0]],
     'Lon':station['Lon'][r[0]], 'Lat':station['Lat'][r[0]],
     'First Year':station['First Year'][r[0]], 'Last Year':station['Last Year'][r[0]]})

gdf = gpd.GeoDataFrame(
    df, geometry=gpd.points_from_xy(df.Lon, df.Lat))

# set CRS to NAD83
gdf = gdf.set_crs('EPSG:4269')

print(gdf.head())

#%% clip points to Fraser Basin bounday 
Fraser = gpd.read_file(input_shape)
gdf_clip = gpd.clip(gdf, Fraser)

#%% display Fraser Basin and climate station together 
ax = Fraser.plot(color='white', edgecolor='black')

gdf_clip.plot(ax=ax, color='red', label = 'Climate Stations')

# set lables 
ax.set_title('Fraser Basin', fontsize=18, fontname='Times New Roman', fontweight='bold')
ax.set_xlabel("longitude", fontsize=14, fontname='Times New Roman', fontweight='bold')
ax.set_ylabel("latitude", fontsize=14, fontname='Times New Roman', fontweight='bold')

# set axis 
plt.setp(ax.get_xticklabels(), ha="right",
             rotation_mode="anchor", fontsize=12, fontname='Times New Roman', 
             fontweight='bold')
plt.setp(ax.get_yticklabels(), fontsize=12, fontname='Times New Roman', 
             fontweight='bold')
ax.grid(True)
ax.legend()

plt.show()

#%% save geodatabase 
gdf_clip.to_file(output)
