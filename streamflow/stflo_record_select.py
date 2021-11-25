# -*- coding: utf-8 -*-
"""
NAME
    stflo_record_selection 
PURPOSE
    The purpose of this script is to extract streamflow station records based 
    on a desired time period of study (e.g., 1951 to 2017). The missing records 
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
    20210727 -- 1) modifying code for the period of 1951 to 2017
                and add the condition when start and finish time 
                of data do not match the time period of selection
                2) reading all streamflow gauges  
REFERENCES

todo 1) : calibrated and non-calibrated list
todo 2) : add header with geographical location of stations 
        then adhere the records 

"""
#%% importing module 
import pandas as pd
import numpy as np 
import os 
import glob

#%% setting I/O dirs 
# get all streamflow files 
path     = 'station_records/updated_records/streamflow'  
dir_list = os.listdir(path)
print(dir_list)

# streamflow files and IDs
files   = glob.glob(path + "/*.csv")
file_id = glob.glob(path + "/*ID.xlsx")

# output all records 
statfill    = 'output/1951_2017/stflo_FRB.csv'
statfill85  = 'output/1951_2017/stflo_FRB_85.csv'
index85     = 'output/1951_2017/stflo_FRB_85_index.csv'

#%% time range (selection period)
time = pd.date_range(start='1/1/1951', end='31/12/2017', freq='D')
m = len(time)

# %% reading directory of streamflow records for calibrated stations 
# calibrated files 
# prmname = 'prm/st_records.txt'

# output calibration 
# statfill    = 'output/1951_2017/stflo_FRB_calib.csv'
# statfill85  = 'output/1951_2017/stflo_FRB_calib_85.csv'
# index85     = 'output/1951_2017/stflo_FRB_calib_85_index.csv'

# reading from a selected list 
# fid  = open(prmname,'r')    

# Info = np.loadtxt(fid,
#             dtype={'names': ('col1', 'col2'),
#             'formats': ('U10', 'U200')})

# fid.close()

#%% reading input streamflow records
# n = len(Info)
n = len(files)

sf = np.zeros((m,n))
ids = []

for i in range(n):
    #data  = pd.read_csv(Info[i][1])
    data  = pd.read_csv(files[i])
    rs = np.where(data['Date'].values == time[0].strftime('%Y/%m/%d'))[0]
    rf = np.where(data['Date'].values == time[m-1].strftime('%Y/%m/%d'))[0]    

    if (data['Date'].values[len(data)-3] < time[0].strftime('%Y/%m/%d')):

            sf[:, i] = np.nan
            ids = np.append(ids, data[' ID'].values[0])
            print("Warning: The Records of Gauge %s does not observations in \
                  the time window of interest" % (data[' ID'].values[0]))
    else:
        
        # check different conditions when the indices of start and finish are not found  
        if ((rs.size == 0) & (rf.size == 0)):
            rs2 = np.where(data['Date'].values[0] == time.strftime('%Y/%m/%d'))[0]
            rf2 = np.where(data['Date'].values[len(data)-3] == time.strftime('%Y/%m/%d'))[0]
            sf[0 : rs2[0] , i] = np.nan
            sf[rs2[0] : rf2[0]+1, i] = data.values[0: len(data)-2 , 3]
            sf[rf2[0] + 1 : m , i]    =  np.nan
            ids = np.append(ids, data[' ID'].values[0])
            
        elif (rs.size == 0):
            rs2 = np.where(data['Date'].values[0] == time.strftime('%Y/%m/%d'))[0]
            sf[0 : rs2[0] , i] = np.nan    
            sf[rs2[0] : rs2[0] + rf[0] + 1 , i] = data.values[0: rf[0] + 1 , 3]
            ids = np.append(ids, data[' ID'].values[0])
            
        elif (rf.size == 0):
            rf2 = np.where(data['Date'].values[len(data)-3] == time.strftime('%Y/%m/%d'))[0]
            sf[0 : rf2[0] + 1 , i]     = data.values[rs[0]: rs[0] + rf2[0] + 1, 3]
            sf[rf2[0] + 1 : m , i]     = np.nan
            ids = np.append(ids, data[' ID'].values[0])
        else : 
           sf[:, i] = data.values[rs[0]: rf[0]+1, 3]
           ids = np.append(ids, data[' ID'].values[0])
       
stflo = pd.DataFrame(time, columns = ['Time'])
stflo[ids] = sf    

#%% reorder streamflow records based on user defined ID
stid  = pd.read_excel(file_id[0])
stflo_reorder = pd.DataFrame(time, columns = ['Time'])
stflo_reorder[stid['Station_ID']] = stflo[stid['Station_ID']]
           
#%% finding missing values with FillValue

fid = stflo_reorder.isnull()
count_nan = len(stflo_reorder) - stflo_reorder.count()

# replacing nan values with -1 
stflo_reorder = stflo_reorder.fillna(value = -1) 

#%% finding missing values and fill them with FillValue 
statfull   =  count_nan[count_nan == 0]
stat_85    =  count_nan[count_nan <= 0.15*(m)]

# extract station indices with more 85% full records 
stflo_reorder_85   = stflo_reorder[stat_85.index] 

#%% write outputs 
stflo_reorder.to_csv(statfill, index = False, float_format='%.1f')
stflo_reorder_85.to_csv(statfill85, index = False, float_format='%.1f')
stat_85.to_csv(index85)