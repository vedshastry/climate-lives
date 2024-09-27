* build 1961 towns dta with from DEO entry
*-------------------------------------------------------------------------------
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

* globals
  do $dropbox/dchb/code/globals.do
*-------------------------------------------------------------------------------

* use 1961 sheet
  // import delimited using "$input/town/deo/1961.csv", clear stringcols(_all) favorstrfixed
  use "$dchb/input/town/deo/deo_chanchal_dta/1981.dta" , clear

*-------------------------------------------------------------------------------
* Rename columns
*-------------------------------------------------------------------------------

        * Metadata
        rename (A B C D E F G H)  (filename pdf_page state district subdivision block group_level1 group_level2)
        rename (I J K L M)        (town_name town_name_2011 facilities area area_units)
        rename (N O)              (houses households)

        * Demographics
        rename (P Q R)            (pop_t pop_m pop_f)
        rename (S T U)            (sc_t sc_m sc_f)
        rename (V W X)            (st_t st_m st_f)
        rename (Y Z AA)           (edu_t edu_m edu_f)

        * Occupation
        rename (AB AC AD)         (wrk_t_t wrk_t_m wrk_t_f)
        rename (AE AF AG)         (wrk_1_t wrk_1_m wrk_1_f)
        rename (AH AI AJ)         (wrk_2_t wrk_2_m wrk_2_f)
        rename (AK AL AM)         (wrk_3_t wrk_3_m wrk_3_f)
        rename (AN AO AP)         (wrk_4_t wrk_4_m wrk_4_f)
        rename (AQ AR AS)         (wrk_5_t wrk_5_m wrk_5_f)
        rename (AT AU AV)         (wrk_6_t wrk_6_m wrk_6_f)
        rename (AW AX AY)         (wrk_7_t wrk_7_m wrk_7_f)
        rename (AZ BA BB)         (wrk_8_t wrk_8_m wrk_8_f)
        rename (BC BD BE)         (wrk_9_t wrk_9_m wrk_9_f)
        rename (BF BG BH)         (wrk_non_t wrk_non_m wrk_non_f)

        * Other
        rename (BJ BK)            (notes year)

      * Keep vars
      drop ? ?? // columns A-Z and AA-ZZ

*-------------------------------------------------------------------------------
* Rename to standardize
*-------------------------------------------------------------------------------

* rename numeric data columns
  qui rename (filename pdf_page_no) (filename_1961 pdf_page_1961)
  qui rename (houses households) (nhouses_1961 nhouseholds_1961)
  qui rename (pop_t pop_m pop_f) (townpop_1961 townpop_m_1961 townpop_f_1961)
  qui rename (sc_t sc_m sc_f) (sc_t_1961 sc_m_1961 sc_f_1961)
  qui rename (st_t st_m st_f) (st_t_1961 st_m_1961 st_f_1961)
  qui rename (edu_t edu_m edu_f) (edu_t_1961 edu_m_1961 edu_f_1961)
  qui rename (wrk_t_t wrk_t_m wrk_t_f) (workers_t_1961 workers_m_1961 workers_f_1961)
  qui rename (wrk_1_t wrk_1_m wrk_1_f) (wrk_1t_1961 wrk_1m_1961 wrk_1f_1961)
  qui rename (wrk_2_t wrk_2_m wrk_2_f) (wrk_2t_1961 wrk_2m_1961 wrk_2f_1961)
  qui rename (wrk_3_t wrk_3_m wrk_3_f) (wrk_3t_1961 wrk_3m_1961 wrk_3f_1961)
  qui rename (wrk_4_t wrk_4_m wrk_4_f) (wrk_4t_1961 wrk_4m_1961 wrk_4f_1961)
  qui rename (wrk_5_t wrk_5_m wrk_5_f) (wrk_5t_1961 wrk_5m_1961 wrk_5f_1961)
  qui rename (wrk_6_t wrk_6_m wrk_6_f) (wrk_6t_1961 wrk_6m_1961 wrk_6f_1961)
  qui rename (wrk_7_t wrk_7_m wrk_7_f) (wrk_7t_1961 wrk_7m_1961 wrk_7f_1961)
  qui rename (wrk_8_t wrk_8_m wrk_8_f) (wrk_8t_1961 wrk_8m_1961 wrk_8f_1961)
  qui rename (wrk_9_t wrk_9_m wrk_9_f) (wrk_9t_1961 wrk_9m_1961 wrk_9f_1961)
  qui rename (wrk_non_t wrk_non_m wrk_non_f) (wrk_nont_1961 wrk_nonm_1961 wrk_nonf_1961)

* create raw town name for id
egen raw_name_1961 = concat(filename_1961 pdf_page_1961 town_name_1961)

* drop empty town/filenames
    drop if filename == ""
    drop if town_name_1961 == ""

* trim state/district names
  replace state = strlower(ustrtrim(state))
  replace district = strlower(ustrtrim(district))

*-------------------------------------------------------------------------------

* clean area - generate numeric var and convert to sq kilometres
	replace area = "" if area == "n.a" | area == "."

  * standardise units
    * split by hyphen for acres-gunthas: area_ag2 contains gunthas
    split area, p("-") destring gen(area_ag)
		* split the result by slash for sqkm/sqmiles: area2 contains sqkm info
    split area_ag1, p("/") destring gen(area_)

		* sieve numeric from area & destring (if not already numeric)
			capture egen area_num = sieve(area_1), char(0123456789.)
			capture gen area_num = area_1
			capture destring area_num, replace

		* convert area_num to sq.km measurement only
		gen area_sqkm_1961 = .
		order area_sqkm_1961, before(nhouses_1961)
			* sq miles to sq km
			replace area_sqkm_1961 = area_num*2.58999 if regexm(area_units, "sq mile?r?s")
			* acres to sq km
			replace area_sqkm_1961 = area_num*0.00404686 if regexm(area_units, "A-G|a-g|acres")
			* 1 guntha = 0.025 acres
			replace area_sqkm_1961 = area_sqkm_1961 + 0.025*area_ag2 if regexm(area_units, "A-G|a-g")

	* round off to 2 decimals
	format area_sqkm_1961 %9.2g
  * drop other area info & round off to 2 decimals
  drop area area_units area_1 area_2 area_ag1 area_ag2 area_num

*-------------------------------------------------------------------------------
* store list to destring numeric vars currently as string
unab numerics : area_sqkm_1961-wrk_nonf_1961
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

* drop empty columns + irrelevant data
missings dropvars, force
drop town_name_2011

*-------------------------------------------------------------------------------

* generate a new subdistrict variable for tehsils/taluks
  gen subdistrict = ""
  order subdistrict, after(subdivision)

* transfer tehsil/taluk info from subdivision to subdistrict
  replace subdistrict = subdivision if regexm(subdivision, "(ta?e?t?h?a?s?h?il|taluka?|i\.s\.t|mahal)")

* drop info from subdivision if it is a tehsil/taluk
  replace subdivision = "" if subdistrict == subdivision

* replace strings to lowercase
  local strings "state district subdivision subdistrict town_name_1961"
  foreach var in `strings'{
    replace `var' = ustrtrim((strlower(`var')))
  }

* sort data
  sort state district filename subdivision subdistrict town_name_1961

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

*-------------------------------------------------------------------------------
* separate civic status from town name

* sieve town names to keep alphanumeric + space only
  egen townsieve = sieve(town_name_1961), keep(a n space)
  order townsieve, after(town_name_1961)
	* clean name
	replace townsieve = regexr(townsieve, "( area)$", "")
	replace townsieve = regexr(townsieve, " town", "")
	replace townsieve = ustrtrim(townsieve)

* track civic status
  gen civic_code_1961 = ""
	gen civic_status_1961 = ""
  order civic_code_1961, after(town_name_1961)

* assign civic code
// br file pdf state town_name townsieve civic* if civic_code==""

	* electrified area (e) - not relevant
		qui replace civic_code_1961 = "()" if regexm(townsieve, "( e)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( e)$","")
		qui replace civic_status_1961 = "electrified town" if civic_code_1961 == "()"

	* township (ts)
		qui replace civic_code_1961 = "(ts)" if regexm(townsieve,"( ts)$|township") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve,"( ts)$|township","")
		qui replace civic_status_1961 = "township" if civic_code_1961 == "(ts)"

  * town area (ta)
    qui replace civic_code_1961 = "(ta)" if regexm(townsieve, "( ta)$") & civic_code_1961 == ""
    qui replace townsieve = regexr(townsieve, "( ta)$","")
		qui replace civic_status_1961 = "town area" if civic_code_1961 == "(ta)"

  * municipal board (mb)
    qui replace civic_code_1961 = "(mb)" if regexm(townsieve, "( mb)$") & civic_code_1961 == ""
    qui replace townsieve = regexr(townsieve, "( mb)$","")
		qui replace civic_status_1961 = "municipal board" if civic_code_1961 == "(mb)"

	* non municipal area (nm)
		qui replace civic_code_1961 = "(nm)" if regexm(townsieve, "( nm| ?nonmunicipality| ?nonmunicipal)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( ?nm| ?nonmunicipality| ?nonmunicipal)$","")
		qui replace civic_status_1961 = "non municipal town" if civic_code_1961 == "(nm)"

	* municipality (m)
		qui replace civic_code_1961 = "(m)" if regexm(townsieve, "( m| ?municipal(ity)?e?)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( m| ?municipal(ity)?e?)$","")
		qui replace civic_status_1961 = "municipality" if civic_code_1961 == "(m)"

	* city municipality (cm)
		qui replace civic_code_1961 = "(cm)" if regexm(townsieve, "( cm)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( cm)$","")
		qui replace civic_status_1961 = "city municipality" if civic_code_1961 == "(cm)"

	* town municipality (tm)
		qui replace civic_code_1961 = "(tm)" if regexm(townsieve, "( tm)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( tm)$","")
		qui replace civic_status_1961 = "town municipality" if civic_code_1961 == "(tm)"

	* municipal committee (mc)
		qui replace civic_code_1961 = "(mc)" if regexm(townsieve, "( mc)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( mc)$","")
		qui replace civic_status_1961 = "municipal commitee" if civic_code_1961 == "(mc)"

	* municipal corporation (mcorp)
		qui replace civic_code_1961 = "(mcorp)" if regexm(townsieve, "(municipal(ity)?)? corporation") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "(municipal(ity)?)? corporation", "")
		qui replace civic_status_1961 = "municipal corporation" if civic_code_1961 == "(mcorp)"

	* notified area committee (nac)
		qui replace civic_code_1961 = "(nac)" if regexm(townsieve, "( na?c?)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( na?c?)$","")
		qui replace civic_status_1961 = "notified area (committee)" if civic_code_1961 == "(nac)"

	* non notified area (nna)
		qui replace civic_code_1961 = "(nna)" if regexm(townsieve, "( nna)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( nna)$","")
		qui replace civic_status_1961 = "non notified area" if civic_code_1961 == "(nna)"

	* panchayat (p)
		qui replace civic_code_1961 = "(p)" if regexm(townsieve, "( p)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( p)$","")
		qui replace civic_status_1961 = "panchayat" if civic_code_1961 == "(p)"

	* town panchayat (tp)
		qui replace civic_code_1961 = "(tp)" if regexm(townsieve, "( tp)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve, "( tp)$","")
		qui replace civic_status_1961 = "town panchayat" if civic_code_1961 == "(tp)"

	* cantonment (cantt)
		qui replace civic_code_1961 = "(cantt)" if regexm(townsieve," cantt|cantonment") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve,"( cantt?)$|cantonment","")
		qui replace civic_status_1961 = "military cantonment" if civic_code_1961 == "(cantt)"

	* town commitee (tc)
		qui replace civic_code_1961 = "(tc)" if regexm(townsieve,"(town committee| stc)$") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve,"(town committee| stc)$","")
		qui replace civic_status_1961 = "town commitee" if civic_code_1961 == "(tc)"

	* sanitary board (sb)
		qui replace civic_code_1961 = "(sb)" if regexm(townsieve,"( sb)$|sanitary ?board") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve,"( sb)$|sanitary ?board","")
		qui replace civic_status_1961 = "sanitary board" if civic_code_1961 == "(sb)"

	* trust board (tb)
		qui replace civic_code_1961 = "(tb)" if regexm(townsieve,"( tb)$|trust ?board") & civic_code_1961 == ""
		qui replace townsieve = regexr(townsieve,"( tb)$|trust ?board","")
		qui replace civic_status_1961 = "trust board" if civic_code_1961 == "(tb)"

  * nagar parishad (np)
    qui replace civic_code_1961 = "(np)" if regexm(townsieve, "( np)$") & civic_code_1961 == ""
    qui replace townsieve = regexr(townsieve, "( np)$","")
		qui replace civic_status_1961 = "nagar parishad" if civic_code_1961 == "(np)"

	* unclassified census towns ()
		qui replace civic_code_1961 = "()" if civic_code_1961 == ""
		qui replace civic_status_1961 = "unknown/not available" if civic_code_1961 == "()" & civic_status_1961 != "electrified town"

*-------------------------------------------------------------------------------


* prepare district names for cleaning
  replace district = regexr(district,"district","")


* strip leading/trailing spaces
  replace townsieve = ustrtrim(townsieve)
  replace filename = ustrtrim(filename)
  replace district = ustrtrim(district)
  drop town_name_1961


* rename variables for assigning codes
  rename state sname_1961
  rename district dname_1961
  rename subdivision sdivname_1961
  rename subdistrict sdname_1961
  rename subdist_type sdclass_1961
  rename townsieve tname_1961
	rename group_level1 tgroup_1961
	rename group_level2 tsubgroup_1961


* assign codes (india_bridge ado programs)
  indiabridge, y(1961) s(sname_1961) d(dname_1961)
  rename scode_sname_1961 scode_1961
  rename iso_sname_1961 isostate_1961
  rename ut_sname_1961 ut_1961
  rename dcode_dname_1961 dcode_1961


* keep relevant states from 2011
  * store states in local
  local states UP BR MH WB MP OR RJ AP PB GJ TN KA KL UT JH CT HR HP DL
  * generate a keep variable
  gen states_keep = 0
  * replace with 1 for required states
  foreach state of local states {
    replace states_keep = 1 if isostate_1961 == "`state'"
  }
  * keep required states and drop identifier
  keep if states_keep == 1
  drop states_keep

* order, keep and sort
  order isostate_1961 scode_1961 sname_1961 dcode_1961 dname_1961 sdivname_1961 sdname_1961 sdclass_1961 tname_1961 civic_code_1961
  sort scode_1961 dcode_1961 sdivname_1961 sdname_1961 tname_1961

* sanity check
  // duplicates tag dcode_1961 tname_1961 civic_code_1961, gen(tag)

  * find duplicated observations, collapse based on non-missing data
    // local bylist "scode_1961 dcode_1961 tname_1961 civic_code_1961"
    // ds
    // local allvars `r(varlist)'
    // local collapse : list allvars - bylist
    // collapse (firstnm) `collapse', by(`bylist')
    // drop tag

  duplicates drop dcode_1961 tname_1961 civic_code_1961, force
  * n = 2581

tempfile 61entry
save `61entry', replace

*-------------------------------------------------------------------------------
/*
* use india_bridge for 1961 identification
  use $india_bridge/output/india_bridge, clear

* keep data for identification at 1961-1961 district level
  keep *_1951 *_1961
  * make 1961 identification unique
  duplicates drop dcode_1961, force
  isid dcode_1961
  * n = 357

* merge with 1961townlist to track 1961 district code
  merge 1:m dcode_1961 using `61entry'
  Result                      Number of obs
  -----------------------------------------
  Not matched                            77
      from master                        77  (_merge==1)
      from using                          0  (_merge==2)

  Matched                             4,007  (_merge==3)
  -----------------------------------------
  keep if _m == 3
  keep *_1961 *_1961
*/
* generate matchit string
  egen tnameclean = sieve(tname_1961), keep(a space)
  * concatenate name and civic status
  gen string61 = dcode_1961 + " " + tnameclean + " " + civic_code_1961
	replace string61 = subinstr(string61,"(","",.)
	replace string61 = subinstr(string61,")","",.)
	replace string61 = ustrtrim(string61)
  * drop cleantname var and periods from towns with missing info on civic status
  drop tnameclean
  order string61

*-------------------------------------------------------------------------------
	* collapse towns to subgroup level

  * find duplicated observations, collapse based on non-missing data
  // compress
  // save `61entry', replace
  // use `61entry', clear
  //   * tag duplicates on string id
  //   duplicates tag string61, gen(tag)
  //   local bylist "string61"
  //   * return numeric vars to collapse totals on
  //   ds, has(type numeric)
  //   * collapse totals for 'portion' towns in duplicates
  //   collapse (sum) `r(varlist)' if regexm(tname_1961,"portion") & tag > 0, by(`bylist')
  //   * sanity check on id and merge back with original dta
  //   isid string61
  //   merge 1:m string61 using `61entry'
  //   * drop duplicates and tag
  //   duplicates drop string61, force
  //   drop _merge tag

*-------------------------------------------------------------------------------
* label variables

  * metadata
  label var filename_1961 "1961 pdf file name"
  label var pdf_page_1961 "1961 pdf page number"

  * id vars
  label var isostate_1961 "1961 state iso code"
  label var scode_1961 "1961 census state code"
  label var sname_1961 "1961 census state name"
  label var sdivname_1961 "1961 subdivision name"
  label var sdname_1961 "1961 subdistrict name"
  label var sdclass_1961 "1961 subdistrict classification"
  label var dname_1961 "1961 census district name"
  label var tname_1961 "1961 town name"
  label var civic_code_1961 "1961 civic status of town"
  label var string61 "1961 matchit string, = dcode61 + tname61 + civic61"
	label var tgroup_1961 "1961 town group"
	label var tsubgroup_1961 "1961 town sub-group"

  * area & houses
    label var area_sqkm_1961 "1961 area in sq kilometres"
    label var nhouses_1961 "1961 number of houses"
    label var nhouseholds_1961 "1961 number of households"

  * town population
    label var townpop_1961 "1961 town population"
    label var townpop_m_1961 "1961 population (male)"
    label var townpop_f_1961 "1961 population (female)"
  * sc
    label var sc_t_1961 "1961 number of scheduled castes (total)"
    label var sc_m_1961 "1961 number of scheduled castes (male)"
    label var sc_f_1961 "1961 number of scheduled castes (female)"
  * st
    label var st_t_1961 "1961 number of scheduled tribes (total)"
    label var st_m_1961 "1961 number of scheduled tribes (male)"
    label var st_f_1961 "1961 number of scheduled tribes (female)"
  * literates
    label var edu_t_1961 "1961 number of literates (total)"
    label var edu_m_1961 "1961 number of literates (male)"
    label var edu_f_1961 "1961 town number of literates (female)"
  * workers
    label var workers_t_1961 "1961 number of workers (total)"
    label var workers_m_1961 "1961 number of workers (male)"
    label var workers_f_1961 "1961 number of workers (female)"
  * 1 workers
    label var wrk_1t_1961 "1961 number of category 1 workers - cultivators (total)"
    label var wrk_1m_1961 "1961 number of category 1 workers - cultivators (male)"
    label var wrk_1f_1961 "1961 number of category 1 workers - cultivators (female)"
  * 2 workers
    label var wrk_2t_1961 "1961 number of category 2 workers - agricultural labourers (total)"
    label var wrk_2m_1961 "1961 number of category 2 workers - agricultural labourers (male)"
    label var wrk_2f_1961 "1961 number of category 2 workers - agricultural labourers (female)"
  * 3 workers
    label var wrk_3t_1961 "1961 number of category 3 workers - livestock fishing etc (total)"
    label var wrk_3m_1961 "1961 number of category 3 workers - livestock fishing etc (male)"
    label var wrk_3f_1961 "1961 number of category 3 workers - livestock fishing etc (female)"
  * 4 workers
    label var wrk_4t_1961 "1961 number of category 4 workers - mining and quarrying (total)"
    label var wrk_4m_1961 "1961 number of category 4 workers - mining and quarrying (male)"
    label var wrk_4f_1961 "1961 number of category 4 workers - mining and quarrying (female)"
  * 5 workers
    label var wrk_5t_1961 "1961 number of category 5 workers - manufacturing, household industry (total)"
    label var wrk_5m_1961 "1961 number of category 5 workers - manufacturing, household industry (male)"
    label var wrk_5f_1961 "1961 number of category 5 workers - manufacturing, household industry (female)"
  * 6 workers
    label var wrk_6t_1961 "1961 number of category 6 workers - construction (total)"
    label var wrk_6m_1961 "1961 number of category 6 workers - construction (male)"
    label var wrk_6f_1961 "1961 number of category 6 workers - construction (female)"
  * 7 workers
    label var wrk_7t_1961 "1961 number of category 7 workers - trade and commerce (total)"
    label var wrk_7m_1961 "1961 number of category 7 workers - trade and commerce (male)"
    label var wrk_7f_1961 "1961 number of category 7 workers - trade and commerce (female)"
  * 8 workers
    label var wrk_8t_1961 "1961 number of category 8 workers - transport and storage (total)"
    label var wrk_8m_1961 "1961 number of category 8 workers - transport and storage (male)"
    label var wrk_8f_1961 "1961 number of category 8 workers - transport and storage (female)"
  * 9 workers
    label var wrk_9t_1961 "1961 number of category 9 workers - other services (total)"
    label var wrk_9m_1961 "1961 number of category 9 workers - other services (male)"
    label var wrk_9f_1961 "1961 number of category 9 workers - other services (female)"
  * non workers
    label var wrk_nont_1961 "1961 number of non workers (total)"
    label var wrk_nonm_1961 "1961 number of non workers (male)"
    label var wrk_nonf_1961 "1961 number of non workers (female)"
*-------------------------------------------------------------------------------

* store variable lists in local
  local numvars "area_sqkm_1961 nhouses_1961 nhouseholds_1961 townpop_1961 townpop_m_1961 townpop_f_1961 sc_t_1961 sc_m_1961 sc_f_1961 st_t_1961 st_m_1961 st_f_1961 edu_t_1961 edu_m_1961 edu_f_1961 workers_t_1961 workers_m_1961 workers_f_1961 wrk_1t_1961 wrk_1m_1961 wrk_1f_1961 wrk_2t_1961 wrk_2m_1961 wrk_2f_1961 wrk_3t_1961 wrk_3m_1961 wrk_3f_1961 wrk_4t_1961 wrk_4m_1961 wrk_4f_1961 wrk_5t_1961 wrk_5m_1961 wrk_5f_1961 wrk_6t_1961 wrk_6m_1961 wrk_6f_1961 wrk_7t_1961 wrk_7m_1961 wrk_7f_1961 wrk_8t_1961 wrk_8m_1961 wrk_8f_1961 wrk_9t_1961 wrk_9m_1961 wrk_9f_1961 wrk_nont_1961 wrk_nonm_1961 wrk_nonf_1961"
  local idvars "string61 isostate_1961 scode_1961 sname_1961 dcode_1961 dname_1961 sdivname_1961 sdname_1961 sdclass_1961 tgroup_1961 tsubgroup_1961 tname_1961 civic_code_1961 raw_name_1961"
  local meta "filename_1961 pdf_page_1961"

* keep, order and sort
  keep `meta' `numvars' `idvars'
  sort scode_1961 dcode_1961 sdivname_1961 sdname_1961 tgroup_1961 tsubgroup_1961 tname_1961 civic_code_1961

* generate id
  gen id_1961 = string(_n, "%05.0f")
  label var id_1961 "1961 town id"
  order id_1961 `meta' `idvars' `numvars'

* compress and save
  compress
	// isid string61
  isid id_1961
  save $dchb/input/town/build/1961, replace
*==============================================================================
