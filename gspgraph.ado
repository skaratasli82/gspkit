program define gspgraph, rclass
    version 14.2
    /*
      GSP SEARCH ENGINE — keywords + optional glued prefixes + optional country filter → yearly bar chart
      - Stata 14.2 compatible; regex-free; Unicode-safe (ustrpos/ustrlower)
      - kw(): space-separated keywords (whitespace-only == no filter)
      - prefix(): optional glued prefixes (antiX, anti-X, etc.)
      - countries(): exact names; multi-word OK; separators ; , |
      - Robust parsing with gettoken + asis
    */

    * ---------- Parse options ----------
    syntax , KW(string asis) ///
        [ PREFIX(string asis) ///
          COUNTRIES(string asis) ///
          FIELDS(string asis) ///
          CFIELD(name) ///
          CONDITION(string asis) ///
          YRANGE(numlist min=2 max=2) ///
          TITLE(string asis) ///
          OUTGRAPH(string asis) ///
          NOTESIZE(string asis) ///
          BAROPTS(string asis) ///
          YTITLE(string asis) ///
          XTITLE(string asis) ///
          RELATIVE ///
          RELATIVELABOR ///
          MA ///
          GEN(name) ///  <--- NEW: create 0/1 match flag
          STRICT ///
          DEBUG ]

    * ---------- Ensure core variables (YEAR) ----------
    local yearv year
    capture confirm numeric variable year
    if _rc {
        tempvar yearnum
        capture gen double `yearnum' = real(year)
        if _rc { di as err "variable {bf:year} not numeric/coercible"; exit 109 }
        local yearv `yearnum'
    }

    * ---------- Sum variable selector ----------
    * Priority: relativelabor -> glu_rel ; else relative -> gsp_rel ; else gsp
    local basevar = cond("`relativelabor'" != "", "glu_rel", ///
                    cond("`relative'" != "", "gsp_rel", "gsp"))

    capture confirm variable `basevar'
    if _rc {
        di as err "variable {bf:`basevar'} not found"
        exit 111
    }
    local gspv `basevar'
    capture confirm numeric variable `gspv'
    if _rc {
        tempvar gspnum
        capture gen double `gspnum' = real(`basevar')
        if _rc {
            di as err "variable {bf:`basevar'} not numeric/coercible"
            exit 109
        }
        local gspv `gspnum'
    }

    * ---------- Defaults ----------
    if `"`fields'"'   == "" local fields "title abstract actors actiontype demands notes"
    if `"`yrange'"'   == "" local yrange "1850 2020"
    if `"`title'"'    == "" local title  "Global Social Protest - Selected Variables"
    if `"`ytitle'"'   == "" local ytitle "Frequency of News Reports"
    if `"`xtitle'"'   == "" local xtitle "Year"
    if `"`notesize'"' == "" local notesize "tiny"

    * STRICT helpers
    local has_coded 0
    capture confirm variable coded_b
    if !_rc local has_coded 1
    local has_online 0
    capture confirm variable online
    if !_rc local has_online 1

    * ---------- Country field default ----------
    if `"`cfield'"' == "" {
        capture confirm variable std_cowname
        if !_rc local cfield std_cowname
        else {
            capture confirm variable country
            if _rc { di as err "neither {bf:std_cowname} nor {bf:country} found"; exit 111 }
            local cfield country
        }
    }

    * ---------- Treat whitespace-only inputs as empty ----------
    if length(trim(`"`kw'"'))==0         local kw ""
    if length(trim(`"`countries'"'))==0  local countries ""

    * ---------- Parse prefixes once (space-separated) ----------
    local PFXTOK ""
    quietly {
        local rest `"`prefix'"'
        while `"`rest'"' != "" {
            gettoken p rest : rest
            if `"`p'"' != "" local PFXTOK `"`PFXTOK' `p'"'
        }
    }

    * ---------- Build keyword tokens (trim each; add glued prefixes) ----------
    local no_kw 1
    local TOK ""
    quietly {
        local rest `"`kw'"'
        while `"`rest'"' != "" {
            gettoken w rest : rest
            local w : display trim(`"`w'"')
            if `"`w'"' != "" {
                local no_kw 0
                local TOK `"`TOK' `w'"'
                foreach p of local PFXTOK {
                    local TOK `"`TOK' `p'`w' `p'-`w'"'
                }
            }
        }
    }

    * ---------- Keyword flag ----------
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

    * ---------- Country flag (multi-word + separators ; , |) ----------
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
            local rest `"`raw'"'
            while `"`rest'"' != "" {
                gettoken u rest : rest
                local u : subinstr local u "'" "", all
                if `"`u'"' != "" replace `ctryflag' = 1 if `ctrynorm' == ustrlower(strtrim(`"`u'"'))
            }
        }
        if `any_cty'==0 replace `ctryflag' = 1
    }

    * ---------- Final condition (auto-AND flags; case-insensitive with lower()) ----------
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
        local condL = lower("`_cond'")
        if strpos("`condL'","kwflag")==0  local _cond "`_cond' & KWFLAG"
        local condL = lower("`_cond'")
        if strpos("`condL'","ctyflag")==0 local _cond "`_cond' & CTYFLAG"
        local condition `"`_cond'"'
    }
    local condition = subinstr(`"`condition'"', "KWFLAG", "`kwflag'", .)
    local condition = subinstr(`"`condition'"', "CTYFLAG", "`ctryflag'", .)

    * ---------- Optional: generate 0/1 match flag ----------
    if `"`gen'"' != "" {
        tempvar _match
        gen byte `_match' = (`condition')
        capture confirm new variable `gen'
        if _rc==0 {
            gen byte `gen' = 0
        }
        else {
            capture confirm variable `gen'
            if _rc {
                di as err "invalid {bf:gen()} name"
                exit 198
            }
            capture confirm numeric variable `gen'
            if _rc {
                di as err "existing variable {bf:`gen'} is not numeric; cannot overwrite"
                exit 109
            }
            replace `gen' = 0
        }
        replace `gen' = 1 if `_match'
        label variable `gen' "GSP match flag (1=meets final condition)"
    }

    * ---------- Aggregate per year ----------
    tempvar incl gsum
    gen double `incl' = cond(`condition', `gspv', .)
    bysort `yearv': egen double `gsum' = total(`incl')

    * ---------- Optional: centered 3-year moving average ----------
    local plotv `gsum'
    if "`ma'" != "" {
        preserve
        tempfile _ma
        keep `yearv' `gsum'
        duplicates drop `yearv', force
        sort `yearv'
        tsset `yearv'
        gen double _ma3 = (L.`gsum' + `gsum' + F.`gsum')/3
        keep `yearv' _ma3
        save "`_ma'", replace
        restore
        merge m:1 `yearv' using "`_ma'", nogenerate
        tempvar gsum_ma
        gen double `gsum_ma' = _ma3
        drop _ma3
        local plotv `gsum_ma'
    }

    * ---------- Notes (cap list lengths) ----------
    local N 15

    * Keywords note
    local n_kw 0
    quietly {
        local rest `"`kw'"'
        while `"`rest'"' != "" {
            gettoken w rest : rest
            local w : display trim(`"`w'"')
            if `"`w'"' != "" local ++n_kw
        }
    }
    if `no_kw' {
        local n_kwd "all"
        local kw_disp "ALL"
    }
    else {
        local rest `"`kw'"'
        local i 0
        local kw_disp ""
        while `"`rest'"' != "" {
            gettoken w rest : rest
            local w : display trim(`"`w'"')
            if `"`w'"' != "" {
                local ++i
                if `i'<=`N' local kw_disp "`kw_disp', `w'"
            }
        }
        local kw_disp = subinstr("`kw_disp'", ", ", "", 1)
        if `n_kw' > `N' local kw_disp "`kw_disp' (+`=`n_kw'-`N'' more)"
        local n_kwd `n_kw'
    }

    * Countries note
    local n_ctry 0
    quietly {
        local rest `"`countries'"'
        while `"`rest'"' != "" {
            gettoken c rest : rest
            if `"`c'"' != "" local ++n_ctry
        }
    }
    if `"`countries'"'=="" {
        local n_ctryd "all"
        local ctry_disp "ALL"
    }
    else {
        local rest `"`countries'"'
        local k 0
        local ctry_disp ""
        while `"`rest'"' != "" {
            gettoken c rest : rest
            if `"`c'"' != "" {
                local ++k
                local cclean = subinstr(`"`c'"',`"""',"",.)
                if `k'<=`N' local ctry_disp "`ctry_disp', `cclean'"
            }
        }
        local ctry_disp = subinstr("`ctry_disp'", ", ", "", 1)
        if `n_ctry' > `N' local ctry_disp "`ctry_disp' (+`=`n_ctry'-`N'' more)"
        local n_ctryd `n_ctry'
    }

    * ---------- Axis range ----------
    tokenize `"`yrange'"'
    local ylo `1'
    local yhi `2'

    * ---------- Graph ----------
    twoway bar `plotv' `yearv' if inrange(`yearv', `ylo', `yhi'), ///
        barw(0.8) fcolor(navy) lcolor(navy) lwidth(thin) ///
        xlabel(`ylo'(20)`yhi', angle(45) labsize(small)) ///
        ylabel(, format(%9.0fc) grid glcolor(gs12) glpattern(solid)) ///
        ytitle(`ytitle') ///
        xtitle(`xtitle') ///
        title(`"`title'"') legend(off) ///
        graphregion(color(white)) plotregion(margin(medium)) ///
        note("Condition: `condition'" "Keywords (`n_kwd'): `kw_disp'" ///
             "Countries (`n_ctryd'): `ctry_disp'", span size(`notesize') color(gs8)) ///
        `baropts'

    if `"`outgraph'"' != "" graph export `"`outgraph'"', replace

    * ---------- Debug ----------
    if "`debug'" != "" {
        di as txt "DEBUG: tokens(KW+prefix) = " as res "`TOK'"
        di as txt "DEBUG: countries(raw) = " as res `"`countries'"'
        di as txt "DEBUG: condition = " as res `"`condition'"'
        quietly count if `kwflag'
        di as txt "DEBUG: kw matches = " as res r(N)
        quietly count if `ctryflag'
        di as txt "DEBUG: ctry matches = " as res r(N)
        quietly count if `condition'
        di as txt "DEBUG: rows used = " as res r(N)
        di as txt "DEBUG: base var used = " as res "`basevar'"
        di as txt "DEBUG: moving average = " as res cond("`ma'"!="","MA(3yr)","off")
        if `"`gen'"' != "" {
            di as txt "DEBUG: generated flag var = " as res "`gen'"
        }
    }

    * ---------- Return ----------
    return local fields   "`fields'"
    return local cfield   "`cfield'"
    return local condition `"`condition'"'
    return local title    `"`title'"'
    return local ytitle   `"`ytitle'"'
    return local xtitle   `"`xtitle'"'
end
