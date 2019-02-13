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
named.pattern <- "track (?P<trackName>(?P<cellType>.*?)_(?P<sampleName>McGill(?P<sampleID>[0-9,]+))(?P<dataType>Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl (?P<bigDataUrl>[^\n]+)"
timing.dt.list <- list()
for(subject.size in 10^seq(2, 4.5, by=0.5)){
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
    re_matches(paste(subject, collapse="\n"), named.pattern, global=TRUE)[[1]] %>% mutate(
      sampleID=as.integer(sampleID))
  }, "base::gregexpr(perl=TRUE)"={
    g.res <- gregexpr(
      named.pattern, paste(subject, collapse="\n"), perl=TRUE)[[1]]
  }, "base::gregexpr(perl=FALSE)"={
    gregexpr(pattern, paste(subject, collapse="\n"), perl=FALSE)[[1]]
  ## }, "namedCapture::str_match_all_named"={
  ##   namedCapture::str_match_all_named(paste(subject, collapse="\n"), named.pattern)[[1]]
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

timing.dt[, seconds := time/1e9]
stats.dt <- timing.dt[, list(
  median=median(seconds),
  q25=quantile(seconds, 0.25),
  q75=quantile(seconds, 0.75)
  ), by=list(expr, subject.size)]
library(ggplot2)
gg <- ggplot()+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, fill=expr),
    alpha=0.5,
    data=stats.dt)+
  geom_line(aes(
    subject.size, median, color=expr),
    data=stats.dt)+
  scale_x_log10(limits=c(1e2, 1e5))+
  scale_y_log10()
directlabels::direct.label(gg, "last.polygons")

gg <- ggplot()+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, fill=expr),
    alpha=0.5,
    data=stats.dt)+
  geom_line(aes(
    subject.size, median, color=expr),
    data=stats.dt)+
  xlim(0, 1e5)
directlabels::direct.label(gg, "last.polygons")

saveRDS(timing.dt, "trackDb.rds")
