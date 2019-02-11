library(data.table)
library(dplyr)
library(rex)
library(namedCapture)
library(rematch2)
library(stringr)
library(stringi)
library(re2r)
log.subject <- 'gate3.fmr.com - - [05/Jul/1995:13:51:39 -0400] "GET /shuttle/countdown/ 
curly02.slip.yorku.ca - - [10/Jul/1995:23:11:49 -0400] "GET /sts-70/sts-70-patch-small.gif
boson.epita.fr - - [15/Jul/1995:11:27:49 -0400] "GET /movies/sts-71-mir-dock.MPG
134.153.50.9 - - [13/Jul/1995:11:02:50 -0400] "GET /icons/text.xbm'
log.lines <- strsplit(log.subject, split="\n")[[1]]

if(FALSE){
namedCapture:::variable_args_list(
      log.lines,
      "\\[",
      time="[^]]*", function(x)as.POSIXct(x, format="%d/%b/%Y:%H:%M:%S %z"),
      "\\]",
      ' "GET ',
      namedCapture.filetype.pattern, "?")
}
pattern <- "\\[([^]]*)\\] \"GET (?:[^[:space:]]+[.]([^[:space:].?\"]+))?"
named.pattern <- "\\[(?P<time>[^]]*)\\] \"GET (?:[^[:space:]]+[.](?P<filetype>[^[:space:].?\"]+))?"
timing.dt.list <- list()
for(subject.size in 10^(1:5)){
  subject <- rep(log.lines, l=subject.size)
  timing <- microbenchmark::microbenchmark("re2r::re2_match"={
    m <- re2r::re2_match(subject, named.pattern)
    data.frame(m[,-1]) %>% mutate(
      filetype = tolower(filetype),
      time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))
  }, "stringr::str_match"={
    m <- stringr::str_match(subject, pattern)
    data.frame(filetype=m[,3], time=m[,2]) %>% mutate(
      filetype = tolower(filetype),
      time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))
  }, "stringi::stri_match"={
    m <- stringi::stri_match(subject, regex=pattern)
    data.frame(filetype=m[,3], time=m[,2]) %>% mutate(
      filetype = tolower(filetype),
      time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))
  }, "utils::strcapture"={
    p <- data.frame(time=character(), filetype=character())
    strcapture(pattern, subject, p, perl=TRUE)%>% mutate(
      filetype = tolower(filetype),
      time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))
  }, "rematch2::re_match"={
    rematch2::re_match(subject, named.pattern) %>% mutate(
      filetype = tolower(filetype),
      time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))
  }, "rex::re_matches"={
    (rex.filetype.pattern <- rex(
      non_spaces, ".",
      capture(name = 'filetype',
              none_of(space, ".", "?", double_quote) %>% one_or_more())))
    rex.pattern <- rex(
      "[",
      capture(name = "time", none_of("]") %>% zero_or_more()),
      "]",
      space, double_quote, "GET", space,
      maybe(rex.filetype.pattern))
    re_matches(subject, rex.pattern) %>% mutate(
      filetype = tolower(filetype),
      time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))
  }, "namedCapture::str_match_variable"={
    namedCapture.filetype.pattern <- list(
      "[^[:space:]]+[.]", 
      filetype='[^[:space:].?"]+', tolower)
    namedCapture::str_match_variable(
      subject,
      "\\[",
      time="[^]]*", function(x)as.POSIXct(x, format="%d/%b/%Y:%H:%M:%S %z"),
      "\\]",
      ' "GET ',
      namedCapture.filetype.pattern, "?")
  }, times=5)
  timing.dt.list[[paste(subject.size)]] <- data.table(subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
saveRDS(timing.dt, "log.rds")
