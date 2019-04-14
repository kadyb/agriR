# The script is used to iterate image processing from the Sentinel 2 satellites.
# The result is a data frame containing the object name, date and reflection 
# values in the all spectral channels of 10 and 20 m in point localizations.

# Enter the path to the folder with the scenes.
# Enter the name of the attribute column containing the names of the point objects.
# Set pixel values (classes) to be omitted in the analysis.

library("raster")
library("rgdal")

#######
### Configuration
main_catalog = 'C:/Images'
col_name = 'Object_name'
# Pixels class to mask
px_off = c(1, 3, 9, 10)
# Pixel class:
# 0 = no_data, 1 = saturated_or_defective, 2 = dark_area_pixels, 3 = cloud_shadows,
# 4 = vegetation, 5 = not_vegetated, 6 = water, 7 = unclassified, 
# 8 = cloud_medium_probability, 9 = cloud_high_probability, 10 = thin_cirrus,
# 11 = snow

#######
### Processing
if(!(all(px_off %in% seq(1, 11, 1)))) stop("Incorrect pixel class")

list_dir = list.dirs(main_catalog, recursive = FALSE)
list_dir_rec = list.dirs(main_catalog, recursive = TRUE)

output = data.frame()

for(i in 1:length(list_dir)) {

   cat(i, "/", length(list_dir), ":", "\n", sep = "")
   cat(list_dir[i], "\n")
   
   scene_name = substr(list_dir[i], (nchar(list_dir[i]) + 1) - 60, nchar(list_dir[i]))
   if(nchar(scene_name)!=60) stop("Incorrect scene name")
   date = as.Date(substr(scene_name, 12, 19), format = "%Y%m%d")
   date = format(date, "%d-%m-%Y")
   
   # Read shapefile
   shapefile_name = list.files(list_dir[i], pattern = "\\.shp$")
   shapefile_name = substr(shapefile_name, 1, nchar(shapefile_name) - 4)
   if(length(shapefile_name)!=1) stop("There should be one shapefile")
   shape = readOGR(dsn = list_dir[i], layer = shapefile_name, verbose = FALSE)
   if(class(shape)[1] != "SpatialPointsDataFrame") stop("This is not a point layer")
   if(!(col_name %in% names(shape))) stop("Incorrect feature name column")
   
   list_dir_10m = list_dir_rec[grepl("R10m", list_dir_rec)][i]
   list_dir_20m = list_dir_rec[grepl("R20m", list_dir_rec)][i]
   
   # 4 bands - 10 m
   imgs_path_10m = list.files(list_dir_10m, ".+B0[2348]+.+\\.jp2$", full.names = TRUE)
   if(length(imgs_path_10m)!=4) stop("Incorrect number of 10 m bands")
   
   # 6 bands - 20 m
   imgs_path_20m = list.files(list_dir_20m, ".+B(05|06|07|8A|11|12)+.+\\.jp2$",  full.names = TRUE)
   if(length(imgs_path_20m)!=6) stop("Incorrect number of 20 m bands")
   
   # Scene classification
   sc_path = list.files(list_dir_20m, ".+SCL.+\\.jp2$",  full.names = TRUE)
   if(length(sc_path)!=1) stop("There should be one scene classification raster")
   sc_raster_20m = raster(sc_path)
   # Compare CRS
   if(compareCRS(shape, sc_raster_20m) == FALSE){
      stop("Different CRS")
   } else {
      sc_raster_20m = crop(sc_raster_20m, bbox(shape), snap = 'out')
   }
   
   # Raster reclassification
   for(px_class in 0:11) {
      if(!(px_class %in% unique(sc_raster_20m))) {
         next
      } else if(px_class %in% px_off & px_class %in% unique(sc_raster_20m)) {
         sc_raster_20m[sc_raster_20m == px_class] = 1
      } else if (!(px_class %in% px_off) & px_class %in% unique(sc_raster_20m)) {
         sc_raster_20m[sc_raster_20m == px_class] = 0
      } else {
         stop("Raster reclassification went wrong")
      }
   }
   
   
   stack_10m = stack(imgs_path_10m)
   stack_10m = crop(stack_10m, bbox(shape), snap = 'out')
   
   stack_20m = stack(imgs_path_20m)
   stack_20m = crop(stack_20m, bbox(shape), snap = 'out')
   
   sc_raster_10m = resample(sc_raster_20m, stack_10m, method = "ngb")
   
   stack_10m = mask(stack_10m, sc_raster_10m, maskvalue = 1)
   values_df_10m = extract(stack_10m, shape, df = TRUE)
   
   stack_20m = mask(stack_20m, sc_raster_20m, maskvalue = 1)
   values_df_20m = extract(stack_20m, shape, df = TRUE)
   
   feature_col = paste0("shape@data$", col_name)
   
   # Merge and transform 10 m and 20 m data frames
   merged_df = merge(values_df_10m, values_df_20m, by = "ID")
   merged_df = cbind(object_name = eval(parse(text = feature_col)), merged_df)
   merged_df = cbind(date = date, merged_df, stringsAsFactors = FALSE)
   merged_df = cbind(scene_name = scene_name, merged_df, stringsAsFactors = FALSE)
   merged_df["ID"] = NULL
   colnames(merged_df)[4:13] = substr(colnames(merged_df)[4:13], (nchar(colnames(merged_df)[4:13]) + 1) - 7, nchar(colnames(merged_df)[4:13]))
   
   output = rbind(output, merged_df)
   }

