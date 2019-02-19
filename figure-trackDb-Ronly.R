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
  timing <- microbenchmark::microbenchmark("R.PCRE"={
    result.list$PCRE <- gregexpr(pattern, subject, perl=TRUE)[[1]]
  }, "R.TRE"={
    result.list$TRE <- gregexpr(pattern, subject, perl=FALSE)[[1]]
  }, times=5)
  timing.dt.list[[paste(subject.size)]] <- data.table(subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
with(result.list, identical(TRE, PCRE))#because no capture groups.

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
    data=stats.dt)
png("figure-trackDb-Ronly.png")
print(gg)
dev.off()
system("display figure-trackDb-Ronly.png")
