 
# loading libs ------------------------------
library(ncdf4)
library(raster)
library(rgdal) 
library(raster)
library(shapefiles)

#library(ggplot2) 

# setting dir -------------------------------
rm(list=ls(all=TRUE))
setwd("D:/Data/SoilData/CLAY1")

# reading inputs info----------------------------
clay      <- "CLAY1.nc"
nc_data   <- nc_open(clay, write=FALSE)
{
  sink('Clay1_metadata.txt')
  print(nc_data)
  sink()
}

# reading input nc file--------------------------
lon             <- ncvar_get(nc_data, "lon")
lat             <- ncvar_get(nc_data, "lat")
clay1.array     <- ncvar_get(nc_data, "depth")


