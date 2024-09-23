*-------------------------------------------------------------------------------
* prepare towns and temperature data
*-------------------------------------------------------------------------------

do "$climate_lives/code/build/dchb_town/04_build_towns_long.do"

* import imd-town mapping

    use "$b_output/imd/04_town_imd_grid_100km.dta" , clear

    isid    id_town id_xy

    * 1. merge IMD data
    joinby  id_xy using "$b_input/imd/05_prep_imd_vars_decadal.dta"

        * sanity check
        isid    id_town census_dec id_xy
        sort    id_town census_dec id_xy

        * store list of vars
        unab    climate_vars : ///
                rain_* tbar_* tmin_* tmax_* ///
                ?khar* ?rabi*

        * adjust var by weight
        foreach var in `climate_vars' {
            gen     adj_`var' = `var' * imd_weight
        }

        * sum up the adjusted pieces
        collapse    (sum) adj_* ///
                    (mean) rain_* tbar_* tmin_* tmax_* ///
                    (max) b??_* ///
                    , by(id_town census_dec)

            * drop/format
            rename  (*_mean *_min *_max) (raw_*_mean raw_*_min raw_*_max)
            rename  raw_adj_* adj_*
            rename  adj_* *
            rename  raw_b??_* b??_*

            format *_mean *_min *_max %9.1f
            format b??_* %5.0g

        * sanity check
        isid        id_town census_dec

    * 3. merge Census town pca
    merge 1:1   id_town census_dec ///
                using "$b_output/dchb_town/04_build_towns_long.dta" ///
                , assert(2 3) keep(3) nogen

                /*
                * 135 unmerged towns are missing x/y coordinates

                using "$b_input/03_prep_census_towns_pca_long.dta" ///
                */

    ** Sanity check
    sort    id_town census_dec
    isid    id_town census_dec

        egen    pid = group(id_town census_dec)
        isid    pid

    *-------------------------------------------------------------------------------

    * Temperature mins
    foreach stat in min mean max {
        egen    bin_tbar_`stat' = cut(tbar_`stat'), at(18(2)32) icodes
        lab var bin_tbar_`stat' "tbar_`stat' bins 18(2)32"
    }

    // gen     lb_tbar_mean = 0 if mi(bin_tbar_mean)
    // replace lb_tbar_mean = (bin_tbar_mean + 16)     if !mi(bin_tbar_mean)
    //
    // gen     ub_tbar_mean = 32 if bin_tbar_mean == 32
    // replace ub_tbar_mean = (bin_tbar_mean * 2) + 16 if !mi(bin_tbar_mean)
    //
    // order tbar_mean bin_tbar_mean
    // lb_tbar_mean ub_tbar_mean

    * fill state/district codes
    gen     stcode = scode if census_dec == 2011
    gen     dtcode = dcode if census_dec == 2011

    bys     id_town (census_dec) : replace  stcode = stcode[_N]
    bys     id_town (census_dec) : replace  dtcode = dtcode[_N]

        * Stateyear FE
        egen    styear = group(stcode census_dec)
        lab var styear "Stateyear FE"

    * Clean up
    order   rain* tbar_* tmin_* tmax_* , after(t_nonagwrk)

    * Labels
    foreach var of varlist *_mean *_min *_max {
        lab var `var' "10y grid weighted mean `var'"
    }
    foreach var of varlist raw_* {
        lab var `var' "10y mean `var'"
    }
    foreach var of varlist *khar*  {
        lab var `var' "10y mean `var' - kharif"
    }
    foreach var of varlist *rabi*  {
        lab var `var' "10y mean `var' - kharif"
    }
    foreach var of varlist *sow*  {
        local label : variable label `var'
        lab var `var' "`label' sowing"
    }
    foreach var of varlist *hvt*  {
        local label : variable label `var'
        lab var `var' "`label' harvest"
    }

    * save
    compress
    save "$a_clean/00_prep_towns_temperature.dta" , replace
