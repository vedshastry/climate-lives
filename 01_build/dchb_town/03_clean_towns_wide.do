*-------------------------------------------------------------------------------
* use cleaned town panel
*-------------------------------------------------------------------------------

    use "$b_output/dchb_town/02_check_census_towns.dta" , clear

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

    }

    *** Note: 2001 and 2011 already constructed and harmonized from the census website, hence no additional cleaning

    *-------------------------------------------------------------------------------
    * Order final vars to the beginning

    order   _all , seq
    order   t_* m_* f_*
    order   id_town xid idchain name_* ///
            ?_pop_* ?_wrk* ?_nonwrk* ?_marwrk* ///
            ?_wrk* ?_nonwrk* ?_marwrk* ///
            ?_clwrk* ?_alwrk* ?_hhwrk* ?_otwrk* ///
            ?_sc* ?_st* ?_lit*

    *-------------------------------------------------------------------------------

    * Sanity check
    isid    id_town


* Compress and save

    compress
    save "$b_output/dchb_town/03_clean_towns_wide.dta" , replace
    // save "$dchb/output/town/03_clean_towns_wide.dta" , replace
