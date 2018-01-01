

station_list <- list(
   Poznan = "352160330"
)

meteo_list <- list(
   temp_max_day = "B100B008BD", #Maksymalna temperatura powietrza-doba-synop
   temp_min_day = "B100B008AD", #Minimalna temperatura powietrza-doba-synop
   temp_avg_day = "B100B008CD", #Średnia temperatura powietrza-doba-synop
   rainfall_sum_day = "B600B008FD", #Suma opadu - deszcz-doba-synop
   
   temp_avg_month = "B100B016CM", #Średnia temperatura powietrza-miesiąc-synop
   temp_min_avg_month = "B100B016DM", #Średnia temperatura minimalna-miesiąc-synop
   temp_max_avg_month = "B100B016EM", #Średnia temperatura maksymalna-miesiąc-synop
   temp_ground_min_month = "B110B016AM", #Minimalna temperatura przy powierzchni gruntu-miesiąc-synop
   rainfall_sum_month = "B600B016FM" #Suma opadu-miesiąc-synop
)

#Example URLs:
#https://dane.imgw.pl/1.0/pomiary/cbdh/352160330-B100B008BD/tydzien/2017-05-12?format=csv
#https://dane.imgw.pl/1.0/pomiary/cbdh/352160330-B100B008BD/doba/2017-05-12?format=csv


################################
################################

create_dates_list <- function(from, to, years, interval) {

   if(!(interval %in% c("week", "month")))
      stop("Incorrect time interval.")
   
   dates_list <- NULL
   
   for(year in years) {
      dates <- seq(as.Date(paste0(year, "-", from)), 
                   as.Date(paste0(year, "-", to)), 
                   interval)
      dates_list_tmp <- as.character(dates)
      dates_list <- append(dates_list, dates_list_tmp)
      }
   
   return(dates_list)
}

#dates_list <- create_dates_list("05-01", "09-30", c(2011:2016), "week")

################################
################################
login <- "..."
password <- "..."


download_data <- function(variable, dates_list, station) {
   
   create_URL <- function(variable, date, station) {
      paste0("https://", login, ":", password, "@", "dane.imgw.pl/1.0/pomiary/cbdh/", 
             station, '-', variable, '/tydzien/', date, '?format=csv')
   }
   
   result <- NULL
   iterator <- 0
   pb <- txtProgressBar(min = 0, max = length(dates_list), style = 3)
   for (date in dates_list) {
      iterator <- iterator + 1
      URL <- url(create_URL(variable, date, station))
      csv <- read.csv(URL, sep = ';')
      result <- rbind(result, csv)
      Sys.sleep(1)
      setTxtProgressBar(pb, iterator)
      }
      close(pb)
      return(result)
}

#create_URL(meteo_list$temp_max_day, "2011-06-12", station_list$Poznan)
#temp_max_day_list <- download_data(meteo_list$temp_max_day, dates_list[1:10], station_list$Poznan)



