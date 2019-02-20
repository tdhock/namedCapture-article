N.vec <- 2^seq(4, 10)
library(data.table)
library(stringi)
timing.dt.list <- list()
for(N in N.vec){
  subject.vec <- rep("A", l=N)
  subject <- paste(subject.vec, collapse="")
  start.vec <- end.vec <- 1:N #slow too.
  start.vec <- end.vec <- rep(1, N)#slow.
  timing <- microbenchmark::microbenchmark("stringi::stri_sub"={
    stringi::stri_sub(subject, start.vec, end.vec)
  }, "base::substring"={
    substring(subject, start.vec, end.vec)
  }, times=5)
  print(timing)
  timing.dt.list[[paste(N)]] <- data.table(N, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
timing.dt[, ms := time/1e6]
(stats.dt <- timing.dt[, list(
  median=median(ms),
  q25=quantile(ms, 0.25),
  q75=quantile(ms, 0.75)
  ), by=list(expr, N)])

library(ggplot2)
gg <- ggplot()+
  ggtitle(
    "Bug: substring in R is quadratic but should be linear time complexity")+
  geom_ribbon(aes(
    N, ymin=q25, ymax=q75, fill=expr),
    alpha=0.5,
    data=stats.dt)+
  geom_line(aes(
    N, median, color=expr),
    data=stats.dt)+
  scale_x_continuous(
    "N = number of substrings = nchar(text)",
    limits=c(NA, 1400))+
  scale_y_continuous(
    "milliseconds (median line and quartile bands)")
dl <- directlabels::direct.label(gg, "last.polygons")
png("figure-substring-bug.png")
print(dl)
dev.off()
