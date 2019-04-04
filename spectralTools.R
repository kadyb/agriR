library("rgdal")
library("dplyr")
library("tidyr")
library("purrr")
library("raster")



interpretQA <- function(x, cloud="high", shadow=TRUE, cirrus="high", sensor) {
   
   # Pixel classification is based on:
   # https://landsat.usgs.gov/landsat-surface-reflectance-quality-assessment
   
   if(canProcessInMemory(x, 3) == FALSE)
      stop("Error: Raster is too big. Try to change rasterOptions() maxmemory")
   
   ### Extracting QA Band bits
   decode <- function(value) {
      if (!is.na(value)) {
         bit <- intToBits(value)
         decoded <- paste(tail(rev(as.integer(bit)), 16), collapse="")
      }
      else {
         decoded <- NA
      }
      
      return(decoded)   
   }
   
   ### Reclassify decoded bits to classes
   reclass <- function(decoded, cloud, shadow, cirrus, sensor) {
      switch(cloud,
             "high" = cloud <- 11,
             "medium" = cloud <- 10,
             "low" = cloud <- 01)
      if (shadow == TRUE) {
         shadow <- 1
      }
      if (sensor == "landsat8") {
         switch(cirrus,
                "high" = cirrus <- 11,
                "medium" = cirrus <- 10,
                "low" = cirrus <- 01)
      }
      
      decoded[as.numeric(substr(decoded, 9, 10)) == cloud]  <- 1
      decoded[as.numeric(substr(decoded, 13, 13)) == shadow]  <- 1
      decoded[as.numeric(substr(decoded, 7, 8)) == cirrus] <- 1
      decoded[is.na(decoded)] <- 1
      decoded[decoded!=1] <- 0
      return(as.numeric(decoded))
   }
   
   v <- getValues(x)
   out <- raster(x)
   vs <- map_chr(v, decode)
   class <- reclass(vs, cloud, shadow, cirrus, sensor)
   out[] <- class
   return(out)
}

# Info:
### Creates a raster with decoded quality conditions classes.
# Input:
### x - pixel_qa raster 
### cloud - level of confidence of pixels containing clouds ("high", "medium", "low")
### shadow - include pixels containing shadows (TRUE, FALSE)
### cirrus - level of confidence of pixels containing cirrus ("high", "medium", "low")
### sensor - name of sensor ("landsat8", "landsat7")

# Example:
#ras <- raster("LE07_L1TP_191023_20130703_20161123_01_T1_pixel_qa.tif")
#test <- interpretQA(ras, sensor = "landsat7")
#writeRaster(test, filename = "test.tif")

#-----------------------------------------------

create_mask <- function(folders) {
   iterator <- 0
   pb <- txtProgressBar(min = 0, max = length(folders), style = 3)
   
   for (folder in folders) {
      iterator <- iterator + 1
      ras <- raster(list.files(folder, pattern = "pixel_qa", full.names = TRUE))
      
      if (length(list.files(folder, pattern = "LC08"))!=0) {
         sensor <- "landsat8"
      }
      if (length(list.files(folder, pattern = "LE07"))!=0) {
         sensor <- "landsat7"
      }
      
      out <- interpretQA(ras, sensor = sensor)
      writeRaster(out, filename = paste0(folder, "/", "Clouds.tif"), overwrite = TRUE)
      setTxtProgressBar(pb, iterator)
   }
   close(pb)
   print("Done.")
}   

# Info:
### Save cloud mask to Clouds.tif file in the relevant folders.
# Input:
### folders - list with names of directories


# Example:
#folders <- list.dirs("Scenes")
#folders <- folders[-1]
#create_mask(folders[1])

#-----------------------------------------------

cloud.list <- function(folders, shape, cloudiness = 0.6) {
   
   iterator <- 0
   pb <- txtProgressBar(min = 0, max = length(folders), style = 3)
   
   out <- list(skip_scenes = NULL, useful_scenes = NULL)
   
   #Data frame structure is faster than data.frame create function
   skip_scenes <- structure(list(Name = character(), 
                                 Percentage = integer()),
                            class = "data.frame")
   useful_scenes <- structure(list(Name = character(), 
                                   Percentage = integer()),
                              class = "data.frame")
   
   for (folder in folders) {
      
      iterator <- iterator + 1
      all_pixels <- 0
      cloud_pixels <- 0
      cloud_value <- 0
      
      ras_mask <- raster(list.files(folder, pattern = "Clouds", full.names = TRUE))
      cloud_count <- raster::extract(ras_mask, shape)
      
      for (i in 1:length(cloud_count)) {
         
         cloud_value_poly <- sum(cloud_count[[i]] == 1)/length(cloud_count[[i]])
         if(cloud_value_poly > cloud_value) {
            cloud_value <- cloud_value_poly
         }    
         
         all_pixels <- all_pixels + length(cloud_count[[i]])
         cloud_pixels <- cloud_pixels + sum(cloud_count[[i]])
         cloud_percent <- cloud_pixels/all_pixels*100
         
      }
      
      if(cloud_value > cloudiness) {
         skip_scenes <- data.frame(Name = folder,
                                   Percentage = round(cloud_percent),
                                   stringsAsFactors = FALSE)
         
         out$skip_scenes <- rbind(out$skip_scenes, skip_scenes)
      }
      
      else {
         useful_scenes <- data.frame(Name = folder,
                                     Percentage = round(cloud_percent),
                                     stringsAsFactors = FALSE)
         
         out$useful_scenes <- rbind(out$useful_scene, useful_scenes)
      }
      
      setTxtProgressBar(pb, iterator)
   }
   
   close(pb)
   return(out)
}

# Info:
### Returns data frame with useful (below the threshold value) 
### and useless (above the threshold value) satellite scenes.
### This is average cloudiness for all features.
# Input:
### folders - list with names of directories
### shape - vector shape
### cloudiness - level of cloudiness from 0 to 1


# Example:
#shape <- readOGR("shape.shp")
#folders <- list.dirs("Scenes")
#folders <- folders[-1]
#test_clouds <- cloud.list(folders, shape)
#test_clouds

#-----------------------------------------------

calculate_stats <- function(folders, shape) {
   iterator <- 0
   pb <- txtProgressBar(min = 0, max = length(folders), style = 3)
   stats_all <- NULL
   
   for (folder in folders) {
      iterator <- iterator + 1
      
      images_list <- list.files(folder,
                                pattern = "evi|msavi|ndmi|ndvi|savi",
                                full.names = TRUE)
      rasters_stack <- stack(images_list)
      ras_mask <- raster(list.files(folder, pattern = "Clouds", full.names = TRUE))
      masked <- mask(rasters_stack, ras_mask, maskvalue = 1)
      data <- raster::extract(masked, shape, df = TRUE)
      stats <- data %>% 
         group_by(ID) %>% 
         summarise_all(funs(mean, median), na.rm = TRUE) %>% 
         gather(Scene, Value, -ID) %>% 
         separate(Scene, c("Scene", "Indicator"), sep = 44) %>% 
         spread(Indicator, Value)
      stats_all <- rbind(stats_all, stats)
      
      setTxtProgressBar(pb, iterator)
   }
   close(pb)
   return(stats_all)
}

# Info:
### Returns the data frame with mean and median value of spectral indicies
### for each feature.
# Input:
### folders - list with names of directories
### shape - vector shape


# Example:
#shape <- readOGR("shape.shp")
#folders <- test_clouds$useful_scenes$Name
#test_stats <- calculate_stats(folders, shape)
#write.csv2(test_stats, file = "results.csv", row.names=FALSE)