********************************************************************************
* Checksum calculation program
********************************************************************************

cap prog drop dchb_check
prog def dchb_check

	* !dchb_check (v1)
	* Sep 2024
    * Written by: Ved Shastry

		/*
			Input
				- Checksum name (for variable naming)
				- LHS variables (aggregate, max 1)
				- RHS variables (categories)
				- Threshold for percentage difference
			1. Calculate checksums for LHS = RHS
			2. Calculate absolute and percentage diff -if- check = 0
				- Set LHS = RHS if within 10% difference
				- Set LHS and RHS to missing otherwise
		*/

	syntax [if] , chkname(string) lhs(varlist max=1) rhs(varlist) Threshold(real) [return missing]

		* chkname: check name
		* lhs: 1 variable on LHS
		* rhs: sum variable on RHs
		* threshold: normalized range for imputation [0,1]
		* return: whether to keep vars or not

	qui {

	nois di "Running checksums using `threshold' range"
	nois di "LHS vars: `lhs'"
	nois di "RHS vars: `rhs'"

	egen 	rnm_`chkname'  = rownonmiss(`rhs') // Calculate row non missing indicators of RHS

	mvencode 	`rhs' 	if rnm_`chkname' > 0 , mv(0) override // RHS missings to 0 if at least 1 RHS exists

	egen 	rsum_`chkname'  = rowtotal(`rhs') , m // Calculate Sum of RHS

	* LHS = RHS total if LHS missing but at least 1 RHS exists
	replace 	`lhs' = rsum_`chkname' 		if rnm_`chkname' > 0 & mi(`lhs')

	* Calculate LHS-RHS difference and percentage
	gen 	byte 	diff_`chkname' = (`lhs' - rsum_`chkname') if rnm_`chkname' > 0  // LHS - RHS
	gen 	float 	pcdiff_`chkname' = diff_`chkname'/`lhs'  // % diff

	* Replace LHS = RHS if difference is within threshold %
	replace `lhs' = rsum_`chkname' if inrange(pcdiff_`chkname',-`threshold',`threshold')

	* Calculate final checksum
	gen 	byte chk_`chkname'  = (`lhs' == rsum_`chkname')  // Check LHS = RHS

	sum  	chk_`chkname'
	local 	pct : di round(r(mean)*100, 0.1) %9.2f
	nois di "Checks complete. See checks in chk_`chkname' (`pct'% OK)"

	* Drop calculated vars unless return specified
	if "`return'" == "" {
		drop 	rnm_`chkname' rsum_`chkname' diff_`chkname' pcdiff_`chkname'
	}
	else {
		nois di "Vars in: rnm_`chkname' rsum_`chkname' diff_`chkname' pcdiff_`chkname'"
	}

	* Set vars to missing if specified
	if "`missing'" == "" {
		foreach var of varlist `lhs' `rhs' {
			replace `var' = .m 		if chk_`chkname' == 0
		}
	}
	else {
	}

	/* end quietly */
	}

end
