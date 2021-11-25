#!/bin/bash
#SBATCH --account=rpp-kshook
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --mem=10G
#SBATCH --time=01:00:00
#SBATCH --job-name=RDRS_FRB
#SBATCH --mail-user=ala.bahrami@usask.ca
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
module load StdEnv/2020  intel/2020.1.217  openmpi/4.0.3
module load cdo/1.9.8

# basin prefix - to be supplied as an argument - grd file should be named accordingly
basin=$1

# input folder
infolder=/project/6008034/Model_Output/105_RDRS_v2_10km/91_Fraser
#output folder
outfolder=/project/6008034/baha2501/FRB/MESH/Forcing/RDRS

fl=$basin'_RDRS_v2_2000-2017'
echo $fl

for var in RDRS_v2_P_HU_09944 RDRS_v2_A_PR0_SFC RDRS_v2_P_P0_SFC RDRS_v2_P_FB_SFC RDRS_v2_P_FI_SFC RDRS_v2_P_TT_09944 RDRS_v2_P_UVC_09944
	do
		cdo selname,$var $infolder/$fl'_MESH'.nc $outfolder/$basin"_"$var"_2000-2017".nc		
	done

## Adjust Units
# Pressure from "mb" to "Pa"
cdo mulc,100 $outfolder/$basin'_RDRS_v2_P_P0_SFC_2000-2017'.nc tmp.nc
cdo setattribute,RDRS_v2_P_P0_SFC@units=Pa tmp.nc $outfolder/$basin'_RDRS_v2_P_P0_SFC_2000-2017'.nc
rm tmp.nc

# Temperature from "deg_C" to "K"
cdo addc,273.16 $outfolder/$basin'_RDRS_v2_P_TT_09944_2000-2017'.nc tmp.nc
cdo setattribute,RDRS_v2_P_TT_09944@units=K tmp.nc $outfolder/$basin'_RDRS_v2_P_TT_09944_2000-2017'.nc
rm tmp.nc

# Wind speed from "knts" to "m/s"
cdo mulc,0.5144444444444444 $outfolder/$basin'_RDRS_v2_P_UVC_09944_2000-2017'.nc tmp.nc
cdo setattribute,RDRS_v2_P_UVC_09944@units="m s-1" tmp.nc $outfolder/$basin'_RDRS_v2_P_UVC_09944_2000-2017'.nc
rm tmp.nc

# Precipitation from "m" over the hour to a rate "mm/s" = "kg m-2 s-1"
cdo divc,3.6 $outfolder/$basin'_RDRS_v2_A_PR0_SFC_2000-2017'.nc tmp.nc
cdo setattribute,RDRS_v2_A_PR0_SFC@units="mm s-1" tmp.nc $outfolder/$basin'_RDRS_v2_A_PR0_SFC_2000-2017'.nc
rm tmp.nc

#cdo -b F32 remapbil,$basin.grd $infolder/$var"_40m_20040901_20170901".nc $outfolder/$basin"_"$var"_2004-2017".nc
# Clip and Interpplate for the basin grid
for var in RDRS_v2_P_HU_09944 RDRS_v2_A_PR0_SFC RDRS_v2_P_P0_SFC RDRS_v2_P_FB_SFC RDRS_v2_P_FI_SFC RDRS_v2_P_TT_09944 RDRS_v2_P_UVC_09944
	do
	cdo -z zip -b F32 remapbil,$basin.grd $outfolder/$basin"_"$var"_2000-2017".nc $outfolder/$basin"_"$var"_2000-2017_MESH".nc
	done