*-------------------------------------------------------------------------------
* use cleaned town panel
*-------------------------------------------------------------------------------

    use "$b_output/dchb_town/02_prep_census_towns.dta" , clear

    * sanity check
    isid        id_town
    sort        id_town

*-------------------------------------------------------------------------------
* Construct indicators
*-------------------------------------------------------------------------------

    *-------------------------------------------------------------------------------
    * Aggregate occupations by category:
        * 1 - Cultivators
        * 2 - Agricultural labourers
        * 3 - Household industry nonworkers
        * 4 - manufacturing, processing, servicing, repairing + Other/services
        * Non - Non workers
        * Mar - Marginal workers
    *-------------------------------------------------------------------------------

    foreach     type in t m f {

    *2. Aggregate: By category of labour

        ** 1961
                /*
                Category : composition
                1 : cultivators
                2 : agricultural labourers
                3 : in mining, quarrying, livestock, forestry, fishing, hunting and plantations, orchards and allied activities
                4 : at household industry
                5 : in manufacturing other than household industry
                6 : in construction
                7 : in trade and commerce
                8 : in transport storage and communications
                9 : other services
                */
        egen        `type'_clwrk_1961      =   rowtotal(`type'_cat1_1961) , m
        egen        `type'_alwrk_1961      =   rowtotal(`type'_cat2_1961) , m
        egen        `type'_hhwrk_1961      =   rowtotal(`type'_cat4_1961) , m
        egen        `type'_otwrk_1961      =   rowtotal(`type'_cat3_1961  `type'_cat5_1961 `type'_cat6_1961 `type'_cat7_1961 `type'_cat8_1961 `type'_cat9_1961) , m

        ** 1971
                /*
                Category : composition
                1 : cultivators
                2 : agricultural labourers
                3 : livestock, forestry, fishing, hunting and plantations, orchards and allied activities
                4 : mining and quarrying
                5a : in household industry
                5b : in manufacturing other than household industry
                6 : in construction
                7 : in trade and commerce
                8 : in transport storage and communications
                9 : other services
                */
        egen        `type'_clwrk_1971      =   rowtotal(`type'_cat1_1971) , m
        egen        `type'_alwrk_1971      =   rowtotal(`type'_cat2_1971) , m
        egen        `type'_hhwrk_1971      =   rowtotal(`type'_cat5a_1971) , m
        egen        `type'_otwrk_1971      =   rowtotal(`type'_cat3_1971 `type'_cat4_1971 `type'_cat5b_1971 `type'_cat6_1971 `type'_cat7_1971 `type'_cat8_1971 `type'_cat9_1971) , m

        ** 1981
                /*
                Category : composition
                1 : cultivators
                2 : agricultural labourers
                5a : in household industry
                9 : other; all categories from 3,4,5b,6,7,8,9

                    3 : livestock, forestry, fishing, hunting and plantations, orchards and allied activities
                    4 : mining and quarrying
                    5b : in manufacturing other than household industry
                    6 : in construction
                    7 : in trade and commerce
                    8 : in transport storage and communications
                    9 : other services

                */
        egen        `type'_clwrk_1981      =   rowtotal(`type'_cat1_1981) , m
        egen        `type'_alwrk_1981      =   rowtotal(`type'_cat2_1981) , m
        egen        `type'_hhwrk_1981      =   rowtotal(`type'_cat5a_1981) , m
        egen        `type'_otwrk_1981      =   rowtotal(`type'_cat9_1981) , m

        ** 1991
                /*
                Category : composition
                1 : cultivators
                2 : agricultural labourers
                3 : livestock, forestry, fishing, hunting and plantations, orchards and allied activities
                4 : mining and quarrying
                5a : in household industry
                5b : in manufacturing other than household industry
                6 : in construction
                7 : in trade and commerce
                8 : in transport storage and communications
                9 : other services
                */
        egen        `type'_clwrk_1991      =   rowtotal(`type'_cat1_1991) , m
        egen        `type'_alwrk_1991      =   rowtotal(`type'_cat2_1991) , m
        egen        `type'_hhwrk_1991      =   rowtotal(`type'_cat5a_1991) , m
        egen        `type'_otwrk_1991      =   rowtotal(`type'_cat3_1991 `type'_cat4_1991 `type'_cat5b_1991 `type'_cat6_1991 `type'_cat7_1991 `type'_cat8_1991 `type'_cat9_1991) , m

        ** 2001
                /*
                Category : composition
                1 : cultivators
                2 : agricultural labourers
                3 : livestock, forestry, fishing, hunting and plantations, orchards and allied activities
                4 : mining and quarrying
                5a : in household industry
                5b : in manufacturing other than household industry
                6 : in construction
                7 : in trade and commerce
                8 : in transport storage and communications
                9 : other services
                */
        egen        `type'_clwrk_2001      =   rowtotal(main_cl_`type'_2001) , m
        egen        `type'_alwrk_2001      =   rowtotal(main_al_`type'_2001) , m
        egen        `type'_hhwrk_2001      =   rowtotal(main_hh_`type'_2001) , m
        egen        `type'_otwrk_2001      =   rowtotal(main_ot_`type'_2001) , m
        egen        `type'_marwrk_2001      =   rowtotal(marg_??_`type'_2001) , m

        ** 2011
                /*
                Category : composition
                1 : cultivators
                2 : agricultural labourers
                3 : livestock, forestry, fishing, hunting and plantations, orchards and allied activities
                4 : mining and quarrying
                5a : in household industry
                5b : in manufacturing other than household industry
                6 : in construction
                7 : in trade and commerce
                8 : in transport storage and communications
                9 : other services
                */
        egen        `type'_clwrk_2011      =   rowtotal(main_cl_`type'_2011) , m
        egen        `type'_alwrk_2011      =   rowtotal(main_al_`type'_2011) , m
        egen        `type'_hhwrk_2011      =   rowtotal(main_hh_`type'_2011) , m
        egen        `type'_otwrk_2011      =   rowtotal(main_ot_`type'_2011) , m
        egen        `type'_marwrk_2011      =   rowtotal(marg_??_`type'_2011) , m

    }

*-------------------------------------------------------------------------------
* Check: total work = sum up across categories
*-------------------------------------------------------------------------------

    * 1961-91 : does not include marginal workers
    forval year = 1961(10)1991 {

        foreach     type in t m f {

        gen chk5_`type'_wrk_`year' = (`type'_wrk_`year' == `type'_clwrk_`year' + `type'_alwrk_`year' + `type'_hhwrk_`year' + `type'_otwrk_`year')
        lab var chk5_`type'_wrk_`year' "`type'_wrk_`year' == `type'_clwrk_`year' + `type'_alwrk_`year' + `type'_hhwrk_`year' + `type'_otwrk_`year'"

        cap assert chk5_`type'_wrk_`year' == 1

            if _rc {
                ereplace    `type'_wrk_`year' = rowtotal(`type'_??wrk_`year') ///
                            if chk5_`type'_wrk_`year' == 0 , m
            }

        }
    }

    * 2001+ : includes marginal workers

    forval year = 2001(10)2011 {

        foreach     type in t m f {

        gen chk5_`type'_wrk_`year' = (`type'_wrk_`year' == `type'_clwrk_`year' + `type'_alwrk_`year' + `type'_hhwrk_`year' + `type'_otwrk_`year')
        lab var chk5_`type'_wrk_`year' "`type'_wrk_`year' == `type'_clwrk_`year' + `type'_alwrk_`year' + `type'_hhwrk_`year' + `type'_otwrk_`year'"

        cap assert chk5_`type'_wrk_`year' == 1

            if _rc {
                ereplace    `type'_wrk_`year' = rowtotal(`type'_??wrk_`year' `type'_marwrk_`year') ///
                            if chk5_`type'_wrk_`year' == 0 , m
            }

        }
    }

*-------------------------------------------------------------------------------
* Clean up
*-------------------------------------------------------------------------------

    forval year = 1961(10)1981 {

        foreach var in      pop sc st lit ///
                            wrk nonwrk marwrk ///
                            clwrk alwrk hhwrk otwrk {

            * Generate as missing if non exisitent
            cap gen     t_`var'_`year' = .
            cap gen     m_`var'_`year' = .
            cap gen     f_`var'_`year' = .

            * 1. m/f = 0 if missing but town population exists
            replace m_`var'_`year'    = 0 if mi(m_`var'_`year') & !mi(t_pop_`year')
            replace f_`var'_`year'    = 0 if mi(f_`var'_`year') & !mi(t_pop_`year')

            * 2. total of var = male + female if missing but m/f exists
            ereplace    t_`var'_`year'   = rowtotal(m_`var'_`year' f_`var'_`year') ///
                                      if mi(t_`var'_`year') & (!mi(m_`var'_`year') | !mi(f_`var'_`year'))

            * 3. total = 0 if missing, but population exists
            replace     t_`var'_`year'   = 0 if mi(t_`var'_`year') & exist_`year' == 1

            * checks
            gen     chk1_`var'_`year' =  (t_`var'_`year' > 0)
            gen     chk2_`var'_`year' =  (m_`var'_`year' > 0)
            gen     chk3_`var'_`year' =  (f_`var'_`year' > 0)
            gen     chk4_`var'_`year' =  (t_`var'_`year' == (m_`var'_`year' + f_`var'_`year')) if !mi(t_`var'_`year')

            * Labels
            lab var    t_`var'_`year' "total `var' `year'"
            lab var    m_`var'_`year' "male `var' `year'"
            lab var    f_`var'_`year' "female `var' `year'"

            lab var chk1_`var'_`year' "t_`var'_`year' > 0"
            lab var chk2_`var'_`year' "m_`var'_`year' > 0"
            lab var chk3_`var'_`year' "f_`var'_`year' > 0"
            lab var chk4_`var'_`year' "t_`var'_`year' == (m_`var'_`year' + f_`var'_`year')"

                * replace t = m + f if fails check 4 and within threshold 25%
                ereplace t_`var'_`year'   = rowtotal(m_`var'_`year' f_`var'_`year') ///
                                          if chk4_`var'_`year' == 0 , m

            * check t = m + f
            cap assert t_`var'_`year' == (m_`var'_`year' + f_`var'_`year')
                if _rc {
                    di as error "Failed `var' `year'"
                }

        /* end var loop */
        }

    /* end year loop */
    }

    *** Note: 2001 and 2011 data are from the census website, hence no additional cleaning


    *-------------------------------------------------------------------------------
    * Aggregate: agricultural and non agricultural work
    *-------------------------------------------------------------------------------

    forval year = 1961(10)2011 {
    foreach     type in t m f {

        egen        `type'_agwrk_`year'      =   rowtotal(`type'_clwrk_`year' `type'_alwrk_`year') , m
        egen        `type'_nonagwrk_`year'   =   rowtotal(`type'_hhwrk_`year' `type'_otwrk_`year' `type'_marwrk_`year') , m

    }
    }

    *-------------------------------------------------------------------------------
    * Generate % variables
    *-------------------------------------------------------------------------------

    forval      year    = 1961(10)2011 {
    foreach     type    in t m f {
    foreach     var     in      sc st lit ///
                                wrk nonwrk marwrk ///
                                clwrk alwrk hhwrk otwrk ///
                                agwrk nonagwrk {

                * Calculate % of town population
                gen     pct_`type'_`var'_`year' = `type'_`var'_`year' / t_pop_`year'
                lab var pct_`type'_`var'_`year' "pct. `type' `var' `year'"

                * check pct is within 0,1
                qui sum     pct_`type'_`var'_`year'
                cap assert  r(max) <= 1
                    if _rc {
                        replace pct_`type'_`var'_`year' = .f if pct_`type'_`var'_`year' > 1 & !mi(pct_`type'_`var'_`year')
                    }
                qui sum     pct_`type'_`var'_`year'
                cap assert  r(max) <= 1
                    if _rc {
                        di "failed"
                    }

    /* end var loop */
    }
    /* end type loop */
    }
    /* end year loop */
    }

    *-------------------------------------------------------------------------------

    * Sanity check
    isid    id_town

* Compress and save

    compress
    save "$b_output/dchb_town/03_clean_towns_wide.dta" , replace
    // save "$dchb/output/town/03_clean_towns_wide.dta" , replace
