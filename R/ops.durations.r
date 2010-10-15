#' Addition for the duration (i.e, difftime), period, and interval classes. 
#'
#' @aliases +.duration +.interval +.period +.POSIXt +.difftime +.Date add_dates add_interval_to_date add_interval_to_interval add_number_to_date add_number_to_posix
#'  add_period_to_date add_duration_to_date add_number_to_duration
#'  add_number_to_period add_period_to_period add_duration_to_period
#'  add_duration_to_duration add_duration_to_interval add_period_to_interval
#'  add_number_to_interval
#' @param date a duration(i.e. difftime), period, interval, POSIXt, or Date object
#' @param period a duration(i.e. difftime), period, interval, POSIXt, or Date object
#' @return a new duration(i.e. difftime), period, interval, POSIXt, or Date object, depending on e1 
#'   and e2 
#' @keywords arith chron methods
#' @ examples
#' x <- new_duration(day = 1)
#' x + now()
#' today() + x
#' x + difftime(now() + 3600, now())
#' x + x
add_duration_to_date <- function(date, duration) {
  if(is.Date(date)){
    date <- as.POSIXct(date)
    ans <- with_tz(.base_add_POSIXt(date, duration), "UTC")
    if (hour(ans) == 0 && minute(ans) == 0 && second(ans) == 0)
      return(as.Date(ans))
    return(ans)
  }
  new <- .base_add_POSIXt(date, duration)
  attr(new, "tzone") <- tz(date)
  reclass_date(new, date)
}

add_duration_to_duration <- function(dur1, dur2)
  make_difftime(as.double(dur1, "secs") + as.double(dur2, "secs"))

add_duration_to_interval <- function(int, dur){
  start <- attr(int, "start")	
  span <- unclass(int) + as.numeric(dur, "secs")
  new_interval(start + span, start)
}

add_duration_to_period <- function(per, dur){
	print("duration converted to seconds")
	per + seconds(as.numeric(dur, "secs"))
}



add_interval_to_date <- function(date, interval){
	if (any(attr(interval, "start") != date))
	   print("coercing interval to duration")
	add_duration_to_date(date, as.duration(interval))
}

add_interval_to_interval <- function(int1, int2){
	start1 <- attr(int1, "start")
	start2 <- attr(int2, "start")
	end1 <- start1 + int1
	end2 <- start2 + int2
	
	if(all(start2 == end1))
		return(new_interval(start1 + int1 + int2, start1))
	else if (all(start1 == end2))
		return(new_interval(start2 + int2 + int1, start2))
	else if (all(start1 == start2))
		return(as.interval(start1, pmax(end1, end2)))
	
	message("Intervals do not align: coercing to durations")
	as.duration(int1) + as.duration(int2)
}



add_number_to_date <- function(e1, e2)
      structure(unclass(e1) + e2, class = "Date")

add_number_to_duration <- function(dur, num){
	if (is.difftime(dur))
		return(make_difftime(num + as.double(dur, "secs")))
  	new_duration(num + unclass(dur))
}

add_number_to_interval <-function(int, num){
  message("numeric coerced to duration in seconds")
  add_duration_to_interval(int, as.duration(num))
}

add_number_to_period <- function(per, num){
  message("numeric coerced to seconds")
  per$second <- per$second + num
  per
}

add_number_to_posix <- function(e1, e2){
      if(is.POSIXct(e1)){
      	return(structure(unclass(as.POSIXct(e1)) + e2, class = 
      		class(e1)))
      }
      as.POSIXlt(structure(unclass(as.POSIXct(e1)) + e2, class = 		class(as.POSIXct(e1))))
}



add_period_to_date <- function(date, period){
	new <- update(as.POSIXlt(date), 
			years = year(date) + period$year,
			months = month(date) + period$month,
			days = mday(date) + period$day,
			hours = hour(date) + period$hour,
			minutes = minute(date) + period$minute,
			seconds = second(date) + period$second
			)
	if (is.Date(date) & sum(new$sec, new$min, new$hour, na.rm = TRUE) != 0)
	return(new)	
	
	reclass_date(new, date)
}

add_period_to_interval <- function(int, per){
  start <- attr(int, "start")
  end <- start + unclass(int)
  end2 <- end + per
  new_interval(end2, start)
}

add_period_to_period <- function(per1, per2){
  to.add <- suppressWarnings(cbind(per1,per2))
  structure(to.add[,1:6] + to.add[,7:12], class = c("period", "data.frame"))
}



add_dates <- function(e1, e2){
  
  if (is.instant(e1)) {
    if (is.instant(e2))
      stop("binary '+' not defined for adding dates together")
    if (is.period(e2))
      add_period_to_date(e1, e2)
    else if (is.interval(e2))
      add_interval_to_date(e1, e2)
    else if (is.difftime(e2)) 
      add_duration_to_date(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_date(e1, e2)
    else if (is.POSIXt(e1))
      add_number_to_posix(e1, e2)
    else if (is.Date(e1))
      add_number_to_date(e1, e2)
    else{
      base::'+'(e1,e2)
      }
  }

  else if (is.period(e1)) {
    if (is.instant(e2))
      add_period_to_date(e2, e1)
    else if (is.period(e2))
      add_period_to_period(e1, e2)
    else if (is.interval(e2))
      add_period_to_interval(e2, e1)
    else if (is.difftime(e2))
      add_duration_to_period(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_period(e1, e2)
    else
      add_number_to_period(e1, e2)
  }
  
  else if (is.interval(e1)){
    if (is.instant(e2))
      add_interval_to_date(e2, e1)
    else if (is.interval(e2))
      add_interval_to_interval(e1, e2)
    else if (is.period(e2))
      add_period_to_interval(e1, e2)
    else if (is.difftime(e2))
      add_duration_to_interval(e1, e2) 
    else if (is.duration(e2)) 
      add_duration_to_interval(e1, e2) 
    else
      add_number_to_interval(e1, e2)
  }

  else if (is.difftime(e1)) {
    if (is.instant(e2))
      add_duration_to_date(e2, e1)
    else if (is.period(e2))
      add_duration_to_period(e2, e1)
    else if (is.interval(e2))
      add_duration_to_interval(e2, e1)
    else if (is.difftime(e2))
      add_duration_to_duration(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_duration(e1, e2)
    else
      add_number_to_duration(e1, e2)
  }
  
    else if (is.duration(e1)) {
    if (is.instant(e2))
      add_duration_to_date(e2, e1)
    else if (is.period(e2))
      add_duration_to_period(e2, e1)
    else if (is.interval(e2))
      add_duration_to_interval(e2, e1)
    else if (is.difftime(e2))
      add_duration_to_duration(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_duration(e1, e2)
    else
      add_number_to_duration(e1, e2)
  }
  
  else if (is.numeric(e1)) {
    if (is.POSIXt(e2))
      add_number_to_posix(e2, e1)
    else if (is.Date(e1))
      add_number_to_date(e2, e1)
    else if (is.period(e2))
      add_number_to_period(e2, e1)
    else if (is.interval(e2))
      add_number_to_interval(e2, e1) 
    else if (is.difftime(e2))
      add_number_to_duration(e2, e1) 
    else stop("Unknown object class")
  }
  else stop("Unknown object class")
}


#' Makes a difftime object from given number of seconds 
#'
#' @param x number value of seconds to be transformed into a difftime object
#' @return a difftime object corresponding to x seconds
#' @keywords chron
#' @examples
#' make_difftime(1)
#' make_difftime(60)
#' make_difftime(3600)
make_difftime <- function (x) {  
  seconds <- abs(x)
    if (any(seconds < 60)) 
        units <- "secs"
    else if (any(seconds < 3600))
        units <- "mins"
    else if (any(seconds < 86400))
        units <- "hours"
    else
        units <- "days"
    
    switch(units, secs = structure(x, units = "secs", class = "difftime"), 
      mins = structure(x/60, units = "mins", class = "difftime"), 
      hours = structure(x/3600, units = "hours", class = "difftime"), 
      days = structure(x/86400, units = "days", class = "difftime"))
}

#' Multiplication for period and interval classes. 
#'
#' @name multiply
#' @aliases *.period *.interval multiply_period_by_number multiply_interval_by_number 
#' @param per a period, interval or numeric object
#' @param num a period, interval or numeric object
#' @return a period or interval object
#' @seealso \code{\link{+.period}}, \code{\link{+.interval}},
#'   \code{\link{-.period}}, \code{\link{-.interval}},
#'   \code{\link{/.interval}}, \code{\link{/.period}}
#' @keywords arith chron methods
#' @examples
#' x <- new_period(day = 1)
#' x * 3
#' 3 * x
multiply_period_by_number <- function(per, num){
  new_period(
    year = per$year * num,
    month = per$month * num,
    day = per$day * num,
    hour = per$hour * num,
    minute = per$minute * num,
    second = per$second * num
  )
}

multiply_interval_by_number <- function(int, num){
	start <- attr(int, "start")
	span <- num * as.duration(int)
	
	new_interval(start + span, start)
}

"*.period" <- "*.interval" <- function(e1, e2){
    if (is.timespan(e1) && is.timespan(e2)) 
      stop("cannot multiply time span by time span")
    else if (is.period(e1))
      multiply_period_by_number(e1, e2)
    else if (is.period(e2))
      multiply_period_by_number(e2, e1)
    else if (is.interval(e1))
      multiply_interval_by_number(e1, e2)
    else if (is.interval(e2))
      multiply_interval_by_number(e2, e1)
    else base::'*'(e1, e2)
}  




#' Division for period, and interval classes. 
#'
#' @name division
#' @aliases /.period /.interval divide_period_by_number divide_interval_by_number 
#' @param per a period, interval or numeric object
#' @param num a period, interval or numeric object
#' @return a period or interval object
#' @seealso \code{\link{+.period}}, \code{\link{+.interval}},
#'   \code{\link{-.period}}, \code{\link{-.interval}}, 
#'   \code{\link{*.interval}}, \code{\link{*.period}}
#' @keywords arith chron methods
#' @examples
#' x <- new_period(day = 2)
#' x / 2
divide_interval_by_difftime <- function(int, diff){
	as.numeric(unclass(int) / as.double(diff, units = "secs"))
}

divide_interval_by_duration <- function(int, dur){
	as.numeric(unclass(int) / unclass(dur))
}

divide_interval_by_number <- function(int, num){
	start <- attr(int, "start")
	span <- as.duration(int) / num
	
	new_interval(start + span, start)
}

est.duration <- function(per){
	per$second +
	60 * per$minute +
	60 * 60 * per$hour +
	60 * 60 * 24 * per$day +
	60 * 60 * 24 * 30 * per$month +
	60 * 60 * 24 * 365.25 * per$year
}

divide_interval_by_period <- function(int, per){
	start <- attr(int, "start")
	end <- start + unclass(int)
	
	# sign of period shouldn't affect answer
	per <- abs(per)
	
	# duration division should give good approximation
	estimate <- trunc(as.numeric(int) / est.duration(per))
	
	# did we overshoot or undershoot?
	try1 <- start + per * estimate
	miss <- as.numeric(end) - as.numeric(try1)
	
	# adjust estimate until satisfactory
	n <- 0
	if (miss >= 0){
		while (try1 + n * per < end)
			n <- n + 1
		# because the last one went too far	
		return(estimate + (n - 1)) 
	} else {
		while (try1 - n * per > end)
			n <- n + 1
		# because the last one went too far	
		return(estimate - (n + 1))
	}
		
}

period_to_seconds <- function(per, start){
  # how many days in the month and years part?
  no.months <- 12 * per$year + per$month
  
  get_days <- function(num.months, start1)
  		sum(day(start + months(1:num.months) - days(1)))
  		
  # how many days is this?
  lapply(no.months, get_days, start1 = start)
  no.days <- unlist(lapply(no.months, get_days, start1 = start))
  
  per$second + 60 * per$minute + 60 * 60 * per$hour + 60 * 60 * 24 * (to.per$day + no.days)
}

divide_interval_by_period2 <- function(int, per){
  per <- abs(per)
  start <- as.POSIXlt(attr(int, "start"))
  end <- start + unclass(int)

  to.per <- as.data.frame(unclass(end)) - 
    as.data.frame(unclass(start))
    
  names(to.per)[1:6] <- c("second", "minute", "hour", "day", "month", "year")
  to.per <- to.per[6:1]
  
  
  numerator <- period_to_seconds(to.per, start)
  denominator <- period_to_seconds(per, start)
 
  numerator / denominator
}




divide_period_by_duration <- function(per, dur){
	print("estimate only: make periods intervals for exact fraction")
	est.duration(per) / dur
}

divide_period_by_number <- function(per, num){
  new_period(
    year = per$year / num,
    month = per$month / num,
    day = per$day / num,
    hour = per$hour / num,
    minute = per$minute / num,
    second = per$second / num
  )
}

divide_period_by_period <- function(per1, per2){
	print("estimate only: make periods intervals for exact fraction")
	est.duration(per1) / est.duration(per2)
}


	





"/.period" <- "/.interval" <- function(e1, e2){
    if (is.interval(e1)) {
    	if (is.duration(e2))
    		divide_interval_by_duration(e1, e2)
    	else if (is.difftime(e2))
    		divide_interval_by_difftime(e1, e2)
    	else if (is.period(e2))
    		divide_interval_by_period(e1, e2)
    	else if (is.numeric(e2))
    		divide_interval_by_number(e1, e2)
    }
   	
    if (is.timespan(e2)) 
      stop( "second argument of / cannot be a timespan")
    else if (is.period(e1))
      divide_period_by_number(e1, e2)
    else base::'/'(e1, e2)
}  





  
#' Subtraction for the duration (i.e, difftime), period, and interval classes. 
#'
#' The subtraction methods returns an interval object when a POSIXt or Date 
#' object is subtracted from another POSIXt or Date object. To retrieve this 
#' difference as a duration, use \code{\link{as.duration}}. To retrieve it as a 
#' period use \code{\link{as.period}}. To retrieve it as a difftime, use \code{\link{difftime}} instead of subtraction.
#'
#' Since a specific number of seconds exists between two dates, the duration 
#' returned will not include unspecific time units such as years and months. See 
#' \code{\link{duration}} for more details.
#'
#' @aliases -.period -.POSIXt -.difftime -.Date -.interval subtract_dates
#' @param e1 a duration(i.e. difftime), period, interval, POSIXt, or Date object
#' @param e2 a duration(i.e. difftime), period, interval, POSIXt, or Date object
#' @return a new duration(i.e. difftime), period, interval, POSIXt, or Date object, depending on e1 
#'   and e2 
#' @keywords arith chron methods
#' @examples
#' x <- new_duration(day = 1)
#' now() - x
#' -x
#' x - x
#' as.Date("2009-08-02") - as.Date("2008-11-25")
subtract_interval_from_date <- function(date, int){
	end <- attr(int, "start") + unclass(int)
	if (any(end != date))
	   print("interval does not align: coercing to duration")
	add_duration_to_date(date, -as.duration(int))
}

subtract_interval_from_interval <- function(int2, int1){
	start1 <- attr(int1, "start")
	start2 <- attr(int2, "start")
	end1 <- start1 + int1
	end2 <- start2 + int2
	
	if (all(end1 >= end2)){
		if (all(end2 == end1))
			return(new_interval(start2, start1))
		else if (all(start2 == start1))
			return(new_interval(end2, end1))
	}
	
	message("Intervals do not align: coercing to durations")
	as.duration(int1) - as.duration(int2)
}

subtract_dates <- function(e1, e2){
  if (missing(e2))
    -1 * e1
  else if(is.instant(e1) && is.instant(e2))
    new_interval(e2, e1)
  else if (is.POSIXct(e1) && !is.timespan(e2))
    structure(unclass(e1) - e2, class = class(e1))
  else if (is.POSIXlt(e1) && !is.timespan(e2)){
    as.POSIXlt(structure(unclass(as.POSIXct(e1)) - e2, 
    	class = class(as.POSIXct(e1))))
  } else if (is.interval(e1) && is.interval(e2))
  	subtract_interval_from_interval(e2, e1)
  else if (is.instant(e1) && is.interval(e2))
  	subtract_interval_from_date(e2, e1)
  else
    e1  + (-1 * e2)
}







