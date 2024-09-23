*-------------------------------------------------------------------------------
* Prep town level climate data
*-------------------------------------------------------------------------------

*--------------------------------
* Prepare monthly temperature
*--------------------------------

    import delimited "$b_input/imd/imd_1951_2023.csv" , clear // monthly data

    * collapse to yearly level
    collapse    (mean) *_mean ///
                (min) *_min ///
                (max) *_max ///
                , by(year month lat lon)

    * Create ID
    egen    id_xy = group(lat lon)
    order   id_xy

    isid    id_xy year month

    * Save
    compress
    save "$b_input/imd/05_prep_imd_vars_monthly.dta" , replace

*--------------------------------
* Prepare annual temperature
*--------------------------------

    use "$b_input/imd/05_prep_imd_vars_monthly.dta" , clear

    isid    id_xy year month

    * Calculate seasonal temperature and rain

    foreach type in mean min max {

        * 1. Kharif season
        bys id_xy year (month) :    egen tkharall_`type' = mean(tbar_`type') if inrange(month,6,11)
        bys id_xy year (month) :    egen pkharall_`type' = mean(rain_`type') if inrange(month,6,11)

        lab var tkharall_`type' "Temp. (C) Jun-Nov, kharif"
        lab var pkharall_`type' "Temp. (C) Jun-Nov, kharif"

            ** sowing
            bys id_xy year (month) :    egen tkharsow_`type' = mean(tbar_`type') if inrange(month,6,9)
            bys id_xy year (month) :    egen pkharsow_`type' = mean(rain_`type') if inrange(month,6,9)

            lab var tkharsow_`type' "Temp. (C) Jun-Sept, kharif sowing"
            lab var pkharsow_`type' "Temp. (C) Jun-Sept, kharif sowing"

            ** harvest
            bys id_xy year (month) :    egen tkharhvt_`type' = mean(tbar_`type') if inrange(month,10,11)
            bys id_xy year (month) :    egen pkharhvt_`type' = mean(rain_`type') if inrange(month,10,11)

            lab var tkharhvt_`type' "Temp. (C) Oct-Nov, kharif harvest"
            lab var pkharhvt_`type' "Temp. (C) Oct-Nov, kharif harvest"


        * 2. Rabi season
        bys id_xy year (month) :    egen trabiall_`type' = mean(tbar_`type') if month == 12 | inrange(month,1,5)
        bys id_xy year (month) :    egen prabiall_`type' = mean(rain_`type') if month == 12 | inrange(month,1,5)

        lab var trabiall_`type' "Temp. (C) Dec-May, rabi"
        lab var prabiall_`type' "Temp. (C) Dec-May, rabi"

            ** sowing
            bys id_xy year (month) :    egen trabisow_`type' = mean(tbar_`type') if month == 12 | inrange(month,1,3)
            bys id_xy year (month) :    egen prabisow_`type' = mean(rain_`type') if month == 12 | inrange(month,1,3)

            lab var trabisow_`type' "Temp. (C) Dec-Mar, rabi sowing"
            lab var prabisow_`type' "Temp. (C) Dec-Mar, rabi sowing"

            ** harvest
            bys id_xy year (month) :    egen trabihvt_`type' = mean(tbar_`type') if inrange(month,4,5)
            bys id_xy year (month) :    egen prabihvt_`type' = mean(rain_`type') if inrange(month,4,5)

            lab var trabihvt_`type' "Temp. (C) Apr-May, rabi harvest"
            lab var prabihvt_`type' "Temp. (C) Apr-May, rabi harvest"
    }

    * collapse to yearly level
    collapse    (mean) *_mean ///
                (min) *_min ///
                (max) *_max ///
                , by(id_xy year lat lon)

    isid    id_xy year

        * Format vars
        foreach var of varlist *_mean *_min *_max {
            replace `var' = round(`var',0.01)
        }
        format *_mean *_min *_max %9.1f

    * prepare temperature category
    bys id_xy (year) : egen tbar_classcalc = mean(tbar_mean)

    gen tempcat = .
    replace tempcat = 1 if inrange(tbar_classcalc,0,20)
    replace tempcat = 2 if inrange(tbar_classcalc,20,25)
    replace tempcat = 3 if inrange(tbar_classcalc,25,30)
    replace tempcat = 4 if inrange(tbar_classcalc,30,35)
    replace tempcat = 5 if inrange(tbar_classcalc,35,50)

    lab def tempcat 1 "0-20" 2 "20-25" 3 "25-30" 4 "30-35" 5 "35-50"
    lab val tempcat tempcat

    * Tag census decades

        gen census_dec = .
        replace census_dec = 1961 if inrange(year,1951,1960)
        replace census_dec = 1971 if inrange(year,1961,1970)
        replace census_dec = 1981 if inrange(year,1971,1980)
        replace census_dec = 1991 if inrange(year,1981,1990)
        replace census_dec = 2001 if inrange(year,1991,2000)
        replace census_dec = 2011 if inrange(year,2001,2011)

    * Collapse to decadal averages
    isid        id_xy year
    collapse    (mean) *_mean ///
                (min) *_min ///
                (max) *_max ///
                if !mi(census_dec) ///
                , by(id_xy lat lon census_dec)

        * bin temperatures
        foreach var of varlist t*_mean t*_min t*_max {

            gen     b20_`var' = (`var' >= 0 &  `var' < 20) & !mi(`var')
            gen     b25_`var' = (`var' >= 20 & `var' <  25) & !mi(`var')
            gen     b30_`var' = (`var' >= 25 & `var' <  30) & !mi(`var')
            gen     b35_`var' = (`var' >= 30 & `var' <  35) & !mi(`var')
            gen     b50_`var' = (`var' >= 35 ) & !mi(`var')

            lab var     b20_`var' "[0,20) `var'"
            lab var     b25_`var' "[20,25) `var'"
            lab var     b30_`var' "[25,30) `var'"
            lab var     b35_`var' "[30,35) `var'"
            lab var     b50_`var' "[35,50) `var'"
        }

        order b??_t* , after(census_dec)

    * Declare panel
    sort id_xy census_dec
    xtset id_xy census_dec

    * Save
    compress
    save "$b_input/imd/05_prep_imd_vars_decadal.dta" , replace
