*-------------------------------------------------------------------------------
* prepare towns and temperature data
*-------------------------------------------------------------------------------

// do "$climate_lives/code/01_build/dchb_town/04_build_towns_long.do"

* import imd-town mapping

    // use "$b_output/imd/04_town_imd_grid_100km.dta" , clear
    use "$b_output/imd/05_map_imd_grid_towns.dta" , clear

    isid    id_town id_xy

    * 1. merge IMD data
    joinby  id_xy using "$b_input/imd/04_build_imd_decadal.dta"

        * sanity check
        isid    id_town census_dec id_xy
        sort    id_town census_dec id_xy

        * store list of vars
        unab    climate_vars : ///
                rain_* tbar_* tmin_* tmax_* ///
                ?khar* ?rabi* ///
                ?lst*

        * adjust var by weight
        foreach var in `climate_vars' {
            gen     adj_`var' = `var' * imd_weight
        }

        * sum up the adjusted pieces
        collapse    (sum) adj_* ///
                    (mean) rain_* tbar_* tmin_* tmax_* ///
                    ?khar* ?rabi* ?lst_* ///
                    , by(id_town census_dec)

            * drop/format
            rename  (*_mean *_min *_max) (raw_*_mean raw_*_min raw_*_max)
            rename  raw_adj_* adj_*
            rename  adj_* *

            format *_mean *_min *_max %9.1f

        * sanity check
        isid        id_town census_dec

    * 3. merge Census town pca
    merge 1:1   id_town census_dec ///
                using "$b_output/dchb_town/05_towns_final.dta" ///
                , assert(2 3) keep(3) nogen

                /*
                * 135 unmerged towns are missing x/y coordinates

                using "$b_input/03_prep_census_towns_pca_long.dta" ///
                */

    ** Sanity check
    sort    id_town census_dec
    isid    id_town census_dec
    xtset   id_town census_dec

        egen    pid = group(id_town census_dec)
        isid    pid

    *-------------------------------------------------------------------------------

    * fill state/district codes
    gen     stcode = scode if census_dec == 2011
    gen     dtcode = dcode if census_dec == 2011

    bys     id_town (census_dec) : replace  stcode = stcode[_N]
    bys     id_town (census_dec) : replace  dtcode = dtcode[_N]

        * Number of years town exists in panel
        bys id_town (census_dec) : egen    years_exist = sum(exist)

        * Stateyear FE
        egen    styear = group(stcode census_dec)
        // egen    styear = group(sname census_dec)

        * Districtyear FE
        egen    dtyear = group(dtcode census_dec)
        // egen    dtyear = group(sname dname census_dec)

    *-------------------------------------------------------------------------------

    * Clean up
    order   _all , seq
    order   rain* tbar_* tmin_* tmax_* ?khar* ?rabi* ?lst* raw_*, after(t_nonagwrk)
    order   id_town census_dec name_* exist ///
            ?_pop ?_sc ?_st ?_lit ?_wrk ?_nonwrk ///
            ?_nonagwrk ?_agwrk ?_clwrk ?_alwrk ?_marwrk shr_* pct_*


    * Labels
    foreach var of varlist *_mean *_min *_max {
        lab var `var' "Decade avg. `var'"
    }
    foreach var of varlist raw_* {
        lab var `var' "Decade avg. `var'"
    }
    foreach var of varlist *khar*  {
        lab var `var' "Decade avg. `var' - kharif"
    }
    foreach var of varlist *rabi*  {
        lab var `var' "Decade avg. `var' - kharif"
    }
    foreach var of varlist *sow*  {
        local label : variable label `var'
        lab var `var' "`label' sowing"
    }
    foreach var of varlist *hvt*  {
        local label : variable label `var'
        lab var `var' "`label' harvest"
    }
    foreach var of varlist *lst*  {
        lab var `var' "Decade avg. `var' - lst"
    }

    * save
    compress
    save "$a_input/00_prep_towns_climate.dta" , replace
