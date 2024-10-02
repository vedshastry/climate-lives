*-------------------------------------------------------------------------------
* use cleaned town panel
*-------------------------------------------------------------------------------

    use "$b_output/dchb_town/01_import_census_towns.dta" , clear

    * Create town ID from idchain
    isid        idchain
    egen    	id_town = group(idchain)
	order 		id_town

    * merge in coordinates
    merge 1:1 	idchain using ///
			    "$dchb/output/town/townpanel_clean.dta" ///
			    , assert(1 3) nogen keepusing(x y code_2011 exist_*)

    * sanity check
    sort       id_town
    isid       id_town

*-------------------------------------------------------------------------------
* Harmonise variables
*-------------------------------------------------------------------------------

    * - area/households
    gen     	area_2011 = . 							// 2011 area is missing

    rename      area_sqkm_*                 area_* // area in sq km.
    rename      res_house_1991              nhouses_1991 // No. of residential houses
    rename      households_1991             nhouseholds_1991 // No. of households

    * - population
    rename      townpop_?_*                 ?_pop_*
    rename      townpop_*                   t_pop_*
    rename      t_?_popln_1991              ?_pop_1991
    rename      t_popln_1991                t_pop_1991
    rename      popln_?6_1991               ?6_pop_1991
    rename      p_06_20??                   t6_pop_20??
    rename      ?_06_20??                   ?6_pop_20??

    * - sc/st
    rename      sc_?_* 						?_sc_* // 1961-91 total sc/st
    rename      st_?_* 						?_st_* // 1961-91 total sc/st
    rename      p_sc_* 						t_sc_* // 2001-11 total sc/st
    rename      p_st_* 						t_st_* // 2001-11 total sc/st

    rename      edu_?_* 					?_lit_* // 1961-91 literate
    rename      ?_literate_* 				?_lit_* // 2001-11 literate

    rename      *_p_* 			*_t_* // rewrite p as t
    rename      p_* 			t_* // rewrite p as t

    * - occupation
    rename      workers_?_* 	?_wrk_* // total workers main
    rename      wrk_non?_* 		?_nonwrk_* // non workers
    rename      wrk_mar?_* 		?_marwrk_* // marginal workers

    * - occupation categories
    rename      wrk_*t_* 	t_cat*_* // 1961-81 total workers main
    rename      wrk_*m_* 	m_cat*_* // 1961-81 male workers
    rename      wrk_*f_* 	f_cat*_* // 1961-81 female workers

    rename      ?_catothers_1981 	?_cat9_1981 // 1981 workers (other)

    rename      t_?_worker_1991 	?_wrk_1991 // 1991 category-wise workers
    rename      ?_marginal_1991 	?_marwrk_1991 // 1991 category-wise workers
    rename      ?_non_work_1991 	?_nonwrk_1991 // 1991 category-wise workers
    rename      *indcat* 			*cat* // 1991 categories

	* rename 		tot_work_?_20?? 	?_wrk_20?? // 2001-11 total workers (main + marginal)
	rename 		mainwork_?_20?? 	?_wrk_20?? // 2001-11 total workers (main)
	rename 		non_work_?_20?? 	?_nonwrk_20?? // 2001-11 non workers
	rename 		margwork_?_20?? 	?_marwrk_20?? // 2001-11 marginal workers


	rename 		main_??_t_20?? t_??wrk_20?? // 2001-11 category workers total
	rename 		main_??_m_20?? m_??wrk_20?? // 2001-11 category workers male
	rename 		main_??_f_20?? f_??wrk_20?? // 2001-11 category workers female

*-------------------------------------------------------------------------------
* Clean names
*-------------------------------------------------------------------------------

	* Town name (most recent)
    gen         name_town = ""
    	forval 		year = 1961(10)2011 {
        replace     name_town = strproper(tname_`year') if !mi(tname_`year') // replace with most recent town name
    	}
	lab var 	name_town "Town name"
	assert 		!mi(name_town) // Town name is never missing

	* District and state name (most recent)
    gen         name_st = "" // 2011 state name
    gen         name_dt = "" // 2011 district name

	lab var 	name_st "State name"
	lab var 	name_dt "District name"

	forval 		year = 1961(10)2011 {
    replace     name_st = strproper(sname_`year') if !mi(sname_`year') // replace with most recent state name
    replace     name_dt = strproper(dname_`year') if !mi(sname_`year') // replace with most recent district name
	}

    * 1991 missing total (only male/female given)
	foreach var in      sc st lit ///
						wrk nonwrk marwrk ///
						cat1 cat2 cat3 cat4 ///
						cat5a cat5b cat6 cat7 cat8 cat9 {

            egen t_`var'_1991 = rowtotal(m_`var'_1991 f_`var'_1991) , m

    }

    * Asserts
	assert 		!mi(name_st) // State name is never missing
	assert 		!mi(name_dt) // District name is never missing

    *** CHECK DATA FOR 1961-1991 [TOTAL = MALE + FEMALE] for all indicators
    forval year = 1961(10)1991 {

            replace 	exist_`year' = 0 if mi(t_pop_`year')

        	foreach var in      pop sc st lit ///
        						wrk nonwrk marwrk ///
        						cat1 cat2 cat3 cat4 cat5 ///
        						cat5a cat5b cat6 cat7 cat8 cat9 {

            * Gen empty var if does not exist
    		cap gen t_`var'_`year' = .
    		cap gen m_`var'_`year' = .
    		cap gen f_`var'_`year' = .

            * Asserts
    		replace t_`var'_`year' = . if t_`var'_`year' == 0 // Zero totals are missing info
    		assert 	t_`var'_`year' > 0 // Totals must be positive

            * Check if total = male + female for var in year
    		dchb_check if exist_`year', ///
    			chkname(`var'_mf_`year') ///
    			lhs(t_`var'_`year') ///
    			rhs(m_`var'_`year' f_`var'_`year') ///
    			threshold(0.25) return missing

        	}
    }

*-------------------------------------------------------------------------------
* Construct consistent indicators for years 1961-2011
*-------------------------------------------------------------------------------

    * Aggregate by category:
        * 1. Non agricultural workers (Household industry + other)
        * 2. Agricultural workers (Household industry + other)
            * 2.1. Cultivators
            * 2.2. Agricultural labourers
        * 3. Marginal workers
        * 4. Non workers

    *** See dofile appendix for a complete definition

*-------------------------------------------------------------------------------

    *---------------------------------
    * 1961-1991
    *---------------------------------

    forval year = 1961(10)1991 {

        foreach type in t m f {

        * Non agricultural workers
        egen        `type'_nonagwrk_`year'   =   rowtotal(`type'_cat3_`year' `type'_cat4_`year' `type'_cat5_`year' `type'_cat5?_`year' `type'_cat6_`year' `type'_cat7_`year' `type'_cat8_`year' `type'_cat9_`year')

        * Agricultural workers
        egen        `type'_agwrk_`year'      =   rowtotal(`type'_cat1_`year' `type'_cat2_`year')
            egen        `type'_clwrk_`year'      =   rowtotal(`type'_cat1_`year') // Cultivators
            egen        `type'_alwrk_`year'      =   rowtotal(`type'_cat2_`year') // Ag. laborers

        *** CHECK: if total workers = ag + nonag workers
		dchb_check if exist_`year', ///
			chkname(`type'_wrkag_`year') ///
			lhs(`type'_wrk_`year') ///
			rhs(`type'_nonagwrk_`year' `type'_agwrk_`year') ///
			threshold(0.25) return missing

        }

    }

    *---------------------------------
    * 2001-2011
    *---------------------------------

    forval year = 2001(10)2011 {
        foreach type in t m f {

        * Non agricultural workers
        egen        `type'_nonagwrk_`year'   =   rowtotal(`type'_hhwrk_`year' `type'_otwrk_`year')

        * Agricultural workers
        egen        `type'_agwrk_`year'      =   rowtotal(`type'_clwrk_`year' `type'_alwrk_`year')
            * egen        `type'_clwrk_`year'      =   rowtotal(`type'_cat1_`year') // Cultivators
            * egen        `type'_alwrk_`year'      =   rowtotal(`type'_cat2_`year') // Ag. laborers

        }
    }


    forval year = 2001(10)2011 {

    	foreach var in      pop sc st lit ///
    						wrk nonwrk marwrk ///
                            nonagwrk agwrk clwrk alwrk {

                    * Check if total = male + female for var in year
                		dchb_check if exist_`year', ///
                			chkname(`var'_mf_`year') ///
                			lhs(t_`var'_`year') ///
                			rhs(m_`var'_`year' f_`var'_`year') ///
                			threshold(0.25) return missing

        }

        foreach type in t m f {

        *** CHECK: if total workers = ag + nonag workers
		dchb_check if exist_`year', ///
			chkname(`type'_wrkag_`year') ///
			lhs(`type'_wrk_`year') ///
			rhs(`type'_nonagwrk_`year' `type'_agwrk_`year') ///
			threshold(0.25) return missing

        }
    }

    *-------------------------------------------------------------------------------
    * Checks
    *-------------------------------------------------------------------------------

    /*
    * Split marginal workers into ag and nonag categories
    forval year = 1961(10)1991 {

        foreach type in t m f {

        * Total workers = total (main) + marginal
        ereplace     `type'_wrk_`year'   = rowtotal(`type'_wrk_`year' `type'_marwrk_`year'), m

        * Agricultural seasonal workers
        gen         `type'_agratio_`year'      = `type'_agwrk_`year' / `type'_wrk_`year'
        gen        `type'_maragwrk_`year'      = `type'_marwrk_`year' * `type'_agratio_`year'

        * Non agricultural seasonal workers
        gen         `type'_nonagratio_`year'      = `type'_nonagwrk_`year' / `type'_wrk_`year'
        gen        `type'_marnonagwrk_`year'   = `type'_marwrk_`year' * `type'_nonagratio_`year'

        *** CHECK: if total workers = ag + nonag workers
		dchb_check if exist_`year', ///
			chkname(`type'_maragwrk_`year') ///
			lhs(`type'_marwrk_`year') ///
			rhs(`type'_maragwrk_`year' `type'_marnonagwrk_`year') ///
			threshold(0.25) return missing

        }
    }

    forval year = 1961(10)1991 {

        foreach type in t m f {

        }
    }

    */


*-------------------------------------------------------------------------------

    * Sanity check
    isid    id_town

* Compress and save
    compress
    save "$b_output/dchb_town/02_prep_towns_wide.dta" , replace

*-------------------------------------------------------------------------------
/*

********************************************************************************
*** APPENDIX
********************************************************************************

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

    ** 1981
            /*
            Category : composition
            1 : cultivators
            2 : agricultural labourers
            5a : in household industry
            9 : other; all categories from 3,4,5b,6,7,8,9
                *** all categories were aggregated to cat 9 due to census delays
            */

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

    *** Note: 2001 and 2011 already constructed and harmonized from the census website, hence no additional cleaning

    */
