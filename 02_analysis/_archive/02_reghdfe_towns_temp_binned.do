*-------------------------------------------------------------------------------
* Regress census outcomes on climate vars at town level
*-------------------------------------------------------------------------------

* regression estimates

    * use analysis data
    // use "$a_input/00_prep_towns_climate.dta" , clear

        * keep towns that exist from a particular year
        // bys id_town (census_dec) : gen etag = (exist == 1 & census_dec == 1961)
        // bys id_town (census_dec) : egen ktag = max(etag)
        // keep if ktag == 1


    ****************************************************************************
    *** Reg workers by category
    ****************************************************************************

        /*
        1. Outcome variable: workers in each category, by gender aggregation and temperature statistic.
        2. Fixed effects: Town, decade, state-year
        */

    use "$a_input/00_prep_towns_climate.dta" , clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var tbar_min " Decadal min temp. (C)"
        lab var tbar_max "Decadal max temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"

        local fe_vars id_town census_dec styear

        est clear // clear estimates

        ** iterate over:
        * gender = total, male, female
        * temperature stat
        * worker categories
        qui {
        foreach sex in t m f {
        foreach stat in mean min max {
        foreach yvar in nonwrk wrk clwrk alwrk hhwrk otwrk {

        nois di "calculating: `sex'_`yvar'_`stat'"

                eststo  `sex'_`yvar'_`stat' : ///
                        reghdfe pct_`sex'_`yvar' ib0.bin_tbar_`stat' c.rain_mean ///
                        , absorb(`fe_vars') vce(cluster id_town) nocons

                sum pct_`sex'_`yvar' if e(sample)
                estadd scalar Mean = r(mean) // store mean

                cap mkdir "$a_output/estimates/binned/"
                estwrite `sex'_`yvar'_`stat' using "$a_output/estimates/binned/`sex'_`yvar'_`stat'" , id(pid) replace reproducible

        /* end yvar loop */
        }
        /* end stat loop */
        }
        /* end sex loop */
        }
        /* end quietly */
        }


*** Export tables

    foreach sex in t m f {
        foreach stat in mean {

            * Table: workers on binned temperatures
            esttab `sex'_*_`stat' using "${tex_dir}/tables/binned_reg_`sex'_workers_category_temperature_`stat'.tex", ///
                mtitles("Nonworkers" "Workers" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                drop(rain_mean) ///
                rename(0.bin_tbar_`stat' "18-20°C" ///
                       1.bin_tbar_`stat' "20-22°C" ///
                       2.bin_tbar_`stat' "22-24°C" ///
                       3.bin_tbar_`stat' "24-26°C" ///
                       4.bin_tbar_`stat' "26-28°C" ///
                       5.bin_tbar_`stat' "28-30°C" ///
                       6.bin_tbar_`stat' "30-32°C") ///
                coeflabels(0.bin_tbar_`stat' "18-20°C" ///
                           1.bin_tbar_`stat' "20-22°C" ///
                           2.bin_tbar_`stat' "22-24°C" ///
                           3.bin_tbar_`stat' "24-26°C" ///
                           4.bin_tbar_`stat' "26-28°C" ///
                           5.bin_tbar_`stat' "28-30°C" ///
                           6.bin_tbar_`stat' "30-32°C") ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                addnotes("Standard errors in parentheses." ///
                         "Temperature bins are in °C, with 18-20°C as the omitted category.")

        /* end stat loop */
        }
    /* end sex loop */
    }

** Coefplot
foreach sex in t m f {
    foreach stat in mean {

        local sex t
        local stat mean

        // Create the coefficient plot
        coefplot ///
            (`sex'_nonwrk_`stat', label("Nonworkers") msymbol(O) color(navy)) ///
            (`sex'_wrk_`stat', label("Workers") msymbol(D) color(maroon)) ///
            (`sex'_clwrk_`stat', label("Cultivators") msymbol(T) color(forest_green)) ///
            (`sex'_alwrk_`stat', label("Ag. Laborers") msymbol(S) color(dkorange)) ///
            (`sex'_hhwrk_`stat', label("HH Industry") msymbol(+) color(purple)) ///
            (`sex'_otwrk_`stat', label("Other") msymbol(X) color(cranberry)), ///
            keep(*.bin_tbar_`stat') ///
            coeflabels(0.bin_tbar_`stat' = "18-20" ///
                       1.bin_tbar_`stat' = "20-22" ///
                       2.bin_tbar_`stat' = "22-24" ///
                       3.bin_tbar_`stat' = "24-26" ///
                       4.bin_tbar_`stat' = "26-28" ///
                       5.bin_tbar_`stat' = "28-30" ///
                       6.bin_tbar_`stat' = "30-32", ///
                       notick labsize(small)) ///
            ylabel(, labsize(small)) ///
            xlabel(, labsize(small)) ///
            xtitle("Temperature Bins (°C)", size(small)) ///
            ytitle("Coefficient (Percentage Points)", size(small)) ///
            legend(rows(2) size(small)) ///
            yline(0, lcolor(gs8) lpattern(dash)) ///
            msymbol(S) ///
            msize(small) ///
            ciopts(recast(rcap) lwidth(thin)) ///
            mlabel format(%9.3f) mlabposition(1) mlabgap(*2) ///
            mlabsize(vsmall) ///
            title("Effects of Temperature on Worker Categories (`sex', `stat')", size(medium)) ///
            note("Note: 18-20°C is the reference category. Whiskers represent 95% confidence intervals.", size(vsmall)) ///
            graphregion(color(white)) ///
            bgcolor(white) ///
            vertical
             recast(connected)

        graph export "$a_output/figures/coefplot_`sex'_`stat'.png", replace
    }
}



/*
    ****************************************************************************
    *** Reg workers per category on 'seasonal' temperature
    ****************************************************************************

    /*
    1. Outcome variable: workers in each category, by gender aggregation and temperature statistic.
    2. Fixed effects: Town, decade, state-year
    3. Breaks down by kharif and rabi:
        * Kharif = Jun-Nov. sowing = Jun-Sep. harvest = Oct-Nov
        * Rabi = Dec-May. sowing = Dec-Feb. harvest = Apr-May
    */

    use "$a_input/00_prep_towns_climate.dta" , clear

        local fe_vars id_town census_dec


        ** Iterate over:
        * gender = total, male, female
        * temperature stat
        * worker categories
        foreach sex in t m f {
        foreach stat in mean min max {
        foreach ssn in rabi khar {
        foreach mon in all sow hvt {
        foreach yvar in nonwrk wrk clwrk alwrk hhwrk otwrk {

        nois di "Calculating: `sex'_`yvar'_`stat'"

            qui {

                est clear // Clear estimates

                eststo  `sex'_`yvar'_`ssn'`mon'_`stat' : ///
                        reghdfe pct_`sex'_`yvar' c.t`ssn'`mon'_`stat' c.p`ssn'`mon'_`stat' ///
                        , absorb(`fe_vars') vce(cluster id_town) nocons

                estwrite `sex'_`yvar'_`ssn'`mon'_`stat' using "$a_output/estimates/`sex'_`yvar'_`ssn'`mon'_`stat'" , id(pid) replace reproducible

            }

        /* end yvar loop */
        }
        /* end months of season loop */
        }
        /* end season loop */
        }
        /* end stat loop */
        }
        /* end sex loop */
        }

    *** Export tables

        use "$a_input/00_prep_towns_climate.dta" , clear

        * Labels
        lab var tkharall_mean "Decadal kharif temp. (C)"
        lab var tkharsow_mean " Decadal kharif sowing temp. (C)"
        lab var tkharhvt_mean "Decadal kharif harvest temp. (C)"

        lab var trabiall_mean "Decadal rabi temp. (C)"
        lab var trabisow_mean " Decadal rabi sowing temp. (C)"
        lab var trabihvt_mean "Decadal rabi harvest temp. (C)"

        lab var pkharall_mean "Decadal kharif rain (mm)"
        lab var pkharsow_mean " Decadal kharif sowing rain (mm)"
        lab var pkharhvt_mean "Decadal kharif harvest rain (mm)"

        lab var prabiall_mean "Decadal rabi rain (mm)"
        lab var prabisow_mean " Decadal rabi sowing rain (mm)"
        lab var prabihvt_mean "Decadal rabi harvest rain (mm)"


        qui foreach sex in t m f {
        foreach ssn in rabi khar {
        foreach mon in all sow hvt {
        foreach stat in mean min max {

            est clear // Clear estimates
            nois di "Exporting: `sex'_`ssn'`mon'_`stat'"

            foreach yvar in nonwrk wrk clwrk alwrk hhwrk otwrk {

                estread `sex'_`yvar'_`ssn'`mon'_`stat' using "$a_output/estimates/`sex'_`yvar'_`ssn'`mon'_`stat'" , id(pid)

                * sum pct_`sex'_`yvar' if _est_`sex'_`yvar'_`ssn'`mon'_`stat' == 1
                * estadd scalar Mean = r(mean) // Store mean

            }

            * Table: total workers on mean temp.
            esttab `sex'_*_`ssn'`mon'_`stat' using "${tex_dir}/tables/reg_`sex'_workers_category_`ssn'_`mon'_`stat'.tex", ///
                mtitles("Nonworkers" "Workers" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

        /* end stat loop */
        }
        /* end months of season loop */
        }
        /* end season loop */
        }
        /* end sex loop */
        }


    ****************************************************************************
    *** Reg demographics on temperature
    ****************************************************************************
        /*
        1. Outcome variable: population density, log of [population, SC, ST, literature]
        2. Fixed effects: Town, decade, state-year
        */

    use "$a_input/00_prep_towns_climate.dta" , clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var tbar_min " Decadal min temp. (C)"
        lab var tbar_max "Decadal max temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"

        local fe_vars id_town census_dec styear

        est clear // Clear estimates

        ** Iterate over:
        * gender = total, male, female
        * temperature stat
        * worker categories
        qui {
        foreach stat in mean min max {
        foreach sex in t m f {

                eststo  `sex'_pdensity_`stat' : ///
                        reghdfe `sex'_pdensity c.tbar_`stat' c.rain_mean ///
                        , absorb(`fe_vars') vce(cluster id_town) nocons

                sum `sex'_pdensity
                estadd scalar Mean = r(mean) // Store mean

        foreach yvar in pop sc st lit {

        nois di "Calculating: `sex'_`yvar'_`stat'"

                eststo  `sex'_`yvar'_`stat' : ///
                        reghdfe log_`sex'_`yvar' c.tbar_`stat' c.rain_mean ///
                        , absorb(`fe_vars') vce(cluster id_town) nocons

                sum log_`sex'_`yvar'
                estadd scalar Mean = r(mean) // Store mean

        /* end yvar loop */
        }
        /* end stat loop */
        }
        /* end sex loop */
        }
        /* end quietly */
        }

    *** Export tables

        foreach sex in t m f {
        foreach stat in mean min max {

            * Table: total workers on mean temp.
            esttab `sex'_*_`stat' using "${tex_dir}/tables/reg_`sex'_demographics_temperature_`stat'.tex", ///
                mtitles("Pop. density" "Log pop." "Log SC pop." "Log ST pop." "Log literate pop.") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%12.3f %12.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

        /* end stat loop */
        }
        /* end sex loop */
        }

*/
*---------------------------------------------------------------------------
