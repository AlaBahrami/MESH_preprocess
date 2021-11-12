# Description  
#
#  The purpose of this script to generate MESH required parameters from
#  DEM and sooil input datasets
#
#  Author: Ala Bahrami
#          First initiation is based on Zelalem's code  
#
# Last Modified: 08/10/2021
#                 modified the organic header to orgm to be consistent with MESH  
# note 1) The TauDEM section is commented as the outputs can be read
#
#               11/12/2021
#               changing slope to tangent instead of degree 
# This part can be replaced in a separate section as a function to produce these output variables.  
# Note 2) all hard coded section can be replaced with input params.  
### laoding libs ------------------------------
rm(list = ls())

library(raster)
library(sp)
library(maptools)
library(rgeos)
library(rgdal)
library(numbers)
library(shapefiles)
library(ncdf4)
library(geosphere)

### set user input directory ---------------------------
#setwd("D:/programing/R/MESH_Preprocess/frb_project/Input")
#ncpath <- "D:/programing/R/MESH_Preprocess/frb_project/Input"
#outdir <- "D:/programing/R/MESH_Preprocess/frb_project/output/Fraser_GEM_0p125_MinThresh_"

setwd("C:/Users/alb129/OneDrive - University of Saskatchewan/programing/R/MESH_Preprocess/frb_project/Input")
ncpath <- "C:/Users/alb129/OneDrive - University of Saskatchewan/programing/R/MESH_Preprocess/frb_project/Input"
outdir <- "C:/Users/alb129/OneDrive - University of Saskatchewan/programing/R/MESH_Preprocess/frb_project/output/Fraser_GEM_0p125_MinThresh_"

### select version of the MESH ---------------------------
#MESHVersion <- "Mountain"
MESHVersion <- "Original"
MinThresh   <- 100 
NSL         <- 5

### Name of the drainage basin of study ------------------------------
BasinName <- paste0(outdir, MinThresh, "_") 

### Set the climate forcing grid domain ------------------------------ 
#! this hard coded and should be replaced by user 
LLXcorner  <- -128.125
LLYcorner  <- 48.50
NumRow     <- 64
NumCol     <- 81
XRes       <- 0.125
YRes       <- 0.125
outlet_lat <- 49.210
outlet_lon <- -122.89  
URXcorner  <- (LLXcorner + (NumCol*XRes)) 
URYcorner  <- (LLYcorner + (NumRow*YRes))

### import DEM and landcover ------------------------------
# todo: this can be replaced with entire canada dem and cliped 
domain_dem <- raster("Merit_DEM_2019_clip.tif")

### import percentage of clay and sand content --------------------------------------
 domain_Clay1 <- raster("Fraser_MESH_CLAYLayer1.tif")
 domain_Clay2 <- raster("Fraser_MESH_CLAYLayer2.tif")
 domain_Clay3 <- raster("Fraser_MESH_CLAYLayer3.tif")
 domain_Clay4 <- raster("Fraser_MESH_CLAYLayer4.tif")

 domain_Sand1 <- raster("Fraser_MESH_SANDLayer1.tif")
 domain_Sand2 <- raster("Fraser_MESH_SANDLayer2.tif")
 domain_Sand3 <- raster("Fraser_MESH_SANDLayer3.tif")
 domain_Sand4 <- raster("Fraser_MESH_SANDLayer4.tif")
 
 domain_Organic1 <- raster("Fraser_MESH_OCLayer1.tif")
 domain_Organic2 <- raster("Fraser_MESH_OCLayer2.tif")
 domain_Organic3 <- raster("Fraser_MESH_OCLayer3.tif")
 domain_Organic4 <- raster("Fraser_MESH_OCLayer4.tif")
 
### import SDEP data ----------------------------
 domain_SDEP     <- raster("Fraser_MESH_SDEP.tif")
 
### Produce the lat long of the center of the forcing grid ----------------------------
YLat <- matrix(0, NumRow, NumCol, byrow = T)
XLon <- matrix(0, NumRow, NumCol, byrow = T)
#
for (i in 1:NumRow) {
  for (j in 1:NumCol) {
    XLon[i,j] <- LLXcorner + (XRes/2) + (j-1)*XRes
    YLat[i,j] <- LLYcorner + (YRes/2) + (i-1)*XRes
  }
}

### Produce zonal raster for the NWP grid -----------------------------------------------
#! nwp_grid has the same resolution as MESH and it the base for cropping raster data (DEM, LCC)
NumGrids         <- matrix(seq(1,(NumRow*NumCol),1), NumRow, NumCol, byrow = T) 
nwp_grid         <- raster(NumGrids)
extent(nwp_grid) <- extent(LLXcorner,(LLXcorner+(NumCol*XRes)),LLYcorner,(LLYcorner+(NumRow*YRes)))
dim(nwp_grid)    <- c(NumRow, NumCol)
res(nwp_grid)    <- c(XRes, YRes)
crs(nwp_grid)    <- crs(domain_dem) 
# crs(nwp_grid) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

### Resample the nwp_elevation and the Land cover map into the model_elevation spatial resolution -------
# coarsening spatial resolution of DEM and LCC
# note: the extent of nwp_grid, nwp_zone1, and nwp_zone should be same
# but due to resampling and croping, the extents are modified 
nwp_zone1 <- resample(nwp_grid, domain_dem, method="ngb")
nwp_zone  <- crop(nwp_zone1, nwp_grid)

nwp_zone2 <- resample(nwp_grid, domain_Clay1, method="ngb")
nwp_zone2 <- crop(nwp_zone2, nwp_grid)

nwp_zone3 <- resample(nwp_grid, domain_SDEP, method="ngb")
nwp_zone3 <- crop(nwp_zone3, nwp_grid)

### Common working variable ------------------------------
ResFactor  <- res(nwp_grid)/res(domain_dem)
ResFactor  <- ResFactor[1]

ResFactor1  <- res(nwp_grid)/res(domain_Clay1)
ResFactor1  <- round(ResFactor1[1])

ResFactor2  <- res(nwp_grid)/res(domain_SDEP)
ResFactor2  <- round(ResFactor2[1])

### Creating the basin outlet using the lat and long data --------------------------
#! this section is hard coded. The location of outlet should be determined by user
# the gauge location is used in the DEM post-processing and it is commented here. 
# streamgauge              <- data.frame(lat = outlet_lat, long = outlet_lon)
# coordinates(streamgauge) <- ~long+lat
# crs(streamgauge)         <- crs(domain_dem)
# raster::shapefile(streamgauge, "approxoutlets.shp", overwrite=TRUE)

### TauDEM approach (DEM post-processing and Watershed Delineation -------------------------
# Pitremove
# system("mpiexec -n 12 pitremove -z Merit_DEM_2019_clip.tif -fel domain_demfel.tif")

#! D8 flow directions and slope
# system("mpiexec -n 12 D8Flowdir -p domain_demp.tif -sd8 domain_demsd8.tif -fel domain_demfel.tif",show.output.on.console=F,invisible=F)

# Contributing area (DA)
# system("mpiexec -n 12 AreaD8 -p domain_demp.tif -ad8 domain_demad8.tif -nc")

# Grid Network gord (Strahler Network Order), plen (longest upslope length grid), tlen (total upslope length grid)
# system("mpiexec -n 12 Gridnet -p domain_demp.tif -gord domain_demgord.tif -plen domain_demplen.tif -tlen domain_demtlen.tif")

# Threshold
# system("mpiexec -n 12 Threshold -ssa domain_demad8.tif -src domain_demsrc.tif -thresh 100")

# Move Outlets to fall in the flow acculation pixcel
# system("mpiexec -n 12 moveoutletstostreams -p domain_demp.tif -src domain_demsrc.tif -o approxoutlets.shp -om outlet.shp")
#

# Contributing area upstream of outlet
#! clip contributing area based on outlet 
#! Once the outlet has been placed exactly on the stream paths, the D8 Contributing Area function is run again
#! , but specifying an outlet shapefile to evaluate contributing area and effectively identify the watershed 
#! upstream of the outlet point (or points for multiple outlets).
# system("mpiexec -n 12 Aread8 -p domain_demp.tif -o outlet.shp -ad8 domain_demssa.tif")

# Threshold
# ! classify the domain_demssa into two classes 0 less than 100, then 1 more than 100
# system("mpiexec -n 12 Threshold -ssa domain_demssa.tif -src domain_demsrc.tif -thresh 100")

# # Drop Analysis
#system("mpiexec -n 8 Dropanalysis -p domain_demp.tif -fel domain_demfel.tif -ad8 domain_demad8.tif -ssa domain_demssa.tif -drp logandrp.txt -o outlet.shp -par 5 500 10 0")

# Stream Reach and Watershed
#! This network is still only represented as a grid. To convert this into vector elements represented using a shapefile, 
#! the Stream Reach and Watershed function is used.
#! outputs : domain_demord.tif (Stream Order grid), Connectivity grid (domain_demtree.txt), Netwrok Coordinates (domain_demcoord.txt) 
#! Reach shape file (domain_demnet.shp), watershed grid (domain_demw.tif)
# system("mpiexec -n 12 Streamnet -fel domain_demfel.tif -p domain_demp.tif -ad8 domain_demad8.tif -src domain_demsrc.tif -o outlet.shp -ord domain_demord.tif -tree domain_demtree.txt -coord domain_demcoord.txt -net domain_demnet.shp -w domain_demw.tif")

### Collecting the drainage files generated from previous steps ------------------------------
# and croping to domain area   
# todo: a mask should be created instead facc_at_outlet based on boundary of interest 
# pitremove
#filldem0 = raster("domain_demfel.tif")
#filldem1 <- crop(filldem0, nwp_zone)

# flow direction 
#fdir0 = raster("domain_demp.tif")
#fdir1 <- crop(fdir0, nwp_zone)

# Contributing area upstream of outlet
facc_at_outlet0 = raster("domain_demssa.tif")
facc_at_outlet1 <- crop(facc_at_outlet0, nwp_zone)

facc_at_outlet2 <- resample(facc_at_outlet1, domain_Clay1, method="ngb")
facc_at_outlet2 <- crop(facc_at_outlet2, nwp_zone2)

facc_at_outlet3 <- resample(facc_at_outlet1, domain_SDEP, method="ngb")
facc_at_outlet3 <- crop(facc_at_outlet3, nwp_zone3)

drain_net = raster("domain_demsrc.tif")

#basin_dem <- mask(filldem1, facc_at_outlet1)

### Calculate Slope and aspect ------------------------------
#slope <- terrain(crop(domain_dem, nwp_zone), opt = "slope", unit='degrees', neighbors=8)
slope <- terrain(crop(domain_dem, nwp_zone), opt = "slope", unit='tangent', neighbors=8)
aspect <- terrain(crop(domain_dem, nwp_zone), opt = "aspect", unit='degrees', neighbors=8, flatAspect = NA)
#

if (MESHVersion == "Original") {
  #! I added basin_slope here it missing for calculaiton of MESH parameters
  basin_slope <- mask(slope, facc_at_outlet1)}

### resample, clip, aggregate soil depth rock  -------------------------
domain_SDEP        <- crop(domain_SDEP, nwp_zone3)
sdep_MESH.array    <- as.matrix(aggregate(mask(domain_SDEP, facc_at_outlet3), fact = ResFactor2, fun = mean, na.rm=TRUE))
sdep_MESH.array    <- apply(sdep_MESH.array, 2, rev)

### resample, clip, aggregate soil datasets -------------------------
clay_MESH.array         <- array(1 : NumRow*NumCol*4, dim = c(NumRow, NumCol, NSL-1))
sand_MESH.array         <- array(1 : NumRow*NumCol*4, dim = c(NumRow, NumCol, NSL-1))
organic_MESH.array      <- array(1 : NumRow*NumCol*4, dim = c(NumRow, NumCol, NSL-1))

for (i in 1:NSL-1){
   if (i ==1){
     domain_Clay        <- crop(domain_Clay1, nwp_zone2)
     clay_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Clay, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
     
     domain_Sand        <- crop(domain_Sand1, nwp_zone2)
     sand_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Sand, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
     
     domain_Organic        <- crop(domain_Organic1, nwp_zone2)
     organic_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Organic, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
     
   }
   else if (i == 2){
     domain_Clay        <- crop(domain_Clay2, nwp_zone2)
     clay_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Clay, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
     
     domain_Sand        <- crop(domain_Sand2, nwp_zone2)
     sand_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Sand, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
     
     domain_Organic        <- crop(domain_Organic2, nwp_zone2)
     organic_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Organic, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
     
   }
  else if (i == 3){
    domain_Clay        <- crop(domain_Clay3, nwp_zone2)
    clay_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Clay, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
    
    domain_Sand        <- crop(domain_Sand3, nwp_zone2)
    sand_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Sand, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
    
    domain_Organic        <- crop(domain_Organic3, nwp_zone2)
    organic_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Organic, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
    
  }
  else {
    domain_Clay        <- crop(domain_Clay4, nwp_zone2)
    clay_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Clay, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
    
    domain_Sand        <- crop(domain_Sand4, nwp_zone2)
    sand_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Sand, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
    
    domain_Organic        <- crop(domain_Organic4, nwp_zone2)
    organic_MESH.array[ , , i] <- as.matrix(aggregate(mask(domain_Organic, facc_at_outlet2), fact = ResFactor1, fun = mean, na.rm=TRUE))
    
  }
}

### Check if organic matter is larger than 30% --------------
clay_MESH_ed.array         <- array(1 : NumRow*NumCol*NSL, dim = c(NumRow, NumCol, NSL))
sand_MESH_ed.array         <- array(1 : NumRow*NumCol*NSL, dim = c(NumRow, NumCol, NSL))
organic_MESH_ed.array      <- array(1 : NumRow*NumCol*NSL, dim = c(NumRow, NumCol, NSL))

for (i in 1:NSL-1){
  
  fid     <- (organic_MESH.array[ , , i] >= 30)
  # clay 
  a1      <- clay_MESH.array[ , , i]
  a1[fid] <- 0
  clay_MESH_ed.array[ , , i] <- apply(a1, 2, rev)
  
  # sand 
  a2      <- sand_MESH.array[ , , i]
  a2[fid] <- -2
  sand_MESH_ed.array[ , , i] <- apply(a2, 2, rev)
  
  # organic 
  a3      <- organic_MESH.array[ , , i]
  
  if (i ==1){
    a3[fid] <- 1  
  }
  else if (i ==2){
    a3[fid] <- 2
  }
  else {
    a3[fid] <- 3
  }
  organic_MESH_ed.array[ , , i] <- apply(a3, 2, rev)
  
}

clay_MESH_ed.array[ , , NSL]    <- apply((clay_MESH.array[ , , NSL-1]), 2, rev)
sand_MESH_ed.array[ , , NSL]    <- apply((sand_MESH.array[ , , NSL-1]), 2, rev)
organic_MESH_ed.array[ , , NSL] <- matrix(0, NumRow, NumCol)

### Collecting soil ------------------------------

# todo : repalce to some metrix instead 
soildatabase <- rbind(clay_MESH_ed.array[ , , 5], 
                      clay_MESH_ed.array[ , , 1], clay_MESH_ed.array[ , , 2], clay_MESH_ed.array[ , , 3],
                      clay_MESH_ed.array[ , , 4],
                      sand_MESH_ed.array[ , , 5],
                      sand_MESH_ed.array[ , , 1], sand_MESH_ed.array[ , , 2], sand_MESH_ed.array[ , , 3],
                      sand_MESH_ed.array[ , , 4], 
                      organic_MESH_ed.array[ , , 5],
                      organic_MESH_ed.array[ , , 1], organic_MESH_ed.array[ , , 2], organic_MESH_ed.array[ , , 3],
                      organic_MESH_ed.array[ , , 4],  
                      sdep_MESH.array)
# Note : I am not sure if replacing NA values with zero is correct or not
# or the mean value should be used intead of zero
soildatabase[is.na(soildatabase)] <- 0

### dem slope ------------------------------ 
gridslope0 <- as.matrix(aggregate(basin_slope, fact = ResFactor, fun = mean, na.rm=TRUE))

# slope, and DDEN datasets
gridslope <- apply(gridslope0, 2, rev)
# I added this section also 
gridslope[is.na(gridslope)] <- 0

### Prepare grided drainage density and collect it  ------------------------------
drain_net[drain_net == 0] <- NA
basin_DN <- mask(crop(drain_net, nwp_zone), facc_at_outlet1)
basin_nwp_zone <- mask(nwp_zone, facc_at_outlet1)
#
#! I guess it is multiplied by sqrt(2) to get the diagonal 
dn_cell_length <- sqrt(2) * sqrt(area(basin_DN, na.rm=TRUE, weights=FALSE))
grid_area_km2 <- area(basin_nwp_zone, na.rm=TRUE, weights=FALSE)
# zonal_drnr_km <- zonal(dn_cell_length, nwp_zone, 'sum', na.rm=TRUE)
# zonal_area_km2 <- zonal(grid_area_km2, nwp_zone, 'sum', na.rm=TRUE)
zonal_drnr_km <- aggregate(dn_cell_length, fact = ResFactor, fun = sum, na.rm=TRUE)

# when the grid has no stream use the minimum length of 0.1 km (100 meter) for overland flow.
zonal_drnr_km[is.na(zonal_drnr_km)] <- 0.1  

zonal_area_km2 <- aggregate(grid_area_km2, fact = ResFactor, fun = sum, na.rm=TRUE)
drainge_dens1 <- zonal_drnr_km / zonal_area_km2
drainge_dens1[is.na(drainge_dens1)] <- 0

#! the reverse funtion is applied to be consistent with MESH format
drainge_dens <- apply(as.matrix(drainge_dens1), 2, rev)

### Creating MESH Parameter and export it to r2c -----------

## header 
projection_value <- ":Projection              LATLONG   "
Ellipsoid_value <- ":Ellipsoid               GRS80 "

xorigin_value <- paste(":xOrigin                 ", LLXcorner, sep = "")
yorigin_value <- paste(":yOrigin                 ", LLYcorner, sep = "")
xcount_value <- paste(":xCount                   ", NumCol, sep = "")
ycount_value <- paste(":yCount                   ", NumRow, sep = "")
xdelta_value <- paste(":xDelta                   ", XRes, sep = "")
ydelta_value <- paste(":yDelta                   ", YRes, sep = "")


if (MESHVersion == "Mountain") {
  ### Combine soil, elevation, slope, aspect, delta, delta_elev_max, curve and drainage density for MESH_parameters file
  soilelevnslopeaspectdeltacurvedraindens <- rbind(soildatabase,elevnslopeaspectdeltacurve,drainge_dens)
} else {
  ### Combine Soil, slope and drainage density for MESH_parameters file
  # I modified this section 
  soilgridslopedraingedens <- rbind(soildatabase,gridslope,drainge_dens)
  #soilelevnslopeaspectdeltacurvedraindens <- rbind(soildatabase,gridslope,drainge_dens)
}
### write header ###
header1 <- "#########################################################################"
filetype <- ":FileType r2c  ASCII  EnSim 1.0"
header1 <- c(header1, filetype, "#")
owner <- "# National Research Council Canada (c) 1998-2014"
header1 <- c(header1, owner)
datatype <- "# DataType                 2D Rect Cell"
header1 <- c(header1, datatype, "#")
application <- ":Application    MESH  "
header1 <- c(header1, application)
version <- ":Version    1.0.0"
header1 <- c(header1, version)
written_by <- ":WrittenBy    Ala Bahrami"
header1 <- c(header1, written_by)
creation_date <- paste(":CreationDate ", date(), sep = "")
header1 <- c(header1, creation_date, "#", "#------------------------------------------------------------------------", "#", "#")
header1 <- c(header1, projection_value)
header1 <- c(header1, Ellipsoid_value, "#")
header1 <- c(header1, xorigin_value, yorigin_value, "#")
##
if (MESHVersion == "Mountain") {
  #  
  for (i in 1:NSL) {
    j <- i 
    attributename <- paste(":AttributeName ", j, " Clay	", i, "")
    header1 <- c(header1, attributename)
    attributeunits <- paste(":AttributeUnits ", j, " % ")
    header1 <- c(header1, attributeunits)
  }
  #
  for (i in 1:NSL) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " Sand	", i, "")
    header1 <- c(header1, attributename)
    attributeunits <- paste(":AttributeUnits ", j, " % ")
    header1 <- c(header1, attributeunits)
  }
  #
  for (i in 1:maxValue(grus1)) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " elevation	", i, "")
    header1 <- c(header1, attributename)
  }
  #
  for (i in 1:maxValue(grus1)) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " slope	", i, "") 
    header1 <- c(header1, attributename)
  }
  #
  for (i in 1:maxValue(grus1)) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " aspect	", i, "")
    header1 <- c(header1, attributename)
  }
  #
  for (i in 1:maxValue(grus1)) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " delta	", i, "") 
    header1 <- c(header1, attributename)
  }
  #
  for (i in 1:maxValue(grus1)) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " delta_elevmax	", i, "") 
    header1 <- c(header1, attributename)
  }
  #
  for (i in 1:maxValue(grus1)) {
    j <- j + 1
    attributename <- paste(":AttributeName ", j, " curvature	", i, "") 
    header1 <- c(header1, attributename)
  }
  #
  j <- j + 1
  attributename <- paste(":AttributeName ", j, " dd	")
  header1 <- c(header1, attributename)
  attributeunits <- paste(":AttributeUnits ", j, " km km-2 ")
  header1 <- c(header1, attributeunits)
  #
  header1 <- c(header1, "#", xcount_value, ycount_value, xdelta_value, ydelta_value, "#")
  header1 <- c(header1, ":EndHeader")
  
  eol <- "\n"
  con <- file(paste0(BasinName,MESHVersion,"_MESH_parameters.r2c"), open = "w")
  writeLines(header1, con = con, sep = eol)
  close(con)
  
  for (row in 1:nrow(soilelevnslopeaspectdeltacurvedraindens)) {
    mountainparams <- formatC(soilelevnslopeaspectdeltacurvedraindens[row, ],
                              digits = 6, width = 1,
                              format = "f")
    cat(mountainparams, "\n", sep = "  ", file = paste0(BasinName,MESHVersion,"_MESH_parameters.r2c"), append = TRUE)
  }
} else {
  
  # CLAY 
  j <- 1
  attributename <- paste(":AttributeName ", j, " Clay	")
  header1 <- c(header1, attributename)

  for (i in 1:NSL) {
    j <- j + 1 
    if (i < NSL){
      attributename <- paste(":AttributeName ", j, " Clay	", i, "")
      header1 <- c(header1, attributename)
    }
  }

  # SAND
  #j <- j + 1
  attributename <- paste(":AttributeName ", j, " Sand	")
  header1 <- c(header1, attributename)

  for (i in 1:NSL) {
    j <- j + 1
    if (i < NSL){
      attributename <- paste(":AttributeName ", j, " Sand	", i, "")
      header1 <- c(header1, attributename) 
    }
  }
  
  # Organic 
  #j <- j + 1
  attributename <- paste(":AttributeName ", j, " orgm	")
  header1 <- c(header1, attributename)

  for (i in 1:NSL) {
    j <- j + 1
    if (i < NSL){
      attributename <- paste(":AttributeName ", j, " orgm	", i, "")
      header1 <- c(header1, attributename)
    }
  }
  
  # SDEP
  #j <- j + 1
  attributename <- paste(":AttributeName ", j, " SDEP	")
  header1 <- c(header1, attributename)
  attributeunits <- paste(":AttributeUnits ", j, " m ")
  header1 <- c(header1, attributeunits)
  
  # xslp
  j <- j + 1
  attributename <- paste(":AttributeName ", j, " xslp	")
  header1 <- c(header1, attributename)
  attributeunits <- paste(":AttributeUnits ", j, " m/m ")
  header1 <- c(header1, attributeunits)
  
  # dd
  j <- j + 1
  attributename <- paste(":AttributeName ", j, " dd	")
  header1 <- c(header1, attributename)
  attributeunits <- paste(":AttributeUnits ", j, " km km-2 ")
  header1 <- c(header1, attributeunits)
  #
  header1 <- c(header1, "#", xcount_value, ycount_value, xdelta_value, ydelta_value, "#")
  header1 <- c(header1, ":EndHeader")
  
  eol <- "\n"
  con <- file(paste0(BasinName,MESHVersion,"_MESH_parameters.r2c"), open = "w")
  writeLines(header1, con = con, sep = eol)
  close(con)
  
  for (row in 1:nrow(soilgridslopedraingedens)) {
    mountainparams <- formatC(soilgridslopedraingedens[row, ],
                              digits = 6, width = 1,
                              format = "f")
    cat(mountainparams, "\n", sep = "  ", file = paste0(BasinName,MESHVersion,"_MESH_parameters.r2c"), append = TRUE)
  }
}
