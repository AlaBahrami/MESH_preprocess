#!/bin/bash
#SBATCH --account=rpp-kshook
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --mem=10G
#SBATCH --time=00:30:00
#SBATCH --job-name=GEMCAPA_FRB
#SBATCH --mail-user=ala.bahrami@usask.ca
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
module load cdo

# basin prefix - to be supplied as an argument - grd file should be named accordingly
basin=$1

# variable 
var=basin_humidity

# input folder
infolder=/project/6008034/Model_Output/101_GEM-CaPA_interpolated_0.125
outfolder=/project/6008034/baha2501/FRB/MESH/Forcing

#outfile=$basin'_RDRS_v2_2000-2017_MESH'
#echo $outfile

cdo -b F32 remapbil,$basin.grd $infolder/$var"_40m_20040901_20170901".nc $outfolder/$basin"_"$var"_2004-2017".nc

# Clip and Interpplate for the basin grid
# #for var in RDRS_v2_P_HU_09944 RDRS_v2_A_PR0_SFC RDRS_v2_P_P0_SFC RDRS_v2_P_FB_SFC RDRS_v2_P_FI_SFC RDRS_v2_P_TT_09944 RDRS_v2_P_UVC_09944
	# do
	# cdo -z zip -b F32 remapbil,$basin.grd $basin"_"$var"_2000-2017".nc $basin"_"$var"_2000-2017_MESH".nc
	# done