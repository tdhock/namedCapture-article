pattern <- "track (?P<trackName>(?P<cellType>.*?)_(?P<sampleName>McGill(?P<sampleID>[0-9,]+))(?P<dataType>Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl (?P<bigDataUrl>[^\n]+)"
trackDb.txt.gz <- system.file(
  "extdata", "trackDb.txt.gz", package="namedCapture")
trackDb.lines <- readLines(trackDb.txt.gz)
subject.vec <- paste(rep(trackDb.lines, l=100000), collapse="\n")
type.list <- NULL
profvis::profvis({
  namedCapture:::check_subject_pattern(subject.vec, pattern)
  parsed <- gregexpr(pattern, subject.vec, perl=TRUE)
  result.list <- list()
  for(i in seq_along(parsed)){
    vec.with.attrs <- parsed[[i]]
    first.start <- vec.with.attrs[1]
    no.match <- first.start == -1
    subject.is.na <- is.na(first.start)
    if(no.match || subject.is.na){
      m <- matrix(character(), nrow=0)
    }else{
      first <- attr(vec.with.attrs, "capture.start")
      last <- attr(vec.with.attrs, "capture.length")-1+first
      subs <- substring(subject.vec[i], first, last)
      m <- matrix(subs, nrow=nrow(first))
      colnames(m) <- namedCapture:::names_or_error(vec.with.attrs)
    }
    result.list[[i]] <- namedCapture:::apply_type_funs(m, type.list)
  }
  names(result.list) <- names(subject.vec)
  result.list
})

profvis::profvis({
  parsed <- gregexpr(pattern, subject.vec, perl=TRUE)
})
