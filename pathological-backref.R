max.N <- 20
times.list <- list()
for(N in 1:max.N){
  cat(sprintf("subject/pattern size %4d / %4d\n", N, max.N))
  subject <- paste(rep("a", N), collapse="")
  pattern <- paste(rep(c("(a)?", "\\1"), each=N), collapse="")
  N.times <- microbenchmark::microbenchmark(
    ICU=stringi::stri_match(subject, regex=pattern),
    PCRE=regexpr(pattern, subject, perl=TRUE),
    TRE=regexpr(pattern, subject, perl=FALSE),
    times=10)
  print(N.times)
  times.list[[N]] <- data.frame(N, N.times)
}
times <- do.call(rbind, times.list)
saveRDS(times, file="pathological-backref.rds")
