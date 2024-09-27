*-------------------------------------------------------------------------------
* Match census towns to IMD grid points
*-------------------------------------------------------------------------------
*--------------------------------
* 1. import imd-town mapping
*--------------------------------

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


*--------------------------------
* Prepare lat/lon list
*--------------------------------

    import delimited "$b_input/imd/all_years_combined.csv" , clear

    * 1. prepare lat/lon level observations
    keep lat lon
    duplicates drop

    sort lat lon
    isid lat lon

    egen id_xy = group(lat lon)
    order id_xy
    isid id_xy

    compress
    cap mkdir "$b_output/imd"
    save "$b_temp/imd/imd_latlon_level.dta" , replace

*--------------------------------
* 2. Import census towns panel
*--------------------------------

    // use "$dchb/output/dchb_town/townpanel_clean.dta" , clear
    use "$dchb/output/dchb_town/townpanel_long_1961_2011.dta" , clear

    drop if mi(x)

    * get nearest gridpoint
    destring panel_id , gen(id_town)
    geonear id_town y x using "$b_temp/imd/imd_latlon_level.dta" , n(id_xy lat lon)

    * rename
    rename nid id_xy
    rename km_to_nid km_to_grid

    ** Merge with coordinates
        merge m:1 id_xy using "$b_temp/imd/imd_latlon_level.dta" , keepusing(lat lon)
        keep if _merge == 3 // keep only merged towns
        /*
            Result                      Number of obs
            -----------------------------------------
            Not matched                           226
                from master                         0  (_merge==1)
                from using                         91  (_merge==2)

            Matched                             8,794  (_merge==3)
            -----------------------------------------
        */

        isid id_town year
        xtset id_town year

    * sanity check
    order id_xy lat lon , after(id_town)

    compress
    save "$b_output/imd/04_match_imd_town.dta" , replace
