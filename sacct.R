library(data.table)
library(namedCapture)
library(tidyr)
library(magrittr)

(sacct.dt <- data.table(
  Elapsed=c("07:04:42", "07:04:42", "07:04:49", "00:00:00", "00:00:00"),
  JobID=c("13937810_25", "13937810_25.batch", "13937810_25.extern",
    "14022192_[1-3]", "14022204_[4]"), stringsAsFactors=FALSE))
int.pattern <- list("[0-9]+", as.integer)
range.pattern <- list(
  "[[]",
  task1=int.pattern,
  list(
    "-",
    taskN=int.pattern
  ), "?",
  "[]]")
task.pattern <- list(
  "_", list(
    task=int.pattern,
    "|",#either one task(above) or range(below)
    range.pattern))
namedCapture.patterns <- list(
  JobID=list(
    job=int.pattern,
    task.pattern,
    list(
      "[.]",
      type=".*"
    ), "?"),
  Elapsed=list(
    hours=int.pattern,
    ":",
    minutes=int.pattern,
    ":",
    seconds=int.pattern))
tidyr.range.pattern <- "\\[([0-9]+)(?:-([0-9]+))?\\]"
tidyr.task.pattern <- paste0(
  "_(?:([0-9]+)|",
  tidyr.range.pattern, 
  ")")
tidyr.job.pattern <- paste0(
  "([0-9]+)", 
  tidyr.task.pattern,
  "(?:[.](.*))?")

rematch2.patterns <- sapply(namedCapture.patterns, function(L){
  namedCapture::variable_args_list(L)$pattern
})

## interesting: for(){big <- cbind(big, small)} is more efficient than do.call(cbind, big.list)!

## But not true for rbind...!

timing.dt.list <- list()
for(subject.size in 10^seq(2, 5, by=0.5)){
  subject.list <- list()
  for(name in names(sacct.dt)){
    subject.list[[name]] <- rep(sacct.dt[[name]], l=subject.size)
  }
  subject <- do.call(data.table, subject.list)
  namedCapture.args <- c(list(subject), namedCapture.patterns)
  timing <- microbenchmark::microbenchmark(
    "tidyr::extract(ICU)"={
      job.df <- tidyr::extract(
        subject, "JobID", 
        c("job", "task", "task1", "taskN", "type"), 
        tidyr.job.pattern,
        convert=TRUE)
      tidyr::extract(
        job.df, "Elapsed", c("hours", "minutes", "seconds"),
        "([0-9]+):([0-9]+):([0-9]+)",
        convert=TRUE)
    },
    "rematch2::bind_re_match(PCRE)"={
      ## out.df <- subject
      ## for(col.name in names(rematch2.patterns)){
      ##   out.df <- rematch2::bind_re_match_(
      ##     out.df, col.name, rematch2.patterns[[col.name]])
      ## }
      subject %>%
        rematch2::bind_re_match(JobID, rematch2.patterns[["JobID"]]) %>%
        rematch2::bind_re_match(Elapsed, rematch2.patterns[["Elapsed"]]) 
    },
    "namedCapture::df_match_variable(PCRE)"={
      options(namedCapture.engine="PCRE")
      do.call(df_match_variable, namedCapture.args)
    },
    "namedCapture::df_match_variable(RE2)"={
      options(namedCapture.engine="RE2")
      do.call(df_match_variable, namedCapture.args)
    },
    times=5)
  timing.dt.list[[paste(subject.size)]] <- data.table(subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)
saveRDS(timing.dt, "sacct.rds")
