library(data.table)
library(ggplot2)
timing.dt.list <- list()
Subjects <- c(
  log="Character vector",
  sacct="Two data.frame columns")
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
for(task in names(Subjects)){
  timing.rds <- paste0(task, ".rds")
  if(file.exists(timing.rds)){
    dt <- readRDS(timing.rds)
    if("seconds" %in% names(dt)){
      dt[, seconds := NULL]
    }
    timing.dt.list[[task]] <- data.table(
      task, Subject=Subjects[[task]], dt)
  }
}
timing.dt <- do.call(rbind, timing.dt.list)

timing.dt[, seconds := time/1e9]
timing.dt[, expr.chr := paste(expr)]
t2 <- namedCapture::df_match_variable(
 timing.dt, expr.chr=list(
   pkg=".*?",
   "::",
   fun="[^(]*",
   list(
     "\\(",
     param="[^(]+", 
     "\\)"
   ), "?"))

stats.dt <- t2[, list(
  median=median(seconds),
  q25=quantile(seconds, 0.25),
  q75=quantile(seconds, 0.75)
), by=list(task, Subject, pkg=expr.chr.pkg, param=expr.chr.param, subject.size, expr)]
stats.dt[, label := ifelse(grepl("utils", expr), paste(expr), ifelse(
  grepl("^base", expr), 
  sub("FALSE", "F", sub("TRUE", "T", sub("^base::", "", expr))),
  sub("::.*", "", expr)))]
stats.dt[, label.param := ifelse(
  param=="", label, paste0(label, "\n", param))]
dl.linetype <- ggplot()+
  theme_bw()+
  theme(panel.spacing=grid::unit(0, "lines"))+
  facet_grid(. ~ Subject, labeller=label_both)+
  scale_y_log10("Time to compute first match
in each subject (seconds)")+
  coord_cartesian(
    xlim=c(10^1.8, 10^6.5),
    ylim=c(1e-3, 1e1),
    expand=FALSE)+
  scale_x_log10(
    "Number of subjects",
    breaks=10^(2:5))+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, group=label.param),
    data=stats.dt,
    alpha=0.5)+
  geom_line(aes(
    subject.size, median, linetype=pkg, group=label.param),
    data=stats.dt)+
  directlabels::geom_dl(aes(
    subject.size, median, 
    label=paste0(label.param, " ")),
    method=list(cex=0.65, box.color="grey", "last.polygons"),
    data=stats.dt)+
  guides(color="none",fill="none", linetype="none")
pdf("figure-timings-first-linetype.pdf", 6, 2.5)
print(dl.linetype)
dev.off()
png("figure-timings-first-linetype.png", 6, 2.5, units="in", res=200)
print(dl.linetype)
dev.off()

dl <- ggplot()+
  theme_bw()+
  theme(panel.spacing=grid::unit(0, "lines"))+
  facet_grid(. ~ Subject, labeller=label_both)+
  scale_y_log10("Time to compute first match
in each subject (seconds)")+
  scale_color_manual(values=pkg.colors)+
  scale_fill_manual(values=pkg.colors)+
  coord_cartesian(
    xlim=c(10^1.8, 10^6.5),
    ylim=c(1e-3, 1e1),
    expand=FALSE)+
  scale_x_log10(
    "Number of subjects",
    breaks=10^(2:5))+
  geom_ribbon(aes(
    subject.size, ymin=q25, ymax=q75, fill=pkg, group=label.param),
    data=stats.dt,
    alpha=0.5)+
  geom_line(aes(
    subject.size, median, color=pkg, group=label.param),
    data=stats.dt)+
  directlabels::geom_dl(aes(
    subject.size, median, color=pkg, 
    label=label.param),
    method=list(cex=0.65, "last.polygons"),
    data=stats.dt)+
  guides(color="none",fill="none")
pdf("figure-timings-first.pdf", 6, 2.5)
print(dl)
dev.off()
