library(data.table)
timing.dt.list <- readRDS("trackDb.test.rds")
timing.dt.list <- timing.dt.list[grepl("big", names(timing.dt.list))]
timing.dt.list[["old"]] <- fread("trackDb.test.csv")
timing.dt <- do.call(rbind, timing.dt.list)
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

png("figure-trackDb-test.png")
print(gg)
dev.off()
system("display figure-trackDb-test.png")
