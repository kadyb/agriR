#' @title
#' Calculate Growing Degree Days
#'
#' @description
#' Calculate Growing Degree Days (GDD) using average model
#' with thresholds including maximum and minimum temperatures.
#'
#' @param temp_max maximum temperature; numeric
#' @param temp_min minimum temperature; numeric
#' @param temp_base base temperature (minimum threshold value); numeric
#' @param temp_limit temperature limit (maximum threshold value, default = 30);
#' numeric
#'
#' @return vector with cumulative sum of GDD; numeric
#'
#' @examples
#' set.seed(1)
#' temp_max = runif(n = 100, min = 10, max = 35)
#' temp_min = runif(n = 100, min = -10, max = 10)
#' x = gdd(temp_max, temp_min, temp_base = 5)
#'
#' # return total sum
#' x[length(x)]
gdd = function(temp_max, temp_min, temp_base, temp_limit = 35) {

  if (length(temp_max) != length(temp_min)) {
    stop("vectors have different lengths")
  }

  n = length(temp_max)
  output = double(n)
  for (i in seq_len(n)) {

    if ((temp_max[i] + temp_min[i]) / 2 < temp_base) {
      output[i] = 0
    }

    else {

      if (temp_min[i] < temp_base) {
        temp_min[i] = temp_base
      }

      if (temp_max[i] > temp_limit) {
        temp_max[i] = temp_limit
      }

      gdd_val = (temp_max[i] + temp_min[i]) / 2 - temp_base
      output[i] = gdd_val

    }

  }

  return(cumsum(output))

}
