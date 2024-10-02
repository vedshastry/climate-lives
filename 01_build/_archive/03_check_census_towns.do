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


*-------------------------------------------------------------------------------
* Use cleaned/harmonised data
*-------------------------------------------------------------------------------

	use "$b_output/dchb_town/02_clean_towns_wide.dta", clear

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
			rhs(`sex'_cat*_`year') ///
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

	* Iterate over variables
	foreach var in      pop sc st lit ///
						wrk nonwrk marwrk ///
						clwrk alwrk hhwrk otwrk {

		cap gen t_`var'_`year' = .
		cap gen m_`var'_`year' = .
		cap gen f_`var'_`year' = .

		replace t_`var'_`year' = . if t_`var'_`year' == 0 // Zero totals are missing info
		assert 	t_`var'_`year' > 0 // Totals must be positive

		*** CHECK AT INDICATOR LEVEL: Total  = male + female
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

		*** Note: In 1981 and 1991, total workers -do not include- marginal workers.
		*** Calculating total (main + marginal) workers
// br *t*81 if chk_t_wrkcat_1981 == 0
		// if inlist(`year',1981,1991){
		// ereplace 	`sex'_wrk_`year' = rowtotal(`sex'_wrk_`year' `sex'_marwrk_`year') , m
		// }
