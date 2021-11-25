#!/bin/bash
#SBATCH --account=rpp-kshook
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --mem=10G
#SBATCH --time=3:00:00
#SBATCH --job-name=WFDEI_FRB
#SBATCH --mail-user=ala.bahrami@usask.ca
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
# the interpolate, fill missing time and data took 02:14:58
module load StdEnv/2020  intel/2020.1.217  openmpi/4.0.3
module load cdo/1.9.8

# basin prefix - to be supplied as an argument - grd file should be named accordingly
basin=$1

# input folder
infolder=/project/6008034/Model_Output/CCRN/WFDEI_1979_2016
#output folder
outfolder=/project/6008034/baha2501/FRB/MESH/Forcing/WFDEI
for var in huss pr ps rlds rsds tas sfcWind 
	do
	   # clip and interpolate to the basin boundary of interest
	   cdo -z zip -b F32 remapbil,$basin.grd $infolder/$var"_WFDEI_Obs_1979_2016".nc tmp.nc
	   
	   # add missing Feb 29 of leap years 
	   set -e
       isleap() {
       date -d $1-02-29 &>/dev/null && echo 0 || echo 1
       }
	   
	   for year in $(cdo showyear tmp.nc)
 
		  do
	 
		   if [ $(isleap $year) -eq 0 ]
	 
		   then
	 
			for hour in {00..23..3}
	 
			do
	 
			 #fill the missing Feb 29 value for leap year
			 cdo -L -a -b 32 -settime,$hour:00:00 -setday,29 -setmon,2 -divc,2 -add -seltime,$hour:00:00 -selday,28 -selmon,2 -selyear,$year tmp.nc -seltime,$hour:00:00 -selday,1 -selmon,3 -selyear,$year tmp.nc tmp1.$year.$hour.nc 
	 
			done
	 
		   fi
	 
		done
 
    # merge time 
	cdo -a mergetime tmp.nc tmp1.????.??.nc tmp1.nc
    #cdo -a mergetime $infile *.nc tmp.nc
 
    #set the time to standard netcdf calender
	cdo setcalendar,'standard' tmp1.nc tmp2.nc 
	   
	   # fill missing data 
	   cdo -z zip setmisstonn tmp2.nc $outfolder/$basin"_"$var"_WFDEI_Obs_1979_2016".nc
	   
	   # deleting data 
	   rm tmp.nc tmp1.????.??.nc tmp1.nc tmp2.nc
	done
