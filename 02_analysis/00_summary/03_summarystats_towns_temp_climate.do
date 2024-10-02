*-------------------------------------------------------------------------------
* Summary stats
*-------------------------------------------------------------------------------

* Load the dataset
use "$a_input/00_prep_towns_climate.dta", clear

        lab var tbar_mean "10y daily mean temp. (C)"
        lab var rain_mean "10y daily mean rain (mm)"

        lab var tlst_mean "10y daily mean temp. (C) - LST definition"
        lab var plst_mean "10y daily mean rain (mm) - LST definition"

        lab var tkharall_mean "10y daily mean temp. (C) - Kharif season"
        lab var pkharall_mean "10y daily mean rain (mm) - Kharif season"

        lab var trabiall_mean "10y daily mean temp. (C) - Rabi season"
        lab var prabiall_mean "10y daily mean rain (mm) - Rabi season"

        lab var tbar_min "10y daily min temp. (C)"
        lab var rain_min "10y daily min rain (mm)"

        lab var tbar_max "10y daily max temp. (C)"
        lab var rain_max "10y daily max rain (mm)"
*-------------------------------------------------------------------------------

** Table: Pct of workers and share of workers in each category

    * List of variables
    local tvars "tbar_mean tlst_mean tkharall_mean trabiall_mean tbar_min tbar_max"
    local pvars "rain_mean plst_mean pkharall_mean prabiall_mean rain_min rain_max"

        * Generate summary statistics by decade
        eststo clear
        forvalues d = 1961(10)2011 {
            eststo dec`d': estpost summarize `tvars' `pvars' if census_dec == `d'
        }

        * Export the results to a LaTeX table
        nois esttab dec* using "${tex_dir}/tables/00_table_towns_decade_climate.tex", ///
            cells("mean(fmt(%9.3fc))") ///
            collabels(none) modelwidth(15) ///
            mtitles("1961" "1971" "1981" "1991" "2001" "2011") ///
            label booktabs replace ///
            compress ///
            addnotes( ///
            "LST definition: main agricultural growing season months (June through February)." ///
            )

*-------------------------------------------------------------------------------
