*-------------------------------------------------------------------------------
* Summary stats
*-------------------------------------------------------------------------------

* Load the dataset
use "$a_input/00_prep_towns_climate.dta", clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"
        lab var area "Area in sq. km"
        lab var t_pdensity "Population density per sq. km"

*-------------------------------------------------------------------------------

** Table: Workers and shares

    * List of variables
    qui foreach sex in t m f {

    local vars "`sex'_pop `sex'_pdensity `sex'_wrk `sex'_nonagwrk `sex'_agwrk `sex'_clwrk `sex'_alwrk `sex'_marwrk"
    // local vars "`sex'_pop `sex'_pdensity `sex'_sc `sex'_st `sex'_wrk `sex'_clwrk `sex'_alwrk `sex'_hhwrk `sex'_otwrk `sex'_marwrk"

        * Generate summary statistics by decade
        eststo clear
        forvalues d = 1961(10)2011 {
            eststo dec`d': estpost summarize `vars' if census_dec == `d'
        }

        * Export the results to a LaTeX table
        nois esttab dec* using "${tex_dir}/tables/00_table_towns_yearwise_`sex'.tex", ///
            cells("mean(fmt(%13.2fc))") ///
            collabels(none) modelwidth(15) ///
            mtitles("1961" "1971" "1981" "1991" "2001" "2011") ///
            label booktabs replace ///
            compress

    }

*-------------------------------------------------------------------------------

** Table: Demographics

    * List of variables
    qui foreach sex in t m f {

    local vars "`sex'_pop `sex'_sc `sex'_st `sex'_lit `sex'_wrk `sex'_nonwrk"

        * Generate summary statistics by decade
        eststo clear
        forvalues d = 1961(10)2011 {
            eststo dec`d': estpost summarize `vars' if census_dec == `d'
        }

        * Export the results to a LaTeX table
        nois esttab dec* using "${tex_dir}/tables/00_table_towns_decade_demographics_`sex'.tex", ///
            cells("mean(fmt(%13.2fc))") ///
            collabels(none) modelwidth(15) ///
            mtitles("1961" "1971" "1981" "1991" "2001" "2011") ///
            label booktabs replace ///
            compress

    }
