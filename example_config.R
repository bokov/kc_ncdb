#' ---
#' title: "Generic R Project Configuration File"
#' author: "Alex F. Bokov, Ph.D."
#' date: "10/18/2018"
#' ---
#' 
#' Please copy this file to `config.R`, edit that copy, and copy it over to
#' the working directory whenever you check out this project. This is just an
#' example of what computer-specific variables should be set. This does not 
#' actually get called by `run.R`. A file needs to be called `config.R` in order
#' to be used as a source of configuration information by our scripts
#' 
inputdata <- 'NOT CURRENTLY USED BUT SHOULD BE SET TO SOME VALUE DOES NOT MATTER WHAT';
#' The full path to wherever you are keeping your .dat file from ncdb
inputdata_ncdb <- '/path/to/NCDBPUF_KidRnPel.0.2015.0.dat';
#' The full path to wherever you are keeping your .do (Stata) file for importing
#' the above `inputdata_ncdb` file
dctfile_ncdb_raw <- '/path/to/NCDB_PUF_Labels_2015.do';
#' 
#' ## Password for creating dashboard
.shinypw <- 'SHINYPASSWORD';
#'
c()