program define gsp2rows, rclass
    version 14.2
    /*
      Export FILTERED ROWS to Excel, writing to the default sheet (Sheet1).
      - Same filters as gspsearch (kw/prefix/countries/condition/yrange)
      - Avoids sheet() completely to dodge Stata 14.2 quirks
      - Downcasts strL → str2045 (trim first) so export excel won’t error
      - Optional keepvars() to limit columns
    */

    syntax using/ , KW(string asis) ///
        [ PREFIX(string asis) ///
          COUNTRIES(string asis) ///
          FIELDS(string asis) ///
          CFIELD(name) ///
          CONDITION(string asis) ///
          YRANGE(numlist min=2 max=2) ///
          KEEPVARS(varlist) ///
          STRICT ///
          DEBUG ]

    * Defaults
    if `"`fields'"'   == "" local fields "title abstract actors actiontype demands notes"
    if `"`yrange'"'   == "" local yrange "1850 2020"

    * Ensure core vars
    local yearv year
    capture confirm numeric variable year
    if _rc {
        tempvar yearnum
        capture gen double `yearnum' = real(year)
        if _rc { di as err "variable {bf:year} not numeric/coercible"; exit 109 }
        local yearv `yearnum'
    }

    * STRICT helpers
    local has_coded 0
    capture confirm variable coded_b
    if !_rc local has_coded 1
    local has_online 0
    capture confirm variable online
    if !_rc local has_online 1

    * Country field default
    if `"`cfield'"' == "" {
        capture confirm variable std_cowname
        if !_rc local cfield std_cowname
        else {
            capture confirm variable country
            if _rc { di as err "neither {bf:std_cowname} nor {bf:country} found"; exit 111 }
            local cfield country
        }
    }

    * Treat whitespace-only inputs as empty
    if length(trim(`"`kw'"'))==0         local kw ""
    if length(trim(`"`countries'"'))==0  local countries ""

    * Prefix tokens
    local PFXTOK
    quietly {
        local rest `"`prefix'"'
        while `"`rest'"' != "" {
            gettoken p rest : rest
            if `"`p'"' != "" local PFXTOK `PFXTOK' `p'
        }
    }

    * Build keyword tokens
    local no_kw 1
    local TOK
    quietly {
        local rest `"`kw'"'
        while `"`rest'"' != "" {
            gettoken w rest : rest
            local w : display trim(`"`w'"')
            local w : subinstr local w `"""' "", all
            if `"`w'"' != "" {
                local no_kw 0
                local TOK : list TOK | w
                if `"`PFXTOK'"' != "" {
                    foreach p of local PFXTOK {
                        local add1 `p'`w'
                        local add2 `p'-`w'
                        local TOK : list TOK | add1
                        local TOK : list TOK | add2
                    }
                }
            }
        }
    }

    * Keyword flag
    tempvar kwflag
    if `no_kw' {
        gen byte `kwflag' = 1
    }
    else {
        gen byte `kwflag' = 0
        foreach f of local fields {
            capture confirm variable `f'
            if _rc continue
            capture confirm string variable `f'
            local isstr = cond(_rc, 0, 1)
            quietly {
                local rest `"`TOK'"'
                while `"`rest'"' != "" {
                    gettoken t rest : rest
                    local t : display trim(`"`t'"')
                    if `"`t'"' == "" continue
                    if `isstr' {
                        replace `kwflag' = 1 if `kwflag'==0 ///
                            & ustrpos(ustrlower(`f'), ustrlower(`"`t'"'))>0
                    }
                    else {
                        replace `kwflag' = 1 if `kwflag'==0 ///
                            & ustrpos(ustrlower(string(`f')), ustrlower(`"`t'"'))>0
                    }
                }
            }
        }
    }

    * Country flag
    tempvar ctryflag ctrynorm
    capture confirm string variable `cfield'
    if !_rc gen strL `ctrynorm' = strtrim(ustrlower(`cfield'))
    else    gen strL `ctrynorm' = cond(missing(`cfield'),"", strtrim(ustrlower(string(`cfield'))))

    local raw `"`countries'"'
    local raw : subinstr local raw "|" ";", all
    local raw : subinstr local raw "," ";", all
    local raw : subinstr local raw `"""' "", all

    gen byte `ctryflag' = 0
    local any_cty 0
    if `"`raw'"' == "" {
        replace `ctryflag' = 1
    }
    else if strpos(`"`raw'"', ";") {
        local s `"`raw'"'
        while `"`s'"' != "" {
            gettoken piece s : s , parse(";")
            if `"`piece'"' == ";" continue
            local t `"`piece'"'
            local t : subinstr local t "'" "", all
            if `"`t'"' != "" {
                replace `ctryflag' = 1 if `ctrynorm' == ustrlower(strtrim(`"`t'"'))
                local any_cty 1
            }
        }
        if `any_cty'==0 replace `ctryflag' = 1
    }
    else {
        local t `"`raw'"'
        local t : subinstr local t "'" "", all
        if `"`t'"' != "" {
            replace `ctryflag' = 1 if `ctrynorm' == ustrlower(strtrim(`"`t'"'))
            local any_cty 1
        }
        quietly {
            local rest2 `"`raw'"'
            while `"`rest2'"' != "" {
                gettoken u rest2 : rest2
                local u : subinstr local u "'" "", all
                if `"`u'"' != "" replace `ctryflag' = 1 if `ctrynorm' == ustrlower(strtrim(`"`u'"'))
            }
        }
        if `any_cty'==0 replace `ctryflag' = 1
    }

    * Final condition
    if `"`condition'"' == "" {
        if "`strict'" != "" {
            if `has_coded' & `has_online' local condition "coded_b==1 & online==0 & KWFLAG & CTYFLAG"
            else if `has_coded'          local condition "coded_b==1 & KWFLAG & CTYFLAG"
            else if `has_online'         local condition "online==0 & KWFLAG & CTYFLAG"
            else                         local condition "KWFLAG & CTYFLAG"
        }
        else local condition "KWFLAG & CTYFLAG"
    }
    else {
        local _cond `"`condition'"'
        if strpos(lower("`_cond'"),"kwflag")==0  local _cond "`_cond' & KWFLAG"
        if strpos(lower("`_cond'"),"ctyflag")==0 local _cond "`_cond' & CTYFLAG"
        local condition `"`_cond'"'
    }
    local condition = subinstr(`"`condition'"', "KWFLAG", "`kwflag'", .)
    local condition = subinstr(`"`condition'"', "CTYFLAG", "`ctryflag'", .)

    * Axis range
    tokenize `"`yrange'"'
    local ylo `1'
    local yhi `2'

    * ---- Export rows (NO sheet() to avoid 14.2 bug) ----
    preserve
        keep if `condition'
        keep if inrange(`yearv', `ylo', `yhi')
        count
        return scalar N_rows = r(N)

        if "`keepvars'" != "" {
            capture unab _keep : `keepvars'
            if !_rc keep `_keep'
        }

        capture drop `kwflag' `ctryflag'
        capture confirm variable year
        if !_rc order year, first

        * strL → str2045 (trim first)
        quietly ds, has(type strL)
        local __strLvars `r(varlist)'
        if "`__strLvars'" != "" {
            foreach v of local __strLvars {
                capture replace `v' = substr(`v',1,2045) if length(`v')>2045
                capture recast str2045 `v'
            }
        }

        export excel using `"`using'"', firstrow(variables) replace
    restore

    * returns
    return local condition  `"`condition'"'
end
