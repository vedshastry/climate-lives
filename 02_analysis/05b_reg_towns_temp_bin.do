*-------------------------------------------------------------------------------
* reg ag outcomes on temperature at town level
*-------------------------------------------------------------------------------

* regression estimates

    *---------------------------------------------------------------------------
    * . Reg employment on seasonal temperature for each year
    ** https://claude.ai/chat/08d138e8-fff5-4351-bf79-8d1d301be07e
    *---------------------------------------------------------------------------

        * use analysis data
        use "$a_clean/00_prep_towns_temperature.dta" , clear

        * Reshape to wide format
            local reshapevars pct_t_wrk pct_t_agwrk pct_t_nonagwrk tbar_mean tbar_min tbar_max rain_mean
            keep id_town census_dec `reshapevars'
            reshape wide `reshapevars', i(id_town) j(census_dec)

            * Calculate long differences (assuming decadal data)
            forvalues year = 1971(10)2011 {
                local prev_year = `year' - 10
                foreach var in pct_t_wrk pct_t_agwrk pct_t_nonagwrk tbar_mean tbar_min tbar_max rain_mean {
                    gen d_`var'`year' = `var'`year' - `var'`prev_year'
                }
            }

        * Reshape back to long format
        drop pct_* t???_* rain_*
        reshape long d_pct_t_wrk d_pct_t_agwrk d_pct_t_nonagwrk d_tbar_mean d_tbar_min d_tbar_max d_rain_mean, i(id_town) j(census_dec)

        * Reg
        est clear

        foreach yvar in wrk agwrk nonagwrk {
            foreach stat in mean { // min max {
                forvalues year = 1971(10)2011 {
                    nois di "Calculating set: `yvar' - `stat' - `year'"

                    eststo `yvar'_`stat'_`year': reg d_pct_t_`yvar' c.d_tbar_`stat' c.d_rain_mean if census_dec == `year', vce(cluster id_town)

                    qui sum d_pct_t_`yvar' if census_dec == `year'
                    estadd scalar Mean = r(mean)
                }
            }
        }

        * Create a dataset to store coefficients
        clear
        set obs 5
        gen year = 1971 + (_n-1)*10

        foreach yvar in wrk agwrk nonagwrk {
            foreach stat in mean min max {
                gen coef_`yvar'_`stat' = .
                gen ci_low_`yvar'_`stat' = .
                gen ci_high_`yvar'_`stat' = .
            }
        }

        * Store coefficients and CIs
        local row = 1
        forvalues year = 1971(10)2011 {
            foreach yvar in wrk agwrk nonagwrk {
            foreach stat in mean { // min max {
                    estimates restore `yvar'_`stat'_`year'
                    replace coef_`yvar'_`stat' = _b[c.d_tbar_`stat'] in `row'
                    replace ci_low_`yvar'_`stat' = _b[c.d_tbar_`stat'] - invttail(e(df_r),0.025)*_se[c.d_tbar_`stat'] in `row'
                    replace ci_high_`yvar'_`stat' = _b[c.d_tbar_`stat'] + invttail(e(df_r),0.025)*_se[c.d_tbar_`stat'] in `row'
                }
            }
            local row = `row' + 1
        }

        * Reshape the data for plotting
        reshape long coef_wrk_ coef_agwrk_ coef_nonagwrk_ ci_low_wrk_ ci_low_agwrk_ ci_low_nonagwrk_ ci_high_wrk_ ci_high_agwrk_ ci_high_nonagwrk_, i(year) j(stat) string

        * Calculate significance levels for stars
        foreach var in wrk agwrk nonagwrk {
            gen stars_`var' = ""
            replace stars_`var' = "*" if abs(coef_`var'_/ci_low_`var'_) > invttail(e(df_r),0.05)
            replace stars_`var' = "**" if abs(coef_`var'_/ci_low_`var'_) > invttail(e(df_r),0.025)
            replace stars_`var' = "***" if abs(coef_`var'_/ci_low_`var'_) > invttail(e(df_r),0.005)
        }

        * Plot the coefficients
        twoway (connected coef_wrk_ year if stat == "mean", lcolor(black*0.5) lwidth(medthick) mcolor(black*0.5) msymbol(circle) msize(medium)) ///
               (rcap ci_low_wrk_ ci_high_wrk_ year if stat == "mean", lcolor(black*0.5)) ///
               (connected coef_agwrk_ year if stat == "mean", lcolor(olive*0.5) lwidth(medthick) mcolor(olive*0.5) msymbol(circle) msize(medium)) ///
               (rcap ci_low_agwrk_ ci_high_agwrk_ year if stat == "mean", lcolor(black*0.5)) ///
               (connected coef_nonagwrk_ year if stat == "mean", lcolor(navy*0.5) lwidth(medthick) mcolor(navy*0.5) msymbol(circle) msize(medium)) ///
               (rcap ci_low_nonagwrk_ ci_high_nonagwrk_ year if stat == "mean", lcolor(black*0.5)) ///
               (scatter coef_wrk_ year if stat == "mean", mlabel(stars_wrk) mlabposition(2) mlabcolor(black) mlabsize(vsmall)) ///
               (scatter coef_agwrk_ year if stat == "mean", mlabel(stars_agwrk) mlabposition(2) mlabcolor(black) mlabsize(vsmall)) ///
               (scatter coef_nonagwrk_ year if stat == "mean", mlabel(stars_nonagwrk) mlabposition(2) mlabcolor(black) mlabsize(vsmall)), ///
               ytitle("Coefficient", size(medium)) xtitle("Year", size(medium)) ///
               legend(order(1 "Total" 3 "Agricultural" 5 "Non-agricultural") rows(1) size(small) region(lcolor(none))) ///
               title("Effect of Temperature on Worker Percentages", size(medium)) ///
               subtitle("Based on long differences regression", size(small)) ///
               note("Vertical bars represent 95% confidence intervals" "* p<0.1, ** p<0.05, *** p<0.01", size(vsmall)) ///
               xlabel(1971(10)2011, labsize(small)) ylabel(, angle(horizontal) labsize(small)) ///
               xscale(range(1970 2012)) yscale(range(. .)) ///
               graphregion(color(white)) plotregion(color(white)) ///
               ylabel(, grid) xlabel(, grid)

        // graph export "temperature_effects_plot.png", replace
