*-------------------------------------------------------------------------------
* NIC price centres
*-------------------------------------------------------------------------------

use "$b_temp/nic_price_centres.dta" , clear

gen matchname = ustrtrim(strupper(centre))

tempfile nic_centres
save `nic_centres' , replace

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
    drop _merge

    duplicates tag idcentre , gen(tag)
    // br if tag
        drop if tag > 0 & regexm(name_town_raw, "P?p?art\)")
        drop tag

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

// use "$climate_lives/data/temp/nic_prices_census_match.dta" , clear
// keep id*
//
//     merge 1:m idcentre using "$b_output/retail_prices_qrtyr.dta" , assert(2 3) keep(3) nogen
//     merge m:1 id_town using `census_towns' , assert(2 3) keep(3) nogen
