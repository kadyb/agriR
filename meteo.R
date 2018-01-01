station_list <- data.frame(
   # Use long_ID for month interval
   # Use short_ID for day interval
   name = "Poznan", 
   long_ID = "352160330", 
   short_ID = "330"
)

meteo_day_list <- list(
   # dane meteorologiczne -> dobowe -> synop -> sd:
   temp_max = 6, # Maksymalna temperatura dobowa
   temp_min = 8, # Minimalna temperatura dobowa 
   temp_avg = 10, #  Średnia temperatura dobowa
   temp_ground_min = 12, # Temperatura minimalna przy gruncie
   rainfall_sum = 14, # Suma dobowa opadów
   sunshine = 21 # Usłonecznienie
)

meteo_month_list <- list(
   # dane meteorologiczne -> miesieczne -> synop -> smd:
   temp_max_avg = 7, # Średnia temperatura maksymalna 
   temp_min_avg = 11, # Średnia temperatura minimalna
   temp_avg_month = 13, # Średnia temperatura miesięczna
   temp_ground_min = 15, # Minimalna temperatura przy gruncie
   rainfall_sum = 17, # Miesięczna suma opadów
   sunshine = 23 # Miesięczna suma usłonecznienia
)

# Example URLs:
# https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_meteorologiczne/dobowe/synop/2011/2011_330_s.zip
# https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_meteorologiczne/miesieczne/synop/2015/2015_s_m.zip
# This data is verified. This came from CBDH.

#-----------------------------------------------

create_dates_list <- function(from, to, years) {
   dates_list <- NULL
   
   for(year in years) {
      dates <- seq(as.Date(paste0(year, "-", from)), 
                   as.Date(paste0(year, "-", to)), 
                   "month")
      dates_list_tmp <- as.character(dates)
      dates_list <- append(dates_list, dates_list_tmp)
   }
   
   return(dates_list)
}

# Info:
### Creates a list of dates based on the specified time interval
# Input:
### from - start date in format "dd-mm"
### to - end date in format "dd-mm"
### year - range of years in format c(yyyy:yyyy)

# Example:
#dates_list <- create_dates_list("05-01", "09-30", c(2011:2016))

#-----------------------------------------------

download.meteo <- function(dates_list, station, variable) {
   result <- NULL
   
   create_URL <- function(year, station, variable) {
      if (variable %in% meteo_day_list) {
         paste0("https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_meteorologiczne/dobowe/synop/", 
                year, "/", year, "_", station[,3], "_s", ".zip")
      }
      
      else if (variable %in% meteo_month_list) {
         paste0("https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_meteorologiczne/miesieczne/synop/", 
                year, "/", year, "_m_s", ".zip")
      }
      
      else stop("Meteo list is incorrect. Should be meteo_day_list or meteo_month_list")
   } 
   
   for (date in dates_list) {
      year <- substr(date, 1, 4)
      month <- as.numeric(substr(date, 6, 7))
      
      url <- create_URL(year, station, variable)
      tmp <- tempfile()
      download.file(url, tmp, quiet = TRUE)
      
      if (variable %in% meteo_day_list) {
         # Uznip data
         dat_unz <- unz(tmp, paste0("s_d_", station[,3], "_", year, ".csv"))
      }
      
      else if (variable %in% meteo_month_list) {
         dat_unz <- unz(tmp, paste0("s_m_d_", year, ".csv"))
      }
      
      dat <- read.csv2(dat_unz, header = FALSE, sep = ",", stringsAsFactors = FALSE)
      unlink(tmp)
      
      if (variable %in% meteo_day_list) {
         dat_sel <- dat[dat$V4 == month, variable] # Choose the correct month from dates_list
         length(dat_sel) <- 31 # No month has no more than 31 days
      }
      
      else if (variable %in% meteo_month_list) {
         dat_sel <- dat[dat$V1 == station[,2] & dat$V4 == month, variable] # Also choose the correct station
      }
      
      result <- cbind(result, as.numeric(dat_sel))
   }
   
   colnames(result) <- substr(dates_list, 1, 7)
   return(result)
}

# Test create_URL:
#create_URL(2011, station_list[station_list$name == "Poznan"], meteo_day_list$temp_max)
#create_URL(2015, station_list[station_list$name == "Poznan"], meteo_month_list$temp_max_avg)

# Info:
### Download selected meteorological data for the specified time period and station
### Doesn't support 2000 or earlier years
# Input:
### dates_list - list with dates, use create_dates_list function 
### station - name of the meteorological station, see station_list
### variable - meteorological variable, see accordingly meteo_day_list or meteo_month_list

# Example:
#temp_min_day <- download.meteo(dates_list,
#                               station_list[station_list$name == "Poznan"],
#                               meteo_day_list$temp_min)
#temp_avg_month <- download.meteo(dates_list,
#                                 station_list[station_list$name == "Poznan"],
#                                 meteo_month_list$temp_avg)

#-----------------------------------------------

transform.meteo <- function(meteo_data, purpose) {
   library("tidyr")
   
   if (purpose == "visualize") {
      meteo_dat <- as.data.frame(meteo_data) %>%
         gather(Date, Value) %>%
         separate(Date, c("Year", "Month"))
      
      meteo_dat$Month <- as.numeric(meteo_dat$Month)
      meteo_dat$Year <- as.factor(meteo_dat$Year)
   }
   
   else if(purpose == "join" & dim(meteo_data)[1] == 1) {
      meteo_dat <- as.data.frame(meteo_data) %>%
         gather(Date, Value) %>%
         separate(Date, c("Year", "Month")) %>%
         spread(Month, Value)
      
      name.col <- deparse(substitute(meteo_data))
      colnames(meteo_dat)[-1] <- paste0(name.col, colnames(meteo_dat)[-1])
      colnames(meteo_dat)[-1] <- sub("month", "", colnames(meteo_dat)[-1])
      meteo_dat$Year <- as.factor(meteo_dat$Year)
   }
   
   else stop ("Choose right purpose.")
   
   return(meteo_dat)
}

# Info:
### Transfor meteo data to long or joint format
# Input:
### meteo_data - data from download.meteo function
### purpose - "visualize" for long format or "join" for joint format

# Example:
#temp_min_day <- transform.meteo(temp_min_day, "visualize")
#temp_avg_month <- transform.meteo(temp_avg_month, "join")



