#' ---
#' title: "Kidney Cancer NCDB Variable Selection"
#' subtitle: "KL2 Aim 2"
#' author: 
#' - "Alex F. Bokov^[UT Health San Antonio]"
#' date: '`r format(Sys.Date(), "%B %d, %Y")`'
#' tags: ["data characterization", "preliminary", "NCDB", "urology", "cancer"]
#' thanks: ["Dr. Shawn Murphy", "Dr. Ronald Rodriguez", "Dr. Amelie Ramirez", "Dr. Joel Michalek"]
#' abstract: |
#'   Basic variable selection-- demographics and staging. 
#' link-citations: true
#' css: production.css
#' bibliography: kidneycancer.bib
#' csl: nature.csl
#' reference-section-title: Bibliography
#' fig_caption: yes
#' linkReferences: true
#' nameInLink: true
#' tblLabels: "roman"
#' tblPrefix: ["table","tables"]
#' output:
#'  html_document:
#'   keep_md: true
#'   pandoc_args: ['--filter','pandoc-crossref']
#'  word_document:
#'   reference_docx: 'nt_styletemplate.docx'
#'   keep_md: true
#'   pandoc_args: ['--filter','pandoc-crossref']
#'  pdf_document:
#'   keep_md: true
#'   pandoc_args: ['--filter','pandoc-crossref']
#' ---
#' 
#+ init, echo=FALSE, include=FALSE, message=FALSE
# init -------------------------------------------------------------------------
# if running in test-mode, uncomment the line below
options(gitstamp_prod=F);
.junk<-capture.output(source('global.R',echo=F));

default_font <- 'Times New Roman';

.depends <- c('dictionary.R','data.R');
.depdata <- paste0(.depends,'.rdata');
.currentscript <- parent.frame(2)$ofile;
if(is.null(.currentscript)) .currentscript <- knitr::current_input();
if(is.null(.currentscript)) .currentscript <- 'RUN_FROM_INTERACTIVE_SESSION';
tself(scriptname=.currentscript);
.loadedobjects <- c();
for(ii in seq_along(.depends)) {
  if(!file.exists(.depdata[ii])) system(sprintf('R -e "source(\'%s\')"'
                                                ,.depends[ii]));
  .loadedobjects <- union(.loadedobjects,tload(.depdata[ii]));
}
knitr::opts_chunk$set(echo = F,warning = F,message=F,fig.scap=NA,fig.lp=''
                      ,dev.args=list(family=default_font));

# if a text string named FOO is created prior to a named chunk also named FOO
# then specifying opts.label='fig_opts' in the options for that chunk will use
# that string as the caption
# knitr::opts_template$set(
#   fig_opts=alist(fig.cap=get0(knitr::opts_current$get("label"))
#                  ,results='asis'));

# Set default arguments for some functions
panderOptions('table.split.table',Inf);
panderOptions('missing','-');
panderOptions('table.alignment.default','right');
panderOptions('table.alignment.rownames','left');
.args_default_v <- formals(v);

# default arguments for getting lists of column names
formals(v)[c('dat','retcol')] <- c(as.name('dat1'),'colname');

# defaults for 'fancy span' string transformation of variable names 
.args_default_fs <- formals(fs);
# this is a copy of fs with different arguments, for note2self
n2s <- fs;
formals(n2s)[c('fs_reg','retfun','match_col')] <- alist(NULL,return,'colname');
formals(n2s)$template <- fstmplts$n2s;
# IN THE MAIN SECTION ONLY!! The retfun should be return for inline use and cat
# for use generating asis chunks.
formals(fs)[c('url','fs_reg','retfun')] <- alist(str,'fs_reg',return);
formals(fs)$template <- fstmplts$link_colnamelong;

# markdown snippets of boilerplate
md <- list(
  pbreak=cm('\n\n\n::::: {.pbreak custom-style="pbreak"}\n&nbsp;\n:::::\n\n\n','

Creates a page break, depends on custom styling at output end to either create a
page break and/or hide this code

')
  ,mainvars = v(c_main_naaccr_vars) %>% sapply(fs) %>% 
    (knitr::combine_words)
  );

# descriptive plots ------------------------------------------------------------
#' # Plots of test data {#sec:descplots}
#' 
# conclusions ---------------------------------------------------------
#' # Conclusion and next steps {#sec:nextsteps}
#' 
#'
#' # References
#' 
#' ::::: {#refs}
#' &nbsp;
#' :::::
#'
# A1 supplementary results -----------------------------------------------------
#' `r md$pbreak`
#' # : Supplementary Results {#sec:supp label="Appendix 1"}
#' 
#' 
# A2 variables -----------------------------------------------------------------
#'
#' # Variable descriptions {#sec:vars label="Appendix 2"}
#' 
#' 
#+ progfootnotes, results='asis'
fs(getOption('fs_reg'),url=paste0('#',getOption('fs_reg'))
   ,template=fstmplts$linkref,retfun=cat);
#' 
#' Here are descriptions of the variables referenced in this document.
#+ vardefs, results='asis'
for(ii in getOption('fs_reg')) {
  fs(ii,url=paste0('#',ii)
     ,template=fstmplts$ncdb_def,retfun = cat);
  cat(paste0('  ~ ',na.omit(unlist(subset(dct0,colname==ii)[,c('comments')]))
             ,'\n\n'),sep='');
  cat(':::::\n\n')};
#' `r md$pbreak`
#' 
# A3 audit ---------------------------------------------------------------------
#' # Audit trail {#sec:audit label="Appendix 3"}
walktrail()[,-5] %>% pander(split.tables=600,,justify='left');
#+ results='hide'
c()
