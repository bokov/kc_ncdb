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
options(gitstamp_prod=F);
.depends <- 'dictionary.R';
.depdata <- paste0(.depends,'.rdata');
.currentscript <- parent.frame(2)$ofile;
if(is.null(.currentscript)) .currentscript <- 'RUN_FROM_INTERACTIVE_SESSION';
tself(scriptname=.currentscript);
if(!file.exists(.depdata)) system(sprintf('R -e "source(\'%s\')"',.depends));
.loadedobjects <- tload(.depdata);
#knitr::opts_chunk$set(echo = F,warning = F,message=F);
#' Default args
formals(v)[c('dat','retcol')] <- c(as.name('dat1'),'colname');
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
for(.ii in setdiff(levels_map$varname,v(c_donotmap))){
  dat1[[.ii]] <- factorclean(dat1[[.ii]],spec_mapper = levels_map,var=.ii
                            ,droplevels = T)};
for(.ii in intersect(levels_map$varname,v(c_donotmap))){
  # so far all the special levels of 0 amount to a numeric value of 0, but this 
  # might need to be handled differently later
  .navals <- setdiff(levels_map[levels_map$varname==.ii,'code'],0);
  if(any(dat1[[.ii]] %in% .navals)){
    dat1[[.sii<- paste0(.ii,'_special')]] <- factorclean(dat1[[.ii]]
                                                         ,spec_mapper=levels_map
                                                         ,var=.ii
                                                         ,droplevels = T);
    dat1[[.ii]][dat1[[.ii]] %in% .navals] <- NA;
    # blow away the non-special levels in the special version of this variable
    dat1[[.sii]][!is.na(dat1[[.ii]])]<-NA;}
}
#' 
#' Map official NCDB labels to their numeric codes
for(ii in unique(subset(levels_map,!is.na(relabel))$varname)){
  .ilevs <- subset(levels_map,varname==ii);
  .irename <- .ilevs[,c('var_rename','varname')] %>% 
    mutate(varname=paste0('a_',tolower(varname))) %>% 
    #(function(xx){browser();xx}) %>% 
    do.call(coalesce,.) %>% unique;
  dat1[[.irename[1]]] <- with(.ilevs,set_names(relabel,label)) %>%
    as.list %>% c(list(dat1[[ii]]),.) %>% do.call(recode,.)};
#' Simplified ethnicity variable
dat1$a_eth <- with(dat1
                   ,case_when(a_hsp != 'non-Hispanic' ~ 
                                as.character(a_hsp)
                              ,a_race %in% c('Black','White') ~ 
                                paste0('non-Hisp ',a_race)
                              ,TRUE ~ 
                                as.character(a_race)));
#' Simplify the TNM_PATH_T variable
dat1$a_path_t <- gsub('A|B|C','',dat1$TNM_PATH_T) %>% gsub('p','pT',.);
# subsets ---------------------------------------------------------------
sbs0 <- alist(kidney=PRIMARY_SITE=='C649',
              # analyze stage IV separately
              no_stg4=ANALYTIC_STAGE_GROUP!='4: Stage IV',
              # only do the surgical cases
              surgery=REASON_FOR_NO_SURGERY=='0: Surgery of the primary site was performed'&
                # only do the surgical cases
                RX_HOSP_SURG_APPR_2010!='0: No surgical procedure of primary site',
              # only the patients who are presenting with their first ever tumor
              firstcancer=SEQUENCE_NUMBER=='00') %>% lapply(function(xx) with(dat1,PUF_CASE_ID[eval(xx)]));
sbs0$eligib0 <- Reduce(intersect,sbs0);

# dummy variables -------------------------------------------------------
#' Create dummy variables for univariate analysis of individual levels where
#' applicable
dat2 <- subset(dat1,PUF_CASE_ID %in% sbs0$eligib0) %>% 
  dummy.data.frame(names=setdiff(v(c_discrete)
                                 ,c(v(c_missingmap),v(c_nonanalytic)))
                   ,omit.constants = F,dummy.classes = '',sep=':::');
#' 
# cox ph ----------
#' Bulk univariate analysis
# .cph0 <- coxph(Surv(DX_LASTCONTACT_DEATH_MONTHS,PUF_VITAL_STATUS=='0: Dead')~1
#                ,data=dat2);
# .cph0_update <- setdiff(names(dat2),c(v(c_missingmap),v(c_nonanalytic))) %>% 
#   sapply(function(xx) xx[!xx %in% c(v(c_missingnap),v(c_nonanalytic)) && 
#                            mean(is.na(dat2[[xx]])<0.2)&&
#                            #!grepl('_special$',xx)&&
#                            (!grepl(':::',xx)||min(table(dat2[[xx]]))>20)] %>% 
#            sprintf('.~`%s`',.),simplify=F) %>% `[`(.,sapply(.,length)>0);
# cph_uni <- list();
# message('Doing univariate fits');
# for(.ii in names(.cph0_update)) cph_uni[[.ii]]<-update(.cph0
#                                                        ,.cph0_update[[.ii]]);
# cph_uni_tab <- cph_uni[!sapply(cph_uni,is,'try-error')] %>% 
#   sapply(function(xx) cbind(tidy(xx),glance(xx)),simplify=F) %>% 
#   do.call(bind_rows,.) %>% arrange(desc(concordance)) %>% 
#   mutate(term=gsub('`','',term),var=gsub(':::.*$','',term)
#          ,level=gsub('^.*:::','',term),p.adj.sc=p.adjust(p.value.sc));
# save out ---------------------------------------------------------------------
#' ## Save all the processed data to an rdata file 
#' 
#' ...which includes the audit trail
tsave(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
c()