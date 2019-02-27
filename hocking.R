### R code from vignette source '/home/tdhock/projects/namedCapture-article/hocking.Rnw'

###################################################
### code chunk number 1: subject
###################################################

chr.pos.subject <- c(
  "chr10:213,054,000-213,055,000",
  "chrM:111,000",
  "this will not match",
  NA, # neither will this.
  "chr1:110-111 chr2:220-222") # two possible matches.



###################################################
### code chunk number 2: chrPosPattern
###################################################

chr.pos.pattern <- paste0(
  "(?P<chrom>chr.*?)",
  ":",
  "(?P<chromStart>[0-9,]+)",
  "(?:",
    "-",
    "(?P<chromEnd>[0-9,]+)",
  ")?")



###################################################
### code chunk number 3: chrPosNoTypes
###################################################

(match.mat <- namedCapture::str_match_named(
  chr.pos.subject, chr.pos.pattern))



###################################################
### code chunk number 4: chrPosNoTypes
###################################################

int.from.digits <- function(captured.text){
  as.integer(gsub("[^0-9]", "", captured.text))
}
conversion.list <- list(
  chromStart=int.from.digits,
  chromEnd=int.from.digits)
(match.df <- namedCapture::str_match_named(
  chr.pos.subject, chr.pos.pattern, conversion.list))



###################################################
### code chunk number 5: allChrPos
###################################################

namedCapture::str_match_all_named(
  chr.pos.subject, chr.pos.pattern, conversion.list)



###################################################
### code chunk number 6: namedSubject
###################################################

named.subject <- c(
  ten="chr10:213,054,000-213,055,000",
  M="chrM:111,000",
  two="chr1:110-111 chr2:220-222") # two possible matches.
namedCapture::str_match_named(
  named.subject, chr.pos.pattern, conversion.list)
namedCapture::str_match_all_named(
  named.subject, chr.pos.pattern, conversion.list)



###################################################
### code chunk number 7: namedSubjectPattern
###################################################

name.pattern <- paste0(
  "(?P<name>chr.*?)",
  ":",
  "(?P<chromStart>[0-9,]+)",
  "(?:",
    "-",
    "(?P<chromEnd>[0-9,]+)",
  ")?")
namedCapture::str_match_named(
  named.subject, name.pattern, conversion.list)
namedCapture::str_match_all_named(
  named.subject, name.pattern, conversion.list)



###################################################
### code chunk number 8: strMatchNamed
###################################################

namedCapture::str_match_variable(
  named.subject, 
  "(?P<chrom>chr.*?)",
  ":",
  "(?P<chromStart>[0-9,]+)",
  "(?:",
    "-",
    "(?P<chromEnd>[0-9,]+)",
  ")?")



###################################################
### code chunk number 9: namedArgs
###################################################

namedCapture::str_match_variable(
  named.subject, 
  chrom="chr.*?",
  ":",
  chromStart="[0-9,]+",
  "(?:",
    "-",
    chromEnd="[0-9,]+",
  ")?")



###################################################
### code chunk number 10: inlineconversion
###################################################

namedCapture::str_match_variable(
  named.subject, 
  chrom="chr.*?",
  ":",
  chromStart="[0-9,]+", int.from.digits,
  "(?:",
    "-",
    chromEnd="[0-9,]+", int.from.digits,
  ")?")



###################################################
### code chunk number 11: subPatternList
###################################################

int.pattern <- list("[0-9,]+", int.from.digits)
namedCapture::str_match_variable(
  named.subject, 
  chrom="chr.*?",
  ":",
  chromStart=int.pattern,
  "(?:",
    "-",
    chromEnd=int.pattern,
  ")?")



###################################################
### code chunk number 12: nonCapturingList
###################################################

namedCapture::str_match_variable(
  named.subject, 
  chrom="chr.*?",
  ":",
  chromStart=int.pattern,
  list(
    "-",
    chromEnd=int.pattern
  ), "?")



###################################################
### code chunk number 13: trackDb
###################################################

trackDb.txt.gz <- system.file(
  "extdata", "trackDb.txt.gz", package="namedCapture")
trackDb.lines <- readLines(trackDb.txt.gz)



###################################################
### code chunk number 14: catTrackDB
###################################################

cat(trackDb.lines[78:107], sep="\n")



###################################################
### code chunk number 15: fieldsDF
###################################################

fields.mat <- namedCapture::str_match_all_variable(
  trackDb.lines,
  "track ",
  name="\\S+",
  fields="(?:\n[^\n]+)*",
  "\n")
head(substr(fields.mat, 1, 50))



###################################################
### code chunk number 16: fieldsList
###################################################

fields.list <- namedCapture::str_match_all_named(
  fields.mat[, "fields"], paste0(
    "\\s+",
    "(?P<name>.*?)",
    " ",
    "(?P<value>[^\n]+)"))
fields.list$bcell_McGill0091Coverage



###################################################
### code chunk number 17: trackDbMatchAll
###################################################

match.df <- namedCapture::str_match_all_variable(
  trackDb.lines,
  "track ",
  name=list(
    cellType=".*?",
    "_",
    sampleName=list(
      "McGill",
      sampleID=int.pattern),
    dataType="Coverage|Peaks",
    "|",
    "[^\n]+")) 
match.df["bcell_McGill0091Coverage", ] 



###################################################
### code chunk number 18: sacctdf
###################################################

(sacct.df <- data.frame(
  Elapsed=c("07:04:42", "07:04:42", "07:04:49", "00:00:00", "00:00:00"),
  JobID=c("13937810_25", "13937810_25.batch", "13937810_25.extern",
    "14022192_[1-3]", "14022204_[4]"), stringsAsFactors=FALSE))



###################################################
### code chunk number 19: rangePat
###################################################

range.pattern <- list(
  "[[]",
  task1=int.pattern,
  list(
    "-",
    taskN=int.pattern
  ), "?",
  "[]]")
namedCapture::df_match_variable(sacct.df, JobID=range.pattern)



###################################################
### code chunk number 20: taskPat
###################################################

task.pattern <- list(
  "_", list(
    task=int.pattern,
    "|",#either one task(above) or range(below)
    range.pattern))
namedCapture::df_match_variable(sacct.df, JobID=task.pattern)



###################################################
### code chunk number 21: dfMatchVar
###################################################

namedCapture::df_match_variable(
  sacct.df,
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



###################################################
### code chunk number 22: logsubject
###################################################

log.subject <- 'gate3.fmr.com - - [05/Jul/1995:13:51:39 -0400] "GET /shuttle/countdown/ 
curly02.slip.yorku.ca - - [10/Jul/1995:23:11:49 -0400] "GET /sts-70/sts-70-patch-small.gif
boson.epita.fr - - [15/Jul/1995:11:27:49 -0400] "GET /movies/sts-71-mir-dock.MPG
134.153.50.9 - - [13/Jul/1995:11:02:50 -0400] "GET /icons/text.xbm'
log.lines <- strsplit(log.subject, split="\n")[[1]]



###################################################
### code chunk number 23: rex
###################################################

library(rex)
library(dplyr)
(rex.filetype.pattern <- rex(
  non_spaces, ".",
  capture(name = 'filetype',
          none_of(space, ".", "?", double_quote) %>% one_or_more())))



###################################################
### code chunk number 24: rexFull
###################################################

rex.pattern <- rex(
  "[",
  capture(name = "time", none_of("]") %>% zero_or_more()),
  "]",
  space, double_quote, "GET", space,
  maybe(rex.filetype.pattern))



###################################################
### code chunk number 25: reMatches
###################################################

re_matches(log.lines, rex.pattern) %>% mutate(
  filetype = tolower(filetype),
  time = as.POSIXct(time, format="%d/%b/%Y:%H:%M:%S %z"))



###################################################
### code chunk number 26: lognamedcapture
###################################################

namedCapture.filetype.pattern <- list(
  "[^[:space:]]+[.]", 
  filetype='[^[:space:].?"]+', tolower)



###################################################
### code chunk number 27: s
###################################################

namedCapture::str_match_variable(
  log.lines,
  "\\[",
  time="[^]]*", function(x)as.POSIXct(x, format="%d/%b/%Y:%H:%M:%S %z"),
  "\\]",
  ' "GET ',
  namedCapture.filetype.pattern, "?")



###################################################
### code chunk number 28: tidyr.range
###################################################

tidyr.range.pattern <- "\\[([0-9]+)(?:-([0-9]+))?\\]"
tidyr::extract(
  sacct.df, "JobID", c("task1", "taskN"), 
  tidyr.range.pattern, remove=FALSE)



###################################################
### code chunk number 29: tidyr.task
###################################################

tidyr.task.pattern <- paste0(
  "_(?:([0-9]+)|",
  tidyr.range.pattern, 
  ")")
tidyr::extract(
  sacct.df, "JobID", c("task", "task1", "taskN"), 
  tidyr.task.pattern, remove=FALSE)



###################################################
### code chunk number 30: tidyr.job
###################################################

tidyr.job.pattern <- paste0(
  "([0-9]+)", 
  tidyr.task.pattern,
  "(?:[.](.*))?")
(job.df <- tidyr::extract(
  sacct.df, "JobID", 
  c("job", "task", "task1", "taskN", "type"), 
  tidyr.job.pattern))



###################################################
### code chunk number 31: tidyr2
###################################################

tidyr::extract(
  job.df, "Elapsed", c("hours", "minutes", "seconds"),
  "([0-9]+):([0-9]+):([0-9]+)",
  convert=TRUE)



