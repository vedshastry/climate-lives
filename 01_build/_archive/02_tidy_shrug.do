


*-------------------------------------------------------------------------------
* Prepare village dir
*-------------------------------------------------------------------------------

* merge 2001 and 2011 data
use "$dt_raw/shrug/census/shrug-vd01-dta/pc01_vd_clean_shrid.dta" , clear
merge 1:1 shrid2 using "$dt_raw/shrug/census/shrug-vd11-dta/pc11_vd_clean_shrid.dta" , nogen keep(3)

* rename & reshape
rename pc01_* *2001
rename pc11_* *2011

local reshapevars "vd_area vd_t_hh vd_t_p vd_t_m vd_t_f vd_sc_p vd_sc_m vd_sc_f vd_st_p vd_st_m vd_st_f "
*-------------------------------------------------------------------------------
