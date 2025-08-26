{smcl}
{* *! version 1.0 23aug2025}{...}
{vieweralsosee "gsp2xlsx" "help gsp2xlsx"}{...}
{title:Title}

{phang}
{cmd:gspwave} — Search + yearly counts + “wave” flags, with Excel export

{title:Syntax}

{p 8 15 2}
{cmd:gspwave} {it:using} {cmd:,}
{cmd:kw(}{it:string}{cmd:)}
[{cmd:prefix(}{it:string}{cmd:)}
{cmd:countries(}{it:string}{cmd:)}
{cmd:fields(}{it:varlist}{cmd:)}
{cmd:cfield(}{it:name}{cmd:)}
{cmd:condition(}{it:exp}{cmd:)}
{cmd:yrange(}{it:min max}{cmd:)}
{cmd:strict}
{cmd:debug}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt using/}}Excel file to write (e.g., {it:"results/gsp_output.xlsx"}){p_end}
{synopt:{opt kw(str)}}Keywords (space-separated). OR-logic across tokens and fields{p_end}

{syntab:Search options}
{synopt:{opt prefix(str)}}Optional prefixes (space-separated). For each {it:kw} token, adds {it:prefix+kw} and {it:prefix-kw}{p_end}
{synopt:{opt fields(varlist)}}Text vars to search. Default: {it:title abstract actors actiontype demands notes}{p_end}
{synopt:{opt countries(str)}}Country filter; e.g. {it:"United States; United Kingdom; Turkey"}. Case-insensitive exact match{p_end}
{synopt:{opt cfield(name)}}Country variable. Default: {it:std_cowname} if present else {it:country}{p_end}
{synopt:{opt condition(exp)}}Additional filter expression. Auto-AND’d with keyword & country flags{p_end}

{syntab:Analysis window}
{synopt:{opt yrange(min max)}}Years to analyze (inclusive). Default: {it:1850 2020}{p_end}

{syntab:Behavior}
{synopt:{opt strict}}Apply stricter filtering if available: {it:coded_b==1} and/or {it:online==0} (only if those vars exist){p_end}
{synopt:{opt debug}}Print diagnostic counts (tokens, flags, rows used){p_end}

{synoptline}

{title:Description}

{pstd}
{cmd:gspwave} performs an in-program search over your dataset using the provided
{cmd:kw()} and {cmd:fields()}, optional {cmd:countries()} via {cmd:cfield()}, and an optional
{cmd:condition()}. It then collapses to a by-year series within {cmd:yrange()},
computes two “wave” indicators, prints a formatted table (and a compact list of wave
years), and exports results to Excel.

{pstd}
The by-year count is the {it:sum of} {bf:gsp} (coerced to numeric if needed) after all filters.

{title:Wave definitions}

{p2colset 9 30 32 2}{...}
{p2col:{bf:TS_wave}}1 if {it:count(t)} > 1.5 × average of {it:count} over years t−1 … t−5 (computed within the {cmd:yrange()} window).{p_end}
{p2col:{bf:WLG_wave}}1 if {bf:TS_wave==1} and {it:count(t)} > overall mean of {it:count} within the {cmd:yrange()} window.{p_end}
{p2colreset}{...}

{pstd}
Console output also summarizes “Major Waves” by compressing consecutive hit years into ranges,
e.g., {it:2012–2014, 2018}.

{title:Output (Excel)}

{pstd}
Writes two sheets to {it:using}:

{p2colset 9 30 32 2}{...}
{p2col:{bf:by_year}}Columns: {it:year} (exported as text "YYYY" to avoid Excel reformatting), {it:count}, {it:TS_wave}, {it:WLG_wave}.{p_end}
{p2col:{bf:meta}}Key inputs used: {it:kw}, {it:prefix}, {it:countries}, {it:fields}, {it:cfield}, {it:condition}, {it:yrange}, {it:overall_mean}, {it:generated}.{p_end}
{p2colreset}{...}

{title:Details of matching}

{pstd}
{bf:Keywords}: tokens are matched with OR-logic across all {cmd:fields()}.
Non-string search vars are cast via {cmd:string()} for matching.

{pstd}
{bf:Prefixes}: tokens in {cmd:prefix()} (space-separated) generate two additional forms per keyword:
{it:prefix+kw} and {it:prefix-kw}.

{pstd}
{bf:Countries}: {cmd:countries()} accepts names separated by {bf:;}, {bf:,}, or {bf:|}.
Matching is case-insensitive exact equality on {cmd:cfield()} (default {it:std_cowname}→{it:country}).

{pstd}
{bf:strict}: If present and variables exist, adds {cmd:coded_b==1} and/or {cmd:online==0}
to the filter. If those variables don’t exist, behavior falls back to keyword+country filtering.

{title:Examples}

{pstd}
Basic run, default fields, write to Excel:
{phang2}{cmd:. gspwave using "results/gsp_output.xlsx", kw("strike protest riot") yrange(1850 2016)}

{pstd}
Add prefixes and country filter; show diagnostics:
{phang2}{cmd:. gspwave using "results/gsp_output.xlsx", kw("strike protest") ///
    prefix("wildcat mass") countries("United States; United Kingdom") yrange(1900 2000) debug}

{pstd}
Stricter filtering (uses {it:coded_b} and {it:online} if present) and a custom country field:
{phang2}{cmd:. gspwave using "out.xlsx", kw("strike") fields(title abstract) cfield(std_cowname) strict}

{pstd}
Hide routine Stata messages during export (recommended for clean logs):
{phang2}{cmd:. set rmsg off}{break}
{phang2}{cmd:. gspwave using "out.xlsx", kw("strike protest") yrange(1850 2016)}

{title:Saved results}

{pstd}
{cmd:gspwave} is {it:rclass}. On exit, it saves:

{synoptset 20}{...}
{synopt:{cmd:r(overall_mean)}}Overall mean of {it:count} within the analysis window{p_end}
{synopt:{cmd:r(ylo)}}Window start year (from {cmd:yrange()}){p_end}
{synopt:{cmd:r(yhi)}}Window end year (from {cmd:yrange()}){p_end}
{synoptline}

{title:Requirements}

{pstd}
Requires variables {bf:year} and {bf:gsp}. If not numeric, the program attempts
to coerce them via {cmd:real()}.

{title:Remarks}

{pstd}
The Year column is exported as text “YYYY” to prevent Excel from autoconverting to dates.
Within Stata, {bf:year} remains numeric for proper time-series logic.

{pstd}
The 5-year average uses only preceding years (t−1 … t−5); early years with fewer than 5 lags
use the available lags via {cmd:rowmean()}.

{title:Troubleshooting}

{phang}{bf:Nothing selected / empty table}? Check {cmd:kw()}, {cmd:fields()}, {cmd:countries()}, and {cmd:yrange()}
filters. Try {cmd:debug} to see pre-collapse row counts.{p_end}

{phang}{bf:Country mismatches}? Confirm {cmd:cfield()} matches the variable that holds your country names,
and that strings in {cmd:countries()} match exactly (case-insensitive).{p_end}

{phang}{bf:Excel shows weird dates in the first column}? The program already exports Year as text "YYYY".
If you post-process the sheet, keep that column as text to avoid Excel auto-formatting.{p_end}

{title:Author}

{pstd}
Prepared for your workflow. Tested on Stata 14.2.

{title:Also see}

{pstd}
{help gsp2xlsx} (companion exporter without wave flags)
