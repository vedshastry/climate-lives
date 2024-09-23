* Objective: use unified crosswalk dta to create a wide panel of towns
*-------------------------------------------------------------------------------

	* initiate tempfile for build
	clear
	tempfile centowns
	save `centowns', emptyok replace

	* use crosswalk dta
	use "$dchb/input/town/build/townbridge_all", clear

	* keep required info
	keep idchain id_* tsplit_* tmerge_* status* detown*

		forval y = 1961(10)2011 {

			* merge using town id for census year
				* master = crosswalk, using = digitised census data
				* assert no unmatched observations from using
			merge m:1 	id_`y' ///
						using "$dchb/input/town/build/`y'" ///
						, gen(_m`y')
						// keep(1 3)

			* compress and save
			compress
			save `centowns', replace
		}

	* Use joined data

		use `centowns', clear


		foreach var of varlist id_* {

			clonevar 	x`var' = `var'
			replace 	x`var' = "xxxxx" if mi(x`var')

		}

			cap drop idchain
			egen 	idchain = concat(xid_*) , p("-")
			order 	idchain
			isid 	idchain

		* create ID
		egen 	xid = group(idchain)
		isid 	xid

		* order/sort
		order 	xid
		sort 	xid

*-------------------------------------------------------------------------------

	* sanity check
	isid idchain
	compress
	cap mkdir "$b_output/dchb_town"
	save "$b_output/dchb_town/01_import_census_towns.dta", replace

*-------------------------------------------------------------------------------

	// use "$b_output/dchb_dchb_town/01_import_census_towns.dta", clear

*-------------------------------------------------------------------------------
*** End
