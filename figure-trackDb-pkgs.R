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
pattern <- "track ((.*?)_(McGill([0-9,]+))(Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl ([^\n]+)"
named.pattern <- "track (?P<trackName>(?P<cellType>.*?)_(?P<sampleName>McGill(?P<sampleID>[0-9,]+))(?P<dataType>Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl (?P<bigDataUrl>[^\n]+)"
timing.dt.list <- list()
for(subject.size in 10^seq(2, 4, by=0.5)){
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
  }, "base::gregexpr(perl=TRUE)"={
    g.res <- gregexpr(
      named.pattern, paste(subject, collapse="\n"), perl=TRUE)[[1]]
  }, "rematch2::re_match_all"={
    tib <- rematch2::re_match_all(paste(subject, collapse="\n"), named.pattern)
  }, "rex::re_matches"={
    re_matches(paste(subject, collapse="\n"), named.pattern, global=TRUE)[[1]] %>% mutate(
      sampleID=as.integer(sampleID))
  }, "namedCapture::str_match_all_named"={
    match.df <- namedCapture::str_match_all_named(
      paste(subject, collapse="\n"), named.pattern)
  },
  times=5)
  print(timing)
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
  ggtitle(paste(
    "Timing regular expression functions",
    "after applying patch to gregexpr_perl"
  ))+
  theme_bw()+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, fill=expr),
    alpha=0.5,
    data=stats.dt)+
  geom_line(aes(
    subject.size, median, color=expr),
    data=stats.dt)+
  ylab("seconds")+
  scale_x_continuous(
    "subject size (lines)",
    limits=c(NA, 2e4))
dl <- directlabels::direct.label(gg, "last.polygons")
png("figure-trackDb-pkgs.png")
print(dl)
dev.off()
