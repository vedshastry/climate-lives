* build 1981 towns dta with from DEO entry
*-------------------------------------------------------------------------------
* prelim
clear all /* clearing memory */
set more off /* ut off long output */

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

* use 1981 sheet
  import delimited using "$input/town/deo/1981.csv", clear varnames(2) stringcols(_all) favorstrfixed

*-------------------------------------------------------------------------------

* keep relevant columns
  keep filename-wrk_non_f

* rename numeric data columns
  rename (filename pdf_page_no) (filename pdf_page)
  rename (houses households) (nhouses nhouseholds)
  rename (pop_t pop_m pop_f) (townpop townpop_m townpop_f)
  rename (sc_t sc_m sc_f) (sc_t sc_m sc_f)
  rename (st_t st_m st_f) (st_t st_m st_f)
  rename (edu_t edu_m edu_f) (edu_t edu_m edu_f)
  rename (wrk_t wrk_t_m wrk_t_f) (workers_t workers_m workers_f)
  rename (wrk_1_t wrk_1_m wrk_1_f) (wrk_1t wrk_1m wrk_1f)
  rename (wrk_2_t wrk_2_m wrk_2_f) (wrk_2t wrk_2m wrk_2f)
  rename (wrk_5a_t wrk_5a_m wrk_5a_f) (wrk_5at wrk_5am wrk_5af)
  rename (wrk_others wrk_others_m wrk_others_f) (wrk_otherst wrk_othersm wrk_othersf)
  rename (wrk_mar_t wrk_mar_m wrk_mar_f) (wrk_mart wrk_marm wrk_marf)
  rename (wrk_non_t wrk_non_m wrk_non_f) (wrk_nont wrk_nonm wrk_nonf)

* drop first row, empty town/filenames, and empty columns
    drop if filename == ""
    drop if town_name == ""

*-------------------------------------------------------------------------------

* clean area - generate numeric var and convert to sq kilometres
  egen area_num = sieve(area), char(0123456789.)
  destring area_num, replace
  * standardise to sq kilometres
  gen area_sqkm = .
  order area_sqkm, before(nhouses)
  replace area_sqkm = area_num if regexm(area_units, "km")
  replace area_sqkm = area_num*2.58999 if regexm(area_units, "mil")
  * drop other area info
  drop area area_units area_num

*-------------------------------------------------------------------------------
* store list to destring numeric vars currently as string
unab numerics : area_sqkm-wrk_nonf
ds `numerics', has(type string)

* iterate over list retrieved above
foreach var in `r(varlist)'{
  * store label for transfer
  local lbl : variable label `var'
  * sieve numbers, interchange names+order and drop unsieved var
  egen `var'_num = sieve(`var'), keep(n)
  rename (`var' `var'_num) (`var'_num `var')
  order `var', before(`var'_num)
  drop `var'_num
  * transfer label to new numeric variable
  label var `var' "`lbl'"
  * destring variable
  qui destring `var', replace
}

* drop empty columns
missings dropvars, force

*-------------------------------------------------------------------------------

* generate a new subdistrict variable for tehsils/taluks
  gen subdistrict = ""
  order subdistrict, after(subdivision)

* transfer tehsil/taluk info from block and subdivision to subdistrict
  replace subdistrict = block if regexm(block, "(ta?e?t?h?a?sil|taluka?|mahal)")
  replace subdistrict = subdivision if regexm(subdivision, "(ta?e?t?h?a?sil|taluka?)")

* drop info from block and subdivision if it is a tehsil/taluk
  replace block = "" if subdistrict == block
  replace subdivision = "" if subdistrict == subdivision

* replace strings to lowercase
  local strings "state district subdivision subdistrict block town_name"
  foreach var in `strings'{
    replace `var' = strtrim(stritrim(strlower(`var')))
  }

* sort data
  sort state district filename subdivision subdistrict block town_name

*-------------------------------------------------------------------------------

* subdistrict classification
  gen subdist_type = ""
  order subdist_type, after(subdistrict)

  * taluka
    replace subdist_type = "taluka" if regexm(subdistrict, " ?taluka?")
    replace subdistrict = regexr(subdistrict, " ?taluka?","")

  * tehsil/tahsil
    replace subdist_type = "tehsil" if regexm(subdistrict, " ?te?a?ha?sil?")
    replace subdistrict = regexr(subdistrict, " ?te?a?ha?sil?","")

  * mahal
    replace subdist_type = "mahal" if regexm(subdistrict, " ?mahal?")
    replace subdistrict = regexr(subdistrict, " ?mahal?","")

  * development block
    replace subdist_type = "development block" if regexm(subdistrict, " ?development( ?block)?")
    replace subdistrict = regexr(subdistrict, " ?development ?block","")

  * municipal corporation
    replace subdist_type = "municipal corporation" if regexm(subdistrict, " ?municipal corporation")
    replace subdistrict = regexr(subdistrict, " ?municipal corporation","")

*-------------------------------------------------------------------------------

* separate civic status from town name

  replace town_name = subinstr(town_name,"("," (",.)
  replace town_name = subinstr(town_name,"  ("," (",.)

* sieve town names to keep alphanumeric + space only
  egen townsieve = sieve(town_name), keep(a n space)
  order townsieve, after(town_name)
	* clean name
	replace townsieve = regexr(townsieve, "^ps", "")
	replace townsieve = regexr(townsieve, "( ?concld)$", "")
	replace townsieve = regexr(townsieve, "( area)$", "")
	replace townsieve = regexr(townsieve, "( town)$", "")
	replace townsieve = ustrtrim(townsieve)

* track civic status
  gen civic_code = ""
	gen civic_status = ""
  order civic_code, after(town_name)

* assign civic code
// br file pdf state town_name townsieve civic* if civic_code==""

* township (ts)
  qui replace civic_code = "(ts)" if regexm(townsieve,"( ts)$|town ?ship") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( ts)$|town ?ship","")
  qui replace civic_status = "township" if civic_code == "(ts)"

* town area (ta)
  qui replace civic_code = "(ta)" if regexm(townsieve, "( t ?a)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( t ?a)$","")
  qui replace civic_status = "town area" if civic_code == "(ta)"

* municipal board (mb)
  qui replace civic_code = "(mb)" if regexm(townsieve, "( mb)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( mb)$","")
  qui replace civic_status = "municipal board" if civic_code == "(mb)"

* non municipal area (nm)
  qui replace civic_code = "(nm)" if regexm(townsieve, "( nm| ?nonmunicipality| ?nonmunicipal)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( ?nm| ?nonmunicipality| ?nonmunicipal)$","")
  qui replace civic_status = "non municipal town" if civic_code == "(nm)"

* municipality (m)
  qui replace civic_code = "(m)" if regexm(townsieve, "( m| ?municipal(ity)?e?)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( m| ?municipal(ity)?e?)$","")
  qui replace civic_status = "municipality" if civic_code == "(m)"

* city municipality (cm)
  qui replace civic_code = "(cm)" if regexm(townsieve, "( cm)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( cm)$","")
  qui replace civic_status = "city municipality" if civic_code == "(cm)"

* town municipality (tm)
  qui replace civic_code = "(tm)" if regexm(townsieve, "( tm)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( tm)$","")
  qui replace civic_status = "town municipality" if civic_code == "(tm)"

* municipal committee/council (mc)
  qui replace civic_code = "(mc)" if regexm(townsieve, "( mc| municipal council)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( mc| municipal council)$","")
  qui replace civic_status = "municipal commitee" if civic_code == "(mc)"

* municipal corporation (mcorp)
  qui replace civic_code = "(mcorp)" if regexm(townsieve, "(municipal(ity)?)? corporation") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "(municipal(ity)?)? corporation", "")
  qui replace civic_status = "municipal corporation" if civic_code == "(mcorp)"

* notified area committee (nac)
  qui replace civic_code = "(nac)" if regexm(townsieve, "( na?c?| notified( area com?mitt?ee)?)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( na?c?| notified( area com?mitt?ee)?)$","")
  qui replace civic_status = "notified area (committee)" if civic_code == "(nac)"

* non notified area (nna)
  qui replace civic_code = "(nna)" if regexm(townsieve, "( nna)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( nna)$","")
  qui replace civic_status = "non notified area" if civic_code == "(nna)"

* industrial notified area (ina)
  qui replace civic_code = "(ina)" if regexm(townsieve, "( ina)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( ina)$","")
  qui replace civic_status = "industrial notified area" if civic_code == "(ina)"

* panchayat (p)
  qui replace civic_code = "(p)" if regexm(townsieve, "( p)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( p)$","")
  qui replace civic_status = "panchayat" if civic_code == "(p)"

* village panchayat (vp)
  qui replace civic_code = "(vp)" if regexm(townsieve, "( vp)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( vp)$","")
  qui replace civic_status = "village panchayat" if civic_code == "(vp)"

* town panchayat (tp)
  qui replace civic_code = "(tp)" if regexm(townsieve, "( tp)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( tp)$","")
  qui replace civic_status = "town panchayat" if civic_code == "(tp)"

* cantonment (cantt)
  qui replace civic_code = "(cantt)" if regexm(townsieve," cantt| chh?av?o?a?ni|cantonment") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( cantt?| chh?av?o?a?ni)$|cantonment","")
  qui replace civic_status = "military cantonment" if civic_code == "(cantt)"

* town commitee (tc)
  qui replace civic_code = "(tc)" if regexm(townsieve,"(town committee| stc)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"(town committee| stc)$","")
  qui replace civic_status = "town commitee" if civic_code == "(tc)"

* sanitary board (sb)
  qui replace civic_code = "(sb)" if regexm(townsieve,"( sb)$|sanitary ?board") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( sb)$|sanitary ?board","")
  qui replace civic_status = "sanitary board" if civic_code == "(sb)"

* trust board (tb)
  qui replace civic_code = "(tb)" if regexm(townsieve,"( tb)$|trust ?board") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( tb)$|trust ?board","")
  qui replace civic_status = "trust board" if civic_code == "(tb)"

* nagar parishad (np)
  qui replace civic_code = "(np)" if regexm(townsieve, "( np)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve, "( np)$","")
  qui replace civic_status = "nagar parishad" if civic_code == "(np)"

* urban outgrowth (og)
  qui replace civic_code = "(og)" if regexm(townsieve,"( og)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( og)$","")
  qui replace civic_status = "urban outgrowth" if civic_code == "(og)"

* urban outgrowth (ua)
  qui replace civic_code = "(ua)" if regexm(townsieve,"( ua)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( ua)$","")
  qui replace civic_status = "urban agglomeration" if civic_code == "(ua)"

* census towns
  qui replace civic_code = "(ct)" if regexm(townsieve,"( ct| u)$") & civic_code == ""
  qui replace townsieve = regexr(townsieve,"( ct| u)$","")
  qui replace civic_status = "census town" if civic_code == "(ct)"

* unclassified census towns ()
	qui replace civic_code = "()" if civic_code == ""
	qui replace civic_status = "unknown/not available" if civic_code == "()"


*-------------------------------------------------------------------------------

* strip leading/trailing spaces
  replace townsieve = ustrtrim(townsieve)
  replace filename = ustrtrim(filename)
  replace district = ustrtrim(district)
  drop town_name


* rename variables for assigning codes
  rename state sname
  rename district dname
  rename subdivision sdivname
  rename subdistrict sdname
  rename subdist_type sdclass
  rename block bname
  rename group_level1 tgroup
  rename group_level2 tsubgroup
  rename townsieve tname

* assign codes (india_bridge ado programs)
  indiabridge, y(1981) s(sname) d(dname)
  rename scode_sname scode
  rename iso_sname isostate
  rename ut_sname ut
  rename dcode_dname dcode

* generate matchit string
  egen tnameclean = sieve(tname), keep(a space)
  * oncatenate name and civic status
  gen string = dcode + " " + tnameclean + " " + civic_code
  * drop cleantname var and periods from towns with missing info on civic status
  drop tnameclean
  * if string ends with a space and dot (i.e. no civic status), delete those characters
  replace string = regexr(string," \.$","")
  order string

*-------------------------------------------------------------------------------
* save checkpoint
tempfile x
save `x', replace
*-------------------------------------------------------------------------------

* load checkpoint
use `x', clear

* absorb outgrowths and remove double counting of (ua)
  gen ua = ""
  replace ua = tsubgroup if ua == ""
  replace ua = tgroup if ua == ""
  replace ua = regexr(ua," u\.a\.?|urban ag?glomeration?","")
  replace ua = tname if civic_code == "(ua)"
  * track if ua group has an aggregated UA town, and if it has outgrowths
  bysort ua: egen has_og = max(civic_code == "(og)") if ua != ""
  bysort ua: egen has_ua = max(civic_code == "(ua)") if ua != ""
  * drop the rest if aggregate UA is available, but replace civic status first
  bysort ua: drop if has_ua == 1 & civic_code != "(ua)"

  replace ua = "" if has_og == 0
  sort ua tname civic_code
  * sort levels : m > rest > og
  gen sortvar = .
  replace sortvar = 1 if inlist(civic_code,"(ua)")
  replace sortvar = 2 if inlist(civic_code, "(m)", "(mc)", "(mb)", "(mcorp)", "()") & has_ua == 0
  replace sortvar = 10 if inlist(civic_code, "(og)","")
  replace sortvar = 5  if regexm(civic_code,"\([a-z]+\)") & sortvar == .

  * sort by levels
  sort ua sortvar tname civic_code
  * drop duplicates if ua is available
  duplicates drop ua if has_ua == 1, force
  * update civic status
  bysort ua sortvar: gen ua_civ = subinstr(civic_code,")"," + og)",.) if has_og == 1
  replace ua_civ = "( + og)" if has_ua == 1
  replace ua_civ = civic_code if ua_civ == ""

* save checkpoint
  save `x', replace

  * collapse totals on town subgroups
  collapse (first) string filename pdf_page isostate scode sname dname sdivname sdname sdclass bname tname ua_civ (sum) area_sqkm-wrk_nonf if ua != "", by(dcode ua)
  * save collapsed to tempfile
    tempfile x2
    save `x2', replace

* use previous dta again, keep non-ua towns and append collapsed ua
  use `x', clear
  drop if ua != ""
  append using `x2'


*-------------------------------------------------------------------------------
* keep relevant states from 2011
  * store states in local
  local states UP BR MH WB MP OR RJ AP PB GJ TN KA KL UT JH CT HR HP DL
  * generate a keep variable
  gen states_keep = 0
  * replace with 1 for required states
  foreach state of local states {
    replace states_keep = 1 if isostate == "`state'"
  }
  * keep required states and drop identifier
  keep if states_keep == 1
  drop states_keep

* swap civic code variable
  rename (civic_code ua_civ) (ua_civ civic_code)
  replace civic_code = "(m + og)" if civic_code == "( + og)"

* drop irrelevant vars
  drop has_* sortvar ua_civ

* order, keep and sort
  order isostate scode sname dcode dname sdivname sdname sdclass bname ua tname civic_code
  sort scode dcode sdivname sdname bname ua tname

* add 1981 suffix to varname
  rename * *_1981

* sanity check
  duplicates tag scode_1981 dcode_1981 tname_1981 civic_code_1981, gen(dup)

  * find duplicated observations, collapse based on non-missing data
    local bylist "scode_1981 dcode_1981 tname_1981 civic_code_1981"
    ds
    local allvars `r(varlist)'
    local collapse : list allvars - bylist
    collapse (firstnm) `collapse', by(`bylist')
    drop dup

  duplicates drop dcode_1981 tname_1981 civic_code_1981, force
  * no duplicates detected. n = 4009
  // isid dcode_1981 tname_1981 civic_code_1981

tempfile 81entry
save `81entry', replace

*-------------------------------------------------------------------------------
* use india_bridge for 1981 identification
  use $india_bridge/output/india_bridge, clear

* keep data for identification at 1971-1981 district level
  keep *_1971 *_1981
  * make 1981 identification unique
  duplicates drop dcode_1981, force
  isid dcode_1981
  * n = 357

* merge with 1981townlist to track 1971 district code
  merge 1:m dcode_1981 using `81entry'
/*
  Result                      Number of obs
  -----------------------------------------
  Not matched                            77
      from master                        77  (_merge==1)
      from using                          0  (_merge==2)

  Matched                             4,011  (_merge==3)
  -----------------------------------------
*/
  keep if _m == 3
  keep *_1971 *_1981

  * find duplicated observations, collapse based on non-missing data
  compress
  save `81entry', replace
  use `81entry', clear
    * tag duplicates on string id
    duplicates tag string, gen(tag)
    local bylist "string"
    * return numeric vars to collapse totals on
    ds, has(type numeric)
    * collapse totals for 'portion' towns
    collapse (sum) `r(varlist)' if regexm(tname_1981,"portion") & tag > 0, by(`bylist')
    * sanity check on id and merge back with original dta
    isid string
    merge 1:m string using `81entry'
    * drop duplicates and tag
    drop _merge
    duplicates drop string, force
    drop tag

*-------------------------------------------------------------------------------
* label variables

  * metadata
  label var filename_1981 "1981 pdf file name"
  label var pdf_page_1981 "1981 pdf page number"

  * id vars
  label var sdivname_1981 "1981 subdivision name"
  label var sdname_1981 "1981 subdistrict name"
  label var sdclass_1981 "1981 subdistrict classification"
  label var bname_1981 "1981 block name"
  label var tname_1981 "1981 town name"
  label var civic_code_1981 "1981 civic status of town"
  label var civic_status_1981 "1981 civic code interpretation for town"
  label var string "1981 matchit string, = dcode71 + tname81 + civic81"

  * area & houses
    label var area_sqkm_1981 "1981 area in sq kilometres"
    label var nhouses_1981 "1981 number of houses"
    label var nhouseholds_1981 "1981 number of households"

  * town population
    label var townpop_1981 "1981 town population"
    label var townpop_m_1981 "1981 population (male)"
    label var townpop_f_1981 "1981 population (female)"
  * sc
    label var sc_t_1981 "1981 number of scheduled castes (total)"
    label var sc_m_1981 "1981 number of scheduled castes (male)"
    label var sc_f_1981 "1981 number of scheduled castes (female)"
  * st
    label var st_t_1981 "1981 number of scheduled tribes (total)"
    label var st_m_1981 "1981 number of scheduled tribes (male)"
    label var st_f_1981 "1981 number of scheduled tribes (female)"
  * literates
    label var edu_t_1981 "1981 number of literates (total)"
    label var edu_m_1981 "1981 number of literates (male)"
    label var edu_f_1981 "1981 town number of literates (female)"
  * workers
    label var workers_t_1981 "1981 number of workers (total)"
    label var workers_m_1981 "1981 number of workers (male)"
    label var workers_f_1981 "1981 number of workers (female)"
  * 1 workers
    label var wrk_1t_1981 "1981 number of category 1 workers - cultivators (total)"
    label var wrk_1m_1981 "1981 number of category 1 workers - cultivators (male)"
    label var wrk_1f_1981 "1981 number of category 1 workers - cultivators (female)"
  * 2 workers
    label var wrk_2t_1981 "1981 number of category 2 workers - agricultural labourers (total)"
    label var wrk_2m_1981 "1981 number of category 2 workers - agricultural labourers (male)"
    label var wrk_2f_1981 "1981 number of category 2 workers - agricultural labourers (female)"
  * 5a workers
    label var wrk_5at_1981 "1981 number of category 5a workers - manufacturing, household industry (total)"
    label var wrk_5am_1981 "1981 number of category 5a workers - manufacturing, household industry (male)"
    label var wrk_5af_1981 "1981 number of category 5a workers - manufacturing, household industry (female)"
  * other workers
    label var wrk_otherst_1981 "1981 number of other workers - categories 3,4,5b,6,7,8,9 (total)"
    label var wrk_othersm_1981 "1981 number of other workers - categories 3,4,5b,6,7,8,9 (male)"
    label var wrk_othersf_1981 "1981 number of other workers - categories 3,4,5b,6,7,8,9 (female)"
  * marginal workers
    label var wrk_mart_1981 "1981 number of marginal workers (total)"
    label var wrk_marm_1981 "1981 number of marginal workers (male)"
    label var wrk_marf_1981 "1981 number of marginal workers (female)"
  * non workers
    label var wrk_nont_1981 "1981 number of non workers (total)"
    label var wrk_nonm_1981 "1981 number of non workers (male)"
    label var wrk_nonf_1981 "1981 number of non workers (female)"
*-------------------------------------------------------------------------------

* store variable lists in local
  local numvars "area_sqkm_1981 nhouses_1981 nhouseholds_1981 townpop_1981 townpop_m_1981 townpop_f_1981 sc_t_1981 sc_m_1981 sc_f_1981 st_t_1981 st_m_1981 st_f_1981 edu_t_1981 edu_m_1981 edu_f_1981 workers_t_1981 workers_m_1981 workers_f_1981 wrk_1t_1981 wrk_1m_1981 wrk_1f_1981 wrk_2t_1981 wrk_2m_1981 wrk_2f_1981 wrk_5at_1981 wrk_5am_1981 wrk_5af_1981 wrk_otherst_1981 wrk_othersm_1981 wrk_othersf_1981 wrk_mart_1981 wrk_marm_1981 wrk_marf_1981 wrk_nont_1981 wrk_nonm_1981 wrk_nonf_1981"
  local idvars "string isostate_1981 scode_1981 sname_1981 dcode_1981 dname_1981 sdivname_1981 sdname_1981 sdclass_1981 bname_1981 ua_1981 tgroup_1981 tsubgroup_1981 tname_1981 civic_code_1981 civic_status_1981"
  local meta "filename_1981 pdf_page_1981"
  local 71vars "sname_1971 dname_1971 dcode_1971"

* keep, order and sort
  keep `meta' `numvars' `idvars' `71vars'
  sort scode_1981 dcode_1981 sdivname_1981 sdname_1981 bname_1981 tname_1981 civic_code_1981

* generate id
  gen id_1981 = string(_n, "%05.0f")
  label var id_1981 "1981 census town unique identifier"
  order id_1981 `meta' `idvars' `numvars' `71vars'

* compress and save
  compress
  isid id_1981
  save $dchb/input/town/build/1981, replace
*==============================================================================
