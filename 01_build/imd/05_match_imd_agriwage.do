*-------------------------------------------------------------------------------
* Match agriwage centers to IMD grid points
*-------------------------------------------------------------------------------

*--------------------------------
* 2. Import census towns panel
*--------------------------------

use "$b_input/agriwage_center_key.dta" , clear

    * Sanity check
    isid    id_center

    * get nearest gridpoint
    geonear id_center y_center x_center using "$b_temp/imd/imd_latlon_level.dta" , n(id_xy lat lon)

    * rename
    rename nid id_xy
    rename km_to_nid km_to_grid

    ** Merge with coordinates
        merge m:1 id_xy using "$b_temp/imd/imd_latlon_level.dta" , keepusing(lat lon)
        keep if _merge == 3 // keep only merged towns
        /*
        Result                      Number of obs
        -----------------------------------------
        Not matched                           113
            from master                         0  (_merge==1)
            from using                        113  (_merge==2)

        Matched                             1,003  (_merge==3)
        -----------------------------------------
        */


    * sanity check
    isid id_center
    order id_xy lat lon , after(id_center)

    compress
    save "$b_output/imd/04_match_imd_agriwage.dta" , replace
