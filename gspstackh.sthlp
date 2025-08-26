{smcl}
{* *! gspstackh 1.0.0 26aug2025}
{title:Title}

{pstd}{hi:gspstackh} — 100% stacked area chart of yearly category shares (Stata 14.2+)

{title:Syntax}

{p 8 15 2}
{cmd:gspstackh} {varlist} {ifin} , {opt yearvar(name)} [{opt yrange(numlist min=2 max=2)} {opt title(string asis)} {opt note(string asis)} {opt notesize(string)} {opt outgraph(string asis)} {opt strict} {opt debug} {opt xopts(string asis)}]

{title:Description}

{pstd}
{cmd:gspstackh} builds a 100% stacked area chart showing, for each year, the {it:share} of the annual total contributed by each variable in {varlist}. It:
(1) filters to your sample, (2) collapses to annual sums, (3) pads missing years inside the range, (4) converts each series to percent of the annual total, and (5) draws stacked bands from 0 to 100.

{pstd}
Legend text uses each variable’s {it:variable label} when available, otherwise the variable name. You can override any graph option with {opt xopts()}.

{title:Data requirements}

{phang}
• {it:Year variable}: numeric integer years. Supply with {opt yearvar()} if not named {bf:year}.

{phang}
• {it:Series in varlist}: ideally 0/1 indicators; program will sum them per year. Use {opt strict} to enforce 0/1 (or missing) before plotting.

{title:Options}

{phang}{opt yearvar(name)} — Name of the year variable (must be numeric).

{phang}{opt yrange(a b)} — Restrict to years {it:a}…{it:b}. Missing-year rows inside the window are padded as zeros so the time axis is continuous.

{phang}{opt title("text")} — Graph title. Quotes inside are safely escaped.

{phang}{opt note("text")} {opt notesize(size)} — Footnote text and optional size (e.g., {it:tiny small medium}).

{phang}{opt outgraph("path")} — Export the graph after drawing (any format accepted by {help graph export}).

{phang}{opt strict} — Assert that all variables in {varlist} are 0/1 (or missing) before collapsing.

{phang}{opt debug} — Print a diagnostic table with yearly totals and computed percentages.

{phang}{opt xopts("...")} — Append arbitrary {help twoway} options (last-one-wins). Useful for {bf:legend()}, {bf:xlabel()}, {bf:scheme()}, etc.

{title:Returned values}

{pstd}
{cmd:r(ymin)} and {cmd:r(ymax)}: min/max year used; {cmd:r(year)}: year variable name; {cmd:r(vars)}: the plotted variables.

{title:Notes on labels & legend}

{phang}
• Default legend labels come from {cmd:label variable}. Set them once and reuse:
{p 12 16 2}{cmd:. label variable ai_labor2 "Labor"}{p_end}

{phang}
• To override without touching data, pass {cmd:xopts(legend(...))}. Because {cmd:xopts()} is appended at the end, your labels supersede the defaults.

{title:Examples}

{pstd}Basic stack (labels taken from variable labels if present){p_end}
{phang2}{cmd:. gspstackh ai_labor2 ai_natind ai_student ai_racial ai_radicalright ai_gender ai_antigov ai_peasant ai_environmentalist ai_religious if year>=1850 & year<=2016, yearvar(year) xopts(xlabel(1850(20)2010))}

{pstd}Set one label in the data, let the rest default{p_end}
{phang2}{cmd:. label variable ai_labor2 "Labor"}{p_end}
{phang2}{cmd:. gspstackh ai_labor2 ai_natind ai_student ai_racial ai_radicalright ai_gender ai_antigov ai_peasant ai_environmentalist ai_religious if inrange(year,1850,2016), yearvar(year) xopts(xlabel(1850(20)2010))}

{pstd}Fully override legend labels via {cmd:xopts()} (no data changes){p_end}
{phang2}{cmd:. gspstackh ai_labor2 ai_natind ai_student ai_racial ai_radicalright ai_antigov ai_peasant ai_religious if inrange(year,1850,2016), yearvar(year) xopts(xlabel(1850(20)2010) legend(label(1 "Labor") label(2 "Nationalist") label(3 "Student/Youth") label(4 "Racial/Ethnic") label(5 "Radical Right") label(6 "Anti-Government") label(7 "Peasant") label(8 "Religious")) )}

{pstd}Add a title, note, and custom axis titles via {cmd:xopts()}{p_end}
{phang2}{cmd:. gspstackh ai_labor2 ai_natind ai_student ai_racial ai_radicalright if inrange(year,1850,2016), yearvar(year) title("Global protest categories") note("GSP dataset; offline, internal news only", size(tiny)) xopts(xtitle("Year") ytitle("Percent of annual total") xlabel(1850(10)2010, angle(45)))}

{pstd}Strict 0/1 enforcement and export{p_end}
{phang2}{cmd:. gspstackh ai_labor2 ai_natind ai_student if inrange(year,1850,2016), yearvar(year) strict outgraph("results/gspstackh_global.png")}
