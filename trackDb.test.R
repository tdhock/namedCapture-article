trackDb.lines <- readLines("trackDb.txt.gz")
pattern <- "track [A-Za-z0-9_]+"
result.list <- list()
timing.df.list <- list()
for(subject.size in 10^seq(2, 4.5, by=0.5)){
  subject.vec <- rep(trackDb.lines, l=subject.size)
  writeLines(subject.vec, "trackDb.txt")
  subject <- paste(subject.vec, collapse="\n")  
  timing <- microbenchmark::microbenchmark("R.PCRE"={
    result.list$PCRE <- gregexpr(pattern, subject, perl=TRUE)[[1]]
  }, "R.TRE"={
    result.list$TRE <- gregexpr(pattern, subject, perl=FALSE)[[1]]
   }, times=5)
  print(sapply(result.list, length))
  timing.df.list[[paste(subject.size)]] <- data.frame(subject.size, timing)
}
with(result.list, identical(TRE, PCRE))
timing.df <- do.call(rbind, timing.df.list)
write.table(timing.df, "trackDb.test.csv", row.names=FALSE)
