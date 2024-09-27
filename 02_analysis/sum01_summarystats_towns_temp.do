*-------------------------------------------------------------------------------
* Summary stats
*-------------------------------------------------------------------------------

* Load the dataset
use "$a_input/00_prep_towns_temperature.dta", clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"
        lab var area "Area in sq. km"
        lab var t_pdensity "Population density per sq. km"

* List of variables
local vars "area t_pdensity t_pop t_sc t_st t_wrk t_clwrk t_alwrk t_hhwrk t_otwrk" // tbar_mean rain_mean"

* Generate summary statistics by decade
eststo clear
forvalues d = 1961(10)2011 {
    eststo dec`d': estpost summarize `vars' if census_dec == `d'
}

* Export the results to a LaTeX table
esttab dec* using "${tex_dir}/tables/decade_summary_stats.tex", ///
    cells("mean(fmt(%13.2fc))") ///
    collabels(none) modelwidth(15) ///
    mtitles("1961" "1971" "1981" "1991" "2001" "2011") ///
    label booktabs replace ///
    compress
