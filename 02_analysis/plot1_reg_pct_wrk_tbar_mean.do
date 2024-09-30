*-------------------------------------------------------------------------------
* Regress census outcomes on climate vars at town level
*-------------------------------------------------------------------------------

    clear
    frames reset

    frame create    graph_data ///
                    str20 category str1 gender ///
                    float N_obs mean coef se p ll ul

        // local sex t
        // local cat alwrk

    * Populate the frame with coefficients and means
    qui foreach sex in t m f {
    foreach cat in pop pdensity wrk agwrk nonagwrk {

        use "$a_input/00_prep_towns_climate.dta" , clear

        est clear

        estread     "$a_output/estimates/`sex'_`cat'_mean" , id(pid)
        est replay  `sex'_`cat'_mean

        * reg output
        local coef  : di r(table)[1,1] // Coefficient
        local se    : di r(table)[2,1] // S.E
        local p     : di r(table)[4,1] // P value
        local ll    : di r(table)[5,1] // P value
        local ul    : di r(table)[6,1] // P value

        * sample mean
        cap sum     log_`sex'_`cat' if _est_`sex'_`cat'_mean == 1
        cap sum     pct_`sex'_`cat' if _est_`sex'_`cat'_mean == 1
        cap sum     shr_`sex'_`cat' if _est_`sex'_`cat'_mean == 1
        local   mean  = r(mean) // Mean of sample
        local   N_obs  = r(N) // N sampled

        * store frame
        frame post graph_data ("`cat'") ("`sex'") (`N_obs') (`mean') (`coef') (`se') (`p') (`ll') (`ul')
    }
    }

    frame change graph_data

*-------------------------------------------------------------------------------

    * Data is at coefficient level
    isid    category gender

    * Clean up
    format  N_obs mean coef se p ll ul %12.4f

    * P values
    gen     sigstars = ""
    replace sigstars = "*" if p <= 0.1
    replace sigstars = "**" if p <= 0.05
    replace sigstars = "***" if p <= 0.01

    * Generate numeric versions of category and gender for graphing
    encode  category , gen(cat_code)
    encode  gender   , gen(gender_code)

    * Generate a categorical variable for ordering
    gen     cat_order = .
    replace cat_order = 0 if category == "pop"
    replace cat_order = 1 if category == "pdensity"
    replace cat_order = 2 if category == "wrk"
    replace cat_order = 3 if category == "agwrk"
    replace cat_order = 4 if category == "nonagwrk"

    gen     gen_order = .
    replace gen_order = 1 if gender == "t"
    replace gen_order = 2 if gender == "m"
    replace gen_order = 3 if gender == "f"

    * Generate a combined group variable
    egen group = group(cat_order gen_order)

*-------------------------------------------------------------------------------

    * Parameters
    qui sum N_obs
    local N_obs = r(max)

    * Set graph scheme
    set scheme s2color
    cap graph drop _all

    * Create the comprehensive bar graph
    twoway ///
        (bar coef group if gender == "t", barwidth(0.6) color(forest_green%70)) ///
        (bar coef group if gender == "m", barwidth(0.6) color(midblue%70)) ///
        (bar coef group if gender == "f", barwidth(0.6) color(cranberry%70)) ///
        (rcap ul ll group, lcolor(gs4)) ///
        (scatter coef group, msymbol(none) mlabel(sigstars) mlabposition(3) mlabsize(vsmall) mlabcolor(gs4)) ///
            , ///
           legend(order(1 "Total" 2 "Male" 3 "Female") rows(1) size(small)) ///
           graphregion(color(white)) plotregion(color(white)) ///
            ylabel(-0.1(0.05)0.1, angle(0) format(%9.2f)) ///
            title("Effects of a 1°C temperature increase", style(subheading)) ///
            ytitle("Percentage change in workers", size(medsmall)) ///
            xtitle("") ///
            xlabel( 2 "Log Population" 5 "Log Density" ///
                   8 "% Workers" 11 "Ag. share" 14 "Non ag. share" ///
                , noticks labsize(small)) ///
            yline(0, lcolor(black) ) ///
            xline(6.5, lcolor(maroon) ) ///
            xline(3.5 9.5 12.5 15.5, lcolor(gs12) ) ///
            note( ///
            "Source: Census of India - Primary Census Abstract [1961-2011]" ///
            "N = `N_obs' town X decade observations" ///
            , size(small))

    graph export "${tex_dir}/figures/reg_workers_tbar_mean.png", as(png) replace

    /*
            yscale(range(-0.03 0.03)) ///
        (scatter coef group, msymbol(none) mlabel(coef) mlabposition(9) mlabsize(vsmall) mlabcolor(gs2)) ///
           note( ///
                "N = 18" ///
                , size(small)) ///
    */


/*
    clear
    frames reset

    frame create    graph_data ///
                    str20 category str1 gender ///
                    float N_obs mean coef se p ll ul

        local sex t
        local cat alwrk

    * Populate the frame with coefficients and means
    qui foreach sex in t m f {
    foreach cat in nonwrk wrk clwrk alwrk hhwrk otwrk {

        use "$a_input/00_prep_towns_climate.dta" , clear

        est clear

        estread     "$a_output/estimates/`sex'_`cat'_mean" , id(pid)
        est replay  `sex'_`cat'_mean

        * reg output
        local coef  : di r(table)[1,1] // Coefficient
        local se    : di r(table)[2,1] // S.E
        local p     : di r(table)[4,1] // P value
        local ll    : di r(table)[5,1] // P value
        local ul    : di r(table)[6,1] // P value

        * sample mean
        sum     pct_`sex'_`cat' if _est_`sex'_`cat'_mean == 1
        local   mean  = r(mean) // Mean of sample
        local   N_obs  = r(N) // N sampled

        * store frame
        frame post graph_data ("`cat'") ("`sex'") (`N_obs') (`mean') (`coef') (`se') (`p') (`ll') (`ul')
    }
    }

    frame change graph_data

*-------------------------------------------------------------------------------

    * Data is at coefficient level
    isid    category gender

    * Clean up
    format  N_obs mean coef se p ll ul %12.4f

    * P values
    gen     sigstars = ""
    replace sigstars = "*" if p <= 0.1
    replace sigstars = "**" if p <= 0.05
    replace sigstars = "***" if p <= 0.01

    * Generate numeric versions of category and gender for graphing
    encode  category , gen(cat_code)
    encode  gender   , gen(gender_code)

    * Generate a categorical variable for ordering
    gen     cat_order = .
    replace cat_order = 0 if category == "nonwrk"
    replace cat_order = 1 if category == "wrk"
    replace cat_order = 2 if category == "clwrk"
    replace cat_order = 3 if category == "alwrk"
    replace cat_order = 4 if category == "hhwrk"
    replace cat_order = 5 if category == "otwrk"

    gen     gen_order = .
    replace gen_order = 1 if gender == "t"
    replace gen_order = 2 if gender == "m"
    replace gen_order = 3 if gender == "f"

    * Generate a combined group variable
    egen group = group(cat_order gen_order)

*-------------------------------------------------------------------------------

    * Parameters
    qui sum N_obs
    local N_obs = r(max)

    * Set graph scheme
    set scheme s2color
    cap graph drop _all

    * Create the comprehensive bar graph
    twoway ///
        (bar coef group if gender == "t", barwidth(0.6) color(forest_green%70)) ///
        (bar coef group if gender == "m", barwidth(0.6) color(midblue%70)) ///
        (bar coef group if gender == "f", barwidth(0.6) color(cranberry%70)) ///
        (rcap ul ll group, lcolor(gs4)) ///
        (scatter coef group, msymbol(none) mlabel(sigstars) mlabposition(3) mlabsize(vsmall) mlabcolor(gs4)) ///
            , ///
           legend(order(1 "Total" 2 "Male" 3 "Female") rows(1) size(small)) ///
           graphregion(color(white)) plotregion(color(white)) ///
            ylabel(-0.03(0.01)0.03, angle(0) format(%9.2f)) ///
            yscale(range(-0.03 0.03)) ///
            title("Effects of a 1°C temperature increase", style(subheading)) ///
            ytitle("Percentage change in workers", size(medsmall)) ///
            xtitle("") ///
            xlabel( 2 "Nonworkers" 5 "Workers" ///
                   8 "Cultivators" 11 "Ag. Laborers" 14 "HH Industry" 17 "Other" ///
                , noticks labsize(small)) ///
            yline(0, lcolor(black) ) ///
            xline(6.5, lcolor(maroon) ) ///
            xline(3.5 9.5 12.5 15.5 18.5, lcolor(gs12) ) ///
            note( ///
            "Source: Census of India - Primary Census Abstract [1961-2011]" ///
            "N = `N_obs' town X decade observations" ///
            , size(small))

    graph export "${tex_dir}/figures/reg_workers_tbar_mean.png", as(png) replace

    /*
        (scatter coef group, msymbol(none) mlabel(coef) mlabposition(9) mlabsize(vsmall) mlabcolor(gs2)) ///
           note( ///
                "N = 18" ///
                , size(small)) ///
    */
*/
