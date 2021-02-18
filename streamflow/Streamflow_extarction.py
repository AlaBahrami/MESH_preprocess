# -*- coding: utf-8 -*-
"""
The purpose of this script is to extarct streamflow records for the Fraser .
Then finding out which stations have missing data. Stations having missing records 
are replaced with -1. data less than 15% missing records are exported 

!todo: 
Data can be categorized into two series. Between 2004 to 
2011 (calibration), and 2011 to 2017 (evaluation).  

"""
# %% importing modules 
import datetime
import pandas as pd

# %% setting parameters
# input 
sh = "Observations_flow_2004_2017" 
filin = "Streamflow_FRB.xlsx"

# output 
filout        = "Streamflow_FRB_fill.xlsx"
filout2       = "Streamflow_FRB_85%.xlsx"
filindex100   = "stflo_index100.xlsx"
filindex85    = "stflo_index85.xlsx"
filmissing    = "stflo_index_missing.xlsx"
filcalib      = "Streamflow_FRB_calibration.xlsx"

# %% start and end time of GEM_CaPA
ts = datetime.datetime(2004, 9 , 1)
tf = datetime.datetime(2017 , 8 , 31)

# time duration in days 
diff = tf - ts;
time_rec = diff.total_seconds()/(3600*24) + 1 

# %% reading streamflow records and filling missing values 
sf  = pd.read_excel(filin, sh) 
#sf2 = sf.drop(columns=['Unnamed: 0'])

# finding null values 
fid = sf.isnull()
# counting nan values 

count_nan = len(sf) - sf.count()

# replacing nan values 
sfed = sf.fillna(value = -1) 

# %% filter out stations with full records or 85% valid records
arful =  count_nan[count_nan == 0]
ar85  =  count_nan[count_nan <= 0.15*(time_rec)]

# %% extracting full records
sfed2 = sfed[ar85.index] 

# %% finding indices of station for calibration 
# here I set it manually
#!+ find them automatically
stations = ['08JC002','08KB001','08KH006','08KG001','08LF051',
            '08MB005','08MC018','08MF005','08MF040']
sfcal = sfed[stations] 


# %% write data (index and records)
count_nan.to_excel(filmissing)
sfed.to_excel(filout)
sfed2.to_excel(filout2)
arful.to_excel(filindex100)
ar85.to_excel(filindex85)
sfcal.to_excel(filcalib)
