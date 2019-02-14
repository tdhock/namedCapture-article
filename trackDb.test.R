library(data.table)
trackDb.txt.gz <- system.file(
  "extdata", "trackDb.txt.gz", package="namedCapture")
trackDb.lines <- readLines(trackDb.txt.gz)
pattern <- "track [A-Za-z0-9_]+"
timing.dt.list <- list()
result.list <- list()
for(subject.size in 10^seq(2, 3, by=0.5)){
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
with(result.list, identical(TRE, PCRE))
