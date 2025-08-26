{smcl}
{* *! version 1.0.2 23aug2025}{...}
{title:Title}
{phang}{bf:gsp2rows} — Export filtered rows to Excel (writes to default Sheet1){p_end}

{title:Syntax}
{p 8 12 2}{cmd:gsp2rows} {it:using}{cmd:,} {opth kw(string)} [{it:options}]{p_end}

{synoptset 24 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opth kw(string)}}Space-separated keywords to search (case-insensitive); use {cmd:kw("")} for no keyword filter{p_end}
{synopt:{opth prefix(string)}}Optional glued prefixes tried before each keyword (e.g., {cmd:anti pro}){p_end}
{synopt:{opth countries(string)}}Country names (exact matches); separate with {bf:;}, {bf:,}, or {bf:|}{p_end}
{synopt:{opth fields(string)}}Text variables to search; default {cmd:"title abstract actors actiontype demands notes"}{p_end}
{synopt:{opth cfield(name)}}Country variable; defaults to {cmd:std_cowname} or {cmd:country}{p_end}
{synopt:{opth condition(string)}}Extra Stata condition (e.g., {cmd:fixpost2014==1 & online==0}){p_end}
{synopt:{opth yrange(numlist)}}Two numbers giving inclusive year range, e.g., {cmd:yrange(1850 2020)}{p_end}
{synopt:{opt keepvars(varlist)}}Limit exported columns to this list; by default, exports all variables{p_end}
{synopt:{opt strict}}If present, also requires {cmd:coded_b==1} and/or {cmd:online==0} when those vars exist{p_end}
{synopt:{opt debug}}Print tokenized keywords and counts for troubleshooting{p_end}
{synoptline}

{title:Description}
{pstd}
{cmd:gsp2rows} filters the current GSP dataset by keywords, optional countries, an optional
user condition, and an optional year range, then exports the matching rows to an Excel workbook.
To be robust in Stata 14.2, it writes to the default sheet ({it:Sheet1}) and does not use
{cmd:sheet()}. If the file exists, it is overwritten.{p_end}

{title:How filtering works}
{pstd}{bf:1) Keywords} — {cmd:kw()} is split on spaces; each token is matched as a case-insensitive
substring across variables listed in {cmd:fields()}. If {cmd:kw("")} or only whitespace is given,
the keyword filter is skipped.{p_end}
{pstd}{bf:2) Countries} — Exact case-insensitive matches after trimming. Multiple names can be separated
by {bf:;}, {bf:,}, or {bf:|}. If empty, the country filter is skipped.{p_end}
{pstd}{bf:3) Condition} — Any valid Stata expression. You do not need to include keyword or country flags
here; they are automatically ANDed into the final condition.{p_end}
{pstd}{bf:4) Year range} — Rows outside {cmd:yrange()} are dropped. The command will coerce a nonnumeric
{cmd:year} to numeric if possible.{p_end}

{title:Examples}
{pstd}{bf:Tip:} These are single-line commands for clean copy/paste. If you prefer multi-line input,
end each continued line with {cmd:///}.{p_end}

{pstd}{bf:1) Minimal export — no keyword/country filter; pick a few columns}{p_end}
{phang2}{cmd:. gsp2rows using "rows_all.xlsx", kw("") countries("") keepvars(year month day title country)}{p_end}

{pstd}{bf:2) Single keyword, one country, limit years}{p_end}
{phang2}{cmd:. gsp2rows using "rows_mexico.xlsx", kw("protest") countries("Mexico") yrange(1950 1990) keepvars(year title actors actiontype)}{p_end}

{pstd}{bf:3) Multiple keywords, multiple countries, plus a condition}{p_end}
{phang2}{cmd:. gsp2rows using "rows_la_offline.xlsx", kw("woman women feminist") countries("Cuba; United States of America; Mexico") condition(fixpost2014==1 & online==0) yrange(1850 2020) keepvars(year month day country title)}{p_end}

{pstd}{bf:4) Advanced — prefixes, custom fields to search, strict mode}{p_end}
{phang2}{cmd:. gsp2rows using "rows_advanced.xlsx", kw("strike wage") prefix("anti pro") fields("title abstract notes") countries("Brazil; Argentina") condition(lu==1) strict yrange(1900 2020) keepvars(year country title actors actiontype demands)}{p_end}

{title:Output}
{pstd}
A single Excel workbook (the {it:using} file) written to the default sheet ({it:Sheet1}),
with variable names in the first row. Long text ({cmd:strL}) columns are safely trimmed to
2,045 characters for compatibility with Stata 14.2’s Excel export.{p_end}

{title:Saved results}
{pstd}
{cmd:gsp2rows} stores the following in {cmd:r()}:{p_end}
{p2colset 9 24 26 2}{...}
{p2col:{cmd:r(N_rows)}}number of rows exported{p_end}
{p2colreset}{...}

{title:Tips & troubleshooting}
{pstd}
• If nothing exports, relax filters: try {cmd:kw("")} and {cmd:countries("")} first, then add constraints one by one.{p_end}
{pstd}
• Wrap multi-word phrases in quotes, e.g., {cmd:kw("minimum wage")}.{p_end}
{pstd}
• Use {cmd:keepvars()} to keep Excel narrow (e.g., {cmd:keepvars(year title country)}).{p_end}
{pstd}
• If your country variable isn’t {cmd:std_cowname} or {cmd:country}, point {cmd:cfield()} to the correct variable.{p_end}
{pstd}
• When breaking a long command across lines, end each line with {cmd:///}.{p_end}

{title:Requirements}
{pstd}
Stata 14.2 or newer. Dataset must include a numeric (or numeric-coercible) {cmd:year}.
For country filtering, the program will look for {cmd:std_cowname} or {cmd:country} unless
you specify {cmd:cfield()}.{p_end}

{title:Also see}
{pstd}{help export excel}, {help ustrlower}, {help ustrpos}{p_end}
