library(data.table)
trackDb.txt.gz <- system.file(
  "extdata", "trackDb.txt.gz", package="namedCapture")
trackDb.lines <- readLines(trackDb.txt.gz)
pattern <- "track [A-Za-z0-9_]+"
timing.dt.list <- list()
result.list <- list()
for(subject.size in 10^seq(2, 4.5, by=0.5)){
  subject.vec <- rep(trackDb.lines, l=subject.size)
  writeLines(subject.vec, "trackDb.txt")
  subject <- paste(subject.vec, collapse="\n")  
  timing <- microbenchmark::microbenchmark("C.PCRE2"={
    system("./pcre2demo -g trackDb.txt > trackDb.out")
  }, "C.PCRE1"={
    system("./pcre_demo -g trackDb.txt > trackDb.out")
  }, "R.PCRE"={
    result.list$PCRE <- gregexpr(pattern, subject, perl=TRUE)[[1]]
  }, "R.TRE"={
    result.list$TRE <- gregexpr(pattern, subject, perl=FALSE)[[1]]
  }, times=5)
  timing.dt.list[[paste(subject.size)]] <- data.table(subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
with(result.list, identical(TRE, PCRE))#because no capture groups.

if(FALSE){
for(subject.size in 10^seq(2, 7, by=0.5)){
  subject.vec <- rep(trackDb.lines, l=subject.size)
  writeLines(subject.vec, "trackDb.txt")
  timing <- microbenchmark::microbenchmark("big.PCRE2"={
    system("./pcre2demo -g trackDb.txt > trackDb.out")
  }, "big.PCRE1"={
    system("./pcre_demo -g trackDb.txt > trackDb.out")
  }, times=5)
  timing.dt.list[[paste("big", subject.size)]] <- data.table(
    subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
}

timing.dt[, seconds := time/1e9]
stats.dt <- timing.dt[grepl("^[^C]", expr), list(
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
  scale_x_log10(
    limits=c(NA, 1e8))+
  scale_y_log10(
    "seconds (median line and quartile bands)")+
  directlabels::geom_dl(aes(
    subject.size, median, color=expr, label=expr),
    method="last.polygons",
    data=stats.dt[grepl("^R", expr)])+
  directlabels::geom_dl(aes(
    subject.size, median, color=expr, label=sub("big.", "", expr)),
    method="last.qp",
    data=stats.dt[subject.size>1e5])+
  guides(color="none", fill="none")
print(gg)

##directlabels::direct.label(gg, "last.polygons")
png("figure-trackDb-PCRE-R-1-2.png")
print(gg)
dev.off()

gg <- ggplot()+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, fill=expr),
    alpha=0.5,
    data=stats.dt)+
  geom_line(aes(
    subject.size, median, color=expr),
    data=stats.dt)+
  scale_y_continuous(
    "seconds (median line and quartile bands)")+
  scale_x_continuous(
    limits=c(0, 40000))
dl <- directlabels::direct.label(gg, "last.polygons")
png("figure-trackDb-gregexpr.png")
print(dl)
dev.off()

