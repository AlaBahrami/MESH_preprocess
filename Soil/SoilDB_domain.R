# Description  
#
#  The purpose of this script is to read soil datasets requried for a domain of interest 
#
#
# Input         
#               
#
#
# Output        extracted Soil layers for the domain of interest
#
#
# Reference     
#
#
# See also: Extract_GSDE
#
# Author: Ala Bahrami       
#
# Created Date: 05/10/2021
#
# Last Modified: 05/25/2021
#                           
# Copyright (C) 2021 Ala Bahrami  
#
# Todo! all process of resampling and cropping or even aggregation of GSDE can be
# applied here instead of generate_MESH_parameters program
#
# loading libs ------------------------------
library(ncdf4)
library(raster)
library(rgdal) 
library(raster)
library(shapefiles)
source("Extract_GSDE.R")

### setting inputs ------------------
# note here the extents are expanded one pixel more
# to avoid any inconsistency with other datasets(e.g., DEM)
nrow   <- 64 +2
ncol   <- 81 +2 
res    <- 0.125
xmin   <- -128.125 - 1*res
ymin   <- 48.5 - 1*res
indir  <- "D:/Data/SoilData/"
### Extracting Clay layers --------
var    <-  "CLAY"
Extract_GSDE(nrow , ncol , res ,
             xmin , ymin , 
             indir, var)

### Extracting SAND layers --------
var   <-  "SAND"
Extract_GSDE(nrow , ncol , res ,
             xmin , ymin , 
             indir, var)

### Extracting Organic layers --------
var   <-  "OC"
Extract_GSDE(nrow , ncol , res ,
             xmin , ymin , 
             indir, var)






