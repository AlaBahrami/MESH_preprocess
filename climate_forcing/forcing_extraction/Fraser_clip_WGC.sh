#!/bin/bash
#SBATCH --account=rpp-kshook
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --mem=10G
#SBATCH --time=03:00:00
#SBATCH --job-name=WGC_FRB
#SBATCH --mail-user=ala.bahrami@usask.ca
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
module load StdEnv/2020  intel/2020.1.217  openmpi/4.0.3
module load cdo/1.9.8

# basin prefix - to be supplied as an argument - grd file should be named accordingly
basin=$1

# input folder
infolder=/project/6008034/Model_Output/181_WFDEI-GEM-CaPA_1979-2016
#output folder
outfolder=/project/6008034/baha2501/FRB/MESH/Forcing/WGC

#cdo -b F32 remapbil,$basin.grd $infolder/$var"_40m_20040901_20170901".nc $outfolder/$basin"_"$var"_2004-2017".nc
# Clip and Interpplate for the basin grid
for var in hus_WFDEI_GEM_1979_2016 pr_WFDEI_GEM_1979_2016 ps_WFDEI_GEM_1979_2016 rlds_WFDEI_GEM_1979_2016 rsds_WFDEI_GEM_1979_2016_thresholded ta_WFDEI_GEM_1979_2016 wind_WFDEI_GEM_1979_2016 
	do
	cdo -z zip -b F32 remapbil,$basin.grd $infolder/$var".Feb29".nc $outfolder/$basin"_"$var.nc
	done