********************************************************************************
* Harmonise PCA data 1961-2011
	/*
	Variables:
		pop sc st lit ///
		wrk nonwrk marwrk ///
		cat1 cat2 cat3 cat4 ///
		cat5a cat5b cat6 cat7 cat8 cat9
	*/
********************************************************************************

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
	lab var 	name_town "Town name"

	forval 		year = 1961(10)2011 {
    replace     name_town = strproper(tname_`year') if !mi(tname_`year')
	}
	assert 		!mi(name_town) // Town name is never missing

	* District and state name (most recent)
    gen         name_st = "" // 2011 state name
    gen         name_dt = "" // 2011 state name
	lab var 	name_st "State name"
	lab var 	name_dt "District name"

	forval 		year = 1961(10)2011 {
    replace     name_st = strproper(sname_`year') if !mi(sname_`year')
    replace     name_dt = strproper(dname_`year') if !mi(sname_`year')
	}

	assert 		!mi(name_st) // State name is never missing
	assert 		!mi(name_dt) // District name is never missing

	* Town existence depends on whether total population was recorded
	forval year = 1961(10)2011 {
		replace 	exist_`year' = 0 if mi(t_pop_`year')
	}

*-------------------------------------------------------------------------------
* Data checks
** See /99_ado/dchb_check.ado
*-------------------------------------------------------------------------------

* Running checks and imputation
*** 1961-1991 ***
forval year = 1961(10)1991 {

	*** AT INDICATOR LEVEL: Total  = male + female
	foreach var in      pop sc st lit ///
						wrk nonwrk marwrk ///
						cat1 cat2 cat3 cat4 cat5 ///
						cat5a cat5b cat6 cat7 cat8 cat9 {

		cap gen t_`var'_`year' = .
		cap gen m_`var'_`year' = .
		cap gen f_`var'_`year' = .

		replace t_`var'_`year' = . if t_`var'_`year' == 0 // Zero totals are missing info
		assert 	t_`var'_`year' > 0 // Totals must be positive

		dchb_check if exist_`year', ///
			chkname(`var'_mf_`year') ///
			lhs(t_`var'_`year') ///
			rhs(m_`var'_`year' f_`var'_`year') ///
			threshold(0.25) return

	}

	*** AT WORKER CATEGORY LEVEL: Total = sum of categories
	foreach sex in t m f {

		dchb_check if exist_`year', ///
			chkname(`sex'_wrkcat_`year') ///
			lhs(`sex'_wrk_`year') ///
			rhs(`sex'_cat*_`year' `sex'_marwrk_`year') ///
			threshold(0.25) return

	}

	*** AT TOWN LEVEL: Town population = workers + nonworkers + marginal workers
	foreach sex in t m f {

		dchb_check if exist_`year', ///
			chkname(`sex'_popwrk_`year') ///
			lhs(`sex'_pop_`year') ///
			rhs(`sex'_wrk_`year' `sex'_nonwrk_`year' `sex'_marwrk_`year') ///
			threshold(0.25) return
	}

}
*** 2001-2011 ***
forval year = 2001(10)2011 {

	*** AT INDICATOR LEVEL: Total  = male + female
	foreach var in      pop sc st lit ///
						wrk nonwrk marwrk ///
						clwrk alwrk hhwrk otwrk {

		cap gen t_`var'_`year' = .
		cap gen m_`var'_`year' = .
		cap gen f_`var'_`year' = .

		replace t_`var'_`year' = . if t_`var'_`year' == 0 // Zero totals are missing info
		assert 	t_`var'_`year' > 0 // Totals must be positive

		dchb_check if exist_`year', ///
			chkname(`var'_mf_`year') ///
			lhs(t_`var'_`year') ///
			rhs(m_`var'_`year' f_`var'_`year') ///
			threshold(0.25) return

	}

	*** AT TOWN LEVEL: Town population = workers + nonworkers

	foreach sex in t m f {

		dchb_check if exist_`year', ///
			chkname(`sex'_popwrk_`year') ///
			lhs(`sex'_pop_`year') ///
			rhs(`sex'_wrk_`year' `sex'_nonwrk_`year' `sex'_marwrk_`year') ///
			threshold(0.25) return
	}

}


*-------------------------------------------------------------------------------

* Re order/sort
order 	id_town xid idchain name_town name_st name_dt ///
		*pop_* *sc_* *st_* *lit_* ///
		*wrk_* *nonwrk_* *marwrk_*

order 	chk* rsum* rnm* diff* pcdiff* , last
/*
*/

* compress and save

    qui compress
    save "$b_output/dchb_town/02_check_census_towns.dta" , replace

*** End
