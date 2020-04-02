library(data.table)
library(ggplot2)
timing.dt.list <- list()
version.vec <- c("3.5.2", "3.6.0")
pkg.colors <- c(
  namedCapture="#E41A1C",#red
  tidyr="#377EB8",#blue
  rex="#4DAF4A",#green
  rematch2="#984EA3",#purple
  utils="#FF7F00",#orange
  base="#FF7F00",#orange
  "#FFFF33",#yellow
  stringi="#A65628",#brown
  re2r="#F781BF",#pink
  stringr="#999999")#grey
for(version in version.vec){
  timing.rds <- paste0("trackDb-", version, ".rds")
  if(file.exists(timing.rds)){
    dt <- readRDS(timing.rds)
    dt[, seconds := NULL]
    timing.dt.list[[version]] <- data.table(
      version, title=paste0("R-", version), dt)
  }
}
timing.dt <- do.call(rbind, timing.dt.list)
timing.dt[, seconds := time/1e9]
timing.dt[, expr.chr := paste(expr)]
t2 <- namedCapture::df_match_variable(
 timing.dt, expr.chr=list(
   pkg=".*?",
   "::",
   fun=".*"))
stats.dt <- t2[, list(
  median=median(seconds),
  q25=quantile(seconds, 0.25),
  q75=quantile(seconds, 0.75)
  ), by=list(version, title, expr.chr.pkg, subject.size, expr)]

dl <- ggplot()+
  theme_bw()+
  theme(panel.margin=grid::unit(0, "lines"))+
  facet_grid(. ~ title)+
  scale_y_log10("Time to compute all matches
in text file (seconds)")+
  scale_color_manual(values=pkg.colors)+
  scale_fill_manual(values=pkg.colors)+
  coord_cartesian(
    xlim=c(10^1.8, 10^6.7),
    ylim=c(1e-4, 1e3),
    expand=FALSE)+
  scale_x_log10(
    "Number of lines in text file",
    breaks=10^(2:5))+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, fill=expr.chr.pkg, group=expr),
    data=stats.dt,
    alpha=0.5)+
  geom_line(aes(
    subject.size, median, color=expr.chr.pkg, group=expr),
    data=stats.dt)+
  directlabels::geom_dl(aes(
    subject.size, median, color=expr.chr.pkg, 
    label=ifelse(grepl("utils", expr), paste(expr), ifelse(
      grepl("^base", expr), 
      sub("FALSE", "F", sub("TRUE", "T", sub("^base::", "", expr))),
      sub("::.*", "", expr)))),
    method=list(cex=0.65, "last.polygons"),
    data=stats.dt)+
  guides(color="none",fill="none")
png("figure-timings-all-email.png", 6, 2.5, units="in", res=200)
print(dl)
dev.off()
pdf("figure-timings-all.pdf", 6, 2.5)
print(dl)
dev.off()

dl.linetype <- ggplot()+
  theme_bw()+
  theme(panel.margin=grid::unit(0, "lines"))+
  facet_grid(. ~ title)+
  scale_y_log10("Time to compute all matches
in text file (seconds)")+
  coord_cartesian(
    xlim=c(10^1.8, 10^6.7),
    ylim=c(1e-4, 1e3),
    expand=FALSE)+
  scale_x_log10(
    "Number of lines in text file",
    breaks=10^(2:5))+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, group=expr),
    data=stats.dt,
    alpha=0.5)+
  geom_line(aes(
    subject.size, median, linetype=expr.chr.pkg, group=expr),
    data=stats.dt)+
  directlabels::geom_dl(aes(
    subject.size, median, 
    label=paste0(
      ifelse(grepl("utils", expr), paste(expr), ifelse(
        grepl("^base", expr), 
        sub("FALSE", "F", sub("TRUE", "T", sub("^base::", "", expr))),
        sub("::.*", "", expr))),
    " ")),
    method=list(cex=0.65, box.color="grey", "last.polygons"),
    data=stats.dt)+
  guides(color="none",fill="none", linetype="none")
png("figure-timings-all-linetype.png", 6, 2.5, units="in", res=200)
print(dl.linetype)
dev.off()
