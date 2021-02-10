# -*- coding: utf-8 -*-
"""
Spyder Editor

The purpose of this script is to extarct streamflow records of the FRB.
Then finding out which stations have missing data. Stations having missing records 
are replaced with -1

"""


import datetime
import pandas as pd
import numpy as np


#-----------------------------------------------------------------------------
# start and end time of GEM_CaPA
#ts = datetime.datetime(2004, 9 , 1, 00, 00, 00)
#tf = datetime.datetime(2017 , 8 , 31 , 23 , 00 , 00);

ts = datetime.datetime(2004, 9 , 1)
tf = datetime.datetime(2017 , 8 , 31)

# time duration in days 
diff = tf - ts;
time_rec = diff.total_seconds()/(3600*24) + 1 

# if requried to transfer it to hours
#time_rec = diff.total_seconds()/3600 +1

#-----------------------------------------------------------------------------
# reading streamflow records and replacing nan values with -1

# setting parameters
fil_in = "Observations_flow_2004_2017" 
fil_out = "Streamflow_FRB_ed.xlsx"

stflo = pd.read_excel(r'Streamflow_FRB.xlsx', sheet_name = fil_in) 
stflo2 = stflo.drop(columns=['Unnamed: 0'])

# finding null values 
fid = stflo.isnull()

# counting nan values 
count_nan = len(stflo2) - stflo2.count()

# convert to array
#stflo.values 

# extract to subarray
# stflo.iloc[:,1]

# replacing nan values 
stflo_ed = stflo.fillna(value = -1) 
stflo_ed.to_excel(fil_out)

#-----------------------------------------------------------------------------
# filter out stations with full records or 75% valid records

arr_ful =  count_nan[count_nan == 0]
arr_90  =  count_nan[count_nan <= 0.1*(time_rec)]

arr_ful.to_excel("stflo_index.xlsx")


#-----------------------------------------------------------------------------
#extract with specific condition
a = stflo_ed[stflo_ed == '-1']

