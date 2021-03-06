#' retreive example type tiltometer file name
#'
#' @export
#' @return filename
example_filename <- function(){
  system.file("exampledata/2102053_LittleDrisko_TCM_Current.zip",
              package="tiltometer")
}

#' clip tiltometer table by date
#'
#' @export
#' @param x tibble, tiltometer
#' @param startstop POSIXt vector of two values or NA, only used if clip = "user"
#' @return tibble
clip_tiltometer <- function(x,
                          startstop = NA) {

  if (is.na(startstop)[1]) {
    x <- x %>% dplyr::mutate (Date = as.Date(.data$DateTime, tz = "UTC"),
                              DateNum = as.numeric(.data$DateTime))

    ix <- which(diff(x$Date) != 0)[1]  + 1
    firstday <- as.numeric(difftime(x$DateTime[ix], x$DateTime[1]))

    if (firstday < 23) {
      x <- x[-(1:(ix-1)),]
    }

    iix <- dplyr::last(which(diff(x$Date) != 0))  + 1
    lastday <- as.numeric(difftime(dplyr::last(x$DateTime),x$DateTime[iix]))

    if (lastday < 23) {
      x <- x[-((iix+1):nrow(x)),]
    }

    x <- x %>% dplyr::select(-.data$Date, -.data$DateNum)
  }


  if (!is.na(startstop)[1]) {
    x <- x %>%
      dplyr::filter(.data$DateTime >= startstop[1]) %>%
      dplyr::filter(.data$DateTime <= startstop[2])
  }

  x
}


#' read tiltometer data file
#'
#' @export
#' @param filename character, the name of the file
#' @param site character, site being read in
#' @param output character, the name for the outputted QAQC file
#' @param clipped character, if auto, removed partial start/end days. if user, uses supplied startstop days. if none, does no date trimming
#' @param startstop POSIXt vector of two values in UTC or NA, only used if clip = "user"
#' @return tibble
read_tiltometer <- function(filename = example_filename(),
                            site = NA,
                            output = NA,
                            clipped = c("auto", "user", "none")[1],
                            startstop = NA){
  stopifnot(inherits(filename, "character"))
  stopifnot(file.exists(filename[1]))
  x <- suppressMessages(readr::read_csv(filename[1], locale = readr::locale(tz = "Etc/GMT-4")))
  #cleaning up the header
  h <- colnames(x)
  lut <- c("ISO 8601 Time" = "DateTime",
           "Speed (cm/s)" = "speed",
           "Heading (degrees)" = "dir",
           "Velocity-N (cm/s)" = "v",
           "Velocity-E (cm/s)" = "u")
  colnames(x) <- lut[h]
#adapted from: https://stackoverflow.com/questions/8613237/extract-info-inside-all-parenthesis-in-r
  attr(x, "units") <- stringr::str_extract(h, "(?<=\\().*?(?=\\))")
  attr(x, "filename") <- filename[1]
  #use the spec attr for original colnames
  #attr(x, "original_colnames") <- h

  x <- x %>% dplyr::mutate(DateTime = lubridate::with_tz(x$DateTime, tzone = "UTC"))


  x <- switch(tolower(clipped[1]),
              "auto" = clip_tiltometer(x, startstop = NA),
              "user" = clip_tiltometer(x, startstop = startstop),
              "none" = x,
              stop("options for clipped are auto, user, or none. what is ", clipped, "?")
  )

  if (!is.na(site)) {x <- x %>% dplyr::mutate(Site = site)}

  #omit NAs from data
  x <- na.omit(x)

  if (!is.na(output)) {
    readr::write_csv(x, file = output) }

  return(x)

}


#' print out summary of tiltmeter data
#'
#' @export
#' @param x tibble, tibble of tiltmeter data
#' @return tibble
summarize_tiltometer<- function(x = read_tiltometer()){

  #remove any NA's before summarizing
  #remove all 0 PAR items when calculating mean

  x <- na.omit(x)

  s <- x %>% dplyr::group_by(.data$Site) %>%
    dplyr::summarise(mean.speed = mean(.data$speed),
                     first.day = dplyr::first(.data$DateTime),
                     last.day = dplyr::last(.data$DateTime),
                     max.speed = max(.data$speed),
                     max.speed.bearing = .data$dir[which.max(.data$speed)],
                     max.speed.date = .data$DateTime[which.max(.data$speed)])

  return(s)
}




#' read tiltometer temperature data file
#'
#' @export
#' @param filename character, the name of the file
#' @param site character, site being read in
#' @param output character, the name for the outputted QAQC file
#' @param clipped character, if auto, removed partial start/end days. if user, uses supplied startstop days. if none, does no date trimming
#' @param startstop POSIXt vector of two values in UTC or NA, only used if clip = "user"
#' @return tibble
read_tiltometer_temp <- function(filename = example_filename(),
                            site = NA,
                            output = NA,
                            clipped = c("auto", "user", "none")[1],
                            startstop = NA){
  stopifnot(inherits(filename, "character"))
  stopifnot(file.exists(filename[1]))
  x <- suppressMessages(readr::read_csv(filename[1], locale = readr::locale(tz = "Etc/GMT-4")))
  #cleaning up the header
  h <- colnames(x)
  lut <- c("ISO 8601 Time" = "DateTime",
           "Temperature (C)" = "Temp")
  colnames(x) <- lut[h]
  #adapted from: https://stackoverflow.com/questions/8613237/extract-info-inside-all-parenthesis-in-r
  attr(x, "filename") <- filename[1]
  #use the spec attr for original colnames
  #attr(x, "original_colnames") <- h

  x <- x %>% dplyr::mutate(DateTime = lubridate::with_tz(x$DateTime, tzone = "UTC"))


  x <- switch(tolower(clipped[1]),
              "auto" = clip_tiltometer(x, startstop = NA),
              "user" = clip_tiltometer(x, startstop = startstop),
              "none" = x,
              stop("options for clipped are auto, user, or none. what is ", clipped, "?")
  )

  if (!is.na(site)) {x <- x %>% dplyr::mutate(Site = site)}

  #omit NAs from data
  x <- na.omit(x)

  if (!is.na(output)) {
    readr::write_csv(x, file = output) }

  return(x)

}

