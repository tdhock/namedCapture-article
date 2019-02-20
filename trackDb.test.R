library(namedCapture)
trackDb.lines <- readLines("trackDb.txt.gz")
pattern <- "track [A-Za-z0-9_]+"
named.pattern <- "(?:track (?<trackName>(?<cellType>.*?)_(?<sampleName>McGill(?<sampleID>[0-9]+))(?<dataType>Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl (?<bigDataUrl>[^\n]+))"
groups.pattern <- "(?:track ((.*?)_(McGill([0-9]+))(Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl ([^\n]+))"
pattern <- groups.pattern
result.list <- list()
timing.df.list <- list()
for(subject.size in 10^seq(2, 4, by=0.5)){
  subject.vec <- rep(trackDb.lines, l=subject.size)
  writeLines(subject.vec, "trackDb.txt")
  subject <- paste(subject.vec, collapse="\n")
  vec.with.attrs <- gregexpr(named.pattern, subject, perl=TRUE)[[1]]
  timing <- microbenchmark::microbenchmark("PCRE.nonames"={
    gregexpr(groups.pattern, subject, perl=TRUE)[[1]]
  }, "PCRE.names"={
    gregexpr(named.pattern, subject, perl=TRUE)[[1]]
  }, "named"={
    namedCapture::str_match_all_named(subject, named.pattern)[[1]]
  }, "variable"={
    namedCapture::str_match_all_variable(subject, named.pattern)
  }, "substring"={
    first <- attr(vec.with.attrs, "capture.start")
    last <- attr(vec.with.attrs, "capture.length") - 1 + first
    subs <- substring(subject, first, last)
  }, "R.TRE"={
    gregexpr(groups.pattern, subject, perl=FALSE)[[1]]
  }, times=5)
  ##print(sapply(result.list, length))
  print(timing)
  timing.df.list[[paste(subject.size)]] <- data.frame(subject.size, timing)
}
##with(result.list, identical(TRE, PCRE))
timing.df <- do.call(rbind, timing.df.list)
write.table(timing.df, "trackDb.test.csv", row.names=FALSE)
