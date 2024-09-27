*-------------------------------------------------------------------------------
* Match IMD grid points with Census towns
*-------------------------------------------------------------------------------

*--------------------------------
* Prepare lat/lon list
*--------------------------------

    // import delimited "$b_input/imd/imd_1951_2023_annual.csv" , clear
    // use "$b_input/imd/03_prep_imd_data_daily.dta" , clear
    use "$b_input/imd/04_build_imd_decadal.dta" , clear

    * 1. prepare lat/lon level observations
    keep        id_xy lat lon
    duplicates  drop

    isid        id_xy

    compress
    cap mkdir "$b_output/imd"
    save "$b_input/imd/imd_latlon_level.dta" , replace

*--------------------------------
* Build mapping between town pca and gridpoints within 100 km
*--------------------------------

    use "$b_output/dchb_town/03_clean_towns_wide.dta" , clear

    * sanity check
    drop    if mi(x)
    keep    id_town y x
    isid    id_town

    * form dchb_town/grid pairs
    cross using "$b_input/imd/imd_latlon_level.dta"

        * Calculate distance
        geodist     y x lat lon , gen(km_to_grid)
        keep if     km_to_grid <= 100 // keep bilateral distance within 100km

        * inverse =  1/squared distance
        gen     inv_km_to_grid = 1 / (km_to_grid^2)

        * total of all inverse distances for a town
        bys     id_town (id_xy) : egen inv_wt_total = sum(inv_km_to_grid)

        * final weight/proportion to multiply with
        gen     imd_weight = inv_km_to_grid / inv_wt_total

    * CLean up
    drop        x y
    lab var     km_to_grid "Km. town distance to gridpoint"
    lab var     inv_km_to_grid "1/km distance^2"
    lab var     inv_wt_total "total of inverse distances at town level"
    lab var     imd_weight "town weight to assign to imd gridpoint"

    * sanity check
    order id_xy lat lon , after(id_town)

    compress
    save "$b_output/imd/05_map_imd_grid_towns.dta" , replace
