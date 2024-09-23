*-------------------------------------------------------------------------------
* Clean converted shapefiles
*-------------------------------------------------------------------------------

    clear

    * iterate over admin level
    forval i = 1/3 {

        * import db file
        use     "$gis_output/shp2dta/gadm41_IND_`i'_db.dta" , clear

        * rename vars
        rename  *_gadm41_IND_`i'    *_adm`i'

        rename  *  , lower

        rename  *_?         *_adm?
        rename  varname_*   altnames_adm*

        * keep/order/sort
        keep    id_* x_* y_* gid_* name_* altnames_* type_*
        order   id_* x_* y_* gid_* name_* altnames_* type_*
        sort    id_*

        * Sanity check
        isid    id_*

            distinct    gid_adm`i'
            cap assert  r(ndistinct) == r(N)
            if !_rc {
                di "File uniquely identified by id_adm`i', but not by gid_adm`i'"
            }

        * Save
        compress
        save    "$b_input/ind_adm`i'.dta" , replace


    }
