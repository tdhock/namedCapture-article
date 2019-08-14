library(data.table)
pathological.rds.vec <- c("pathological.rds"="N=2 pattern without backreferences: a?a?aa",
"pathological-backref.rds"="N=2 pattern with backreferences: (a)?(a)?\\1\\1")
pathological.list <- list()
for(pathological.rds in names(pathological.rds.vec)){
  facet <- pathological.rds.vec[[pathological.rds]]
  pathological.list[[facet]] <- data.table(facet, readRDS(pathological.rds))
}
pathological <- do.call(rbind, pathological.list)
pathological[, seconds := time/1e9]
path.stats <- pathological[, list(
  median=median(seconds),
  q25=quantile(seconds, 0.25),
  q75=quantile(seconds, 0.75)
  ), by=list(N, expr, facet)]
library(ggplot2)

lt.dl <- ggplot()+
  theme_bw()+
  theme(panel.margin=grid::unit(0, "lines"))+
  facet_grid(. ~ facet)+
  scale_y_log10("Time to compute first match (seconds)")+
  scale_x_log10(
    "Subject/pattern size N",
    limits=c(1, 45),
    breaks=c(1, 5, 10, 15, 20, 25))+
  geom_ribbon(aes(
    N, ymin=q25, ymax=q75, group=expr),
    data=path.stats,
    alpha=0.5)+
  geom_line(aes(
    N, median, linetype=expr, group=expr),
    data=path.stats)+
  guides(linetype="none")+
  directlabels::geom_dl(aes(
    N, median, label=expr),
    data=path.stats,
    method=list(box.color="grey", "last.polygons"))
pdf("figure-timings-pathological-linetype.pdf", 7, 3)
print(lt.dl)
dev.off()
png("figure-timings-pathological-linetype.png", 7, 3, units="in", res=200)
print(lt.dl)
dev.off()

log.legend <- ggplot()+
  theme_bw()+
  theme(panel.margin=grid::unit(0, "lines"))+
  facet_grid(. ~ facet)+
  scale_y_log10("Time to compute first match (seconds)")+
  scale_x_log10(
    "Subject/pattern size N",
    limits=c(1, 45),
    breaks=c(1, 5, 10, 15, 20, 25))+
  geom_ribbon(aes(
    N, ymin=q25, ymax=q75, fill=expr, group=expr),
    data=path.stats,
    alpha=0.5)+
  geom_line(aes(
    N, median, color=expr, group=expr),
    data=path.stats)
log.dl <- directlabels::direct.label(log.legend, "last.polygons")
pdf("figure-timings-pathological.pdf", 7, 3)
print(log.dl)
dev.off()
