*-------------------------------------------------------------------------------
* Summary stats
*-------------------------------------------------------------------------------

* Load the dataset
use "$a_input/00_prep_towns_climate.dta", clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"
        lab var area "Area in sq. km"
        lab var t_pdensity "Population density per sq. km"

    foreach sex in t m f {

        // local L = strproper("`sex'")
        if "`sex'" == "t" {
            local L "Total"
        }
        if "`sex'" == "m" {
            local L "Male"
        }
        if "`sex'" == "f" {
            local L "Female"
        }

        lab var log_`sex'_pop "`L' log. population"
        lab var pct_`sex'_wrk "`L' percent working population"
        lab var shr_`sex'_nonagwrk "`L' share of non-agricultural workers"
        lab var shr_`sex'_agwrk "`L' share of agricultural workers"
        lab var shr_`sex'_clwrk "`L' share of cultivators"
        lab var shr_`sex'_alwrk "`L' share of agricultural laborers"
        lab var shr_`sex'_marwrk "`L' share of marginal workers"

    }

*-------------------------------------------------------------------------------

** Table: Pct of workers and share of workers in each category

    * List of variables
    qui foreach sex in t m f {

    local vars "log_`sex'_pop pct_`sex'_wrk shr_`sex'_nonagwrk shr_`sex'_agwrk shr_`sex'_clwrk shr_`sex'_alwrk shr_`sex'_marwrk"

        * Generate summary statistics by decade
        eststo clear
        forvalues d = 1961(10)2011 {
            eststo dec`d': estpost summarize `vars' if census_dec == `d'
        }

        * Export the results to a LaTeX table
        nois esttab dec* using "${tex_dir}/tables/00_table_towns_decade_share_`sex'.tex", ///
            cells("mean(fmt(%9.3fc))") ///
            collabels(none) modelwidth(15) ///
            mtitles("1961" "1971" "1981" "1991" "2001" "2011") ///
            label booktabs replace ///
            compress

    }

*-------------------------------------------------------------------------------
