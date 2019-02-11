library(data.table)
library(dplyr)
library(rex)
library(namedCapture)
library(rematch2)
library(stringr)
library(stringi)
library(re2r)

trackDb.txt.gz <- system.file(
  "extdata", "trackDb.txt.gz", package="namedCapture")
trackDb.lines <- readLines(trackDb.txt.gz)

if(FALSE){
namedCapture:::variable_args_list(
      trackDb.lines,
      "track ",
      name=trackName.pattern,
      "(?:\n[^\n]+)*",
      "\\s+bigDataUrl ",
      bigDataUrl="[^\n]+")
}
pattern <- "track ((.*?)_(McGill([0-9,]+))(Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl ([^\n]+)"
named.pattern <- "track (?P<name>(?P<cellType>.*?)_(?P<sampleName>McGill(?P<sampleID>[0-9,]+))(?P<dataType>Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl (?P<bigDataUrl>[^\n]+)"
timing.dt.list <- list()
for(subject.size in 10^(2:4)){
  subject <- rep(trackDb.lines, l=subject.size)
  timing <- microbenchmark::microbenchmark("re2r::re2_match_all"={
    m <- re2r::re2_match_all(paste(subject, collapse="\n"), named.pattern)[[1]]
    data.frame(m[,-1]) %>% mutate(
      sampleID=as.integer(sampleID))
  }, "stringr::str_match_all"={
    m <- stringr::str_match_all(paste(subject, collapse="\n"), pattern)[[1]]
    data.frame(m[,-1]) %>% mutate(
      sampleID=as.integer(X4))
  }, "stringi::stri_match_all"={
    m <- stringi::stri_match_all(paste(subject, collapse="\n"), regex=pattern)[[1]]
    data.frame(m[,-1]) %>% mutate(
      sampleID=as.integer(X4))
  }, "rematch2::re_match_all"={
    tib <- rematch2::re_match_all(paste(subject, collapse="\n"), named.pattern)
  }, "rex::re_matches"={
    re_matches(paste(subject, collapse="\n"), named.pattern) %>% mutate(
      sampleID=as.integer(sampleID))
  }, "namedCapture::str_match_all_variable"={
    int.pattern <- list("[0-9]+", as.integer)
    trackName.pattern <- list(
      cellType=".*?",
      "_",
      sampleName=list(
        "McGill",
        sampleID=int.pattern),
      dataType="Coverage|Peaks",
      "|",
      "[^\n]+")
    match.df <- namedCapture::str_match_all_variable(
      subject,
      "track ",
      trackName=trackName.pattern,
      "(?:\n[^\n]+)*",
      "\\s+bigDataUrl ",
      bigDataUrl="[^\n]+")
  }, times=5)
  timing.dt.list[[paste(subject.size)]] <- data.table(subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
saveRDS(timing.dt, "trackDb.rds")
