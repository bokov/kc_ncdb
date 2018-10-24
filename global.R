#' ---
#' title: "Generic Global R Settings"
#' author: "Alex F. Bokov"
#' date: "10/18/2018"
#' ---
#' 
#' This is a script that loads (and if needed, installs)
#' libraries needed for this project, and sets a few global
#' variables that will be needed by many different scripts.
#' Keep this script minimalistic and *no number crunching here*
#' 
# local_fns --------------------------------------------------------------------
#' ## Local functions
#+ warning=FALSE, message=FALSE
source('./functions.R');
# Now that we are managing trailR as a standalone package, need devtools
if(!'devtools' %in% names(installed.packages()[,1])) instrequire('devtools');
devtools::install_github('bokov/trailR',ref='integration'); library(trailR);
#source('./trailR.R');

# libs -------------------------------------------------------------------------
#' Libraries
#' 
#' load and if necessary install needed libraries
#+ warning=FALSE, message=FALSE
instrequire(
  c(# just-in-time compilation
    # 'compiler'
    
    # propensity scores and glm residuals
    #,'MatchIt','DHARMa'
    
    # zero-inflated poisson, sigh
    #,'pscl'
    
    # various analysis methods
    'survival' # this one can be moved to exploration.R
    #,'MASS','Hmisc','zoo','coin'
    
    # evaluating predictive power
    #,'survAUC','survivalROC','pROC'
    
    # for pd matrices needed by faker()
    #,'Matrix'
    
    # data manipulation & piping. 
    # 'tools' is used by trailR.R
    # 'LaF' is used for fast and powerful reading of text files.
    ,'readr','dplyr','magrittr','tools','LaF'
    # dummies breaks categoric variables into individual dummy variables
    ,'dummies'
    #,'lubridate'
    
    # plotting
    ,'ggfortify','survminer'
    #,'ggplot2','grid','GGally','heatmap3','gridExtra','scales'
    
    # string manipulation
    ,'stringi' #,'stringr'
    
    # table formatting
    ,'pander','tableone','broom'
    #,'knitr','htmltab','stargazer','janitor'
    
    # Web
    ,'RCurl','XML'
));

#' Turn JIT to max: pre-compile all closures, `for`, `while`, and `repeat` loops
#enableJIT(3);
# config -----------------------------------------------------------------------
#' ## Load local config file
#' 
source('./config.R');

# vars -------------------------------------------------------------------------
#' ## Set generic variables
#' 
#' That is to say, variables which can be set without reference to the data and
#' do not take a lot of time to do.
#' 
#' data dictionary produced by datafinisher, should physically accompany inputdata
if(!exists('dctfile_raw')) {
  dctfile_raw <- dctfile_ncdb_raw};
#' data dictionary template-- metadata that should persist accross multiple 
#' versions of the data and data dictionary
dctfile_tpl <- 'datadictionary_static.csv';
#' checked-in file, with added rows and columns, ready-to-use FOR THIS DATASET
#' if it doesn't exist, it will get created in data.R
dctfile <- paste0('dct_',basename(inputdata));
#' This is the file that lists levels of discrete variables and what each listed
#' level should be renamed to.
levels_map_file <- 'levels_map.csv';
#' random seed
project_seed <- 20181018;
# searchrep --------------------------------------------------------------------
globalsearchrep <- rbind(
  c('\\[[0-9,]+ facts; [0-9,]+ patients\\]','')
);

# urls -------------------------------------------------------------------------
urls <- list(
  # recent version of compiled document online
   exp_rpubs='https://rpubs.com/bokov/kidneycancer'
  # archival version for discontinued figures
  ,exp_181009='https://rpubs.com/bokov/kidneycancer_181009'
  # NAACCR data dictionary, section 10
  ,dict_naaccr='http://datadictionary.naaccr.org/?c=10'
  # base URL for git tickets
  ,git_tix='https://github.com/bokov/kc_ncdb/issues/'
  );
#' RPubs keeps the actual content in an iframe, and this cool little 3-liner 
#' gets the address of that iframe's target so in principle I can now construct
#' links with targets to other documents I published previously, starting with
#' the most recent version of this document.
urls$exp_raw <- getURL(urls$exp_rpubs) %>% 
  htmlParse %>% xpathApply('//iframe') %>% `[[`(1) %>% xmlAttrs() %>% 
  paste0('https:',.);
urls$exp_raw_181009 <- getURL(urls$exp_181009) %>% 
  htmlParse %>% xpathApply('//iframe') %>% `[[`(1) %>% xmlAttrs() %>% 
  paste0('https:',.);
# fs_templates -----------------------------------------------------------------
#' templates for `fs()` ... note that the actual values inserted depend on 
#' the other arguments of `fs()` and the columns of the data dictionary
fstmplts <- list(
  # [n_ddiag]: #n_ddiag "0390 Date of Diagnosis"
  linkref="[%1$s]: %2$s \"%4$s\"\n"  
  # [`n_ddiag`][#n_ddiag]
  ,link_varname="[`%1$s`][%2$s]"
  # [`0390 Date of Diagnosis`][#n_ddiag]
  ,link_colnamelong="[`%4$s`][%2$s]"
  # `0390 Date of Diagnosis`
  ,code_colnamelong="`%4$s`"
  # 0390 Date of Diagnosis
  ,plain_colnamelong="%4$s"
  # note2self spans, each linking to a ticket
  ,n2s=paste0('(',urls$git_tix,'%1$s){#gh%1$s .note2self custom-style="note2self"}')
  # NCDB style variable definitions
  ,ncdb_def=paste(':::::{%2$s .vardef custom-style=\"vardef\"}',' %4$s :'
                  ,'  ~ %1$s\n\n',sep='\n\n')
);
c()
