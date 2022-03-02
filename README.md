# agriR
Tools for processing raster and meteorological data related to agriculture

## RGB_transform.R
Transform RGB to HSV, HSI and HSL color space. Function requires these arguments:
- `R` - Red channel
- `G` - Green channel
- `B` - Blue channel
- `norm_val` - Divider to normalize input values (they can not exceed 1 after dividing)

**Example**
``` r
RGB_transform = Vectorize(RGB_transform)
sample_data = data.frame(R = c(runif(10, 0, 255)), 
                         G = c(runif(10, 0, 255)),
                         B = c(runif(10, 0, 255)))
data_transformed = RGB_transform(sample_data$R, sample_data$G, sample_data$B, 255)
data_transformed = data.frame(t(data_transformed)) # transpose matrix
```

## gdd.R
Calculate Growing Degree Days by avarage model with thresholds. Function requires these arguments:
- `temp_max` - maximum temperature; numeric
- `temp_min` - minimum temperature; numeric
- `temp_base` - base temperature (minimum threshold value); numeric
- `temp_limit` - temperature limit (maximum threshold value, default = 30); numeric

**Example**
``` r
temp_max = runif(n = 100, min = 10, max = 35)
temp_min = runif(n = 100, min = -10, max = 10)
x = gdd(temp_max, temp_min, temp_base = 5)
```

## merge_bbox.R
Merge bounding boxes of two vector layers. The layer can contain several objects. The distance between them must be less than 20 km. Function requires these arguments:
- `vlayer1` - First sf layer
- `vlayer2` - Second sf layer

**Example**
``` r
vlayer1 = st_read("path_to_polygon1")
vlayer2 = st_read("path_to_polygon2")
merged_bbox = merge_bbox(vlayer1, vlayer2)
```

## meteo.R - download.meteo(dates_list, station, variable)
Download selected meteorological data for the specified time period and station from [IMGW](https://dane.imgw.pl/). Doesn't support 2000 and earlier years. Function requires these arguments:
- `dates_list` - List with dates, use create_dates_list function 
- `station` - Name of the meteorological station, see station_list
- `variable` - Meteorological variable, see accordingly meteo_day_list or meteo_month_list in raw code

**Example**
``` r
temp_max_day = download.meteo(dates_list,
                              station_list[station_list$name == "Poznan"],
                              meteo_day_list$temp_max)
temp_avg_month = download.meteo(dates_list,
                                station_list[station_list$name == "Poznan"],
                                meteo_month_list$temp_avg)
```
To create a list of dates based on the specified time interval use `create_dates_list(from_month, to_month, year)`:
- `from_month` - Start month in format "mm"
- `to_month` - End month in format "mm"
- `year` - Range of years in format c(yyyy:yyyy)

**Example**
``` r
dates_list = create_dates_list("05", "09", c(2011:2016))
```

To transform downloaded meteo data to long or joint format use `transform.meteo(meteo_data, purpose)`:
- `meteo_data` - Data from download.meteo function
- `purpose` - "visualize" for long format or "join" for joint format

**Example**
``` r
temp_min_day = transform.meteo(temp_min_day, "visualize")
temp_avg_month = transform.meteo(temp_avg_month, "join")
```

## spectralTools.R - interpretQA(x, cloud, shadow, cirrus, sensor)
Creates a raster with decoded quality conditions classes from Landsat 4-8 scenes. Function requires these arguments:
- `x` - Pixel_qa raster 
- `cloud` (default = "high") - Level of confidence of pixels containing clouds ("high", "medium", "low")
- `shadow` (default = TRUE) - Include pixels containing shadows (TRUE, FALSE)
- `cirrus` (default = "high") - Level of confidence of pixels containing cirrus ("high", "medium", "low")
- `sensor` - Name of sensor ("landsat8", "landsat7")

**Example**
``` r
ras = raster("LE07_L1TP_191023_20130703_20161123_01_T1_pixel_qa.tif")
test = interpretQA(ras, sensor = "landsat7")
writeRaster(test, filename = "test.tif")
```

To iterative processing through folders and save results to files use `create_mask(folders)`:
- `folders` - List with names of directories

**Example**
``` r
folders = list.dirs("Scenes")
folders = folders[-1] # skip the main folder
create_mask(folders[5:10]) # you can choose which folders exactly
```

## spectralTools.R - cloud.list(folders, shape, cloudiness)
Returns data frame with useful (below the threshold value) and useless (above the threshold value) satellite scenes. This is average cloudiness for all features. Function requires these arguments:
- `folders` - List with names of directories
- `shape` - Vector shape
- `cloudiness` (default = 0.6) - Level of cloudiness from 0 to 1

**Example**
``` r
shape = readOGR("shape.shp")
test_clouds = cloud.list(folders, shape) # folders have been set before
test_clouds
```

## spectralTools.R - calculate_stats(folders, shape)
Returns the data frame with mean and median value of spectral indicies for each feature. Function requires these arguments:
- `folders` - List with names of directories
- `shape` - Vector shape

**Example**
``` r
test_stats = calculate_stats(folders, shape) # folders and shape have been set before
write.csv2(test_stats, file = "results.csv", row.names = FALSE)
```

## calibration.py
Script to calibrate satellite images from Sentinel 2 using sen2cor. It supports multiple cores, but parallel processing can be turned off. To run set the correct settings and paths by script edit.
