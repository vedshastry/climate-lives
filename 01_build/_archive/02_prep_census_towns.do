*-------------------------------------------------------------------------------
* prepare census town data for cleaning
*-------------------------------------------------------------------------------

	use "$b_output/dchb_town/01_import_census_towns.dta", clear

    * sanity check
    isid        idchain

    egen    	id_town = group(idchain)
	order 		id_town

    isid        id_town

    * merge in coordinates
    merge 1:1 	idchain using ///
			    "$dchb/output/town/townpanel_clean.dta" ///
			    , assert(1 3) nogen keepusing(x y code_2011 exist_*)

    isid        id_town

    * sanity check
    sort       id_town
    isid       id_town

*-------------------------------------------------------------------------------
* Harmonise variables
*-------------------------------------------------------------------------------

    * - area/households
    rename      area_sqkm_*                 area_*
    rename      res_house_1991              nhouses_1991
    rename      households_1991             nhouseholds_1991

    * - population
    rename      townpop_?_*                 ?_pop_*
    rename      townpop_*                   t_pop_*
    rename      t_?_popln_1991              ?_pop_1991
    rename      t_popln_1991                t_pop_1991
    rename      popln_?6_1991               ?6_pop_1991
    rename      p_06_20??                   t6_pop_20??
    rename      ?_06_20??                   ?6_pop_20??

    * - sc/st
    rename      sc_?_* 						?_sc_*
    rename      st_?_* 						?_st_*
    rename      p_sc_* 						t_sc_* // 2001-11 total sc/st
    rename      p_st_* 						t_st_* // 2001-11 total sc/st

    rename      edu_?_* 					?_lit_*
    rename      ?_literate_* 				?_lit_*

    rename      *_p_* 			*_t_* // rewrite p as t
    rename      p_* 			t_* // rewrite p as t

    * - occupation
    rename      workers_?_* 	?_wrk_* // total workers
    rename      wrk_non?_* 		?_nonwrk_* // non workers
    rename      wrk_mar?_* 		?_marwrk_* // marginal workers

        * category
        rename      wrk_*t_* 	t_cat*_* // 1961-81 total workers
        rename      wrk_*m_* 	m_cat*_* // 1961-81 male workers
        rename      wrk_*f_* 	f_cat*_* // 1961-81 female workers

        rename      ?_catothers_1981 	?_cat9_1981 // 1981 workers (other)

        rename      t_?_worker_1991 	?_wrk_1991 // 1991 category labels
        rename      ?_marginal_1991 	?_marwrk_1991 // 1991 category labels
        rename      ?_non_work_1991 	?_nonwrk_1991 // 1991 category labels
        rename      *indcat* 			*cat* // 1991 categories

		rename 		tot_work_?_2001 	?_wrk_2001
		rename 		non_work_?_2001 	?_nonwrk_2001

		rename 		tot_work_?_2011 	?_wrk_2011
		rename 		non_work_?_2011 	?_nonwrk_2011

	* town name
    gen         name_town = tname_2011 // 2011 town name

*-------------------------------------------------------------------------------
* Clean and standardise indicators
*-------------------------------------------------------------------------------

	* Generate totals for 1991
    foreach var in      sc st lit ///
                        wrk nonwrk marwrk ///
                        cat1 cat2 cat3 cat4 ///
						cat5a cat5b cat6 cat7 cat8 cat9 {

		egen t_`var'_1991 = rowtotal(m_`var'_1991 f_`var'_1991) , m

	}


    * Clean up area
    forval year = 1961(10)2011 {

        cap gen     area_`year' = .

            egen    count_area = rownonmiss(area_`year')

                * Clean area
                foreach var of varlist area_`year' {

                    ereplace     `var' = rowmean(area_`year') ///
                                        if mi(`var') & count_area > 0 // mean town area
                    replace     `var' = round(`var', 0.01) // round to 2 decimals

                }

                * winsorize area at 2nd/98th pctile
                winsor2 area_* , cut(2 98) replace

            drop    count_area
	}

*-------------------------------------------------------------------------------

* compress and save

    compress
    save "$b_output/dchb_town/02_check_census_towns.dta" , replace

*** End
