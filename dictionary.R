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
debug <- 1;
#' Default args
formals(v)$dat <- as.name('dat1');
#' Saving original file-list so we don't keep exporting functions and 
#' environment variables to other scripts
.origfiles <- ls();
#' Do not remap the following variables specified by `r basename(dctfile_raw)`
.levels_map_ignore <- c('AGE','DX_LASTCONTACT_DEATH_MONTHS'
                        ,'RAD_ELAPSED_RX_DAYS','RAD_NUM_TREAT_VOL'
                        ,'RAD_REGIONAL_DOSE_CGY','TUMOR_SIZE');
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
  do.call(rbind,.) %>% set_names(c('code','label','varname')) %>% 
  subset(!varname %in% .levels_map_ignore);

# read in data -----------------------------------------------------------------
#' hardcoding the number of rows so that the same random sample gets chosen each
#' run of these scripts. Don't change until you are absolutely positively 
#' certain that method development/testing/validation and you have committed to
#' publishing its results no matter what they may be.
#' 
#' Or if you obtained a different year or eligibility set of course.
input_nrows <- 465126;
sample_size <- round(input_nrows/100);
fh <- with(dct0,tread(inputdata_ncdb,laf_open_fwf
                      ,column_types = recode(type,str='string',int='integer'
                                             ,long='double',float='double'
                                             ,byte='integer')
                      ,column_widths = 1+stop-start,column_names = colname));
#' Create a variable named `use_all_data` in config.R or global.R and set it to
#' any value. IF YOU'RE SURE YOU HAVE THE HARDWARE TO HANDLE IT **and** ARE 
#' READY TO COMMIT TO FINAL ANALYSIS AS PER THE ABOVE COMMENT
sample_rows <- if(!exists('use_all_data')) {
  tseed(project_seed);sample(seq_len(input_nrows),sample_size)} else {
    seq_len(nrow(fh))};

dat0 <- LaF::read_lines(fh,rows=sample_rows);


# save out ---------------------------------------------------------------------
#' ## Save all the processed data to an rdata file 
#' 
#' ...which includes the audit trail
tsave(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
c()