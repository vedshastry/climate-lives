*************************************************************************************************************
*** Author: VS
*** Purpose: Regress town outcomes on climate data
*** Created: 2024/09/28
*** Modified:
********************************************************************************

*-------------------------------------------------------------------------------

* regression estimates

    * use analysis data
    // use "$a_input/00_prep_towns_climate.dta" , clear

        * keep towns that exist from a particular year
        // bys id_town (census_dec) : gen etag = (exist == 1 & census_dec == 1961)
        // bys id_town (census_dec) : egen ktag = max(etag)
        // keep if ktag == 1

    global      est_dir     "${a_output}/01_reghdfe/01_climate_towns"
    cap mkdir  "${est_dir}"

****************************************************************************
*** Reg workers by category
****************************************************************************

    * 0. Import analysis data
    use     "$a_input/00_prep_towns_climate.dta" , clear

        *   Clean observations

    * 1. Outcome variable: workers in each category, by gender aggregation and temperature statistic.
    local   outcome1 "log_`sex'_`yvar'"

    * 2. Fixed effects: Town, decade

    lab var tbar_mean "Decadal mean temp. (C)"
    lab var tbar_min " Decadal min temp. (C)"
    lab var tbar_max "Decadal max temp. (C)"
    lab var rain_mean "Decadal mean rain (mm)"

    local fe_vars id_town census_dec

    ***********************************
    *** Collect estimates
    ***********************************

    est clear // clear estimates

    ** iterate over:
    * worker categories
    qui {
    foreach sex in t m f {
    foreach stat in mean min max {

        nois di "* `sex'_`stat'"

    * iterate counter
    local   i = 0

    *-------------- Log population & pdensity
    foreach yvar in pop pdensity {

    local   yvarname "log_`sex'_`yvar'"
    local   ++i

    nois di "`i': `yvarname'"

            * Store reg
            eststo  `sex'_`stat'_`yvar' : ///
                    reghdfe `yvarname' c.tbar_`stat' c.rain_mean ///
                    , absorb(`fe_vars') vce(cluster id_town) nocons

                * Control mean
                sum     `yvarname' if e(sample)
                estadd  scalar Mean = r(mean)

            * Write estimates
            estwrite    `sex'_`stat'_`yvar' ///
                        using "${est_dir}/`sex'_`stat'_`yvar'" ///
                        , id(pid) replace reproducible

    /* end yvar loop */
    }

    *-------------- % of workers / town population
    foreach yvar in wrk {

    local   yvarname "pct_`sex'_`yvar'"
    local   ++i

    nois di "`i': `yvarname'"

            * Store reg
            eststo  `sex'_`stat'_`yvar' : ///
                    reghdfe `yvarname' c.tbar_`stat' c.rain_mean ///
                    , absorb(`fe_vars') vce(cluster id_town) nocons

                * Control mean
                sum     `yvarname' if e(sample)
                estadd  scalar Mean = r(mean)

            * Write estimates
            estwrite    `sex'_`stat'_`yvar' ///
                        using "${est_dir}/`sex'_`stat'_`yvar'" ///
                        , id(pid) replace reproducible

    /* end yvar loop */
    }

    *-------------- % of categories / workers
    * foreach yvar in nonagwrk agwrk {
    foreach yvar in nonagwrk agwrk clwrk alwrk marwrk {

    local   yvarname "shr_`sex'_`yvar'"
    local   ++i

    nois di "`i': `yvarname'"

            * Store reg
            eststo  `sex'_`stat'_`yvar' : ///
                    reghdfe `yvarname' c.tbar_`stat' c.rain_mean ///
                    , absorb(`fe_vars') vce(cluster id_town) nocons

                * Control mean
                // sum     `yvarname' if e(sample)
                sum     `yvarname'
                estadd  scalar Mean = r(mean)

            * Write estimates
            estwrite    `sex'_`stat'_`yvar' ///
                        using "${est_dir}/`sex'_`stat'_`yvar'" ///
                        , id(pid) replace reproducible

    /* end yvar loop */
    }

    ***********************************
    *** Export tables
    ***********************************

    * Table: total workers on mean temp.
    esttab `sex'_`stat'_* using "${tex_dir}/tables/01_climate_towns_`sex'_`stat'_main.tex", ///
        mtitles("Log pop." "Log pdensity" "Pct. Workers" "Non-Ag." "Ag." "Cultivators" "Laborers" "Seasonal") ///
        b(%9.3f) se(%9.3f) star label booktabs replace ///
        stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
        starlevels(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. Fixed effects include towns and census decades.")

    /* end stat loop */
    }
    /* end sex loop */
    }
    /* end quietly */
    }

*-------------------------------------------------------------------------------
* mtitles("Nonworkers" "Workers" "Ag." "Non-Ag." "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
* mtitles("Nonworkers" "Workers" "Ag." "Non-Ag.") ///
