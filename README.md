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

## calc_gdd.R
Calculate Growing Degree Days by avarage model with thresholds. Function requires these arguments:
- `x` - Data frame with temperatures
- `temp_max` - Column with maximum temperature
- `temp_min` - Column with minimum temperature
- `temp_base` (= 10) - Base temperature (minimum threshold value)
- `temp_limit` (= 30) - Temperature limit (maximum threshold value)

**Example**
``` r
max2011 = as.vector(temp_max_day[, 1:5])
min2011 = as.vector(temp_min_day[, 1:5])
df2011 = data.frame(temp_max = max2011, temp_min = min2011)
df2011 = na.omit(df2011)
sum(calc_gdd(df2011, temp_max, temp_min, temp_base = 8, temp_limit = 28))
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

## meteo.R - download.meteo()
Download selected meteorological data for the specified time period and station from [IMGW](https://dane.imgw.pl/). Doesn't support 2000 and earlier years. Function requires these arguments:
- `dates_list` - List with dates, use create_dates_list function 
- `station` - Name of the meteorological station, see station_list
- `variable` - Meteorological variable, see accordingly meteo_day_list or meteo_month_list in raw code

**Example**
``` r
temp_max_day <- download.meteo(dates_list,
                               station_list[station_list$name == "Poznan"],
                               meteo_day_list$temp_max)
temp_avg_month <- download.meteo(dates_list,
                                 station_list[station_list$name == "Poznan"],
                                 meteo_month_list$temp_avg)
```
To create a list of dates based on the specified time interval use `create_dates_list(from_month, to_month, year)`:
- `from_month` - Start month in format "mm"
- `to_month` - End month in format "mm"
- `year` - Range of years in format c(yyyy:yyyy)

**Example**
``` r
dates_list <- create_dates_list("05", "09", c(2011:2016))
```

To transform downloaded meteo data to long or joint format use `transform.meteo(meteo_data, purpose)`:
- `meteo_data` - Data from download.meteo function
- `purpose` - "visualize" for long format or "join" for joint format

**Example**
``` r
temp_min_day = transform.meteo(temp_min_day, "visualize")
temp_avg_month = transform.meteo(temp_avg_month, "join")
```

## calibration.py
Script to calibrate satellite images from Sentinel 2 using sen2cor. It supports multiple cores, but parallel processing can be turned off. To run set the correct settings and paths.
