*-------------------------------------------------------------------------------
* Prepare IMD variables for analysis
*-------------------------------------------------------------------------------

*--------------------------------
* 1. import imd temperature data
*--------------------------------

    import delimited "$b_input/imd/all_years_combined.csv" , clear

    * create temp bins
    foreach temp in tbar tmin tmax {
        gen `temp'_bin = .
        replace `temp'_bin = 1 if inrange(`temp'_mean,0,20)
        replace `temp'_bin = 2 if inrange(`temp'_mean,20,25)
        replace `temp'_bin = 3 if inrange(`temp'_mean,25,30)
        replace `temp'_bin = 4 if inrange(`temp'_mean,30,35)
        replace `temp'_bin = 5 if inrange(`temp'_mean,30,50)
    }

    lab def bin 1 "0-20" 2 "20-25" 3 "25-30" 4 "30-35" 5 "35-50"
    lab val *_bin bin

    * count no. of days per bin
    forval bin = 1/5 {
    foreach temp in tbar tmin tmax {
        egen `temp'_
    }


    keep year month lat lon *_mean *_bin

    import delimited "$b_temp/town_imdgrid_mapping.csv" , clear stringcols(1)

    * clean up
    count // 8050 obs
    rename  * , lower
    /*
    some code_2011 can be duplicated because of town size
    duplicates tag    code_2011 , gen(tag)
        tag |      Freq.     Percent        Cum.
        ------------+-----------------------------------
          0 |      7,987       99.22       99.22
          1 |         38        0.47       99.69
          2 |         15        0.19       99.88
          3 |          4        0.05       99.93
          5 |          6        0.07      100.00
        ------------+-----------------------------------
        Total |      8,050      100.00
    */

    duplicates drop    code_2011 , force

    * Sanity check
    isid    code_2011

    tempfile imd_town
    save `imd_town' , replace

// * Merge quarterly headline cpi
//     merge   m:1 qrtyr using "$b_input/headline_cpi_qrtyr" , assert(2 3) keep(3) nogen keepusing(hcpi)
//
// * Calculating real wages
//     foreach var of varlist  wage_* {
//
//         * Separate nominal/real wages
//         rename  `var'       nom`var'
//         gen     real`var'   = nom`var' * (hcpi / 100)
//
//         * Assign label
//         local label : var label nom`var'
//         lab var     real`var' "`label', 2015 adj."
//     }
//
// * Winsorize wages at 99th pct within center
// winsor2 *wage*  , replace cuts(0 99) by(id_center)
//
//     * Rearrange/sort
//
//     order   realwage* nomwage* , before(qrtyr)
//     sort    id_center monyr
//
//     * sanity check
//     xtset   id_center monyr
//     isid    id_center monyr
//
// * Save
//     save "$b_output/agriwage_types.dta" , replace
