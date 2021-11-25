#!/bin/bash
#SBATCH --account=rpp-kshook
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --mem=10G
#SBATCH --time=10:00:00
#SBATCH --job-name=CWGC_FRB
#SBATCH --mail-user=ala.bahrami@usask.ca
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
module load StdEnv/2020  intel/2020.1.217  openmpi/4.0.3
module load cdo/1.9.8

# basin prefix - to be supplied as an argument - grd file should be named accordingly
basin=$1

for R in {8..10}
	do 
	 for P in {1..5}
	  do 
	    # input folder
		infolder=/project/6008034/Model_Output/280_CanRCM4_Cor_WFDEI-GEM-CaPA/r"${R}"i2p1r"${P}"
		#output folder
		outfolder=/project/6008034/baha2501/FRB/MESH/Forcing/CWGC/r"${R}"/r"${P}"
		for var in hus pr ps rlds rsds ta wind 
			do
			   # clip and interpolate to the basin boundary of interest
			   cdo -z zip -b F32 remapbil,$basin.grd $infolder/$basin"_"$var"_r"${R}"i2p1r"${P}"_z1_1951-2100.Feb29".nc4 tmp.nc
			   # fill missing data
			   cdo -z zip setmisstonn tmp.nc $outfolder/$basin"_"$var"_r"${R}"i2p1r"${P}"_z1_1951-2100.Feb29".nc4
			   rm tmp.nc
			done
      done 
	done 