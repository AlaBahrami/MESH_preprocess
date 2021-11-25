# -*- coding: utf-8 -*-
"""
NAME
    forcing_seasonal_calc 
PURPOSE
    The purpose of this script is to read MESH forcing basin averaged results 
    of different subbasins and calculat the seasonal cycles. The seasonal cycles 
    between two periods then can be compared. 
    
Input 
    prmname                       The input parameter file includes metric results   

Output 
                                  Series of plots                               
PROGRAMMER(S)
    Ala Bahrami
    
REVISION HISTORY
    20211025 -- Initial version created and posted online
    20211028--     
       
REFERENCES

todo works:  
1) construnct the data frame if needed 
2) saving output as netcdf  
3) number 4 is hardcoded  
4) change prec to forcing as I have temperature here 
5) the seasonal calculation and presentation needs recoding.
and it can be calculayed based on the regroupy results     
"""
#%% importing modules 
import pandas as pd
import numpy as np
import datetime
import matplotlib.pyplot as plt
import seaborn as sns

#%% reading input files
prmname = 'prm/wb_set.txt'

fid  = open(prmname,'r')    
Info = np.loadtxt(fid,
            dtype={'names': ('col1', 'col2'),
            'formats': ('U10', 'U200')})
fid.close()

#%%  setting plot styles 
cl =([0.35,0.35,0.35],[0.55,0.55,0.55],[0.055,0.310,0.620],[0,0.48,0.070],
                             [0.850,0.325,0.0980],[0.8,0.608,0],[0.6350,0.0780,0.1840],
                             [0.4940,0.1840,0.5560])

names = ['WGC','WFDEI','RDRS','GC']
lsty  =  ['-','--','-','--']

tl = ["08JC002 ","Basin-Average","Basin-Average"]

outdir = "output/"

#%% tiem variable 
# complete time index for all forcing
time   = pd.date_range(start='9/1/1979', end='08/31/2017', freq='M')
time_y = pd.date_range(start='9/1/1979', end='08/31/2017', freq='Y')

m    = len(time)
prec = np.zeros((m,4))
prec_y = np.zeros((len(time_y),4))
prec_timemean = np.zeros((3,4))
# todo : to be modified 
#prec_forcing_st6 = np.zeros((m,4))

#%% convert Julian date to standard date 
def julian_todate (jdate):
    fmt = '%Y%j'
    datestd = datetime.datetime.strptime(jdate, fmt).date()
    return(datestd)

#%% construct monthly and yearly time variable based on MESH wb file 
def time_construct(watbal):
    # construct time index 
    nn = len(watbal)
    ts = '%d'%watbal['month'][0]+'/'+'%d'%watbal['day'][0]+'/'+'%d'%watbal['YEAR'][0]
    te = '%d'%watbal['month'][nn-1]+'/'+'%d'%watbal['day'][nn-1]+'/'+'%d'%watbal['YEAR'][nn-1]
    tm = pd.date_range(start=ts, end=te, freq='M')
    ty = pd.date_range(start=ts, end=te, freq='Y')    
    return(tm, ty)    

#%% reading input wb file, regroup, calculate monthly mean, store in compelete time series 
for p in range(3):
    for k in range(4):
    
        wb = pd.read_csv(Info[4*p+k][1], skipinitialspace=True)
        #list(wb) header of input 
         
        # convert MESH wb jday to month and day 
        n = len(wb)
        month = np.zeros((n,1))
        day   = np.zeros((n,1))
        
        for i in range(n):    
            jd     = '%d'%wb['YEAR'][i]+'%d'%wb['JDAY'][i]
            md     = julian_todate(jd)
            day[i] = md.day
            month[i] = md.month
        
        wb['month'] = month
        wb['day']   = day
        
        [time2,time2_y] = time_construct(wb)
    
        rs = np.where(time2[0] == time)[0]
        rf = np.where(time2[len(time2)-1] == time)[0]
        
        rs2 = np.where(time2_y[0] == time_y)[0]
        rf2 = np.where(time2_y[len(time2_y)-1] == time_y)[0]
        
        # compute time mean average from 2005-2016
        rs3 = np.where((wb['YEAR'] == 2005) & (wb['day'] == 1) & (wb['month'] == 1))[0]
        rf3 = np.where((wb['YEAR'] == 2016) & (wb['day'] == 30) & (wb['month'] == 12))[0]
        
        # cuases a crash here
        if(p < 2):
            prec_timemean[p,k]= wb['PREC'][rs3[0]:rf3[0]].mean()
        else:
            prec_timemean[p,k]= wb['TA'][rs3[0]:rf3[0]].mean()
        
        # Regroup and calculate the means 
        #calculting monthly average 
        
        if(p < 2):
        
            wb_prec_month = wb.groupby(["YEAR","month"])["PREC"].sum()
            wb_prec_year  = wb.groupby(["YEAR"])["PREC"].sum()

        else :
                wb_prec_month = wb.groupby(["YEAR","month"])["TA"].sum()
                wb_prec_year  = wb.groupby(["YEAR"])["TA"].sum()
        
        # building complete monthly time series
        if (rs[0]!=0): 
            prec[0:rs[0],k]          =  np.nan
            prec_y[0:rs2[0],k]       =  np.nan
        
        if (("wfdei") in Info[k][0]) or (("gc") in Info[k][0]):
                prec[rs[0]:rf[0]+1,k]     =  wb_prec_month.values[0:len(wb_prec_month)-1]
                prec_y[rs2[0]:rf2[0]+1,k] =  wb_prec_year.values[0:len(wb_prec_year)-1]
        else:
                prec[rs[0]:rf[0]+1,k]     =  wb_prec_month
                prec_y[rs2[0]:rf2[0]+1,k] =  wb_prec_year[0:len(wb_prec_year)-1]
                
        if (rf[0]+1<m):
            prec[rf[0]+1:,k]         =  np.nan
            prec_y[rf2[0]+1:,k]      =  np.nan
    
    #% contrunct seasonal signal from 2005 to 2016
    # this section of code reads recoding # line 154 to 241 
    rr1 = np.asarray(np.where(time =='01/31/2005'))
    rr2 = np.asarray(np.where(time =='01/31/2017')) 
    
    # todo the number should be replaced auto
    prec2 = prec[304:448,:]
    prec2 = prec2.flatten(order='F')
    
    #dataframe  
    
    d = {'month':[],'forcing':[],
         'region':[],'PREC':[]}

    if (p==2):
        d = {'month':[],'forcing':[],
         'region':[],'Temp':[]}
    
    prec_season = pd.DataFrame(data=d)
    prec_season['PREC'] = prec2
    
    if (p==2):
        prec_season['Temp'] = prec2
    
    if (p == 0):
        prec_season['region']= '08JC002'
    else:
        prec_season['region']= 'Fraser River Basin'
    
    prec_season['forcing'][0:144]= 'WGC'
    prec_season['forcing'][144:144*2]= 'WFDEI'
    prec_season['forcing'][144*2:144*3]= 'RDRS'
    prec_season['forcing'][144*3:144*4]= 'GC'
    
    mm = [1,2,3,4,5,6,7,8,9,10,11,12]
    n2 = np.int32(len(prec2)/12)
    for i in range(n2):
        prec_season['month'][12*i:12*(i+1)]=mm
        
    if (p < 2):
        #% display the seasonal cycle for four forcing 
        sns.relplot(
        data=prec_season, kind="line",
        x="month", y="PREC", col="region",
        hue="forcing", style="forcing")
        
        # saving image
        mng = plt.get_current_fig_manager()
        mng.full_screen_toggle()
        fs = outdir+tl[p]+"-seasonal"+".png"
        plt.savefig(fs, dpi=150) 
        plt.close()
        
        #% display the box plot
        sns.boxplot(x="month", y="PREC",
                hue="forcing", palette=["m", "g","b","r"],
                data=prec_season)
        sns.despine(offset=10, trim=True)
        
        mng = plt.get_current_fig_manager()
        mng.full_screen_toggle()
        fs = outdir+tl[p]+"-seasonal-box"+".png"
        plt.savefig(fs, dpi=150) 
        plt.close()
    else:
        #% display the seasonal cycle for four forcing 
        sns.relplot(
        data=prec_season, kind="line",
        x="month", y="Temp", col="region",
        hue="forcing", style="forcing")
        
        # saving image
        mng = plt.get_current_fig_manager()
        mng.full_screen_toggle()
        fs = outdir+tl[p]+'Temperature'+"-seasonal"+".png"
        plt.savefig(fs, dpi=150) 
        plt.close()
        
        #% display the box plot
        sns.boxplot(x="month", y="Temp",
                hue="forcing", palette=["m", "g","b","r"],
                data=prec_season)
        sns.despine(offset=10, trim=True)
        
        mng = plt.get_current_fig_manager()
        mng.full_screen_toggle()
        fs = outdir+tl[p]+'Temperature'+"-seasonal-box"+".png"
        plt.savefig(fs, dpi=150) 
        plt.close()
        
    #%% displaing the results 
    fig,axs   = plt.subplots(3,1)
    for k in range(4):
                        # monthly plot
                        axs[0].plot(time, prec[:,k],
                        marker="o",
                        linestyle = lsty[k],
                        color=cl[k],
                        markerfacecolor=cl[k],
                        markeredgecolor=cl[k],
                        label = names[k])
                        # zoom plot
                        axs[1].plot(time[252:336], prec[252:336,k],
                        marker="o",
                        linestyle = lsty[k],
                        color=cl[k],
                        markerfacecolor=cl[k],
                        markeredgecolor=cl[k],
                        label = names[k])
                        # yearly plot
                        axs[2].plot(time_y, prec_y[:,k],
                        marker="o",
                        linestyle = lsty[k],
                        color=cl[k],
                        markerfacecolor=cl[k],
                        markeredgecolor=cl[k],
                        label = names[k])
    # setting labels 
    axs[0].set_title(tl[p], fontsize=18, fontname='Times New Roman', fontweight='bold')
    axs[1].set_xlabel("Time [months]", fontsize=14, fontname='Times New Roman', fontweight='bold')
    axs[2].set_xlabel("Time [years]", fontsize=14, fontname='Times New Roman', fontweight='bold')
    
    for i in range(3):
        axs[i].set_ylabel("Precipitation Rate [mm $s^{-1}$]", fontsize=12, fontname='Times New Roman', fontweight='bold')
        
        # setting axis 
        plt.setp(axs[i].get_xticklabels(), ha="right",
                     rotation_mode="anchor", fontsize=12, fontname='Times New Roman', 
                     fontweight='bold')
        plt.setp(axs[i].get_yticklabels(), fontsize=12, fontname='Times New Roman', 
                     fontweight='bold')
        axs[i].grid(True)
        axs[i].legend()
        
    # setting xlim
    axs[0].set_xlim(time[0], time[m-1])
    axs[1].set_xlim(time[252], time[335])
    axs[2].set_xlim(time_y[0], time_y[len(time_y)-1])
    
    # saving image 
    mng = plt.get_current_fig_manager()
    mng.full_screen_toggle()
    fs = outdir+tl[p]+".png"
    plt.savefig(fs, dpi=150)    
    
    # showing and closing 
    plt.show()
    plt.close()
    