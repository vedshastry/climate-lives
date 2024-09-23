* idp markets
import delimited "/home/ved/Dropbox/gq_markets/data/raw/mandi/Market_directory_indiadataportal.csv", clear


    gen id_idp = market_code
    strkeep district_name, gen(dtname_rec) strlower alpha
    strkeep market_center, gen(mktname_rec) strlower alpha numeric keep("&")

order *_idp, first
isid id_idp

tempfile idp
save `idp', replace

* ceda markets
use "/home/ved/Dropbox/agmarknet/output/mandi_key.dta" , clear

    gen id_ceda = mkt_id
    strkeep dt_name, gen(dtname_rec) strlower alpha
    strkeep mkt_name, gen(mktname_rec) strlower alpha numeric keep("&")

tempfile ceda
save `ceda', replace

use `ceda', clear

reclink mktname_rec dtname_rec using `idp', idm(id_ceda) idu(id_idp) gen(score) wmatch(10 2)

keep if _merge == 3
drop _merge

order score mkt_name market_center dtname_rec Udtname_rec

keep if score > 0.8333 // .0.833 is the cutoff because it is the min threshold where names match but districts dont

gsort mkt_id -score
duplicates drop mkt_id , force

isid mkt_id

tempfile rec
save `rec', replace

use `rec', clear


merge 1:1 mkt_id using "/home/ved/Dropbox/agmarknet/output/mandi_key.dta" , assert(2 3) keep(3) nogen

drop U*
keep id_* latitude longitude market_center state_name district_name
order id_* latitude longitude market_center state_name district_name

export delimited "/home/ved/Dropbox/climate_lives/gis/input/mandi_id_ceda.csv" , replace

** merge with prices/arrivals
// keep id_* latitude longitude
// order id_* latitude longitude
//
// gen mid_agmark = id_ceda
// gsort mid_agmark
//
// merge 1:m mid_agmark using "/home/ved/Dropbox/agmarknet/output/ceda_agmarknet_weekly_qty_prices.dta"
