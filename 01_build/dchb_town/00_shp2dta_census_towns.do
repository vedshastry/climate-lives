*-------------------------------------------------------------------------------
* import India towns shapefile
*-------------------------------------------------------------------------------

clear

    shp2dta using "$gis_input/cen11_towns/Town2011.shp" , ///
            database("$gis_output/shp2dta/cen11_towns_db.dta") ///
            coordinates("$gis_output/shp2dta/cen11_towns_xy.dta") ///
            replace ///
            genid(id_town) ///
            gencentroids(town)

*-------------------------------------------------------------------------------
* use converted town dta
*-------------------------------------------------------------------------------

use "$gis_output/shp2dta/cen11_towns_db.dta" , clear

    * sanity check
    isid    id_town

    * prepare vars
    drop    *_ID
    rename  * , lower

    * Clean town name / civic status
    gen         name_town = ""
    gen         civic_status = ""

        replace     civic_status    = regexs(2) if regexm(name, "(.+)(\(.+\))")
        replace     name_town       = regexs(1) if regexm(name, "(.+)(\(.+\))")

            gen     is_part         = regexm(civic_status,"(P|p)art")

        * for towns that did not extract civic status in the first iteration
        replace     civic_status    = regexs(2) if regexm(name_town, "(.+)(\(.+\))")
        replace     name_town       = regexs(1) if regexm(name_town, "(.+)(\(.+\))")

    * trim name
    replace     name_town = name if mi(name_town)
    replace     name_town = ustrtrim(name_town)

    * rearrange
    order       id_town name_town civic_status is_part ///
                x_town y_town sub_dist district ///
                state_ut code_2011 , first

* sanity check
sort       id_town
isid       id_town

* Save
compress
save "$b_input/census_towns.dta" , replace
