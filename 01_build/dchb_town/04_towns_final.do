*-------------------------------------------------------------------------------
* use town long panel
*-------------------------------------------------------------------------------

    use "$b_output/dchb_town/03_build_towns_long.dta" , clear

*-------------------------------------------------------------------------------
* 3. Clean up
*-------------------------------------------------------------------------------

    * Winsorize
    // foreach var in  pop sc st lit wrk nonagwrk agwrk clwrk alwrk marwrk nonwrk {
    // winsor2     pop  wrk nonagwrk agwrk clwrk alwrk marwrk nonwrk , by(name_st) replace cuts(0 98)

    * population density
    foreach gen in t m f {
        gen         `gen'_pdensity = .
        replace     `gen'_pdensity = `gen'_pop / area
        lab var     `gen'_pdensity "`gen' pop density per sq km."
    }

    ************************************************
    * Construct indicators
    ************************************************

    * Pct variables (% of town population)
        foreach var in  pop sc st lit wrk nonagwrk agwrk clwrk alwrk marwrk nonwrk {

            gen         pct_t_`var' = t_`var' / t_pop
            gen         pct_m_`var' = m_`var' / m_pop
            gen         pct_f_`var' = f_`var' / f_pop

            lab var     pct_t_`var' "pct t `var'"
            lab var     pct_m_`var' "pct m `var'"
            lab var     pct_f_`var' "pct f `var'"

            foreach gen in t m f {
                replace     pct_`gen'_`var' = .m if !inrange(pct_`gen'_`var',0,1)
                lab var     pct_`gen'_`var' "pct `gen' `var'"
            }

        }

    * Share of workers
        foreach var in  wrk nonagwrk agwrk clwrk alwrk marwrk nonwrk {

            gen         shr_t_`var' = t_`var' / t_wrk
            gen         shr_m_`var' = m_`var' / m_wrk
            gen         shr_f_`var' = f_`var' / f_wrk

            foreach gen in t m f {
                replace     shr_`gen'_`var' = .m if !inrange(shr_`gen'_`var',0,1)
                lab var     shr_`gen'_`var' "shr `gen' `var'"
            }
    }


    * Log variables
        gen         log_area = log(area)
        lab var     log_area "Log area"

        foreach var in pop pdensity sc st lit wrk nonwrk marwrk {

            gen         log_t_`var' = log(t_`var')
            gen         log_m_`var' = log(m_`var')
            gen         log_f_`var' = log(f_`var')

            lab var     log_t_`var' "Log t `var'"
            lab var     log_m_`var' "Log m `var'"
            lab var     log_f_`var' "Log f `var'"

        }

    * Format vars
    format log_* pct_* shr_* %9.3f

    *----------------------------
    * Misc data
    *----------------------------

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

    // lab var     t_hhwrk "Total household industry workers"
    // lab var     m_hhwrk "Male household industry workers"
    // lab var     f_hhwrk "Female household industry workers"
    //
    // lab var     t_otwrk "Total other or service workers"
    // lab var     m_otwrk "Male other or service workers"
    // lab var     f_otwrk "Female other or service workers"

    lab var     t_agwrk "Agricultural workers"
    lab var     m_agwrk "Male agricultural workers"
    lab var     f_agwrk "Female agricultural workers"

    lab var     t_nonagwrk "Non agricultural workers"
    lab var     m_nonagwrk "Male non agricultural workers"
    lab var     f_nonagwrk "Female non agricultural workers"

    lab var     pct_t_agwrk "Pct ag workers / population"
    lab var     pct_t_nonagwrk "Pct non ag workers / population"

    lab var     pct_m_agwrk "Pct ag workers / population, male"
    lab var     pct_m_nonagwrk "Pct non ag workers / population, male"

    lab var     pct_f_agwrk "Pct ag workers / population, female"
    lab var     pct_f_nonagwrk "Pct non ag workers / population, female"

    lab var     shr_t_agwrk "Share ag workers / workers"
    lab var     shr_t_nonagwrk "Share non ag workers / workers"

    lab var     shr_m_agwrk "Share ag workers / workers, male"
    lab var     shr_m_nonagwrk "Share non ag workers / workers, male"

    lab var     shr_f_agwrk "Share ag workers / workers, female"
    lab var     shr_f_nonagwrk "Share non ag workers / workers, female"

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
    save "$b_output/dchb_town/05_towns_final.dta" , replace
