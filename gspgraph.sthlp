{smcl}
{* *! gspgraph 1.0.0 22aug2025}
{title:Title}

{pstd}{hi:gspgraph} — Global Social Protest (GSP) search-based graph producer (Stata 14.2 compatible) -- contact: Sahan S. Karatasli (skaratasli@gmail.com) 

{title:Syntax}

{p 8 15 2}
{cmd:gspgraph} , {opt kw(string)}
[{opt prefix(string)} {opt countries(string)} {opt fields(string)} {opt cfield(name)}
{opt condition(string)} {opt yrange(numlist)} {opt title(string)} {opt outgraph(string)}
{opt notesize(string)} {opt baropts(string)} {opt strict} {opt debug}]

{title:Description}

{pstd}
{cmd:gspgraph} is designed for Arrighi Center for Global Studies research working group to analyze the GSP data.  
This STATA command scans user-selected text fields for the {it:kw()} tokens (case-insensitive,
substring match; e.g., {it:protest} matches {it:protests/protesting}), optionally also
searching glued prefixes (e.g., {it:antiwoman}, {it:anti-woman}) supplied via {it:prefix()}.
It can restrict to countries in {it:countries()}, then aggregates {it:gsp} by {it:year} to draw a bar chart.{p_end}

{pstd}
This version is regex-free (uses Unicode-safe {cmd:ustrlower()} and {cmd:ustrpos()} logic) and works in Stata 14.2.{p_end}

{title:Requirements}

{pstd}Variables expected in the dataset:{p_end}
{p2colset 9 28 30 2}
{p2col:{bf:year}}numeric (or string coercible to numeric){p_end}
{p2col:{bf:gsp}}numeric (or string coercible to numeric){p_end}
{p2col:{bf:title abstract actors actiontype demands notes}}(optional) text fields scanned for keywords; configurable via {it:fields()}{p_end}
{p2col:{bf:std_cowname} or {bf:country}}country field used by {it:countries()}{p_end}
{p2col:{bf:fixpost2014}, {bf:online}}(optional) used by {it:strict} (adds {cmd:fixpost2014==1} and/or {cmd:online==0}){p_end}
{p2colreset}

{title:Options}

{p2colset 9 28 30 2}
{p2col:{opt kw(string)}}Space-separated keywords. Whitespace-only means “no keyword filter”.{p_end}
{p2col:{opt prefix(string)}}Space-separated prefixes added in glued and hyphenated forms (e.g., {it:anti} → {it:antiprotest}, {it:anti-protest}).{p_end}
{p2col:{opt countries(string)}}Exact country names to include. Multi-word OK. Separate items with {it:;}, {it:,}, or {it:|}.
Examples: {cmd:countries("Turkey, Israel, United States of America")} or {cmd:countries("Algeria; Tunisia|Morocco")}.
Whitespace-only means “all countries.”{p_end}
{p2col:{opt fields(string)}}Which text variables to scan. Default: {it:title abstract actors actiontype demands notes}.{p_end}
{p2col:{opt cfield(name)}}Country variable to use. Default: {it:std_cowname}, else {it:country}.{p_end}
{p2col:{opt condition(string)}}Row-inclusion condition (your data filter). {bf:In this version, do NOT wrap it in quotes.}
Example: {cmd:condition(fixpost2014==1 & online==0)}.{p_end}
{p2col:{opt yrange(numlist)}}Two numbers: x-axis range. Default: {cmd:1850 2020}.{p_end}
{p2col:{opt title(string)}}Graph title. Default provided.{p_end}
{p2col:{opt outgraph(string)}}Filename to export graph (format inferred by extension).{p_end}
{p2col:{opt notesize(string)}}Note text size. Default: {cmd:tiny}.{p_end}
{p2col:{opt baropts(string)}}Extra {cmd:twoway bar} options appended verbatim.{p_end}
{p2col:{opt strict}}If present, auto-ANDs {cmd:fixpost2014==1} and/or {cmd:online==0} when those vars exist.{p_end}
{p2col:{opt debug}}Prints tokens, condition, and match counts.{p_end}
{p2colreset}

{title:Remarks}

{pstd}
{it:Keywords.} Tokens are trimmed and matched as substrings across the {it:fields()} list,
case-insensitive. To broaden reach, use {it:prefix()} (e.g., {cmd:prefix(anti pro)} will also look for
{it:antistrike}, {it:anti-strike}, {it:prostrike}, {it:pro-strike}).{p_end}

{pstd}
{it:Countries.} Matching is exact after lowercasing and trimming. Use separators {it:;}, {it:,}, {it:|}
or provide a single multi-word country. Examples:
{cmd:countries("United States of America; United Kingdom | Turkey")} or
{cmd:countries("Turkey France")} (space-separated single-word items also work).{p_end}

{pstd}
{it:Condition.} This version expects an {bf:unquoted} Stata expression in {it:condition()}:
{cmd:condition(fixpost2014==1 & online==0)}. If you wrap it in quotes, Stata will treat it as a string
and the parser here will not modify it correctly.{p_end}

{pstd}
{it:Performance tips.} To speed up, restrict {it:fields()} to the few columns you need, and/or prefilter
your dataset with {cmd:keep if} before calling {cmd:gspgraph}.{p_end}

{title:Examples}

{pstd}{bf:General:}{p_end}
{cmd}
1) Global Social Protest pattern (no keywords/no countries):
. gspgraph, kw("") countries("") condition(fixpost2014==1 & online==0) title("Global Social Protest")
{txt}

{cmd}
2) Basic keywords across default fields such as title, abstract, actiontype, demands, actors, notes:
. gspgraph, kw("woman women female feminist girl") condition(fixpost2014==1 & online==0) title("Global Social Protest - Women/Feminist")
{txt}

{cmd}

3) Global Labor Unrest (Only when labor==1)
. gspgraph, kw("") countries("") condition(fixpost2014==1 & online==0 & inlist(labor, 1)) title ("Global Labor Unrest")
{txt}

{cmd}

4) Global Labor Unrest (Including Hard Calls:1, 2 and 9)
. gspgraph, kw("") countries("") condition(fixpost2014==1 & online==0 & inlist(labor, 1, 2, 9)) title ("Global Labor Unrest")
{txt}

{cmd}

5) Multiple countries (mixed separators):
. gspgraph, kw("") countries("Egypt, Tunisia, Turkey, Morocco, Israel, Palestine") condition(fixpost2014==1 & online==0)  title ("Global Labor Unrest (Select Countries)")
{txt}

{cmd}
6) Multi-word country with other countries and keywords:
. gspgraph, kw("student youth") countries("United States of America, United Kingdom, France, Germany") condition(fixpost2014==1 & online==0) title ("Student/Youth Protests in the West")
{txt}

{cmd}
7) Unemployment
. gspgraph, kw("") countries("") condition(fixpost2014==1 & online==0 & inlist(unemployed, 1, 2, 9)) title ("Unemployment Related Protests")
{txt}

{pstd}{bf:Prefixes & phrasing:}{p_end}
{cmd}
8) Glued and hyphenated prefixes:
. gspgraph, kw("union") prefix("anti pro") ///
    countries("Brazil, Mexico") condition(fixpost2014==1 & online==0)
{txt}

{cmd}
9) Phrase tokens (quotes keep them together):
. gspgraph, kw(`"minimum wage"' strike) countries("Argentina; Chile") ///
    condition(fixpost2014==1 & online==0)
{txt}

{pstd}{bf:Fields & country column:}{p_end}
{cmd}
10) Restrict scanned text fields:
. gspgraph, kw("bread rice") fields("title abstract") ///
    condition(fixpost2014==1 & online==0)
{txt}

{cmd}
11) Use a specific country field:
. gspgraph, kw("") cfield(locationcountry0) countries("Rhodesia") condition(fixpost2014==1 & online==0 )
{txt}


{cmd}
12) Particular Source only
. gspgraph, kw("") countries("") condition(fixpost2014==1 & online==0 & source=="NYT") title("NYT only")
. gspgraph, kw("") countries("") condition(fixpost2014==1 & online==0 & source=="Guardian") title("Guardian only")
{txt}

{pstd}{bf:Strict & complex conditions:}{p_end}
{cmd}
13) Strict mode (adds fixpost2014==1 and/or online==0 if present):
. gspgraph, kw("protest") countries("South Africa") strict
{txt}

{cmd}
14) Complex condition (note: no quotes):
. gspgraph, kw("auto") countries("Germany; France; United States of America; United Kingdom") condition(fixpost2014==1 & online==0 & inlist(labor,1,2,9))
{txt}

{pstd}{bf:Graphing tweaks:}{p_end}
{cmd}
15) Custom year range & title:
. gspgraph, kw("housing rent") condition(fixpost2014==1 & online==0) ///
    yrange(1900 2020) title("Housing-related GSP (1900–2020)")
{txt}

{cmd}
16) Export the graph:
. gspgraph, kw("unemployment") condition(fixpost2014==1 & online==0) ///
    outgraph("gsp_unemp.png")
{txt}

{cmd}
17) Extra bar options (passed via baropts()):
. gspgraph, kw("tax") condition(fixpost2014==1 & online==0) ///
    baropts("fcolor(%30) lcolor(black) barw(0.6)")
{txt}

{pstd}{bf:Debugging & edge cases:}{p_end}
{cmd}
18) Inspect final condition and match counts:
. gspgraph, kw("protest") countries("Israel, Palestine") ///
    condition(fixpost2014==1 & online==0) debug
{txt}

{cmd}
19) “All countries”, keyword-only:
. gspgraph, kw("feminism feminist") countries("") ///
    condition(fixpost2014==1 & online==0)
{txt}

{cmd}
20) Whitespace-only keyword (no keyword filter), country filter on:
. gspgraph, kw("") countries("Turkey; Greece") ///
    condition(fixpost2014==1 & online==0)
{txt}

{cmd}
21) Using {it:std_cowname} by default (no cfield()):
. gspgraph, kw("price") countries("Egypt; Tunisia; Morocco") ///
    condition(fixpost2014==1 & online==0)
{txt}

{cmd}
22) If {it:year} or {it:gsp} are stored as strings (auto-coercion):
. gspgraph, kw("food") countries("") condition(fixpost2014==1 & online==0)
{txt}

{cmd}
23) Long list of countries:
. gspgraph, kw("strike") countries("Algeria; Bahrain; Egypt; Iran; Iraq; Israel; Jordan; Kuwait; Lebanon; Libya; Morocco; Oman; Palestine; Qatar; Saudi Arabia; Syria; Tunisia; Turkey; United Arab Emirates; Yemen") ///
    condition(fixpost2014==1 & online==0)
{txt}

{title:Stored results}

{p2colset 9 28 30 2}
{p2col:{it:r(fields)}}Space-separated fields scanned{p_end}
{p2col:{it:r(cfield)}}Country field used{p_end}
{p2col:{it:r(condition)}}Final condition after auto-AND and substitutions{p_end}
{p2colreset}

{title:Installation}

{pstd}
Place {bf:gspgraph.ado} and {bf:gspgraph.sthlp} in your personal ado directory. To see it:
{cmd:. di c(sysdir_personal)}
On macOS it is typically {it:~/Library/Application Support/Stata/ado/personal/}.{p_end}

{pstd}
Reload and check:{p_end}
{cmd}
. program drop _all
. which gspgraph
. help gspgraph
{txt}

{title:Author}

{pstd}
Your Sahan S. Karatasli <skaratasli@gmail.com>{p_end}

{title:Also see}

{psee}
{space 2} {help gsp2rows} {help gsp2wave} {help twoway}, {help graph bar}, {help ustrfix}
