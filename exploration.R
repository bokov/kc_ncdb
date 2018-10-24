#' ---
#' title: "Kidney Cancer NCDB Data Exploration"
#' subtitle: "KL2 Aim 2"
#' author: 
#' - "Alex F. Bokov^[UT Health San Antonio]"
#' date: '`r format(Sys.Date(), "%B %d, %Y")`'
#' tags: ["data characterization", "preliminary", "NCDB", "urology", "cancer"]
#' thanks: ["Dr. Shawn Murphy", "Dr. Ronald Rodriguez", "Dr. Amelie Ramirez", "Dr. Joel Michalek"]
#' abstract: |
#'   Attempting to replicate proposed disparity analysis on large independent
#'   data source. 
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
#'  word_document:
#'   reference_docx: 'nt_styletemplate.docx'
#'   keep_md: true
#'  pdf_document:
#'   keep_md: true
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

# NOTE!!! Will need to add pandoc_args: ["--filter", "pandoc-crossref"]
# back into each of the output format sections in YAML header after plots start
# existing again
# 
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
formals(n2s)[c('fs_reg','retfun','match_col')] <- alist(NULL,return);
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

# note_toc ---------------------------------------------------------------------
#' ###### TOC {-}
#+ news_toc,results='asis'
.news <- c("
**Note:** This is not (yet) a manuscript. We are still at the data 
cleaning/alignment stage and it is far too early to draw conclusions. Rather, 
this is a regularly updated report that I am sharing with you to keep you in the 
loop on my work. I value your perspective and perhaps my results might be useful 
to your own work.\\
\\
[Yellow highlights]{.note2self custom-style='note2self'} are items with 
which I know I need to deal soon. Verbatim names of files, variables/elements,
or values are displayed in a special style, `like this`. Data element names are 
in addition linked to a glossary at the end of this document, e.g. 
[`Surgical Oncology`](#e%5Fsurgonc). This is where any relevant cleaning or 
tranformation steps will be described (in progress). Data elements from 
NAACCR usually have a NAACCR ID preceding them, e.g. 
[`1780 Quality of Survival`](#n%5Fqsurv). I try to use the word 'data element' to
describe data in its raw state and 'variable' to refer to analysis-ready data
that I have already processed. Often one variable incorporates information from
multiple data elements. Tables, figures, and sections are also linked from text 
that references them. If you have a Word version of this document, to follow a 
link, please hold down the 'control' key and click on it. The most current
version of this document can be found online at 
https://rpubs.com/bokov/kidneycancer and it has a built-in chat session."
);

.toc <- rep_len(NA,length(.news));
.toc[1] <- "
* [-@sec:overview Overview]
* [-@sec:dataprep Data preparation]
* [-@sec:descplots Plots of test data]
* [4 Cohort characterization](#sec:cohorchar)
* [5 Conclusion & next steps](#sec:nextsteps)
* Appendices
____* [A1. Supplementary results](#sec:supp)
____* [A2. Variable descriptions](#sec:vars)
____* [A3. Audit trail](#sec:audit)
";
.temp0 <- cbind(.news,.toc) %>% unname;
pander(.temp0,style='grid',keep.line.breaks=T,justify='left'
               ,split.cells=c(30,Inf),missing='')[1] %>% 
  gsub('_',' ',.) %>% cat;
# overview ---------------------------------------------------------------------
#' 
#' # Overview {#sec:overview}
#' 
#' A recent study of state death records [@PinheiroHighcancermortality2017]
#' reports that among US-born Texans of Hispanic ancestry (7.3 million, 27% of
#' the State's population), annual age-adjusted mortality rates for kidney
#' cancer  are 1.5-fold and 1.4-fold those of non-Hispanic whites for males and
#' females respectively. My goal is to determine whether these findings can be
#' replicated at UT Health (Aim 2) and Massachusetts General Hospital (Aim 3).
#' If there is evidence for an ethnic disparity, I will look for possible
#' _mediators_ of this disparity among socioeconomic, lifestyle, and family
#' history variables (Aim 2a). Otherwise the focus will shift to determining
#' which of these same variables are the best _predictors_ of mortality and
#' recurrence.
#' 
# dataprep ---------------------------------------------------------------------
#+ dataprep
#' # Data preparation {#sec:dataprep}
#' 
#' ## Required NAACCR data elements. {#sec:reqelmnts}
#' 
#' The primary outcome variables I need are date of initial diagnosis, date of 
#' surgery (if any), date of recurrence (if any), and date of death (if any). 
#' The primary predictor variable is whether or not a patient is  Hispanic. 
#' There are many covariates of interest, but these five values are the 
#' scaffolding on which the rest of the analysis will be built.
#' 
#' **I found the following NAACCR elements sufficient for deriving all the above 
#' analytic variables: `fs('n_hisp')`, 
#' `fs(v(c_main_naaccr_vars),retfun=knitr::combine_words)`.** More details 
#' about how these were selected can be found in [-@sec:vartrn]. In addition the 
#' following will almost certainly be needed for covariates or mediators: 
#' `knitr::combine_words(fs(c('n_sex','n_dob','n_marital','n_brthplc')),and='')`,
#' and any field whose name contains `Race`, `Comorbid/Complication`, 
#' `AJCC`, or `TNM`. For crosschecking it will also be useful to have 
#' `fs('n_mets')`, `fs('n_fc')`, and `fs('n_mult')`. Additional items 
#' are likely to be needed as this project evolves, but **the elements listed so
#' far should be sufficient to replicate my analysis on de-identified State or
#' National NAACCR data**. In NCDB they correspond to the following: [to be 
#' filled in]`r n2s(1)`
#' 
# descriptive plots ------------------------------------------------------------
#' # Plots of test data {#sec:descplots}
#' 
#' These survival curves are not yet adjusted for covariates such 
#' as age or stage at diagnosis. There are also refinements planned to the
#' exclusion criteria which I discuss below in [@sec:nextsteps].
#' 
#' In all the plots below, the time is expressed in weeks and `+` signs denote
#' censored events (the last follow-up of patients for whom the respective 
#' outcomes were never observed). The lightly-shaded regions around each line 
#' are 95% confidence intervals. 
#' 
#+ .survfit_prep,results='hide'
# prepare if needed
#' ###### blank
#' ::::: {#fig:surg_survfit custom-style="Image Caption"}
#+ surv_surg,results='asis',fig.align='center'
.survfit_plot0 <- mutate(dat1
                         ,c=DX_LASTCONTACT_DEATH_MONTHS-ifelse(
                           PUF_VITAL_STATUS=='1: Alive',1,0)
                         ,strt=0) %>% 
  as_tibble %>% survfit_wrapper(
    eventvars='DX_LASTCONTACT_DEATH_MONTHS',censrvars='c',startvars='strt'
    # restrict them to non renal pelvis
    ,subs=PRIMARY_SITE=='C649'&
      # analyze stage IV separately
      ANALYTIC_STAGE_GROUP!='4: Stage IV'&
      # only do the surgical cases
      REASON_FOR_NO_SURGERY=='0: Surgery of the primary site was performed'&
      # only do the surgical cases
      RX_HOSP_SURG_APPR_2010!='0: No surgical procedure of primary site'&
      # only the patients who are presenting with their first ever tumor
      SEQUENCE_NUMBER=='00'
    ,fsargs=NA,predvars='a_hsp');
.survfit_plot0$plot;
cat('

Number of weeks elapsed from ',fs('a_tdiag'),' (time 0) to ',fs('a_tsurg')
,' for ',.survfit_plot0$fit$n[1],' Hispanic and ',.survfit_plot0$fit$n[2]
,' non-Hispanic white patients with a 3-year follow-up period (any surgeries
occurring more than 3 years post-diagnosis are treated as censored)');
#' :::::
#' 
#' ###### blank
#'
#' ::::: {#fig:naaccrdeath_survfit custom-style="Image Caption"}
#+ naaccrdeath_survfit,results='asis',fig.dim=c(3.1,3),fig.align='center'
# (.survfit_plot2 <- update(.survfit_plot1,eventvars='n_vtstat'
#                           # ,plotadd = list(
#                           #   guides(colour=guide_legend('')
#                           #          ,fill=guide_legend(''))
#                           #   ,coord_cartesian(ylim=c(.5,1))
#                           #   ,theme_light()
#                           #   ,theme(legend.position = 'top'))
#                           ,main='Time from surgery to death\n'
#                           ,ylab='Fraction alive'))$plot;
# cat('
# 
# Like [@fig:recur_survfit] except now the outcome is ',fs('n_vtstat')
# ,' for ',.survfit_plot2$fit$n[1],' Hispanic  and ',.survfit_plot2$fit$n[2]
# ,' non-Hispanic white patients. Six-year follow-up');
cat('FOO\n\nplaceholder');
#' :::::
#' 
#' ::::: {#fig:alldeath_survfit custom-style="Image Caption"}
#+ alldeath_survfit,results='asis',fig.dim=c(3.1,3),fig.align='center'
# also do plots for survival stratified by age and by stage
#' :::::
#' 
#' ###### blank
#' 
# tableone ---------------------------------------------------------------------
#' # Cohort Characterization {#sec:cohorchar}
#'
#' The below variables are subject to change as the data validation and 
#' preparation processes evolve.
#' 
#+ TableOne
.tc <- paste0('
Summary of all categoric variables compared between Hispanic and non-Hispanic
white cancer patients. {#tbl:hspnhwcat}');

subset(dat1,PUF_CASE_ID %in% sbs0$s_hspnhw) %>% 
  CreateTableOne(setdiff(subset(dct0,type %in% c('int','long'))$colname
                         ,c(v(c_nonanalytic),v(c_discrete)))
                 ,strata = 'a_eth',data=.) %>% print(printToggle=F) %>% 
  pander(.,col.names=gsub('test','',colnames(.)),caption=.tc);
#+ TableOneCat
.tc <- paste0('
Summary of all continuous variables compared between Hispanic and non-Hispanic
white cancer patients. {#tbl:hspnhwnum}');

subset(dat1,PUF_CASE_ID %in% sbs0$s_hspnhw &
         a_eth %in% c('Hispanic','non-Hisp White')) %>% 
  CreateTableOne(setdiff(v(c_discrete),c(v(c_nonanalytic),'a_eth'))
                 ,strata = 'a_eth',data=.) %>% print(printToggle=F) %>% 
  pander(.,col.names=gsub('test','',colnames(.)),caption=.tc);
#
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
#' ## Observations about NCDB staging
#' 
# .astages<-sprintf('n_a%d%s',rep(6:7,3),c('t','n','m')) %>% sort %>% rev;
# # OMG what a hack. Pasting the corresponding AJCC6/7 desriptor fields onto the 
# # left side of all AJCC6/7 TNM fields. The idea here is to build an argument for 
# # mutate dynamically, without a lot of copy-paste code nor without yet another 
# # c_ group in the data dictionary if this turns out to not be needed
# .mutate_stages <- .astages %>% setNames(sprintf(
#   'ifelse(is.na(%1$s)|is.na(%1$s),NA,paste0(%1$sd,%1$s))',.),.) %>% 
#   lapply(function(xx) parse(text=xx)[[1]]);
# # now create a data.frame on which to do the various ftables below
# dat1tnmcounts <- subset(dat1,a_n_visit) %>% as.data.frame %>% 
#   select(c(v(c_tnm),paste0(.astages,'d'))) %>% 
#   mutate_all(function(xx) gsub('"','',xx)) %>% list %>% c(.mutate_stages) %>% 
#   do.call(mutate,.);
# # note that here the pipeline is nested within the sapply statement... the 
# # inline function is one big pipe. This is for viewing the counts of various 
# # TNM/stage values
# tnmtabs <- sapply(c('c_stagegrp','c_staget','c_stagen','c_stagem')
#                   ,function(xx) eval(substitute(v(xx),list(xx=xx))) %>% 
#                     select(dat1tnmcounts,.) %>% table(useNA='if') %>% 
#                     as.data.frame(stringsAsFactors=F) %>% subset(Freq>0) %>% 
#                     arrange(desc(Freq)),simplify = F);
#' `knitr::combine_words(fs(.astages))` are missing if and only if 
#' `knitr::combine_words(fs(paste0(.astages,'d')))` are also missing, 
#' respectively. For the tables in this section, the counts are by visit rather
#' than by unique patient since the question of interest is how often do the 
#' stages assigned to the same case agree with each other. Each of the tables 
#' shows the 20 most common combinations of values.
#' 
#+ stagegrp
# .tc <- paste0('Frequency of various combinations of '
#               ,knitr::combine_words(fs(v(c_stagegrp))),' {#tbl:stagegrp}');
# 
# pander(head(tnmtabs$c_stagegrp,20),col.names=c(fs(colnames(tnmtabs$c_stagegrp)[1:4])
#                                              ,'N'),caption=.tc);
#' 
#+ staget
# .tc <- paste0('Frequency of various combinations of '
# ,knitr::combine_words(fs(v(c_staget))),' {#tbl:staget}');
# 
# pander(head(tnmtabs$c_staget,20),col.names=c(fs(colnames(tnmtabs$c_staget)[1:4])
#                                              ,'N'),caption=.tc);
#' 
#+ stagen
# .tc <- paste0('Frequency of various combinations of '
#               ,knitr::combine_words(fs(v(c_stagen))),' {#tbl:stagen}');
# 
# pander(head(tnmtabs$c_stagen,20),col.names=c(fs(colnames(tnmtabs$c_stagen)[1:4])
#                                              ,'N'),caption=.tc);
#' 
#+ stagem
# .tc <- paste0('Frequency of various combinations of '
#               ,knitr::combine_words(fs(v(c_stagem))),' {#tbl:stagem}');
# 
# pander(head(tnmtabs$c_stagem,20),col.names=c(fs(colnames(tnmtabs$c_stagem)[1:4])
#                                              ,'N'),caption=.tc);
#' 
#+ tnm_agree_miss
# .tnmmissvals <- c('N-',NA,'UNK','-');
# .tnmagree<-lapply(tnmtabs,function(xx) {
#   dd<-xx[!xx[,1]%in%.tnmmissvals&!xx[,2]%in%.tnmmissvals,];
#   sum(dd[dd[,1]==dd[,2],'Freq'])/sum(dd$Freq)*100}) %>% sprintf('%3.1f%%',.);
# .tnmnoa7 <- lapply(tnmtabs,function(xx) {
#   dd <- xx[-1,];
#   sum(dd[dd[,1]%in%.tnmmissvals,'Freq'])/sum(dd$Freq)*100}) %>% 
#   sprintf('%3.1f%%',.);
# .tnmrescueable <- lapply(tnmtabs,function(xx) {
#   #dd<-xx[!is.na(xx[,1])|!is.na(xx[,2]),];
#   dd <- xx[-1,];
#   sum(dd[dd[,1]%in%.tnmmissvals & !dd[,2]%in%.tnmmissvals,'Freq'])/
#     sum(dd$Freq)*100}) %>% sprintf('%3.1f%%',.);
#' In [@tbl:stagegrp; @tbl:staget; @tbl:stagen; @tbl:stagem], when both the 
#' AJCC-7 and AJCC-6 values are non-missing they agree with each other 
#' `knitr::combine_words(.tnmagree)` of the time for T, N, and M respectively.
#' There are `knitr::combine_words(.tnmnoa7)` AJCC-7 values missing but
#' `knitr::combine_words(.tnmrescueable)` can be filled in from AJCC-6 for overall stage, T, 
#' N, and M respectively.
#' 
# A4 variables -----------------------------------------------------------------
#'
#' # Variable descriptions {#sec:vars label="Appendix 4"}
#' 
#' 
#+ progfootnotes, results='asis'
fs(getOption('fs_reg'),url=paste0('#',getOption('fs_reg'))
   ,template=fstmplts$linkref,retfun=cat);
#' 
#' Here are descriptions of the variables referenced in this document.
#+ readablefootnotes, results='asis'
# This is brittle. Really ought to make fs() flexible enough to do this itself.
# TODO: stop using those silly H6 headers, use a fenced div
# 
# Here is a mockup of how it can be done (before even editing fs() to be able to
# combine different columns for the text value)
#
# # This part opens the div, writes the link target, and writes the 
# # human-readable variable name
# {fs('foo','bar','baz','bat'
# ,template='\n\n\n::::: {#%1$s .vardef custom-style=\"vardef\"}\n\n %4$s :\n\n  ~ ');
# # This part constructs the body of the variable definition, can't be done in
# # fs() yet because 'blah blah' has to be pasted together from the non-NA 
# # values of several columns.
# # Below needs to be uncommented when ready to do the new links
# .junk <- dct0[match(getOption('fs_reg')
#                     ,do.call(coalesce,dct0[,c('varname','colname')]))
#               ,c('varname','colname_long','chartname'
#                  ,'comment','col_url','colname')] %>%
#   # subset(dct0,varname %in% getOption('fs_reg')
#   #               ,select = c('varname','colname_long','chartname','comment'
#   #                           ,'col_url')) %>% 
#   apply(1,function(xx) {
#     # TODO: the hardcoded offsets make this brittle. Fina better way.
#     cat('######',na.omit(xx[c(1,6)])[1],'\n\n',na.omit(xx[2:1])[1],':\n\n  ~ '
#         ,ifelse(length(na.omit(xx[2:4]))>0
#                 ,iconv(paste(na.omit(xx[2:4]),collapse='; '),to='UTF-8',sub='')
#                 ,'')
#         ,ifelse(is.na(xx[5]),'',paste('\n\n  ~ Link:',xx[5])),'\n\n***\n')});
#' 
#' `r md$pbreak`
#' 
# A5 audit ---------------------------------------------------------------------
#' # Audit trail {#sec:audit label="Appendix 5"}
walktrail()[,-5] %>% pander(split.tables=600,,justify='left');
#+ results='hide'
c()
