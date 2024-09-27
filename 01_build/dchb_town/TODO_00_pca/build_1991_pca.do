* build 1991 towns dta with from DEO entry
*-------------------------------------------------------------------------------
* prelim
clear all /* clearing memory */
set more off /* cut off long output */

* define dropbox globals
if "`c(username)'" == "aadit" {
  global dropbox "C:/Users/aadit/Arthashala Dropbox"
}
else if "`c(username)'" == "ved" {
  global dropbox "/home/ved/dropbox"
}
else {
  display as error "Please specify root directory" ///
  "Your username is: `c(username)'" ///
  "Replace yourName with `c(username)'"
  exit
}


*-------------------------------------------------------------------------------
* globals
  do $dropbox/dchb/code/globals.do
*-------------------------------------------------------------------------------
*** build towndirectory from raw csv data
// /*
clear all
* initiate tempfile for build
tempfile t
save `t', emptyok replace

* store list of csvs, import and append
local inpath "$dchb/input/town/census_data_tables/1991/towndir"
local flist : dir "`inpath'" files "Town Directory*.csv"
* for each file
foreach f in `flist'{
  * import csv and mark source
	import delimited using "`inpath'/`f'", clear stringcols(_all)
	gen source = "`f'"
  order source

  * clean source in state~district format
    replace source = subinstr(source,"Town Directory of ","",.)
    replace source = subinstr(source," Table For ","~",.)
    replace source = subinstr(source,".csv","",.)
    replace source = ustrtrim(strlower(source))
    replace source = subinstr(source," ","",.)

    * split district and state by ~
      split source, p("~")
      order source?, after(source)
      rename source2 source_state
      drop source1

  * append to tempfile and save
	append using `t'
	save `t', replace
}

* compress and save
  compress
  save $temp/town_dir_1991, replace
*/
*-------------------------------------------------------------------------------

* use appended pca
  use $temp/town_dir_1991, clear

* clean state/dist/town names
  * state
  clonevar o_scode = stcdc2
  replace o_scode = "0" + o_scode if strlen(o_scode) == 1
  clonevar sname = source_state
  * district
  clonevar o_dcode = dist_codec2
  replace o_dcode = "0" + o_dcode if strlen(o_dcode) == 1
  clonevar dname = dist_namec30
  replace dname = ustrtrim(strlower(dname))
  * fix amravati missing name
  replace dname = "amravati" if o_scode == "14" & o_dcode == "24"
  * town
  clonevar tcode = town_codec6
  gen tname = ""
  replace tname = town_namec30 if tname == ""
  replace tname = town_namec34 if tname == ""
  replace tname = town_namec35 if tname == ""
  replace tname = town_namec40 if tname == ""

* indiabridge identifiers
  indiabridge, y(1991) s(sname) d(dname)
  rename *_sname *
  rename *_dname *
  rename iso isostate

* order and sort identifiers
  order scode iso ut sname dcode dname tcode tname, after(source)
  sort scode dcode tcode tname
  drop *source*

* drop empty rows
  rename *n?? *
  rename arean112 area
  destring area-f_non_work, replace
  egen emptycheck = rowtotal(area-f_non_work)
  drop if emptycheck == 0
  drop emptycheck

* keep relevant vars
  keep scode-tname area-f_non_work
  rename * *_1991

* find missing districts
  // destring dcode, gen(n_dcode)
  // collapse (firstnm) o_scode sname dname, by(n_dcode)
  // sort n_dcode
  // bysort o_scode: gen check = n_dcode - n_dcode[_n-1]
  // br if inlist(check,.,1) == 0

*-------------------------------------------------------------------------------

* keep relevant states from 2011
  * store states in local
  local states UP BR MH WB MP OR RJ AP PB GJ TN KA KL UT JH CT HR HP DL
  * generate a keep variable
  gen states_keep = 0
  * replace with 1 for required states
  foreach state of local states {
    replace states_keep = 1 if isostate_1991 == "`state'"
  }
  * keep required states and drop identifier
  keep if states_keep == 1
  drop states_keep

* generate reclink ids
  gen r_idu = _n
  * state and district
  clonevar r_sc = scode
  clonevar r_dc = dcode
  clonevar r_pop = t_popln_1991
  * town name
  egen r_name = sieve(tname), keep(a)

  compress
  save `t', replace
*-------------------------------------------------------------------------------

* merge in with data from previous build
  use $input/town/build/1991_towndir, clear

  * reclink with saved tempfile
  gen r_idm = _n
  * state and district
  clonevar r_sc = scode_1991
  clonevar r_dc = dcode_1991
  clonevar r_pop = townpop_1991
  * town name
  clonevar r_name = tname_1991

  * reclink on state/dist/name/population, with state/dist/population being a mandatory match (orblock)
  reclink r_name r_sc r_dc r_pop using `t', idm(r_idm) idu(r_idu) orblock(r_sc r_dc r_pop) gen(score)
  keep if _m == 3
*-------------------------------------------------------------------------------
* cleanup and keep required data
  keep string91-civic_status_1991 ut_1991-f_non_work_1991 *81
  duplicates drop string91, force

*-------------------------------------------------------------------------------
* label variables
label var civic_status       "1991 civic status of town"
label var area               "1991 area"
label var res_house          "1991 no. of occupied resi.houses."
label var households         "1991 no. of households."
label var t_popln            "1991 total population."
label var t_m_popln          "1991 total male population."
label var t_f_popln          "1991 total female population."
label var popln_m6           "1991 male population below age 7."
label var popln_f6           "1991 female population below age 7."
label var m_sc               "1991 male sc population."
label var f_sc               "1991 female sc population."
label var m_st               "1991 male st population."
label var f_st               "1991 female st population."
label var m_literate         "1991 male literates."
label var f_literate         "1991 female literates."
label var t_m_worker         "1991 total main workers-male."
label var t_f_worker         "1991 total main workers-female."
label var m_indcat1          "1991 cultivators-male."
label var f_indcat1          "1991 cultivators-female."
label var m_indcat2          "1991 agricultural labourers-male."
label var f_indcat2          "1991 agricultural labourers-female."
label var m_indcat3          "1991 livestock,forestry,fishing etc.and allied activities,workers-male."
label var f_indcat3          "1991 livestock,forestry,fishing etc.and allied activities, workers-female."
label var m_indcat4          "1991 mining and quarying, workers -male."
label var f_indcat4          "1991 mining and quarying, workers - female."
label var m_indcat5a         "1991 manufacturing and processingin household industry,workers male."
label var f_indcat5a         "1991 manufacturing and processing household industry, female."
label var m_indcat5b         "1991 manufacturing and in other than industry workers - male."
label var f_indcat5b         "1991 manufacturing and processing other than household workers-female."
label var m_indcat6          "1991 construction,workers - male."
label var f_indcat6          "1991 construction,workers - female."
label var m_indcat7          "1991 trade and commerce, workers - male."
label var f_indcat7          "1991 trade and commerce, workers - female."
label var m_indcat8          "1991 trans., storage & workers -  male."
label var f_indcat8          "1991 trans., storage & workers - female."
label var m_indcat9          "1991 other services, workers - male"
label var f_indcat9          "1991 other services, workers-female."
label var m_marginal         "1991 marginal workers - male"
label var f_marginal         "1991 marginal workers - female"
label var m_non_work         "1991 non-workers - male"
label var f_non_work         "1991 non-workers - female."

*-------------------------------------------------------------------------------

* store variable lists in local
  local numvars "area_1991 res_house_1991 households_1991 t_popln_1991 t_m_popln_1991 t_f_popln_1991 popln_m6_1991 popln_f6_1991 m_sc_1991 f_sc_1991 m_st_1991 f_st_1991 m_literate_1991 f_literate_1991 t_m_worker_1991 t_f_worker_1991 m_indcat1_1991 f_indcat1_1991 m_indcat2_1991 f_indcat2_1991 m_indcat3_1991 f_indcat3_1991 m_indcat4_1991 f_indcat4_1991 m_indcat5a_1991 f_indcat5a_1991 m_indcat5b_1991 f_indcat5b_1991 m_indcat6_1991 f_indcat6_1991 m_indcat7_1991 f_indcat7_1991 m_indcat8_1991 f_indcat8_1991 m_indcat9_1991 f_indcat9_1991 m_marginal_1991 f_marginal_1991 m_non_work_1991 f_non_work_1991"
  local idvars "string91 isostate_1991 scode_1991 sname_1991 sdname_1991 dcode_1991 dname_1991 tcode_1991 tname_1991 civic_code_1991 civic_status_1991 ut_1991 "
  local 81vars "sname_1981 dname_1981 dcode_1981"

* keep, order and sort
  keep `numvars' `idvars' `81vars'
  sort scode_1991 dcode_1991 sdname_1991 tname_1991 civic_code_1991

* generate id
  gen id_1991 = string(_n, "%05.0f")
  label var id_1991 "1991 town id"
  order id_1991 `meta' `idvars' `numvars' `81vars'

* compress and save
  // isid string91
  isid id_1991
  compress
  save $input/town/build/1991, replace

*==============================================================================
