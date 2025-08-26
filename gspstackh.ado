program define gspstackh, rclass
    version 14.2
    syntax varlist(min=1 numeric) [if] [in], ///
        [ YEARVAR(name) YRANGE(numlist min=2 max=2) ///
          TITLE(string asis) NOTE(string asis) NOTESIZE(string) ///
          OUTGRAPH(string asis) STRICT DEBUG XOPTS(string asis) ]

    * ---- year variable ----
    if ("`yearvar'"=="") {
        capture confirm variable year
        if _rc {
            di as err "No year variable found. Provide {bf:yearvar()}."
            exit 111
        }
        local yearv year
    }
    else {
        capture confirm variable `yearvar'
        if _rc {
            di as err "yearvar(`yearvar') not found."
            exit 111
        }
        local yearv `yearvar'
    }
    capture confirm numeric variable `yearv'
    if _rc {
        di as err "`yearv' must be numeric (integer years)."
        exit 109
    }

    * ---- strict 0/1 (optional) ----
    if ("`strict'"!="") {
        foreach v of varlist `varlist' {
            capture assert inlist(`v',0,1,.) 
            if _rc {
                di as err "`v' has non-binary values; use option -strict- only with 0/1 vars."
                exit 109
            }
        }
    }

    * ---- apply if/in filter ----
    preserve
    keep `if' `in' `yearv' `varlist'
    drop if missing(`yearv')

    * ---- restrict to yrange ----
    if ("`yrange'"!="") {
        local y1 : word 1 of `yrange'
        local y2 : word 2 of `yrange'
        keep if inrange(`yearv',`y1',`y2')
    }
    quietly summarize `yearv', meanonly
    local ymin = r(min)
    local ymax = r(max)

    * ---- collapse to yearly sums ----
    collapse (sum) `varlist', by(`yearv')

    * ---- pad missing years ----
    rangejoin `yearv' = `ymin'/`ymax', by(`yearv')
    foreach v of varlist `varlist' {
        replace `v' = 0 if missing(`v')
    }

    * ---- convert to percent shares ----
    egen total = rowtotal(`varlist')
    foreach v of varlist `varlist' {
        gen double p_`v' = 100*`v'/total
    }

    * ---- debugging option ----
    if ("`debug'"!="") {
        list `yearv' total p_*
    }

    * ---- graph ----
    twoway area ///
        `=subinstr("`varlist'"," ", " ", .)' ///
        `yearv', ///
        stack ///
        ylabel(0(20)100, angle(0)) ///
        xtitle("Year") ytitle("Percent") ///
        `title' `note' `notesize' ///
        `xopts'

    * ---- outgraph ----
    if ("`outgraph'"!="") {
        graph export "`outgraph'", replace
    }

    * ---- returned ----
    return local vars "`varlist'"
    return local year "`yearv'"
    return scalar ymin = `ymin'
    return scalar ymax = `ymax'

    restore
end
