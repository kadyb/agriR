# Avarage model with thresholds:
### IF (TEMP_MAX + TEMP_MIN)/2 < TEMP_BASE, THEN GSD = 0, ELSE:
   ### IF TEMP_MAX > TEMP_LIMIT, THEN TEMP_MAX = TEMP_LIMIT
   ### IF TEMP_MIN < TEMP_BASE, THEN TEMP_MIN = TEMP_BASE
      ### GSD = (TEMP_MAX + TEMP_MIN)/2 - TEMP_BASE

calc_gdd <- function(x, temp_max, temp_min, temp_base = 10, temp_limit = 30) {
  
   gdd_list <- NULL
  
   for (i in 1:nrow(x)){
      
      if ((x$temp_max[i] + x$temp_min[i])/2 < temp_base) {
         gdd_list <- append(gdd_list, 0)
      }
   
      else {
         if (x$temp_min[i] < temp_base & x$temp_max[i] > temp_limit) {  
            x$temp_min[i] <- temp_base 
            x$temp_max[i] <- temp_limit
         }
         
         else if (x$temp_min[i] < temp_base) {
            x$temp_min[i] <- temp_base
         }
         
         else if (x$temp_max[i] > temp_limit) {
            x$temp_max[i] <- temp_limit
         }
      
         gdd_list <- append(gdd_list,(x$temp_max[i] + x$temp_min[i])/2 - temp_base)
      }
   }
  
   return(gdd_list)
}

# Info:
### Calculate Growing Degree Days
# Input:
### x - data frame with temperatures
### temp_max - Column with maximum temperature
### temp_min - Column with minimum temperature
### temp_base (= 10) - Base temperature (minimum threshold value)
### temp_limit (= 30) - Temperature limit (maximum threshold value)

# Example:
#max2011 <- as.vector(temp_max_day[, 1:5])
#min2011 <- as.vector(temp_min_day[, 1:5])
#df2011 <- data.frame(temp_max = max2011, temp_min = min2011)
#df2011 <- na.omit(df2011)
#sum(calc_gdd(df2011, temp_max, temp_min, temp_base = 8, temp_limit = 28))


