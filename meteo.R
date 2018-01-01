

station_list <- list(
   Poznan = "352160330"
)

meteo_list <- list(
   temp_max_day = "B100B008BD", # Maksymalna temperatura powietrza-doba-synop
   temp_min_day = "B100B008AD", # Minimalna temperatura powietrza-doba-synop
   temp_avg_day = "B100B008CD", # Średnia temperatura powietrza-doba-synop
   rainfall_sum_day = "B600B008FD", # Suma opadu - deszcz-doba-synop
   
   temp_avg_month = "B100B016CM", # Średnia temperatura powietrza-miesiąc-synop
   temp_min_avg_month = "B100B016DM", # Średnia temperatura minimalna-miesiąc-synop
   temp_max_avg_month = "B100B016EM", # Średnia temperatura maksymalna-miesiąc-synop
   temp_ground_min_month = "B110B016AM", # Minimalna temperatura przy powierzchni gruntu-miesiąc-synop
   rainfall_sum_month = "B600B016FM" # Suma opadu-miesiąc-synop
)

# Example URLs:
# https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/2016/dane_2016_01_149180010.csv.gz
# https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/2017/dane_2017_od01_do06_149180010.csv.gz
# This data isn't verified. This is not CBDH.

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

dates_list <- create_dates_list("05-01", "09-30", c(2011:2016))

##########################
##########################

#online read function:
#
#download <- function(year, month, station) {
#   #con <- gzcon(url(create_URL))
#   con <- gzcon(url("https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/2016/dane_2016_01_352160330.csv.gz"))
#   txt <- readLines(con)
#   dat <- read.table(textConnection(txt), header = FALSE, sep = ";",
#                     colClasses = c("NULL", NA, NA, NA))
#}



download <- function(dates_list, station, variable) {
   result <- NULL
   
   create_URL <- function(year, month, station) {
      paste0("https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/", year, "/",
             month, "/", "dane_", year, "_", month, "_", station, ".csv.gz")
   } 
   
   for (date in dates_list) {
      year <- substr(date, 1, 4)
      month <- substr(date, 6, 7)
      
      url <- create_URL(year, month, station)
      tmp <- tempfile()
      download.file(url, tmp, quiet = TRUE)
      # read.table with these parametrs is faster than read.csv
      dat <- read.table(tmp, header = FALSE, sep = ";", stringsAsFactors = FALSE,
                        colClasses = c("NULL", NA, NA, NA))
      unlink(tmp)
      dat_sel <- dat[dat$V3 == variable, ]
      result <- rbind(result, dat_sel)
   }
   
   names(result) <- c("date", "variable", "value")
   return(result)
}

#create_URL(year, month, station_list$Poznan)

#temp_max_day_list <- download(dates_list[29:30], 
#                              station_list$Poznan, 
#                              meteo_list$temp_max_day)

#temp_avg_month_list <- download(dates_list[29:30],
#                                station_list$Poznan,
#                                meteo_list$temp_avg_month)


