*-------------------------------------------------------------------------------
* use cleaned wide town panel (3963-2033)
*-------------------------------------------------------------------------------

    use "$b_output/dchb_town/03_clean_towns_wide.dta" , clear

    * sanity check
    isid        id_town

*-------------------------------------------------------------------------------
* 2. Reshape to long on town x census decade
*-------------------------------------------------------------------------------

    local       i_vars ///
                id_town xid x y name_town code_2011

    local       geo_vars ///
                tname sname scode dname dcode ///
                ut isostate

    local       num_vars ///
                area nhouses nhouseholds ///
                t_pop m_pop f_pop ///
                t_sc m_sc f_sc ///
                t_st m_st f_st ///
                t_lit m_lit f_lit ///
                t_wrk m_wrk f_wrk ///
                t_nonwrk m_nonwrk f_nonwrk ///
                t_marwrk m_marwrk f_marwrk ///
                t_clwrk m_clwrk f_clwrk ///
                t_alwrk m_alwrk f_alwrk ///
                t_hhwrk m_hhwrk f_hhwrk ///
                t_otwrk m_otwrk f_otwrk ///
                t_agwrk t_nonagwrk ///
                m_agwrk m_nonagwrk ///
                f_agwrk f_nonagwrk ///
                pct_t_sc pct_m_sc pct_f_sc ///
                pct_t_st pct_m_st pct_f_st ///
                pct_t_lit pct_m_lit pct_f_lit ///
                pct_t_wrk pct_m_wrk pct_f_wrk ///
                pct_t_nonwrk pct_m_nonwrk pct_f_nonwrk ///
                pct_t_marwrk pct_m_marwrk pct_f_marwrk ///
                pct_t_clwrk pct_m_clwrk pct_f_clwrk ///
                pct_t_alwrk pct_m_alwrk pct_f_alwrk ///
                pct_t_hhwrk pct_m_hhwrk pct_f_hhwrk ///
                pct_t_otwrk pct_m_otwrk pct_f_otwrk ///
                pct_t_agwrk pct_t_nonagwrk ///
                pct_m_agwrk pct_m_nonagwrk ///
                pct_f_agwrk pct_f_nonagwrk

    local       oth_vars ///
                exist status


    tolong      `geo_vars' `num_vars' `oth_vars' ///
                , i(`i_vars') j(census_dec)

    * sanity check
    destring   census_dec , ignore("_") replace
    isid       id_town census_dec

    keep       `i_vars' census_dec `geo_vars' `num_vars' `oth_vars'
    order      id_town census_dec code_2011 name_town exist `num_vars' `i_vars' `geo_vars' `oth_vars'

*-------------------------------------------------------------------------------

* Declare panel data

    sort       id_town census_dec
    xtset      id_town census_dec

*-------------------------------------------------------------------------------

    * Fill geovariables
    gen     neg_dec = -census_dec
        bys id_town (census_dec): carryforward `geo_vars' , replace nonotes
        bys id_town (neg_dec): carryforward `geo_vars' , replace nonotes
    drop    neg_dec

    * Clean up
    destring    ?code , replace

    * population density
    foreach gen in t m f {
        gen         `gen'_pdensity = .
        replace     `gen'_pdensity = `gen'_pop / area
        lab var     `gen'_pdensity "`gen' pop density per sq km."
    }

    * Get the entry and exit decade into panel for each town
    bysort id_town (census_dec):    egen enter_dec = min(census_dec) if exist == 1
    bysort id_town (census_dec):    egen exit_dec = max(census_dec) if exist == 1

    replace     enter_dec = .m  if enter_dec == 1961 // missing data
    replace     exit_dec = .m   if exit_dec == 2011 // missing data

    * Calculate the number of status switches
    by id_town (census_dec):     gen status_change = (exist != exist[_n-1]) if _n > 1
    by id_town (census_dec):     egen total_changes = sum(status_change)

    * Tag towns that have changed status more than once
    gen mult_entry = (total_changes > 1)

    * Log variables
        gen         log_area = log(area)
        lab var     log_area "Log area"

    foreach var in pop sc st lit wrk nonwrk marwrk {

        gen         log_t_`var' = log(t_`var')
        gen         log_m_`var' = log(m_`var')
        gen         log_f_`var' = log(f_`var')

        lab var     log_t_`var' "Log t `var'"
        lab var     log_m_`var' "Log m `var'"
        lab var     log_f_`var' "Log f `var'"

    }

    * Percentage variables
    // foreach var in pop sc st lit wrk nonwrk marwrk agwrk nonagwrk {
    //
    //     gen         pct_t_`var' = t_`var' / t_pop
    //     gen         pct_m_`var' = m_`var' / t_pop
    //     gen         pct_f_`var' = f_`var' / t_pop
    //
    //     lab var     pct_t_`var' "Pct t `var'"
    //     lab var     pct_m_`var' "Pct m `var'"
    //     lab var     pct_f_`var' "Pct f `var'"
    //
    // }
    //
    foreach gen in t m f {
        gen         pct_`gen'_cagwrk = `gen'_agwrk / t_wrk
        gen         pct_`gen'_cnonagwrk = `gen'_nonagwrk / t_wrk

        lab var     pct_`gen'_cagwrk "Pct `gen' agwrk / t_wrk"
        lab var     pct_`gen'_cnonagwrk "Pct `gen' nonagwrk / t_wrk"
    }

        * Format vars
        format log_* %9.3f
        format pct_* %9.3f


    * Reorder
    order       id_town census_dec code_2011 name_town *pdensity* `num_vars'

*-------------------------------------------------------------------------------

    * Labels

    lab var     id_town "Town ID"
    lab var     xid "group(idchain), =id_town"
    lab var     status "Merge status with previous decade"

    lab var     census_dec "Census decade"

    lab var     name_town "Town name"
    lab var     tname "Town name"
    lab var     sname "State name"
    lab var     isostate "State ISO code"
    lab var     scode "State code"
    lab var     dcode "District code"
    lab var     dname "District name"
    lab var     ut "UT status"

    lab var     area "Area (sq. km)"
    lab var     nhouses "Num houses"
    lab var     nhouseholds "Num households"

    lab var     t_pop "Total population"
    lab var     m_pop "Male population"
    lab var     f_pop "Female population"

    lab var     t_sc "Total SC"
    lab var     m_sc "Male SC"
    lab var     f_sc "Female SC"

    lab var     t_st "Total ST"
    lab var     m_st "Male ST"
    lab var     f_st "Female ST"

    lab var     t_lit "Total literate"
    lab var     m_lit "Male literate"
    lab var     f_lit "Female literate"

    lab var     t_wrk "Total workers"
    lab var     m_wrk "Male workers"
    lab var     f_wrk "Female workers"

    lab var     t_nonwrk "Total nonworkers"
    lab var     m_nonwrk "Male nonworkers"
    lab var     f_nonwrk "Female nonworkers"

    lab var     t_marwrk "Total marginal workers"
    lab var     m_marwrk "Male marginal workers"
    lab var     f_marwrk "Female marginal workers"

    lab var     t_clwrk "Total cultivators"
    lab var     m_clwrk "Male cultivators"
    lab var     f_clwrk "Female cultivators"

    lab var     t_alwrk "Total agricultural labour"
    lab var     m_alwrk "Male agricultural labour"
    lab var     f_alwrk "Female agricultural labour"

    lab var     t_hhwrk "Total household industry workers"
    lab var     m_hhwrk "Male household industry workers"
    lab var     f_hhwrk "Female household industry workers"

    lab var     t_otwrk "Total other or service workers"
    lab var     m_otwrk "Male other or service workers"
    lab var     f_otwrk "Female other or service workers"

    lab var     t_agwrk "Agricultural workers"
    lab var     m_agwrk "Male agricultural workers"
    lab var     f_agwrk "Female agricultural workers"

    lab var     t_nonagwrk "Non agricultural workers"
    lab var     m_nonagwrk "Male non agricultural workers"
    lab var     f_nonagwrk "Female non agricultural workers"

    lab var     pct_t_agwrk "Pct ag workers / population"
    lab var     pct_t_nonagwrk "Pct non ag workers / population"
    lab var     pct_t_cagwrk "Pct ag workers / all workers"
    lab var     pct_t_cnonagwrk "Pct non ag workers / all workers"

    lab var     pct_m_agwrk "Pct ag workers / population, male"
    lab var     pct_m_nonagwrk "Pct non ag workers / population, male"
    lab var     pct_m_cagwrk "Pct ag workers / all workers, male"
    lab var     pct_m_cnonagwrk "Pct non ag workers / all workers, male"

    lab var     pct_f_agwrk "Pct ag workers / population, female"
    lab var     pct_f_nonagwrk "Pct non ag workers / population, female"
    lab var     pct_f_cagwrk "Pct ag workers / all workers, female"
    lab var     pct_f_cnonagwrk "Pct non ag workers / all workers, female"

    lab var     enter_dec "Town birth/entry decade"
    lab var     exit_dec "Town death/exit decade"
    lab var     status_change "=1 if exist status changed"
    lab var     total_changes "Total exist status changes"
    lab var     mult_entry "Multiple entry/exit of town"

    * sanity check
    sort        id_town census_dec
    isid        id_town census_dec

* Compress and save

    compress
    save "$b_output/dchb_town/04_build_towns_long.dta" , replace
    // save "$dchb/output/town/04_build_towns_long.dta" , replace
