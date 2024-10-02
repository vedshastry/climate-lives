* Climate impacts on livelihoods
** Created: Oct 2023
** Author: Ved Shastry
** Last updated: Sep 2024

*-------------------------------------------------------------------------------
*== Globals/paths
*-------------------------------------------------------------------------------

* Set paths
if "`c(username)'" == "ved" {
    global  dropbox "/home/ved/dropbox"
    global  overleaf "$dropbox/Apps/Overleaf"
}
    /*
        if "`c(username)'" == "username" {
            global  dropbox "/path/to/dropbox"
        }
    */

* Project folders

global dchb_climate     "$dropbox/dchb-climate"
global dchb             "$dropbox/dchb"

global nic_prices       "$dropbox/retail_price_data"

    * LaTeX project:
    // global tex_dir          "$overleaf/Climate impacts on agriculture in India"
    global tex_dir          "$dchb_climate/tex"

                cap mkdir   "${tex_dir}/figures"
                cap mkdir   "${tex_dir}/tables"

* Subfolders

    * -> /code
    global      dchb_climate_code        "$dchb_climate/code"
                global  b_code          "$dchb_climate_code/build"
                global  a_code          "$dchb_climate_code/analysis"

    * -> /data
    global      dchb_climate_data        "$dchb_climate/data"

        global      dt_raw          "$dchb_climate_data/raw"

        global      dt_build        "$dchb_climate_data/build"
                global  b_input         "$dt_build/input"
                global  b_output        "$dt_build/output"
                global  b_temp          "$dt_build/temp"

        global      dt_analysis     "$dchb_climate_data/analysis"
                global  a_input        "$dt_analysis/input"
                global  a_output       "$dt_analysis/output"
                global  a_temp         "$dt_analysis/temp"

            * make folders
            foreach dir in a b {
                cap mkdir "$`dir'_input"
                cap mkdir "$`dir'_output"
                cap mkdir "$`dir'_temp"
            }

    * -> /gis
    global      dchb_climate_gis        "$dchb_climate/gis"
                global  gis_input         "$dchb_climate_gis/input"
                global  gis_output        "$dchb_climate_gis/output"

*-------------------------------------------------------------------------------
*== Package dependencies
*-------------------------------------------------------------------------------

   local pkglist    gtools distinct reclink strkeep hdfe reghdfe

   foreach pkg in `pkglist' {
       cap which `pkg'
       if _rc == 111 {
           ssc install `pkg'
       }
   }

   adopath ++ "$dchb_climate/code/99_ado"


*-------------------------------------------------------------------------------
*== Run scripts
*-------------------------------------------------------------------------------

* Toggles
local   IMD 0
local   DCHB_TOWN 0

local   SUM_OUTPUT 0
local   REG_OUTPUT 0


    * Prepare IMD data
    if `IMD' == 1 {

        * IMD temperature and rainfall
            // Python scripts to pull data
            // "$dchb_climate_code/build/imd/01_get_imd_data.py"
            // "$dchb_climate_code/build/imd/02_build_imd_data_daily.py"

        do "$dchb_climate_code/01_build/imd/03_prep_imd_data_daily.do"
        do "$dchb_climate_code/01_build/imd/04_build_imd_decadal.do"
        do "$dchb_climate_code/01_build/imd/05_map_imd_grid_towns.do"
    }

    * Census data
    if `DCHB_TOWN' == 1 {

        do "$dchb_climate_code/01_build/dchb_town/00_shp2dta_census_towns.do"
        do "$dchb_climate_code/01_build/dchb_town/01_import_census_towns.do"
        do "$dchb_climate_code/01_build/dchb_town/02_prep_towns_wide.do"
        do "$dchb_climate_code/01_build/dchb_town/03_build_towns_long.do"
        do "$dchb_climate_code/01_build/dchb_town/04_towns_final.do"

    * Analysis data
        do "$dchb_climate_code/01_build/00_prep_towns_climate.do"
    }


    * Summary stats
    if `SUM_OUTPUT' == 1 {
        do "$dchb_climate_code/02_analysis/00_summary/01_summarystats_towns_temp_aggregate.do"
        do "$dchb_climate_code/02_analysis/00_summary/02_summarystats_towns_temp_share.do"
        do "$dchb_climate_code/02_analysis/00_summary/03_summarystats_towns_temp_climate.do"
    }

    * Regression output
    if `REG_OUTPUT' == 1 {

        do "$dchb_climate_code/02_analysis/01_reghdfe/01_climate_towns_main.do"

        // do "$dchb_climate_code/02_analysis/plot1_reg_pct_wrk_tbar_mean.do"

    }
