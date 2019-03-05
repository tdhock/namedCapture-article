options(repos="http://cloud.r-project.org")
### Write down what package versions work with your R code, and
### attempt to download and load those packages. The first argument is
### the version of R that you used, e.g. "3.0.2" and then the rest of
### the arguments are package versions. For
### CRAN/Bioconductor/R-Forge/etc packages, write
### e.g. RColorBrewer="1.0.5" and if RColorBrewer is not installed
### then we use install.packages to get the most recent version, and
### warn if the installed version is not the indicated version. For
### GitHub packages, write "user/repo@commit"
### e.g. "tdhock/animint@f877163cd181f390de3ef9a38bb8bdd0396d08a4" and
### we use install_github to get it, if necessary.
works_with_R <- function(Rvers,...){
  local.lib <- file.path(getwd(), "library")
  old.path.vec <- .libPaths()
  if(! local.lib %in% old.path.vec){
    dir.create(local.lib, showWarnings=FALSE, recursive=TRUE)
    .libPaths(local.lib)
  }
  pkg_ok_have <- function(pkg,ok,have){
    stopifnot(is.character(ok))
    if(!as.character(have) %in% ok){
      warning("works with ",pkg," version ",
              paste(ok,collapse=" or "),
              ", have ",have)
    }
  }
  pkg_ok_have("R",Rvers,getRversion())
  pkg.vers <- list(...)
  for(pkg.i in seq_along(pkg.vers)){
    vers <- pkg.vers[[pkg.i]]
    pkg <- if(is.null(names(pkg.vers))){
      ""
    }else{
      names(pkg.vers)[[pkg.i]]
    }
    if(pkg == ""){# Then it is from GitHub.
      ## suppressWarnings is quieter than quiet.
      if(!suppressWarnings(require(requireGitHub))){
        ## If requireGitHub is not available, then install it using
        ## devtools.
        if(!suppressWarnings(require(devtools))){
          install.packages("devtools")
          require(devtools)
        }
        install_github("tdhock/requireGitHub")
        require(requireGitHub)
      }
      requireGitHub(vers)
    }else{# it is from a CRAN-like repos.
      if(!suppressWarnings(require(pkg, character.only=TRUE))){
        install.packages(pkg)
      }
      pkg_ok_have(pkg, vers, packageVersion(pkg))
      library(pkg, character.only=TRUE)
    }
  }
}
works_with_R(
  "3.6.0",
  microbenchmark="1.4.6",
  data.table="1.12.0",
  dplyr="0.7.6",
  rex="1.1.2",
  namedCapture="2019.2.28",
  rematch2="2.0.1",
  stringr="1.3.1",
  stringi="1.2.4",
  re2r="0.2.0")

trackDb.txt.gz <- system.file(
  "extdata", "trackDb.txt.gz", package="namedCapture")
trackDb.lines <- readLines(trackDb.txt.gz)

if(FALSE){
namedCapture:::variable_args_list(
      trackDb.lines,
      "track ",
      name=trackName.pattern,
      "(?:\n[^\n]+)*",
      "\\s+bigDataUrl ",
      bigDataUrl="[^\n]+")
}
pattern <- "track ((.*?)_(McGill([0-9,]+))(Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl ([^\n]+)"
named.pattern <- "track (?P<trackName>(?P<cellType>.*?)_(?P<sampleName>McGill(?P<sampleID>[0-9,]+))(?P<dataType>Coverage|Peaks)|[^\n]+)(?:\n[^\n]+)*\\s+bigDataUrl (?P<bigDataUrl>[^\n]+)"
timing.dt.list <- list()
for(subject.size in 10^seq(2, 5, by=0.5)){
  subject <- rep(trackDb.lines, l=subject.size)
  timing <- microbenchmark::microbenchmark("re2r::re2_match_all"={
    m <- re2r::re2_match_all(paste(subject, collapse="\n"), named.pattern)[[1]]
    data.frame(m[,-1]) %>% mutate(
      sampleID=as.integer(sampleID))
  }, "stringr::str_match_all"={
    m <- stringr::str_match_all(paste(subject, collapse="\n"), pattern)[[1]]
    data.frame(m[,-1]) %>% mutate(
      sampleID=as.integer(X4))
  }, "stringi::stri_match_all"={
    m <- stringi::stri_match_all(paste(subject, collapse="\n"), regex=pattern)[[1]]
    data.frame(m[,-1]) %>% mutate(
      sampleID=as.integer(X4))
  }, "base::gregexpr(perl=TRUE)"={
    g.res <- gregexpr(
      named.pattern, paste(subject, collapse="\n"), perl=TRUE)[[1]]
  ## }, "base::gregexpr(perl=FALSE)"={
  ##   gregexpr(pattern, paste(subject, collapse="\n"), perl=FALSE)[[1]]
  ## }, "namedCapture::str_match_all_named"={
  ##   namedCapture::str_match_all_named(paste(subject, collapse="\n"), named.pattern)[[1]]
  }, "rematch2::re_match_all"={
    tib <- rematch2::re_match_all(paste(subject, collapse="\n"), named.pattern)
  }, "rex::re_matches"={
    re_matches(paste(subject, collapse="\n"), named.pattern, global=TRUE)[[1]] %>% mutate(
      sampleID=as.integer(sampleID))
  }, "namedCapture::str_match_all_variable"={
    int.pattern <- list("[0-9]+", as.integer)
    trackName.pattern <- list(
      cellType=".*?",
      "_",
      sampleName=list(
        "McGill",
        sampleID=int.pattern),
      dataType="Coverage|Peaks",
      "|",
      "[^\n]+")
    match.df <- namedCapture::str_match_all_variable(
      subject,
      "track ",
      trackName=trackName.pattern,
      "(?:\n[^\n]+)*",
      "\\s+bigDataUrl ",
      bigDataUrl="[^\n]+")
  },
  times=5)
  print(timing)
  timing.dt.list[[paste(subject.size)]] <- data.table(subject.size, timing)
}
timing.dt <- do.call(rbind, timing.dt.list)

if(FALSE){
  timing.dt[, seconds := time/1e9]
  stats.dt <- timing.dt[, list(
    median=median(seconds),
    q25=quantile(seconds, 0.25),
    q75=quantile(seconds, 0.75)
  ), by=list(expr, subject.size)]
  library(ggplot2)
  gg <- ggplot()+
    geom_ribbon(aes(
      subject.size, ymin=q25, ymax=q75, fill=expr),
      alpha=0.5,
      data=stats.dt)+
    geom_line(aes(
      subject.size, median, color=expr),
      data=stats.dt)+
    scale_x_log10(limits=c(1e2, 1e5))+
    scale_y_log10()
  directlabels::direct.label(gg, "last.polygons")

  gg <- ggplot()+
    geom_ribbon(aes(
      subject.size, ymin=q25, ymax=q75, fill=expr),
      alpha=0.5,
      data=stats.dt)+
    geom_line(aes(
      subject.size, median, color=expr),
      data=stats.dt)+
    xlim(0, 1e5)
  directlabels::direct.label(gg, "last.polygons")
}

saveRDS(timing.dt, "trackDb.rds")
