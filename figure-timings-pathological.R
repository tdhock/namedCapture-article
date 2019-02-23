library(data.table)
pathological <- data.table(readRDS("pathological.rds"))
pathological[, seconds := time/1e9]
path.stats <- pathological[, list(
  median=median(seconds),
  q25=quantile(seconds, 0.25),
  q75=quantile(seconds, 0.75)
  ), by=list(N, expr)]
library(ggplot2)
log.legend <- ggplot()+
  theme_bw()+
  theme(panel.margin=grid::unit(0, "lines"))+
  scale_y_log10("seconds")+
  scale_x_log10(
    "subject/pattern size",
    limits=c(1, 30),
    breaks=c(1, 5, 10, 15, 20, 25))+
  geom_ribbon(aes(
    N, ymin=q25, ymax=q75, fill=expr, group=expr),
    data=path.stats,
    alpha=0.5)+
  geom_line(aes(
    N, median, color=expr, group=expr),
    data=path.stats)
log.dl <- directlabels::direct.label(log.legend, "last.polygons")
pdf("figure-timings-pathological.pdf")
print(log.dl)
dev.off()
