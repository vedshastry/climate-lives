* build 2001 towns dta with from DEO entry
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
* append excel files
*-------------------------------------------------------------------------------

* store list of files
  local flist :  dir "$input/town/census_data_tables/2001/pca/" files "*.xls"

* create tempfile for build
  tempfile town01
  save `town01', replace emptyok

* import state PCA excel and append to build file
  foreach xls in `flist'{
    import excel using "$input/town/census_data_tables/2001/pca/`xls'", firstrow clear allstring
    gen source = "`xls'"
    append using `town01'
    save `town01', replace
  }

* compress and save
  compress
  save `town01', replace

*-------------------------------------------------------------------------------
* clean and build 2001 town data
*-------------------------------------------------------------------------------

* use 2001 town tempfile
  use `town01', clear

* rename vars to lower case
  rename *, lower

* generate state name
  gen sname = subinstr(source,".xls","",.)
  order sname
  replace sname = ustrtrim(strlower(sname))

* copy name info from district level id
  egen dname = sieve(name) if level == "DISTRICT", keep(a)
  replace dname = ustrtrim(strlower(dname))
  order dname, before(name)
  * fill missing cells downward based on group
  carryforward dname, replace

* apply indiabridge identifiers
  indiabridge, y(2001) s(sname) d(dname)
  * sanity check - count should be 0
  count if strlen(dcode_dname) != 4

* rename vars
  rename *_sname *
  rename *_dname *
  rename name tname

* destring numeric vars
  destring no_hh-non_work_f, replace

* keep relevant data
  keep if level == "TOWN"
  keep iso scode ut sname dcode dname subdistt town_vill tname no_hh-non_work_f

* replace town name for delhi
  replace tname = "DMC (U) Part" if tname == "DMC(U) Part"
  replace tname = "DMC (U) (Part)" if tname == "DMC (U) Part"

* duplicate (part) towns
  duplicates tag scode tname, gen(tag)
  gen part_town = (tag>0 & regexm(tname,"Part"))

* save to tempfile
  save `town01', replace

* collapse sums for 'part' towns
  collapse (sum) no_hh-non_work_f if part_town == 1, by(scode tname)
  * merge back with original data
  merge 1:m scode tname using `town01'
  * drop duplicates due to 1:m merge
  duplicates drop scode tname if _m == 3, force
  * drop tag vars
  drop tag part_town _merge
  * remove "part" from town name
  replace tname = subinstr(tname, " (Part)","",.)
  replace tname = ustrtrim(tname)

* extract civic status
  gen civic_status = ""
  replace civic_status = regexs(0) if regexm(tname,"\( ?[a-zA-Z]+\.? ?([a-zA-Z]+)?\.? ?\)$")
  replace tname = regexr(tname,"\( ?[a-zA-Z]+\.? ?([a-zA-Z]+)?\.? ?\)$","")
  replace tname = ustrtrim(strlower(tname))
  * civic code
  clonevar civic_code = civic_status
  replace civic_code = subinstr(civic_code,"(","",.)
  replace civic_code = subinstr(civic_code,")","",.)
  replace civic_code = ustrtrim(strlower(civic_code))
  replace civic_code = "mcorp" if regexm(civic_code,"corp")
  replace civic_code = "mcl" if regexm(civic_code,"m ?ci?l?")

* order and sort
  order iso scode ut sname dcode dname subdistt town_vill tname civic_status civic_code no_hh-non_work_f
  sort dcode subdistt tname civic_code

*-------------------------------------------------------------------------------
* keep relevant states
 local states UP BR MH WB MP OR RJ AP PB GJ TN KA KL UT JH CT HR HP DL
 * generate a keep variable
 gen states_keep = 0
 * replace with 1 for required states
 foreach state of local states {
   replace states_keep = 1 if iso == "`state'"
 }
 * keep required states and drop identifier
 keep if states_keep == 1
 drop states_keep
*-------------------------------------------------------------------------------
* rename variables
  rename iso isostate
  rename subdistt sdcode
  rename town_vill tcode
  rename no_hh nhouseholds
  rename tot_p townpop
  rename tot_m townpop_m
  rename tot_f townpop_f

* rename to 2001
  rename * *_2001
*-------------------------------------------------------------------------------
* merge with india bridge
  save `town01', replace

* identify indiabridge at 2001 district level
  use $india_bridge/output/india_bridge, clear
  duplicates drop *_2001, force
* keep 1991 and 2001
  keep *1991 *2001
* merge with 2001 town data, keep only merged
  merge 1:m dcode_2001 using `town01'
  keep if _m == 3
  drop _m

* keep only dcode 1991
  rename dcode_1991 dc91
  drop *1991
  rename dc91 dcode_1991

*-------------------------------------------------------------------------------
* string01 identifies on (dcode01 + tname01 + civic01)
  gen string0101 = dcode_2001 + " " + tname_2001 + " " + civic_code_2001
  * remove periods and leading/trailing whitespace
  replace string0101 = subinstr(string0101, "(", "",.)
  replace string0101 = subinstr(string0101, ")", "",.)
  replace string0101 = ustrtrim(subinstr(string0101,".","",.))
  label var string0101 "2001 matchit string with 2001 dcodes"
*-------------------------------------------------------------------------------

* label variables

  * id vars
  label var tname_2001 "2001 town name"
  label var civic_code_2001 "2001 civic status of town"
  label var tcode_2001 "2001 census town unique identifier"

  * area & houses
    label var nhouseholds_2001 "2001 number of households"

  * town population
    label var townpop_2001 "2001 town population"
    label var townpop_m_2001 "2001 town population (male)"
    label var townpop_f_2001 "2001 town population (female)"
    label var p_06_2001 "2001 population between 0-6 years of age"
    label var m_06_2001 "2001 population between 0-6 years of age (male)"
    label var f_06_2001 "2001 population between 0-6 years of age (female)"
  * sc
    label var p_sc_2001 "2001 number of scheduled castes (total)"
    label var m_sc_2001 "2001 number of scheduled castes (male)"
    label var f_sc_2001 "2001 number of scheduled castes (female)"
  * st
    label var p_st_2001 "2001 number of scheduled tribes (total)"
    label var m_st_2001 "2001 number of scheduled tribes (male)"
    label var f_st_2001 "2001 number of scheduled tribes (female)"
  * literates
    label var p_lit_2001 "2001 number of literates (total)"
    label var m_lit_2001 "2001 number of literates (male)"
    label var f_lit_2001 "2001 number of literates (female)"
    label var p_ill_2001 "2001 total of uneducated population"
    label var m_ill_2001 "2001 total of uneducated population (male)"
    label var f_ill_2001 "2001 total of uneducated population (female)"
    * using pca headers repo
    label var tot_work_p_2001 "2001 total worker population (total)"
    label var tot_work_m_2001 "2001 total worker population (male)"
    label var tot_work_f_2001 "2001 total worker population (female)"
    label var mainwork_p_2001 "2001 main working population (total)"
    label var mainwork_m_2001 "2001 main working population (male)"
    label var mainwork_f_2001 "2001 main working population (female)"
    label var main_cl_p_2001 "2001 main cultivator population (total)"
    label var main_cl_m_2001 "2001 main cultivator population (male)"
    label var main_cl_f_2001 "2001 main cultivator population (female)"
    label var main_al_p_2001 "2001 main agricultural labourers population (total)"
    label var main_al_m_2001 "2001 main agricultural labourers population (male)"
    label var main_al_f_2001 "2001 main agricultural labourers population (female)"
    label var main_hh_p_2001 "2001 main household industries population (total)"
    label var main_hh_m_2001 "2001 main household industries population (male)"
    label var main_hh_f_2001 "2001 main household industries population (female)"
    label var main_ot_p_2001 "2001 main other workers population (total)"
    label var main_ot_m_2001 "2001 main other workers population (male)"
    label var main_ot_f_2001 "2001 main other workers population (female)"
    label var margwork_p_2001 "2001 marginal worker population (total)"
    label var margwork_m_2001 "2001 marginal worker population (male)"
    label var margwork_f_2001 "2001 marginal worker population (female)"
    label var marg_cl_p_2001 "2001 marginal cultivator population (total)"
    label var marg_cl_m_2001 "2001 marginal cultivator population (male)"
    label var marg_cl_f_2001 "2001 marginal cultivator population (female)"
    label var marg_al_p_2001 "2001 marginal agriculture labourers population (total)"
    label var marg_al_m_2001 "2001 marginal agriculture labourers population (male)"
    label var marg_al_f_2001 "2001 marginal agriculture labourers population (female)"
    label var marg_hh_p_2001 "2001 marginal household industries population (total)"
    label var marg_hh_m_2001 "2001 marginal household industries population (male)"
    label var marg_hh_f_2001 "2001 marginal household industries population (female)"
    label var marg_ot_p_2001 "2001 marginal other workers population (total)"
    label var marg_ot_m_2001 "2001 marginal other workers population (male)"
    label var marg_ot_f_2001 "2001 marginal other workers population (female)"
    label var non_work_p_2001 "2001 non working population (total)"
    label var non_work_m_2001 "2001 non working population (male)"
    label var non_work_f_2001 "2001 non working population (female)"
*-------------------------------------------------------------------------------
* merge in area info from town directory
  gen code_2001 = dcode_2001 + tcode_2001
  duplicates drop code_2001, force
  isid code_2001
  merge 1:m code_2001 using $temp/tdir01, keepusing(area)
  drop if _m == 2
  drop _m code_2001

*-------------------------------------------------------------------------------
* store variable lists in local
  local numvars "area_2001 nhouseholds_2001 townpop_2001 townpop_m_2001 townpop_f_2001 p_06_2001 m_06_2001 f_06_2001 p_sc_2001 m_sc_2001 f_sc_2001 p_st_2001 m_st_2001 f_st_2001 p_lit_2001 m_lit_2001 f_lit_2001 p_ill_2001 m_ill_2001 f_ill_2001 tot_work_p_2001 tot_work_m_2001 tot_work_f_2001 mainwork_p_2001 mainwork_m_2001 mainwork_f_2001 main_cl_p_2001 main_cl_m_2001 main_cl_f_2001 main_al_p_2001 main_al_m_2001 main_al_f_2001 main_hh_p_2001 main_hh_m_2001 main_hh_f_2001 main_ot_p_2001 main_ot_m_2001 main_ot_f_2001 margwork_p_2001 margwork_m_2001 margwork_f_2001 marg_cl_p_2001 marg_cl_m_2001 marg_cl_f_2001 marg_al_p_2001 marg_al_m_2001 marg_al_f_2001 marg_hh_p_2001 marg_hh_m_2001 marg_hh_f_2001 marg_ot_p_2001 marg_ot_m_2001 marg_ot_f_2001 non_work_p_2001 non_work_m_2001 non_work_f_2001"
  local idvars "string0101 isostate_2001 scode_2001 sname_2001 dcode_2001 dname_2001 ut_2001 sdcode_2001 tcode_2001 tname_2001 civic_status_2001 civic_code_2001"
  local 91vars "dcode_1991"

* keep, order and sort
  keep `numvars' `idvars' `91vars'
  sort string0101

* generate id
  gen id_2001 = string(_n, "%05.0f")
  label var id_2001 "2001 town id"
  order id_2001 `idvars' `numvars' `91vars'

* compress and save
  compress
  isid id_2001
  save $dchb/input/town/build/2001, replace
*-------------------------------------------------------------------------------
