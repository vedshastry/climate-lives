*-------------------------------------------------------------------------------
** Prices
*-------------------------------------------------------------------------------
use "$b_output/retail_prices_monyr.dta" , clear

    * keeping 48 centres that have been reporting since 2010
    gen in_2010 = year == 2010
    bys idcentre : ereplace in_2010 = max(in_2010)
    keep if in_2010 == 1

    xtset idcentre monyr
    tsfill, full

    bys idcentre (zone) : replace zone = zone[_N]
    bys idcentre (centre) : replace centre = centre[_N]

tempfile prices
save `prices' , replace

*-------------------------------------------------------------------------------
* Town shapefile polygon data
*-------------------------------------------------------------------------------

use "$gis_output/shp2dta/cen11_towns_db.dta" , clear

merge 1:m id_town using "$climate_lives/data/temp/nic_prices_census_match.dta" , assert(1 3) keep(3) nogen keepusing(idcentre)

tempfile towns
save `towns', replace

    * town polygons
    use "$gis_output/shp2dta/cen11_towns_xy.dta" , clear

        clonevar    id_town = _ID
            merge m:1 id_town using `towns' , assert(1 3) keep(3) nogen keepusing(id_town)
        drop        id_town

    tempfile town_poly
    save `town_poly', replace

*-------------------------------------------------------------------------------
* Connectivity data
*-------------------------------------------------------------------------------

use                "$b_input/01_prep_towers.dta", clear

* reference towers against town polygon
    geoinpoly latitude longitude ///
        using `town_poly' , ///
        unique

* keep matched data
drop if mi(_ID)
rename _ID id_town

* Save
compress
keep id_tower id_town
save "$b_temp/opencellid_towns_match.dta" , replace

*-------------------------------------------------------------------------------

use "$b_temp/opencellid_towns_match.dta" , clear

isid    id_tower
merge 1:1 id_tower using "$b_input/01_prep_towers.dta" , assert(2 3) keep(3) nogen

* Keep 3g towers, identify month of creation
drop if mi(dmy_created_3g)
gen monyr = mofd(dmy_created_3g)
order monyr, after(id_town)
format monyr %tm

gcollapse   (count) n_towers_3g = id_tower ///
            (mean) avg_cells = n_cells_3g ///
            (mean) range_3g ///
            (sum) samples_3g ///
                , by(id_town monyr)

        * Merge in centre ID
        merge m:1 id_town using "$b_temp/nic_prices_census_match.dta" , keepusing(idcentre) assert(2 3) nogen

        order idcentre monyr , first
        isid idcentre monyr

* Merge prices
merge 1:1 idcentre monyr using `prices'
        gsort idcentre monyr



// use "$b_temp/nic_prices_census_match.dta" , clear

*-------------------------------------------------------------------------------
* Census towns
*-------------------------------------------------------------------------------

use "$b_input/census_towns.dta" , clear

    order id_town name_town x_town y_town district state_ut

    rename  name     name_town_raw
    strkeep name_town, strupper alpha sub(" ") replace

    forval i = 1/3 {
        replace name_town = ustrtrim(subinstr(name_town, "  ", " ", .))
    }

    clonevar matchname = name_town

tempfile census_towns
save `census_towns' , replace

*-------------------------------------------------------------------------------
* Match NIC price data with census towns
*-------------------------------------------------------------------------------

use `nic_centres' , clear

    reclink matchname using `census_towns' , idm(idcentre) idu(id_town) gen(score)

    keep if _merge == 3
    keep if score > 0.9

    duplicates tag idcentre , gen(tag)
    br if tag

        drop if tag > 0 & regexm(name_town_raw, "P?p?art\)")

        * centre Bilaspur UP (idcentre = 70) must match within UP (town ID 6646)
        drop if idcentre == 70 & id_town != 6646
        * centre Bilaspur CG (idcentre = 153) not found in census towns data
        drop if idcentre == 153

    order idcentre id_town score
    order state_ut, after(Umatchname)
    gsort idcentre -score

    duplicates drop idcentre, force

* Sort/arrange
gsort idcentre id_town

* Save
compress
save "$b_temp/nic_prices_census_match.dta" , replace

*-------------------------------------------------------------------------------
