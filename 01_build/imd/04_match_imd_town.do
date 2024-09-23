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
* Build mappingn between town pca and gridpoints within 100 km
*--------------------------------

    use "$b_output/dchb_town/03_clean_towns_wide.dta" , clear

    * sanity check
    drop    if mi(x)
    keep    id_town y x
    isid    id_town

    * form dchb_town/grid pairs
    cross using "$b_temp/imd/imd_latlon_level.dta"

        * Calculate distance
        geodist     y x lat lon , gen(km_to_grid)
        drop if     km_to_grid > 100 // keep within 100km

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
    save "$b_output/imd/04_town_imd_grid_100km.dta" , replace
