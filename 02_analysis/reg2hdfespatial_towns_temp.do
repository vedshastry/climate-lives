*-------------------------------------------------------------------------------
* reg ag outcomes on temperature at town level
*-------------------------------------------------------------------------------

* regression estimates

    * use analysis data
    // use "$a_clean/00_prep_towns_temperature.dta" , clear

        // local   fe_vars "styear"
        local   fe_vars ""

    *---------------------------------------------------------------------------
    * 0. Reg workers by category
    *---------------------------------------------------------------------------

    use "$a_clean/00_prep_towns_temperature.dta" , clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var tbar_min " Decadal min temp. (C)"
        lab var tbar_max "Decadal max temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"

        egen    styear = group(stcode census_dec)
        lab var styear "Stateyear FE"

        est clear

            foreach yvar in wrk clwrk alwrk hhwrk otwrk {

                qui foreach stat in mean min max {

                nois di "Calculating set: `yvar' - `stat'"

                    * total
                    eststo  t`yvar'_`stat' :    reg2hdfespatial pct_t_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(100) lagcutoff(3)


                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)


                    * male
                    eststo  m`yvar'_`stat' :    reg2hdfespatial pct_m_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(100) lagcutoff(3)

                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)

                    * female
                    eststo  f`yvar'_`stat' :    reg2hdfespatial pct_f_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(100) lagcutoff(3)

                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)



                }

            }

            * Table: total workers on mean temp.
            esttab t*_mean using "${tex_dir}/tables/reg_t_workers_category_temperature_mean.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: male workers on mean temp.
            esttab m*_mean using "${tex_dir}/tables/reg_m_workers_category_temperature_mean.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: female workers on mean temp.
            esttab f*_mean using "${tex_dir}/tables/reg_f_workers_category_temperature_mean.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: total workers on min temp.
            esttab t*_min using "${tex_dir}/tables/reg_t_workers_category_temperature_min.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: male workers on min temp.
            esttab m*_min using "${tex_dir}/tables/reg_m_workers_category_temperature_min.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: female workers on min temp.
            esttab f*_min using "${tex_dir}/tables/reg_f_workers_category_temperature_min.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: total workers on max temp.
            esttab t*_max using "${tex_dir}/tables/reg_t_workers_category_temperature_max.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: male workers on max temp.
            esttab m*_max using "${tex_dir}/tables/reg_m_workers_category_temperature_max.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")

            * Table: female workers on max temp.
            esttab f*_max using "${tex_dir}/tables/reg_f_workers_category_temperature_max.tex", ///
                mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
                b(%9.3f) se(%9.3f) star label booktabs replace ///
                stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
                starlevels(* 0.10 ** 0.05 *** 0.01) ///
                note("Standard errors in parentheses.")


    *---------------------------------------------------------------------------
    * 1. Reg employment on temperature (ag and non ag)
    *---------------------------------------------------------------------------

    use "$a_clean/00_prep_towns_temperature.dta" , clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var tbar_min " Decadal min temp. (C)"
        lab var tbar_max "Decadal max temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"

        est clear

            foreach yvar in wrk agwrk nonagwrk {


                qui foreach stat in mean min max {

                nois di "Calculating set: `yvar' - `stat'"

                    * total
                    eststo  t`yvar'_`stat' :    reg2hdfespatial pct_t_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(100) lagcutoff(3)


                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)


                    * male
                    eststo  m`yvar'_`stat' :    reg2hdfespatial pct_m_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(100) lagcutoff(3)

                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)

                    * female
                    eststo  f`yvar'_`stat' :    reg2hdfespatial pct_f_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(100) lagcutoff(3)

                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)
                }

            }

        * Table: total workers on mean temp.
        esttab t*_mean using "${tex_dir}/tables/reg_t_workers_agnonag_temperature_mean.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers on min temp.
        esttab t*_min using "${tex_dir}/tables/reg_t_workers_agnonag_temperature_min.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers on max temp.
        esttab t*_max using "${tex_dir}/tables/reg_t_workers_agnonag_temperature_max.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: male workers on mean temp.
        esttab m*_mean using "${tex_dir}/tables/reg_m_workers_agnonag_temperature_mean.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: male workers on min temp.
        esttab m*_min using "${tex_dir}/tables/reg_m_workers_agnonag_temperature_min.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: male workers on max temp.
        esttab m*_max using "${tex_dir}/tables/reg_m_workers_agnonag_temperature_max.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: female workers on mean temp.
        esttab f*_mean using "${tex_dir}/tables/reg_f_workers_agnonag_temperature_mean.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: female workers on min temp.
        esttab f*_min using "${tex_dir}/tables/reg_f_workers_agnonag_temperature_min.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: female workers on max temp.
        esttab f*_max using "${tex_dir}/tables/reg_f_workers_agnonag_temperature_max.tex", ///
            mtitles("Overall" "Agriculture" "Non agriculture") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

    *---------------------------------------------------------------------------
    * . Reg employment on seasonal temperature
    *---------------------------------------------------------------------------

    use "$a_clean/00_prep_towns_temperature.dta" , clear

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

        est clear

        foreach yvar in wrk clwrk alwrk hhwrk otwrk {

                nois di "Calculating set: `yvar'"

                qui foreach stat in all sow hvt {

                    * total (kharif)
                    eststo  k`yvar'_`stat' :    reg2hdfespatial pct_t_`yvar' c.tkhar`stat'_mean c.pkhar`stat'_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(250) lagcutoff(3)


                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)

                    * total (rabi)
                    eststo  r`yvar'_`stat' :    reg2hdfespatial pct_t_`yvar' c.trabi`stat'_mean c.prabi`stat'_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(250) lagcutoff(3)


                        qui sum pct_t_`yvar'
                        estadd scalar Mean = r(mean)

                }

            }

        * Table: total workers  (kharif)
        esttab k*_all using "${tex_dir}/tables/reg_t_workers_category_kharif_all.tex", ///
            mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers (kharif sowing)
        esttab k*_sow using "${tex_dir}/tables/reg_t_workers_category_kharif_sow.tex", ///
            mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers  (kharif harvest)
        esttab k*_hvt using "${tex_dir}/tables/reg_t_workers_category_kharif_harvest.tex", ///
            mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers (rabi)
        esttab r*_all using "${tex_dir}/tables/reg_t_workers_category_rabi_all.tex", ///
            mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers (rabi sowing)
        esttab r*_sow using "${tex_dir}/tables/reg_t_workers_category_rabi_sow.tex", ///
            mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total workers on (rabi harvest)
        esttab r*_hvt using "${tex_dir}/tables/reg_t_workers_category_rabi_harvest.tex", ///
            mtitles("Total" "Cultivators" "Ag. Labourers" "HH Industry" "Other") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

    *---------------------------------------------------------------------------
    * 2. Reg demographics on temperature
    *---------------------------------------------------------------------------

    use "$a_clean/00_prep_towns_temperature.dta" , clear

        est clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var tbar_min " Decadal min temp. (C)"
        lab var tbar_max "Decadal max temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"

        foreach yvar in sc st lit {

            foreach stat in mean min max {

                    * total
                    eststo  t`yvar'_`stat' :    reg2hdfespatial pct_t_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(250) lagcutoff(3)


                        qui sum `yvar'
                        estadd scalar Mean = r(mean)


                    * male
                    eststo  m`yvar'_`stat' :    reg2hdfespatial pct_m_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(250) lagcutoff(3)

                        qui sum `yvar'
                        estadd scalar Mean = r(mean)

                    * female
                    eststo  f`yvar'_`stat' :    reg2hdfespatial pct_f_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(250) lagcutoff(3)

                        qui sum `yvar'
                        estadd scalar Mean = r(mean)
            }

        }

        * Table: total demographics on mean temp.
        esttab t*_mean using "${tex_dir}/tables/reg_t_demographics_temperature_mean.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total demographics on min temp.
        esttab t*_min using "${tex_dir}/tables/reg_t_demographics_temperature_min.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total demographics on max temp.
        esttab t*_max using "${tex_dir}/tables/reg_t_demographics_temperature_max.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: male demographics on mean temp.
        esttab m*_mean using "${tex_dir}/tables/reg_m_demographics_temperature_mean.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: male demographics on min temp.
        esttab m*_min using "${tex_dir}/tables/reg_m_demographics_temperature_min.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: male demographics on max temp.
        esttab m*_max using "${tex_dir}/tables/reg_m_demographics_temperature_max.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: female demographics on mean temp.
        esttab f*_mean using "${tex_dir}/tables/reg_f_demographics_temperature_mean.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: female demographics on min temp.
        esttab f*_min using "${tex_dir}/tables/reg_f_demographics_temperature_min.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: female demographics on max temp.
        esttab f*_max using "${tex_dir}/tables/reg_f_demographics_temperature_max.tex", ///
            mtitles("Log population" "Log population (M)" "Log population (F)" "Log pdensity") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

*---------------------------------------------------------------------------
/*
    *---------------------------------------------------------------------------
    * 3. Reg population on temperature
    *---------------------------------------------------------------------------

    use "$a_clean/00_prep_towns_temperature.dta" , clear

    est clear

        lab var tbar_mean "Decadal mean temp. (C)"
        lab var tbar_min " Decadal min temp. (C)"
        lab var tbar_max "Decadal max temp. (C)"
        lab var rain_mean "Decadal mean rain (mm)"

        foreach yvar in log_t_pop pdensity log_pdensity pct_t_wrk {

            foreach stat in mean min max {

                    * total
                    eststo  t`yvar'_`stat' :    reg2hdfespatial `yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , timevar(census_dec) panelvar(id_town) ///
                                        lat(y) lon(x) distcutoff(250) lagcutoff(3)


                        qui sum `yvar'
                        estadd scalar Mean = r(mean)


            }

        }

        * Table: total demographics on mean temp.
        esttab t*_mean using "${tex_dir}/tables/reg_t_population_temperature_mean.tex", ///
            mtitles("Log population" "Pop. density (sq. km)" "Log pop. density" "\% workers") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total population on min temp.
        esttab t*_min using "${tex_dir}/tables/reg_t_population_temperature_min.tex", ///
            mtitles("Log population" "Pop. density (sq. km)" "Log pop. density" "\% workers") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")

        * Table: total population on max temp.
        esttab t*_max using "${tex_dir}/tables/reg_t_population_temperature_max.tex", ///
            mtitles("Log population" "Pop. density (sq. km)" "Log pop. density" "\% workers") ///
            b(%9.3f) se(%9.3f) star label booktabs replace ///
            stats(Mean N, fmt(%9.3f %9.0g) labels("Mean" "N")) ///
            starlevels(* 0.10 ** 0.05 *** 0.01) ///
            note("Standard errors in parentheses.")


*/
                    /*

                    ** Commented out for reg2hdfespatial

                    * total workers on temp
                    eststo  t`yvar'_`stat' :   reghdfe pct_t_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , absorb(id_town census_dec stcode dtcode) vce(cluster id_town) nocons

                    * male workers on temp
                    eststo  m`yvar'_`stat' :   reghdfe pct_m_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , absorb(id_town census_dec stcode dtcode) vce(cluster id_town) nocons

                        qui sum `e(depvar)' if e(sample)
                        estadd scalar Mean = r(mean)

                    * female workers on temp
                    eststo  f`yvar'_`stat' :   reghdfe pct_f_`yvar' c.tbar_`stat' c.rain_mean `fe_vars' ///
                                        , absorb(id_town census_dec stcode dtcode) vce(cluster id_town) nocons

                        qui sum `e(depvar)' if e(sample)
                        estadd scalar Mean = r(mean)

                    */
