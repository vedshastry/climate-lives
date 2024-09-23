*-------------------------------------------------------------------------------
* import price data
*-------------------------------------------------------------------------------

    use "$nic_prices/output/pricedata_appended.dta" , clear

        * identify observations by centre x day
        drop    if zone == "ALL" | mi(zone)
        egen    idcentre = group(zone centre)

        * sanity check
        isid idcentre date

        * observation date
        gen         date_dmy  = date(date, "YMD")
            format      date_dmy  %td
            order       date_dmy  , after(date)
        drop        date

    * Rearrange
    order   idcentre date_dmy zone centre , first
    isid    idcentre date_dmy

*-------------------------------------------------------------------------------
* Clean variables
*-------------------------------------------------------------------------------

* Datetime

    * Quarter
    gen     qrtyr = qofd(date_dmy)
    format  qrtyr %tq

    * Month
    gen     monyr = mofd(date_dmy)
    format  monyr %tm

    * Week
    gen     wkyr = wofd(date_dmy)
    format  wkyr %tw

    order   *yr , after(date_dmy)


* Prices

foreach var of varlist rice-tomato {
    gen     nonmiss_`var' = !mi(`var')
    rename  `var' price_`var'
}

    * store prices as float
    recast float price_* , force

    * Drop empty observations
    egen    nonmiss_all = rowtotal(nonmiss_*)
    drop    if nonmiss_all == 0
    drop    nonmiss_all

    * winsorize at 1st & 99th percentile within centre and year
    winsor2 price_* , replace cuts(1 99) by(idcentre year)

    * Log prices
    foreach var of varlist price_* {
        gen     log_`var' = log(`var')
    }

*-------------------------------------------------------------------------------
* Generate analysis variables
*-------------------------------------------------------------------------------

** Aggregate to specified frequency
local timevar "monyr"

gcollapse   (mean) mean_price_* = price_*  ///
            (p50) p50_price_* = price_*  ///
            (sd) sd_price_* = price_*  ///
            (sum) n_days_* = nonmiss_*     ///
            (mean) year ///
            , by(idcentre `timevar' zone centre) ///
            wildparse

    * recast / rename
    recast  float *price* , force
    rename  *_price_* *_*


    isid        idcentre `timevar'

* Save
compress
save "$b_input/retail_prices_`timevar'.dta" , replace

*-------------------------------------------------------------------------------
* Export list of centers
*-------------------------------------------------------------------------------

use "$b_input/retail_prices_monyr.dta" , clear

    keep idcentre zone centre
    duplicates drop

save "$b_temp/nic_price_centres.dta" , replace
