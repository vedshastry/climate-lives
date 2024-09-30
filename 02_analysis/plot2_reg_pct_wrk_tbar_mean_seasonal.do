*-------------------------------------------------------------------------------
* Regress census outcomes on climate vars at town level
*-------------------------------------------------------------------------------

    clear
    frames reset

    frame create    graph_data ///
                    str20 category str1 gender ///
                    float N_obs mean coef se p ll ul

        local sex t
        local cat alwrk

    qui foreach sex in t m f {
    foreach ssn in rabi khar {
    foreach mon in all sow hvt {

        est clear // Clear estimates
        nois di "Exporting: `sex'_`ssn'`mon'_mean"

        foreach cat in nonwrk wrk clwrk alwrk hhwrk otwrk {

            use "$a_input/00_prep_towns_climate.dta" , clear

            estread `sex'_`cat'_`ssn'`mon'_mean using "$a_output/estimates/`sex'_`cat'_`ssn'`mon'_mean" , id(pid)
            est replay `sex'_`cat'_`ssn'`mon'_mean

            * reg output
            local coef  : di r(table)[1,1] // Coefficient
            local se    : di r(table)[2,1] // S.E
            local p     : di r(table)[4,1] // P value
            local ll    : di r(table)[5,1] // P value
            local ul    : di r(table)[6,1] // P value

            * sample mean
            sum     pct_`sex'_`cat' if _est_`sex'_`cat'_`ssn'`mon'_mean == 1
            local   mean  = r(mean) // Mean of sample
            local   N_obs  = r(N) // N sampled

            * store frame
            frame post graph_data ("`cat'_`ssn'`mon'") ("`sex'") (`N_obs') (`mean') (`coef') (`se') (`p') (`ll') (`ul')
        }

    /* end months of season loop */
    }
    /* end season loop */
    }
    /* end sex loop */
    }

    frame change graph_data

*-------------------------------------------------------------------------------

    * Data is at coefficient level
    isid    category gender

    keep if gender == "t" // Total only
    keep if regexm(category,"all") // overall lonly

    * Clean up
    format  mean coef se p ll ul %12.4f

    * P values
    gen     sigstars = ""
    replace sigstars = "*" if p <= 0.1
    replace sigstars = "**" if p <= 0.05
    replace sigstars = "***" if p <= 0.01

    * Generate numeric versions of category and gender for graphing
    split   category , parse("_")
    rename  category1 cat
    rename  category2 season

    * Generate a categorical variable for ordering
    gen     cat_order = .
    replace cat_order = 0 if cat == "nonwrk"
    replace cat_order = 1 if cat == "wrk"
    replace cat_order = 2 if cat == "clwrk"
    replace cat_order = 3 if cat == "alwrk"
    replace cat_order = 4 if cat == "hhwrk"
    replace cat_order = 5 if cat == "otwrk"

    gen     ssn_order = .
    replace ssn_order = 1 if season == "kharall"
    replace ssn_order = 2 if season == "rabiall"

    * Generate a combined group variable
    egen group = group(cat_order ssn_order)

*-------------------------------------------------------------------------------

    * Parameters
    qui sum N_obs
    local N_obs = r(max)

    * Set graph scheme
    set scheme s2color
    cap graph drop _all

    * Create the comprehensive bar graph
    twoway ///
        (bar coef group if season == "kharall", barwidth(0.6) color(navy%70)) ///
        (bar coef group if season == "rabiall", barwidth(0.6) color(orange%70)) ///
        (rcap ul ll group, lcolor(gs4)) ///
        (scatter coef group, msymbol(none) mlabel(sigstars) mlabposition(3) mlabsize(vsmall) mlabcolor(gs4)) ///
            , ///
           title("Effects of a 1°C temperature increase", style(subheading)) ///
           legend(order(1 "Kharif" 2 "Rabi" ) rows(1) size(small)) ///
           graphregion(color(white)) plotregion(color(white)) ///
            ylabel(-0.03(0.01)0.03, angle(0) format(%9.2f)) ///
            yscale(range(-0.03 0.03)) ///
            ytitle("Percentage change in workers", size(medsmall)) ///
            xtitle("") ///
            xlabel( 1.5 "Nonworkers" 3.5 "Workers" ///
                   5.5 "Cultivators" 7.5 "Ag. Laborers" 9.5 "HH Industry" 11.5 "Other" ///
                , noticks labsize(small)) ///
            yline(0, lcolor(black) ) ///
            xline(4.5 , lcolor(maroon) ) ///
            xline(2.5 6.5 8.5 10.5 12.5 14.5, lcolor(gs12) ) ///
            note( ///
            "Source: Census of India - Primary Census Abstract [1961-2011]" ///
            "Kharif season: June - November. Rabi season: December - May" ///
            "N = `N_obs' town X decade observations" ///
            , size(small))

        * Save graph
        graph export "${tex_dir}/figures/reg_workers_tbar_mean_seasonal.png", as(png) replace

    /*
        (scatter coef group, msymbol(none) mlabel(coef) mlabposition(9) mlabsize(vsmall) mlabcolor(gs2)) ///
           note( ///
                "N = 18" ///
                , size(small)) ///
    */
