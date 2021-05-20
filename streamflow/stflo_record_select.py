# -*- coding: utf-8 -*-
"""
NAME
    stflo_record_selection 
PURPOSE
    The purpose of this script is to extract streamflow station records based 
    on a desired time period of study (e.g., 1979 to 2017). The missing records 
    of stations are filled out. The indices and records of stations with less than
    15% of missing records are exported. 

Input 
     prmname                       The input station record directories   

Output 
     stflo                         Stations with filled records
     stflo_85                      Selected stations which their missing records
                                   are less than 15%      
     stat_85                       Indices of stations which their missing records
                                   are less than 15%  
                                    
PROGRAMMER(S)
    Ala Bahrami
REVISION HISTORY
    20210517 -- Initial version created and posted online
REFERENCES

"""
#%% importing module 
import pandas as pd
import numpy as np 

#%% setting I/O dirs 
prmname = 'prm/st_records.txt'

# output 
statfill    = 'output/stflo_FRB_calib.csv'
statfill85  = 'output/stflo_FRB_calib_85.csv'
index85     = 'output/stflo_FRB_calib_85_index.csv'

#%% time range (selection period)
time = pd.date_range(start='1/1/1979', end='31/12/2017', freq='D')
m = len(time)

# %% reading directory of streamflow records 
fid  = open(prmname,'r')    

Info = np.loadtxt(fid,
            dtype={'names': ('col1', 'col2'),
            'formats': ('U10', 'U200')})

fid.close()

#%% reading input streamflow records
n = len(Info)
sf = np.zeros((m,n))
ids = []

for i in range(n):
    data  = pd.read_csv(Info[i][1])
    rs = np.where(data['Date'].values == '1979/01/01')[0]
    rf = np.where(data['Date'].values == '2017/12/31')[0]    
    if ((rf-rs + 1) == m):
            ids = np.append(ids, data[' ID'].values[0])
            sf[:, i] = data.values[rs[0]: rf[0]+1, 3] 
    else: 
            print("Error: The Input %s have %d missing records" % (data[' ID'].values[0], m-(rf-rs)))

stflo = pd.DataFrame(time, columns = ['Time'])
stflo[ids] = sf

#%% finding missing values with FillValue

fid = stflo.isnull()
count_nan = len(stflo) - stflo.count()

# replacing nan values with -1 
stflo = stflo.fillna(value = -1) 

#%% finding missing values and fill them with FillValue 
statfull   =  count_nan[count_nan == 0]
stat_85    =  count_nan[count_nan <= 0.15*(m)]

# extract station indices with more 85% full records 
stflo_85   = stflo[stat_85.index] 

#%% write outputs 
stflo.to_csv(statfill, index = False, float_format='%.1f')
stflo_85.to_csv(statfill85, index = False, float_format='%.1f')
stat_85.to_csv(index85)
