*-------------------------------------------------------------------------------
* Prepare dta from admin boundary shapefiles
*-------------------------------------------------------------------------------

    clear

    * create output dir if non existent
    cap mkdir "$gis_input/shp2dta"


    * Iterate over shapefiles
    local shpfiles  :    dir "$gis_input/raw/gadm41_IND_shp"    files "*.shp"

    foreach shp in `shpfiles' {

        * pull filename without extension
        local fname : subinstr local shp ".shp" "" , all
        di "Converting `fname' ..."


        * export dta. store centroid coordinates in db
        shp2dta using "$gis_input/raw/gadm41_IND_shp/`fname'.shp" , ///
                database("$gis_output/shp2dta/`fname'_db.dta") ///
                coordinates("$gis_output/shp2dta/`fname'_xy.dta") ///
                replace ///
                genid(id_`fname') ///
                gencentroids(`fname')
    }
