program define gspstackh, rclass
    version 14.2
    syntax varlist(min=1 numeric) [if] [in], ///
        [ YEARVAR(name) YRANGE(numlist min=2 max=2) ///
          TITLE(string asis) NOTE(string asis) NOTESIZE(string) ///
          OUTGRAPH(string asis) STRICT DEBUG ///
          XOPTS(string asis) ]

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
        foreach v of local varlist {
            capture assert inlist(`v',0,1) | missing(`v')
            if _rc {
                di as err "Variable {bf:`v'} is not 0/1 (or missing)."
                exit 9
            }
        }
    }

    preserve
        marksample touse
        keep if `touse'

        * yrange filter (optional)
        if ("`yrange'"!="") {
            tokenize "`yrange'"
            local ymin `1'
            local ymax `2'
            keep if inrange(`yearv', `ymin', `ymax')
        }

        * keep needed vars; missing→0
        keep `yearv' `varlist'
        foreach v of local varlist {
            replace `v' = 0 if missing(`v')
        }

        * collapse to annual sums
        collapse (sum) `varlist', by(`yearv')

        * no data guard
        count
        if r(N)==0 {
            di as err "No observations after filters; nothing to plot."
            restore
            exit 2000
        }

        * ===== store only the years that exist pre-padding (for clean xlabels) =====
        levelsof `yearv', local(_xlab_present)

        * min/max years
        summarize `yearv', meanonly
        local miny = r(min)
        local maxy = r(max)
        if ("`yrange'"!="") {
            local miny = `ymin'
            local maxy = `ymax'
        }
        if (`maxy' < `miny') {
            di as err "Invalid year range (min>max)."
            restore
            exit 198
        }

        * save collapsed, build full year sequence, merge (pad missing years)
        tempfile collapsed allyears
        save `collapsed', replace

        clear
        set obs `= `maxy' - `miny' + 1'
        gen `yearv' = `miny' + _n - 1
        save `allyears', replace

        use `allyears', clear
        merge 1:1 `yearv' using `collapsed', nogenerate
        foreach v of local varlist {
            replace `v' = 0 if missing(`v')
        }
        sort `yearv'

        * =========================
        * >>> 100% SHARE TRANSFORM
        * =========================
        egen double _total = rowtotal(`varlist')
        foreach v of local varlist {
            gen double p_`v' = cond(_total>0, 100*`v'/_total, 0)
        }

        * ---- stacked bands (on percentages) ----
        tempvar base
        gen double `base' = 0
        local i = 0
        local twplots ""
        local ordlist ""
        local labopts ""

        foreach v of local varlist {
            local ++i
            gen double hi_`i' = `base' + p_`v'
            gen double lo_`i' = `base'
            replace `base' = hi_`i'

            local lbl : variable label `v'
            if "`lbl'"=="" local lbl "`v'"
            local lbl = subinstr("`lbl'", `"""', `"""""', .)

            local twplots `"`twplots' (rarea lo_`i' hi_`i' `yearv', lwidth(none))"'
            local ordlist `ordlist' `i'
            local labopts `labopts' label(`i' "`lbl'")
        }

        * titles/notes (escape quotes)
        local ttl `"`title'"'
        if "`ttl'" != "" {
            local ttl = subinstr("`ttl'", `"""', `"""""', .)
            local ttlopt `"`"title("`ttl'")'"''
        }
        else local ttlopt ""

        local nto ""
        if ("`note'"!="") {
            local ntxt = subinstr("`note'", `"""', `"""""', .)
            if ("`notesize'"!="") local nto `"note("`ntxt'", size(`notesize'))"'
            else                  local nto `"note("`ntxt'")"'
        }

        * ---- graph: 0–100 fixed scale for percent shares ----
        local xlo = `= `miny' - 0.5'
        local xhi = `= `maxy' + 0.5'

        twoway `twplots', `ttlopt' ///
            xscale(range(`xlo' `xhi')) ///
            yscale(range(0 100)) ///
            ytitle("Percent of annual total") xtitle("Year") ///
            xlabel(`_xlab_present') ///
            legend(order(`ordlist') `labopts') `nto' ///
            plotregion(margin(zero)) graphregion(color(white)) ///
            ylabel(0(20)100, angle(horizontal)) name(GSPSTACKH, replace) ///
            `xopts'

        * returns
        return scalar ymin = `miny'
        return scalar ymax = `maxy'
        return local year = "`yearv'"
        return local vars = "`varlist'"
    restore
end
