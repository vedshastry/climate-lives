* build 2011 towns dta with from DEO entry
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
* clean and build 2011 town data
*-------------------------------------------------------------------------------
** town dta
* prepare 2011 file for build
  use $temp/pca2011_append, clear
  * rename vars to lowercase
  rename *, lower
  * keep towns
  keep if level == "TOWN"
  * clean source var
  order source
  replace source = subinstr(source,"Primary Census Abstract Total Table For","",.)
  replace source = subinstr(source," District ","-",.)
  replace source = subinstr(source,".xlsx","",.)
  replace source = ustrtrim(strlower(source))
  replace source = subinstr(source," ","_",.)

  * sort, compress and save
  drop ward eb level tru
  destring no_hh-non_work_f, replace
  sort state district subdistt townvillage
  compress
  save $temp/town_pca_2011, replace

*-------------------------------------------------------------------------------

* use 2011 town tempfile
  use $temp/town_pca_2011, clear

* rename vars
  rename name tname
  rename state scode
  rename district dcode

* distinct dcode
* 637 out of 640 districts have at least 1 town.
** districts with no urban areas: lahul&spiti (hp), kinnaur (hp), nicobars (an)


* duplicate (part) towns
  duplicates tag dcode tname, gen(tag)
  gen part_town = (tag>0 & regexm(tname,"Part"))

* save to tempfile
  tempfile town11
  save `town11', replace

* collapse sums for 'part' towns
  collapse (sum) no_hh-non_work_f if part_town == 1, by(dcode tname)
  * merge back with original data
  merge 1:m dcode tname using `town11'
  * drop duplicates due to 1:m merge
  duplicates drop dcode tname if _m == 3, force
  * drop tag vars
  drop tag part_town _merge
  * remove "part" from town name
  replace tname = subinstr(tname, " (Part)","",.)
  replace tname = ustrtrim(tname)

* extract civic status
  gen civic_status = ""
  replace civic_status = regexs(0) if regexm(tname,"\( ?[a-zA-Z]+\.? ?([a-zA-Z]+)?\.? ?([a-zA-Z]+)?\.? ?\+? ?([a-zA-Z]+)?\.? ?\)$")
  replace tname = regexr(tname,"\( ?[a-zA-Z]+\.? ?([a-zA-Z]+)?\.? ?([a-zA-Z]+)?\.? ?\+? ?([a-zA-Z]+)?\.? ?\)$","")
  replace tname = ustrtrim(strlower(tname))
  * civic code
  clonevar civic_code = civic_status
  * outgrowths
  gen outgrowth = (regexm(civic_status, "\+"))
  replace civic_code = subinstr(civic_code,"(","",.)
  replace civic_code = subinstr(civic_code,")","",.)
  replace civic_code = ustrtrim(strlower(civic_code))
  replace civic_code = "mcl" if regexm(civic_code,"m ?ci?l?")
  replace civic_code = "mcorp" if regexm(civic_code,"corp")
  replace civic_code = civic_code + " + og" if outgrowth == 1 & regexm(civic_code,"\+")==0

* order and sort
  order scode dcode subdistt townvillage tname civic_status civic_code no_hh-non_work_f
  sort dcode subdistt townvillage tname civic_code

*-------------------------------------------------------------------------------
* rename variables
  rename subdistt sdcode
  rename no_hh nhouseholds
  rename tot_p townpop
  rename tot_m townpop_m
  rename tot_f townpop_f

* rename to 2011
  rename * *_2011
*-------------------------------------------------------------------------------
* merge with india bridge
  save `town11', replace

* identify indiabridge at 2011 district level
  use $india_bridge/output/india_bridge, clear
  duplicates drop *_2011, force
* keep 2001 and 2011
  keep *2001 *2011
* merge with 2011 town data, keep only merged
  merge 1:m dcode_2011 using `town11'
  keep if _m == 3
  drop _m

*-------------------------------------------------------------------------------
* keep relevant states
 local states UP BR MH WB MP OR RJ AP PB GJ TN KA KL UT JH CT HR HP DL
 * generate a keep variable
 gen states_keep = 0
 * replace with 1 for required states
 clonevar iso = isostate_2001
 foreach state of local states {
   replace states_keep = 1 if iso == "`state'"
 }
 * keep required states and drop identifier
 keep if states_keep == 1
 drop states_keep iso
 rename dcode_2001 dc01
 drop *_2001
 rename dc01 dcode_2001


* make string identifier
  gen string1111 = dcode_2011 + " " + tname_2011 + " " + civic_code_2011
  duplicates drop string1111, force
  isid string1111
*-------------------------------------------------------------------------------
* label variables

  * id vars
  label var tname_2011 "2011 town name"
  label var civic_code_2011 "2011 civic status of town"

  * area & houses
    label var nhouseholds_2011 "2011 number of households"

  * town population
      label var townpop_2011 "2011 town population"
      label var townpop_m_2011 "2011 town population (male)"
      label var townpop_f_2011 "2011 town population (female)"
      label var p_06_2011 "2011 population between 0-6 years of age"
      label var m_06_2011 "2011 population between 0-6 years of age (male)"
      label var f_06_2011 "2011 population between 0-6 years of age (female)"
      label var p_sc_2011 "2011 number of scheduled castes (total)"
      label var m_sc_2011 "2011 number of scheduled castes (male)"
      label var f_sc_2011 "2011 number of scheduled castes (female)"
    * st
      label var p_st_2011 "2011 number of scheduled tribes (total)"
      label var m_st_2011 "2011 number of scheduled tribes (male)"
      label var f_st_2011 "2011 number of scheduled tribes (female)"
    * literates
      label var p_lit_2011 "2011 number of literates (total)"
      label var m_lit_2011 "2011 number of literates (male)"
      label var f_lit_2011 "2011 number of literates (female)"
      label var p_ill_2011 "2011 total of uneducated population"
      label var m_ill_2011 "2011 total of uneducated population (male)"
      label var f_ill_2011 "2011 total of uneducated population (female)"

* using pca headers repo
label var tot_work_p_2011 "2011 total worker population (total)"
label var tot_work_m_2011 "2011 total worker population (male)"
label var tot_work_f_2011 "2011 total worker population (female)"
label var mainwork_p_2011 "2011 main working population (total)"
label var mainwork_m_2011 "2011 main working population (male)"
label var mainwork_f_2011 "2011 main working population (female)"
label var main_cl_p_2011 "2011 main cultivator population (total)"
label var main_cl_m_2011 "2011 main cultivator population (male)"
label var main_cl_f_2011 "2011 main cultivator population (female)"
label var main_al_p_2011 "2011 main agricultural labourers population (total)"
label var main_al_m_2011 "2011 main agricultural labourers population (male)"
label var main_al_f_2011 "2011 main agricultural labourers population (female)"
label var main_hh_p_2011 "2011 main household industries population (total)"
label var main_hh_m_2011 "2011 main household industries population (male)"
label var main_hh_f_2011 "2011 main household industries population (female)"
label var main_ot_p_2011 "2011 main other workers population (total)"
label var main_ot_m_2011 "2011 main other workers population (male)"
label var main_ot_f_2011 "2011 main other workers population (female)"
label var margwork_p_2011 "2011 marginal worker population (total)"
label var margwork_m_2011 "2011 marginal worker population (male)"
label var margwork_f_2011 "2011 marginal worker population (female)"
label var marg_cl_p_2011 "2011 marginal cultivator population (total)"
label var marg_cl_m_2011 "2011 marginal cultivator population (male)"
label var marg_cl_f_2011 "2011 marginal cultivator population (female)"
label var marg_al_p_2011 "2011 marginal agriculture labourers population (total)"
label var marg_al_m_2011 "2011 marginal agriculture labourers population (male)"
label var marg_al_f_2011 "2011 marginal agriculture labourers population (female)"
label var marg_hh_p_2011 "2011 marginal household industries population (total)"
label var marg_hh_m_2011 "2011 marginal household industries population (male)"
label var marg_hh_f_2011 "2011 marginal household industries population (female)"
label var marg_ot_p_2011 "2011 marginal other workers population (total)"
label var marg_ot_m_2011 "2011 marginal other workers population (male)"
label var marg_ot_f_2011 "2011 marginal other workers population (female)"
label var margwork_3_6_p_2011 "2011 marginal worker population 3-6 (total)"
label var margwork_3_6_m_2011 "2011 marginal worker population 3-6 (male)"
label var margwork_3_6_f_2011 "2011 marginal worker population 3-6 (female)"
label var marg_cl_3_6_p_2011 "2011 marginal cultivator population 3-6 (total)"
label var marg_cl_3_6_m_2011 "2011 marginal cultivator population 3-6 (male)"
label var marg_cl_3_6_f_2011 "2011 marginal cultivator population 3-6 (female)"
label var marg_al_3_6_p_2011 "2011 marginal agriculture labourers population 3-6 (total)"
label var marg_al_3_6_m_2011 "2011 marginal agriculture labourers population 3-6 (male)"
label var marg_al_3_6_f_2011 "2011 marginal agriculture labourers population 3-6 (female)"
label var marg_hh_3_6_p_2011 "2011 marginal household industries population 3-6 (total)"
label var marg_hh_3_6_m_2011 "2011 marginal household industries population 3-6 (male)"
label var marg_hh_3_6_f_2011 "2011 marginal household industries population 3-6 (female)"
label var marg_ot_3_6_p_2011 "2011 marginal other workers population (total) 3-6 (total)"
label var marg_ot_3_6_m_2011 "2011 marginal other workers population (total) 3-6 (male)"
label var marg_ot_3_6_f_2011 "2011 marginal other workers population (total) 3-6 (female)"
label var margwork_0_3_p_2011 "2011 marginal worker population 0-3 (total)"
label var margwork_0_3_m_2011 "2011 marginal worker population 0-3 (male)"
label var margwork_0_3_f_2011 "2011 marginal worker population 0-3 (female)"
label var marg_cl_0_3_p_2011 "2011 marginal cultivator population 0-3 (total)"
label var marg_cl_0_3_m_2011 "2011 marginal cultivator population 0-3 (male)"
label var marg_cl_0_3_f_2011 "2011 marginal cultivator population 0-3 (female)"
label var marg_al_0_3_p_2011 "2011 marginal agriculture labourers population 0-3 (total)"
label var marg_al_0_3_m_2011 "2011 marginal agriculture labourers population 0-3 (male)"
label var marg_al_0_3_f_2011 "2011 marginal agriculture labourers population 0-3 (female)"
label var marg_hh_0_3_p_2011 "2011 marginal household industries population 0-3 (total)"
label var marg_hh_0_3_m_2011 "2011 marginal household industries population 0-3 (male)"
label var marg_hh_0_3_f_2011 "2011 marginal household industries population 0-3 (female)"
label var marg_ot_0_3_p_2011 "2011 marginal other workers population 0-3 (total)"
label var marg_ot_0_3_m_2011 "2011 marginal other workers population 0-3 (male)"
label var marg_ot_0_3_f_2011 "2011 marginal other workers population 0-3 (female)"
label var non_work_p_2011 "2011 non working population (total)"
label var non_work_m_2011 "2011 non working population (male)"
label var non_work_f_2011 "2011 non working population (female)"
*-------------------------------------------------------------------------------

* store variable lists in local
  local numvars "nhouseholds_2011 townpop_2011 townpop_m_2011 townpop_f_2011 p_06_2011 m_06_2011 f_06_2011 p_sc_2011 m_sc_2011 f_sc_2011 p_st_2011 m_st_2011 f_st_2011 p_lit_2011 m_lit_2011 f_lit_2011 p_ill_2011 m_ill_2011 f_ill_2011 tot_work_p_2011 tot_work_m_2011 tot_work_f_2011 mainwork_p_2011 mainwork_m_2011 mainwork_f_2011 main_cl_p_2011 main_cl_m_2011 main_cl_f_2011 main_al_p_2011 main_al_m_2011 main_al_f_2011 main_hh_p_2011 main_hh_m_2011 main_hh_f_2011 main_ot_p_2011 main_ot_m_2011 main_ot_f_2011 margwork_p_2011 margwork_m_2011 margwork_f_2011 marg_cl_p_2011 marg_cl_m_2011 marg_cl_f_2011 marg_al_p_2011 marg_al_m_2011 marg_al_f_2011 marg_hh_p_2011 marg_hh_m_2011 marg_hh_f_2011 marg_ot_p_2011 marg_ot_m_2011 marg_ot_f_2011 margwork_3_6_p_2011 margwork_3_6_m_2011 margwork_3_6_f_2011 marg_cl_3_6_p_2011 marg_cl_3_6_m_2011 marg_cl_3_6_f_2011 marg_al_3_6_p_2011 marg_al_3_6_m_2011 marg_al_3_6_f_2011 marg_hh_3_6_p_2011 marg_hh_3_6_m_2011 marg_hh_3_6_f_2011 marg_ot_3_6_p_2011 marg_ot_3_6_m_2011 marg_ot_3_6_f_2011 margwork_0_3_p_2011 margwork_0_3_m_2011 margwork_0_3_f_2011 marg_cl_0_3_p_2011 marg_cl_0_3_m_2011 marg_cl_0_3_f_2011 marg_al_0_3_p_2011 marg_al_0_3_m_2011 marg_al_0_3_f_2011 marg_hh_0_3_p_2011 marg_hh_0_3_m_2011 marg_hh_0_3_f_2011 marg_ot_0_3_p_2011 marg_ot_0_3_m_2011 marg_ot_0_3_f_2011 non_work_p_2011 non_work_m_2011 non_work_f_2011"
  local idvars "string1111 dcode_2001 isostate_2011 scode_2011 sname_2011 dcode_2011 dname_2011 ut_2011 sdcode_2011 townvillage_2011 tname_2011 civic_status_2011 civic_code_2011 source_2011 outgrowth_2011"
  local 01vars "dcode_2001"

* keep, order and sort
  keep `numvars' `idvars' `01vars'
  sort string1111

* generate id
  gen id_2011 = string(_n, "%05.0f")
  label var id_2011 "2011 town id"
  order id_2011 `idvars' `numvars' `01vars'

* compress and save
  compress
  isid id_2011
  save $dchb/input/town/build/2011, replace
*-------------------------------------------------------------------------------
