*-------------------------------------------------------------------------------
* Prep town level climate data
*-------------------------------------------------------------------------------

*--------------------------------
* Define aggregation program
*--------------------------------

// cap prog drop imd_agg
// prog imd_agg
//
//     * Collapse
//
// end

    clear
    tempfile imd
    save `imd' , replace emptyok

    qui forval year = 1951/2023 {

        nois di "Year = `year'"
        import delimited "$b_input/imd/daily/`year'.csv" , clear

        * append and save
        append using `imd'
        save         `imd' , replace
    }

*--------------------------------
* Use appended data
*--------------------------------

    use         `imd' , clear

    * Sanity check
    isid    year month day lat lon

        * Create lat/lon ID
        egen    id_xy = group(lat lon)
        order   id_xy

        * Create datetime variable
        gen int date = mdy(month, day, year)
        format  date %td

    * Sanity check
    order   id_xy date
    isid    id_xy date
    xtset   id_xy date

    * Save
    compress
    save "$b_input/imd/03_prep_imd_data_daily.dta" , replace


*--------------------------------
* Prepare annual temperature
*--------------------------------

    // use "$b_input/imd/05_prep_imd_vars_monthly.dta" , clear
    // isid    id_xy year month

    use "$b_input/imd/03_prep_imd_data_daily.dta" , clear

    * Sanity check
    gsort    id_xy date
    gisid    id_xy date

    * Tag census decades
    gen         census_dec = .
    replace     census_dec = 1961 if inrange(year,1951,1960)
    replace     census_dec = 1971 if inrange(year,1961,1970)
    replace     census_dec = 1981 if inrange(year,1971,1980)
    replace     census_dec = 1991 if inrange(year,1981,1990)
    replace     census_dec = 2001 if inrange(year,1991,2000)
    replace     census_dec = 2011 if inrange(year,2001,2011)

    keep if     !mi(census_dec) // keep tagged years only


    * Aggregation definition from LST
        /*
            We construct measures of average temperature and precipitation
            during the main agricultural growing season months (June through
            February) as these have the greatest impacts on agriculture.
        */

        bys id_xy year (month) : egen tlst = mean(tbar) if inrange(month,1,2) | inrange(month,6,12)
        bys id_xy year (month) : egen plst = mean(rain) if inrange(month,1,2) | inrange(month,6,12)

    * Calculate seasonal temperature and rain

        * 1. Kharif season
        bys id_xy census_dec (month) :    egen tkharall = mean(tbar) if inrange(month,6,11)
        bys id_xy census_dec (month) :    egen pkharall = mean(rain) if inrange(month,6,11)

        lab var tkharall "Temp. (C) Jun-Nov, kharif"
        lab var pkharall "Temp. (C) Jun-Nov, kharif"

            ** sowing
            bys id_xy census_dec (month) :    egen tkharsow = mean(tbar) if inrange(month,6,9)
            bys id_xy census_dec (month) :    egen pkharsow = mean(rain) if inrange(month,6,9)

            lab var tkharsow "Temp. (C) Jun-Sept, kharif sowing"
            lab var pkharsow "Temp. (C) Jun-Sept, kharif sowing"

            ** harvest
            bys id_xy census_dec (month) :    egen tkharhvt = mean(tbar) if inrange(month,10,11)
            bys id_xy census_dec (month) :    egen pkharhvt = mean(rain) if inrange(month,10,11)

            lab var tkharhvt "Temp. (C) Oct-Nov, kharif harvest"
            lab var pkharhvt "Temp. (C) Oct-Nov, kharif harvest"


        * 2. Rabi season
        bys id_xy census_dec (month) :    egen trabiall = mean(tbar) if month == 12 | inrange(month,1,5)
        bys id_xy census_dec (month) :    egen prabiall = mean(rain) if month == 12 | inrange(month,1,5)

        lab var trabiall "Temp. (C) Dec-May, rabi"
        lab var prabiall "Temp. (C) Dec-May, rabi"

            ** sowing
            bys id_xy census_dec (month) :    egen trabisow = mean(tbar) if month == 12 | inrange(month,1,3)
            bys id_xy census_dec (month) :    egen prabisow = mean(rain) if month == 12 | inrange(month,1,3)

            lab var trabisow "Temp. (C) Dec-Mar, rabi sowing"
            lab var prabisow "Temp. (C) Dec-Mar, rabi sowing"

            ** harvest
            bys id_xy census_dec (month) :    egen trabihvt = mean(tbar) if inrange(month,4,5)
            bys id_xy census_dec (month) :    egen prabihvt = mean(rain) if inrange(month,4,5)

            lab var trabihvt "Temp. (C) Apr-May, rabi harvest"
            lab var prabihvt "Temp. (C) Apr-May, rabi harvest"

    * Aggregate to decade level
        collapse ///
                (mean) rain_mean = rain ///
                (mean) tbar_mean = tbar ///
                (mean) tmin_mean = tmin ///
                (mean) tmax_mean = tmax ///
                (min) rain_min = rain ///
                (min) tbar_min = tbar ///
                (min) tmin_min = tmin ///
                (min) tmax_min = tmax ///
                (max) rain_max = rain ///
                (max) tbar_max = tbar ///
                (max) tmin_max = tmin ///
                (max) tmax_max = tmax ///
                (mean) tkharall_mean = tkharall ///
                (mean) trabiall_mean = trabiall ///
                (mean) pkharall_mean = pkharall ///
                (mean) prabiall_mean = prabiall ///
                (mean) tkharsow_mean = tkharsow ///
                (mean) trabisow_mean = trabisow ///
                (mean) pkharsow_mean = pkharsow ///
                (mean) prabisow_mean = prabisow ///
                (mean) tkharhvt_mean = tkharhvt ///
                (mean) trabihvt_mean = trabihvt ///
                (mean) pkharhvt_mean = pkharhvt ///
                (mean) prabihvt_mean = prabihvt ///
                (min) tkharall_min = tkharall ///
                (min) trabiall_min = trabiall ///
                (min) pkharall_min = pkharall ///
                (min) prabiall_min = prabiall ///
                (min) tkharsow_min = tkharsow ///
                (min) trabisow_min = trabisow ///
                (min) pkharsow_min = pkharsow ///
                (min) prabisow_min = prabisow ///
                (min) tkharhvt_min = tkharhvt ///
                (min) trabihvt_min = trabihvt ///
                (min) pkharhvt_min = pkharhvt ///
                (min) prabihvt_min = prabihvt ///
                (max) tkharall_max = tkharall ///
                (max) trabiall_max = trabiall ///
                (max) pkharall_max = pkharall ///
                (max) prabiall_max = prabiall ///
                (max) tkharsow_max = tkharsow ///
                (max) trabisow_max = trabisow ///
                (max) pkharsow_max = pkharsow ///
                (max) prabisow_max = prabisow ///
                (max) tkharhvt_max = tkharhvt ///
                (max) trabihvt_max = trabihvt ///
                (max) pkharhvt_max = pkharhvt ///
                (max) prabihvt_max = prabihvt ///
                (mean) tlst_mean = tlst ///
                (min) tlst_min = tlst ///
                (max) tlst_max = tlst ///
                (mean) plst_mean = plst ///
                (min) plst_min = plst ///
                (max) plst_max = plst ///
                , by(id_xy lat lon census_dec)


    * Sanity check
    isid    id_xy census_dec
    xtset   id_xy census_dec

    bys     id_xy : egen n_years = count(census_dec)

        * Format vars
        foreach var of varlist *_mean *_min *_max {
            replace `var' = round(`var',0.01)
        }
        format *_mean *_min *_max %9.1f

    * Declare panel
    sort id_xy census_dec
    xtset id_xy census_dec

    * Save
    compress
    save "$b_input/imd/05_prep_imd_vars_decadal.dta" , replace
    
/*
        keep    year month day lat lon *_mean
        rename  *_mean *

        collapse ///
                (mean) rain_mean = rain ///
                (mean) tbar_mean = tbar ///
                (mean) tmin_mean = tmin ///
                (mean) tmax_mean = tmax ///
                (min) rain_min = rain ///
                (min) tbar_min = tbar ///
                (min) tmin_min = tmin ///
                (min) tmax_min = tmax ///
                (max) rain_max = rain ///
                (max) tbar_max = tbar ///
                (max) tmin_max = tmin ///
                (max) tmax_max = tmax ///
                , by(year month lat lon)

*--------------------------------
* Prepare monthly temperature
*--------------------------------
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

    */
