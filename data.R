#' ---
#' title: "Kidney Cancer NCDB Data Processing"
#' author: "Alex F. Bokov"
#' date: "10/18/2018"
#' ---
#' 
#' Please read this file through before trying to run it. The comments tell
#' you what you need to edit in order to proceed.
#' 
# init -------------------------------------------------------------------------
source('global.R');
.depends <- 'dictionary.R';
.depdata <- paste0(.depends,'.rdata');
.currentscript <- parent.frame(2)$ofile;
if(is.null(.currentscript)) .currentscript <- 'RUN_FROM_INTERACTIVE_SESSION';
tself(scriptname=.currentscript);
if(!file.exists(.depdata)) system(sprintf('R -e "source(\'%s\')"',.depends));
.loadedobjects <- tload(.depdata);
#knitr::opts_chunk$set(echo = F,warning = F,message=F);
#' Default args
formals(v)$dat <- as.name('dat1');
#' Saving original file-list so we don't keep exporting functions and 
#' environment variables to other scripts
.origfiles <- ls();
#' Create custom synonyms for 'TRUE' if needed
l_truthy_default <- eval(formals(truthy.default)$truewords);
l_missing <- c(NA,'Unknown','unknown','UNKNOWN','UNK','-');
# dat1 organize codes ----------------------------------------------------------
#' Create copy of original dataset
dat1 <- dat0;
#' Bulk-transform the NA/non-NA columns to FALSE/TRUE ones
# for(ii in v(c_natf)) dat1[[ii]] <- !is.na(dat1[[ii]]);
#' Rename columns that will be individually referenced later on so that they
#' always have the same name regardless of the data version
# names(dat1) <- submulti(names(dat1)
#                         ,searchrep=as.matrix(na.omit(dct0[,c('colname','varname')]))
#                         ,method='startsends');
#' Mass relabel/reorder factor variables.
for(.ii in unique(levels_map$varname)){
  dat1[[.ii]] <- factorclean(dat1[[.ii]],spec_mapper = levels_map,var=.ii
                            ,droplevels = T)};
#' 
#' Simplified recurrence type: Not available in NCDB?
#' 
#' Unified diabetes comorbidity: no comorbidity in NCDB as far as I can tell
#' 
#' Find the patients which had active kidney cancer (rather than starting with 
#' pre-existing): data not available in NCDB as far as I can tell
#' 
#' hispanic strict and lenient: unified variable already baked into NCDB
#' 
#' cohorts <- data.frame(patient_num=unique(dat1$patient_num)) %>% 
#'   mutate( NAACCR=patient_num %in% kcpatients.naaccr
#'          ,EMR=patient_num %in% kcpatients.emr
#'          ,PreExisting=patient_num %in% kcpatients.pre_existing
#'          ,combo=interaction(NAACCR,EMR,PreExisting)) %>% group_by(combo);
#' 
#' consort_table <- summarise(cohorts,NAACCR=any(NAACCR),EMR=any(EMR)
#'                            ,PreExisting=any(PreExisting)
#'                            ,N=length(patient_num))[,-1];
# save out ---------------------------------------------------------------------
#' ## Save all the processed data to an rdata file 
#' 
#' ...which includes the audit trail
tsave(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
c()