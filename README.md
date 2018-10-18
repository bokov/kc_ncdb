# kc_ncdb
The R scripts for reading in NCDB .dat files

Basic usage:

1. This assumes you already have an NCDB .dat file and accompanying Stata .do
   file. Once you do, clone this repo and check out the `integration` branch. 
   The `master` branch is for frozen snapshots corresponding to formal 
   publications mostly.
2. Edit the `example_config.R` file that comes with this repository and 
   change the `inputdata_ncdb` and `dctfile_ncdb_raw` variables (the others 
   aren't used yet). Save the edited version as `config.R` and whenever you 
   check out this repo, copy your `config.R` file into it (you'll likely need 
   a different `config.R` for different computers you work on). Never check your 
   own `config.R` into any public repo-- it's included in `.gitignore` for a 
   reason.
3. From the console run `R -e "source('data.R')"` or from RStudio source the 
   `data.R` file. Either one will create a file called `data.R.rdata` which you
   can load into any R session and the `dat1` object will have a random sample
   of 4000+ patients from the NCDB data with all the codes mapped to official 
   NCDB labels (some of them rather long, be warned). If you like, you can also 
   load the file `dictionary.R.rdata` which will give you the raw NCDB object
   `dat0` the level maps `levels_map` and the data dictionary `dct0`. For more
   information about how to use those, please read comments in `data.R` and 
   `dictionary.R`.

More soon, including charaterization/testing of the variables similar to my
[report for i2b2/NAACCR](https://bokov.github.io/kl2_kc_analysis/files/exploration.html).