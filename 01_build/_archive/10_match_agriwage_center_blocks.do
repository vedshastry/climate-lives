*-------------------------------------------------------------------------------
* Agricultural wage centers
*-------------------------------------------------------------------------------

use "$b_input/agriwage_center_key.dta" , clear

strkeep center_name , gen(name_match) strupper alpha numeric
strkeep state_name  , gen(stname_match) strupper alpha numeric

keep id_center *_match

tempfile wage_centers
save `wage_centers' , replace

*-------------------------------------------------------------------------------
* Subdistrict names (admin3 level taluks)
*-------------------------------------------------------------------------------

use "$b_input/ind_adm3.dta" , clear

    strkeep name_adm3  , gen(name_match) strupper alpha numeric
    strkeep name_adm1  , gen(stname_match) strupper alpha numeric

    keep  id_adm3 x_adm3 y_adm3 *_match

tempfile subdistricts
save `subdistricts' , replace

*-------------------------------------------------------------------------------
* Match NIC price data with census towns
*-------------------------------------------------------------------------------

use `wage_centers' , clear

* match on names + state names
    reclink name_match using `subdistricts' , idm(id_center) idu(id_adm3) gen(score)

    * 821 id_center match to 735 id_adm3 after reclink
    save    "$b_temp/wagecenter_adm3_reclink.dta" , replace

    use     "$b_temp/wagecenter_adm3_reclink.dta" , replace
    ** Keep merged obs
    keep if _merge == 3 | _merge == 1
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
    order state_ut, after(Uname_match)
    gsort idcentre -score

    duplicates drop idcentre, force

* Sort/arrange
gsort idcentre id_town

* Save
compress
save "$b_temp/nic_prices_census_match.dta" , replace

*-------------------------------------------------------------------------------
