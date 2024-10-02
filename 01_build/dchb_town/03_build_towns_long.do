*-------------------------------------------------------------------------------
* use cleaned wide town panel (3963-2033)
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Store checks data
*-------------------------------------------------------------------------------

    frames reset
    use "$b_output/dchb_town/02_clean_towns_wide.dta" , clear

    * sanity check
    isid        id_town
    keep        id_town chk_*

    * Reshape to long on checksums X year.
    tolong      chk_ ///
                , i(id_town) j(index)

        * Split reshape index
        gen  label           = substr(index, 1, strlen(index)-5) // checksum variable name (until _last 4 digits)
        gen  census_dec      = real(substr(index,-4,.)) // decade (last 4 digits)

    * Check range
    assert      inrange(census_dec, 1961, 2011)

    * Total checks passed
    bys id_town label (census_dec): egen  N_   = count(census_dec)
    bys id_town label (census_dec): egen  pass_ = sum(chk_) , m

    gen  rate_ = pass_/N_

    * Keep/order + sort by check status
    keep        id_town census_dec label N_ pass_ rate_
    order       id_town census_dec label

    * Sanity check
    isid        id_town census_dec label

    * Reshape to wide at id_town census_dec level
    greshape    wide N_ pass_ rate_ ///
                , i(id_town census_dec) j(label) string fast unsorted

    * Average pass rate
    egen        pass_rate = rowmean(rate_*)
    gen         town_flag = pass_rate != 1

    * order/sort
    order       id_town census_dec pass_rate
    gsort       id_town census_dec

    isid        id_town census_dec

    * Flag town if did not pass all checks
    frame put _all , into(town_checks)

*-------------------------------------------------------------------------------
* 2. Reshape to long on town x census decade
*-------------------------------------------------------------------------------

    use "$b_output/dchb_town/02_clean_towns_wide.dta" , clear

    local       i_vars ///
                id_town xid x y idchain name_town name_st name_dt code_2011

    local       geo_vars ///
                tname sname scode dname dcode ///
                ut isostate

    local       num_vars ///
                area nhouses nhouseholds ///
                t_pop m_pop f_pop ///
                t_wrk m_wrk f_wrk ///
                t_nonagwrk m_nonagwrk f_nonagwrk ///
                t_agwrk m_agwrk f_agwrk ///
                t_clwrk m_clwrk f_clwrk ///
                t_alwrk m_alwrk f_alwrk ///
                t_marwrk m_marwrk f_marwrk ///
                t_nonwrk m_nonwrk f_nonwrk ///
                t_sc m_sc f_sc ///
                t_st m_st f_st ///
                t_lit m_lit f_lit

    local       oth_vars ///
                exist status

    tolong      `geo_vars' `num_vars' `oth_vars' ///
                , i(`i_vars') j(census_dec)

    * Sanity check
    destring   census_dec , ignore("_") replace
    isid       id_town census_dec

    * Keep/order vars
    keep       `i_vars' census_dec `geo_vars' `num_vars' `oth_vars'
    order      id_town census_dec code_2011 name_town exist `num_vars' `i_vars' `geo_vars' `oth_vars'

    * Declare panel data
    sort       id_town census_dec
    xtset      id_town census_dec

    * Merge in checks
    frlink     1:1 id_town census_dec, frame(town_checks)
    frget      town_flag pass_rate , from(town_checks)

    * Fill geovariables
    gen     neg_dec = -census_dec
        bys id_town (census_dec): carryforward `geo_vars' , replace nonotes
        bys id_town (neg_dec): carryforward `geo_vars' , replace nonotes
    drop    neg_dec

    * Clean up
    destring    ?code , replace

    * sanity check
    sort        id_town census_dec
    isid        id_town census_dec

* Compress and save
    compress
    save "$b_output/dchb_town/03_build_towns_long.dta" , replace
