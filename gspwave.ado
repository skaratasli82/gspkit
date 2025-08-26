program define gspwave, rclass
    version 14.2
    /*
      GSP → Excel export (with wave flags, no graph)
      Outputs to Excel:
        - by_year : year | count | TS_wave | WLG_wave
        - meta    : key options/inputs used (+ overall_mean)

      Wave definitions (computed within yrange window):
        TS_wave  = 1 if count(t) > 1.5 * avg(count[t-1..t-5])
        WLG_wave = 1 if TS_wave==1 & count(t) > overall mean (in window)
    */

    * ---------- Parse options ----------
    syntax using/ , KW(string asis) ///
        [ PREFIX(string asis) ///
          COUNTRIES(string asis) ///
          FIELDS(string asis) ///
          CFIELD(name) ///
          CONDITION(string asis) ///
          YRANGE(numlist min=2 max=2) ///
          RELATIVE ///
          RELATIVELABOR ///
          STRICT ///
          DEBUG ]

    * ---------- Ensure core variables ----------
    local yearv year
    capture confirm numeric variable year
    if _rc {
        tempvar yearnum
        capture gen double `yearnum' = real(year)
        if _rc { di as err "variable {bf:year} not numeric/coercible"; exit 109 }
        local yearv `yearnum'
    }

    * ---------- Sum variable selector (default gsp; relative→gsp_rel; relativelabor→glu_rel) ----------
    local basevar gsp
    if "`relativelabor'" != "" local basevar glu_rel
    else if "`relative'" != "" local basevar gsp_rel

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
        if _rc { di as err "variable {bf:`basevar'} not numeric/coercible"; exit 109 }
        local gspv `gspnum'
    }

    * ---------- Defaults ----------
    if `"`fields'"'  == "" local fields "title abstract actors actiontype demands notes"
    if `"`yrange'"'  == "" local yrange "1850 2020"

    * STRICT helpers (match your gsp2xlsx behavior)
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
    local PFXTOK
    quietly {
        local rest `"`prefix'"'
        while `"`rest'"' != "" {
            gettoken p rest : rest
            if `"`p'"' != "" local PFXTOK `PFXTOK' `p'
        }
    }

    * ---------- Build keyword tokens (robust: no compound quotes) ----------
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
                foreach p of local PFXTOK {
                    local add1 `p'`w'
                    local add2 `p'-`w'
                    local TOK : list TOK | add1
                    local TOK : list TOK | add2
                }
            }
        }
    }

    * ---------- Keyword flag (OR across fields & tokens) ----------
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
            local rest2 `"`raw'"'
            while `"`rest2'"' != "" {
                gettoken u rest2 : rest2
                local u : subinstr local u "'" "", all
                if `"`u'"' != "" replace `ctryflag' = 1 if `ctrynorm' == ustrlower(strtrim(`"`u'"'))
            }
        }
        if `any_cty'==0 replace `ctryflag' = 1
    }

    * ---------- Final condition (auto-AND flags) ----------
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

    * ---------- Y-range ----------
    tokenize `"`yrange'"'
    local ylo `1'
    local yhi `2'
    if `ylo' > `yhi' {
        local tmp = `ylo'
        local ylo = `yhi'
        local yhi = `tmp'
    }

    * ---------- Build by_year counts (hits) ----------
    tempfile _counts _spine _merged
    tempname overall

    preserve
        keep if `condition'
        keep `yearv' `gspv'
        drop if missing(`yearv')
        quietly replace `yearv' = floor(`yearv')
        keep if inrange(`yearv', `ylo', `yhi')

        * count = sum(selected measure) after filters
        collapse (sum) count=`gspv', by(`yearv')
        rename `yearv' year
        sort year
        save `"_counts"', replace
    restore

    * ---------- Create full year spine and merge (zero-fill) ----------
    preserve
        clear
        set obs `=`yhi'-`ylo'+1'
        gen int year = `ylo' + _n - 1
        save `"_spine"', replace

        use `"_spine"', clear
        merge 1:1 year using `"_counts"', nogenerate
        replace count = 0 if missing(count)

        * ---------- Compute overall mean within window ----------
        quietly summarize count
        scalar `overall' = r(mean)

        * ---------- Rolling mean of preceding 5 years ----------
        sort year
        tsset year, yearly
        forvalues k=1/5 {
            gen double count_L`k' = L`k'.count
        }
        egen double mean5 = rowmean(count_L1 count_L2 count_L3 count_L4 count_L5)

        gen byte TS_wave  = (count > 1.5*mean5) if !missing(mean5)
        replace TS_wave   = 0 if missing(TS_wave)

        gen byte WLG_wave = (TS_wave==1 & count > scalar(`overall'))
        replace WLG_wave  = 0 if missing(WLG_wave)

        drop count_L1 count_L2 count_L3 count_L4 count_L5

        * ---------- Display nicely in Stata ----------
        di as text _newline "{hline 72}"
        di as result "By-year counts with wave flags (" `ylo' "–" `yhi' ")"
        di as text    "Overall mean in window: " %9.3f scalar(`overall')
        di as text    "Measure used: `basevar'"
        di as text "{hline 72}"
        list year count TS_wave WLG_wave, noobs
        di as text "{hline 72}"

* ---------- Summarize wave years on console (compress consecutive years) ----------
quietly levelsof year if TS_wave==1, local(ts_years)
quietly levelsof year if WLG_wave==1, local(wlg_years)

* Helper to compress a space-separated year list into ranges
* (single years stay as-is; runs like 2012 2013 2014 -> 2012-2014)
local ts_disp "None"
if "`ts_years'" != "" {
    local rest "`ts_years'"
    local start ""
    local prev  ""
    local ts_disp ""
    while "`rest'" != "" {
        gettoken y rest : rest
        if "`start'" == "" {
            local start `y'
            local prev  `y'
        }
        else {
            if (`y' == `prev' + 1) {
                local prev `y'
            }
            else {
                if (`start' == `prev') local ts_disp "`ts_disp'`start', "
                else                    local ts_disp "`ts_disp'`start'-`prev', "
                local start `y'
                local prev  `y'
            }
        }
    }
    if (`start' == `prev') local ts_disp "`ts_disp'`start'"
    else                    local ts_disp "`ts_disp'`start'-`prev'"
}

local wlg_disp "None"
if "`wlg_years'" != "" {
    local rest "`wlg_years'"
    local start ""
    local prev  ""
    local wlg_disp ""
    while "`rest'" != "" {
        gettoken y rest : rest
        if "`start'" == "" {
            local start `y'
            local prev  `y'
        }
        else {
            if (`y' == `prev' + 1) {
                local prev `y'
            }
            else {
                if (`start' == `prev') local wlg_disp "`wlg_disp'`start', "
                else                    local wlg_disp "`wlg_disp'`start'-`prev', "
                local start `y'
                local prev  `y'
            }
        }
    }
    if (`start' == `prev') local wlg_disp "`wlg_disp'`start'"
    else                    local wlg_disp "`wlg_disp'`start'-`prev'"
}

di as text "{hline 72}"
di as result "Major Waves (Tilly/Shorter TS method): " as text "`ts_disp'"
di as result "Major Waves (World Labor Group WLG method): " as text "`wlg_disp'"
di as text "{hline 72}"


    
* ---------- Export by_year (Year as "YYYY" text; no renames, no extra preserve) ----------
tempvar year_txt
gen str4 `year_txt' = string(year, "%04.0f")
label variable `year_txt' "year"

export excel `year_txt' count TS_wave WLG_wave using `"`using'"', ///
    sheet("by_year") firstrow(varlabels) replace




* ---------- Meta sheet (no nested preserve) ----------
clear
set obs 10
gen str20   key = ""
gen str2045 val = ""

replace key = "kw"           in 1
replace val = `"`kw'"'       in 1
replace key = "prefix"       in 2
replace val = `"`prefix'"'   in 2
replace key = "countries"    in 3
replace val = `"`countries'"' in 3
replace key = "fields"       in 4
replace val = `"`fields'"'   in 4
replace key = "cfield"       in 5
replace val = `"`cfield'"'   in 5
replace key = "condition"    in 6
replace val = `"`condition'"' in 6
replace key = "yrange"       in 7
replace val = "`ylo'-`yhi'"  in 7
replace key = "overall_mean" in 8
replace val = string(scalar(`overall'),"%9.3f") in 8
replace key = "measure"      in 9
replace val = "`basevar'"    in 9
replace key = "generated"    in 10
replace val = "`c(current_date)' `c(current_time)'" in 10

export excel key val using `"`using'"', sheet("meta") firstrow(variables) sheetreplace


        * ---------- Returns ----------
        return scalar overall_mean = scalar(`overall')
        return scalar ylo = `ylo'
        return scalar yhi = `yhi'
        return local  measure = "`basevar'"
    restore

    * ---------- Debug (optional) ----------
    if "`debug'" != "" {
        di as txt "DEBUG: tokens(KW+prefix) = " as res "`TOK'"
        di as txt "DEBUG: countries(raw) = " as res `"`countries'"'
        di as txt "DEBUG: condition(final) = " as res `"`condition'"'
        di as txt "DEBUG: measure used = " as res "`basevar'"
        quietly count if `kwflag'
        di as txt "DEBUG: kw matches = " as res r(N)
        quietly count if `ctryflag'
        di as txt "DEBUG: ctry matches = " as res r(N)
        quietly count if `condition'
        di as txt "DEBUG: rows used (pre-collapse, in yrange) = " as res r(N)
    }
end
