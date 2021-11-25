# -*- coding: utf-8 -*-
"""
NAME
    calculate zonal histogram 
PURPOSE
    The purpose of this script is to calculate zonal histogram of land cover types 
    for Fraser River subbasins and save the results as .csv and  figures. 
    
Input 
    lc                       Land cover types 
    basin                    A concated subbasins

Output 
    zh                       Zonal histogram stats
    zh_stat                  Zonal histogram percentages
                             pie charts 
    
PROGRAMMER(S)
    Ala Bahrami
    
REVISION HISTORY
    20211124 -- Initial version created and posted online     
    
See Also     
    concat_shapefile.py    
    
REFERENCES

todo: 
    add a pie chart for this 

"""
#%% import modules 
import geopandas as gpd
import pandas as pd
from rasterstats import zonal_stats
import matplotlib.pyplot as plt
#import rasterio
#from rasterio.plot import show

#%% input files 
input_lc       = 'input/NALCMS_LC_2010_30M_clip_12class.tif'
input_shape    = 'input/fraser_shape/Fraser_calib.shp'

#%% reading input 
fraser = gpd.read_file(input_shape) 

#%% calculate zonal histogram 
cmap = {1.0: 'NL Forest', 2.0: 'BL Forest', 3.0: 'Mixed Forest', 4.0: 'Shrubland',
        5.0: 'Grassland', 6.0: 'Lichenmoss', 7.0: 'Wetland',8.0: 'Crop',
        9.0: 'Barren', 10.0: 'Urban', 11.0: 'Water',12.0: 'SnowIce'}
zh = zonal_stats(fraser, input_lc, categorical=True, category_map=cmap)
zh = pd.DataFrame(zh)

#%% calculate the percentage and adding station ids
#zh.sum(axis=1) 
zh_stat = zh.apply(lambda x: round(x/x.sum()*100,2), axis=1)

zh_stat.insert(loc=0, column='Station',value=fraser['Station'])

#%% export the results 
zh_stat.to_csv('output/Fraser_zonalStat.csv')

#%% display as pie charts

outdir  = "output/"
labels = ['NL Forest', 'BL Forest', 'Mixed Forest', 'Shrubland',
         'Grassland','Lichenmoss', 'Wetland','Crop',
         'Barren', 'Urban', 'Water', 'SnowIce']

# only "explode" the 1nd slice (Needle Forest)
explode = (0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)  

for i in range(len(zh)): 
    fig, ax = plt.subplots()
    ax.pie(zh.iloc[i].values, explode=explode, labels=labels, autopct='%1.1f%%',
            shadow=True, startangle=90)
    
    # Equal aspect ratio ensures that pie is drawn as a circle.
    ax.axis('equal')  
    
    #  setting title 
    ax.set_title(zh_stat['Station'][i], fontsize=18, fontname='Times New Roman', fontweight='bold')    

    # saving figure 
    mng = plt.get_current_fig_manager()
    mng.full_screen_toggle()
    fs = outdir+"zonalstat-"+zh_stat['Station'][i]+".png"
    plt.savefig(fs, dpi=150) 

    plt.show()
    plt.close()

