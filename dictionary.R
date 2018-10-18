#' ---
#' title: "Kidney Cancer NCDB Data Dictionary Init"
#' author: 
#' - "Alex F. Bokov^[UT Health, Department of Epidemiology and Biostatistics]"
#' date: "10/18/2018"
#' ---
#' 
# init -------------------------------------------------------------------------
source('global.R');
.currentscript <- parent.frame(2)$ofile;
if(is.null(.currentscript)) .currentscript <- 'RUN_FROM_INTERACTIVE_SESSION';
tself(scriptname=.currentscript);
project_seed <- 20181018;
debug <- 1;
#' Default args
formals(v)$dat <- as.name('dat1');
#' Saving original file-list so we don't keep exporting functions and 
#' environment variables to other scripts
.origfiles <- ls();
#' 
# make data dictionary ---------------------------------------------------------
#' Create the data dictionary
.dctraw <- tread(dctfile_raw,readLines) %>%
  # blow away the non UTF-8 characters
  submulti(cbind(c('\x93|\x94','\x96'),c('"','-')));

dct0 <- full_join(
  # variable name mappings
   .dctraw[grep('^label var',.dctraw)] %>% gsub('label var |\t','',.) %>% 
     paste0(collapse='\n') %>% read_delim('"',trim_ws = T,col_names=F) %>% 
     select(1:2) %>% set_colnames(c('colname','colname_long'))
  # variable data types and offests for the FWF NCDB data
  ,.dctraw[grep('^infix ',.dctraw):(grep('[ ]*using ',.dctraw)-1)] %>% 
    gsub('(\\s|infix|-)+',' ',.) %>% paste0(collapse='\n') %>% 
    read_delim(.,' ',trim_ws=T,col_names = F) %>% select(2:5) %>% 
    set_colnames(c('type','colname','start','stop'))
);

if(nrow(dct0)!=length(grep('^label var',.dctraw))) {
  stop('
Data dictionary mismatch the "make data dictionary" section of dictionary.R')};
#'
# level names ------------------------------------------------------------------
levels_map <- data.frame(lstart=grep('^label define',.dctraw)
                         ,lstop=grep('^label values',.dctraw)) %>% 
  cbind(.,name=gsub('label define ([A-Z0-9_]+).*','\\1'
                    ,.dctraw[(.)$lstart]),stringsAsFactors=F) %>% 
  apply(1,function(xx) {
    .dctraw[as.numeric(xx[1])+seq_len(diff(as.numeric(xx[1:2]))-1)] %>% 
      gsub('\t','',.) %>% c(NA,.) %>% paste0(collapse='\n') %>% 
      read_delim(.,'"',col_names=F,skip = 1,trim_ws=T) %>% select(1:2) %>% 
      cbind(var=xx[3])}) %>% 
  do.call(rbind,.) %>% set_names(c('code','label','varname'));

# read in data -----------------------------------------------------------------
dat0 <- with(dct0,tread(inputdata_ncdb,read_fwf
                        ,col_positions = fwf_positions(start,stop,colname)
                        ,n_max=20
                        ,col_types = do.call(cols,as.list(set_names(recode(
                          type,str='c',byte='l',int='i',long='n',float='n'
                          ),colname)))));

# save out ---------------------------------------------------------------------
#' ## Save all the processed data to an rdata file 
#' 
#' ...which includes the audit trail
tsave(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
c()