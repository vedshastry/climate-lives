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

global climate_lives     "$dropbox/climate-lives"
global dchb             "$dropbox/dchb"

global nic_prices       "$dropbox/retail_price_data"

    * LaTeX project:
    // global tex_dir          "$overleaf/Climate impacts on agriculture in India"
    global tex_dir          "$climate_lives/tex"

                cap mkdir   "${tex_dir}/figures"
                cap mkdir   "${tex_dir}/tables"

* Subfolders

    * -> /code
    global      clives_code        "$climate_lives/code"
                global  b_code          "$clives_code/build"
                global  a_code          "$clives_code/analysis"

    * -> /data
    global      clives_data        "$climate_lives/data"

        global      dt_raw          "$clives_data/raw"

        global      dt_build        "$clives_data/build"
                global  b_input         "$dt_build/input"
                global  b_output        "$dt_build/output"
                global  b_temp          "$dt_build/temp"

        global      dt_analysis     "$clives_data/analysis"
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
    global      clives_gis        "$climate_lives/gis"
                global  gis_input         "$clives_gis/input"
                global  gis_output        "$clives_gis/output"

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

   adopath ++ "$climate_lives/code/99_ado"


*-------------------------------------------------------------------------------
*== Run scripts
*-------------------------------------------------------------------------------

* Toggles
local   00_RAW_DATA 0
local   DCHB_TOWN 0
local   IMD 0


    * Prepare raw data
    if `00_RAW_DATA' == 1 {
        // 01_get_imd_data.py
        // 02_build_imd_data.py
        // 03_town_imdgrid_mapping.py
        // 04_match_imd_town.do
        // 05_match_imd_agriwage.do
        // 05_prep_imd_vars.do
    }

    * Census data
    if `DCHB_TOWN' == 1 {

        do "$clives_code/build/dchb_town/00_shp2dta_census_towns.do"
        do "$clives_code/build/dchb_town/01_import_census_towns.do"
        do "$clives_code/build/dchb_town/02_prep_census_towns.do"
        do "$clives_code/build/dchb_town/03_clean_towns_wide.do"
        do "$clives_code/build/dchb_town/04_build_towns_long.do"

    }
