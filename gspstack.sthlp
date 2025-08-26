{smcl}
{* *! gspstack 1.0.0 26aug2025}
{title:Title}

{pstd}{hi:gspstack} — Stacked area chart of yearly {it:counts} (Stata 14.2+)

{title:Syntax}

{p 8 15 2}
{cmd:gspstack} {varlist} {ifin} , {opt yearvar(name)} [{opt yrange(numlist min=2 max=2)} {opt title(string asis)} {opt note(string asis)} {opt notesize(string)} {opt outgraph(string asis)} {opt strict} {opt debug} {opt xopts(string asis)}]

{title:Description}

{pstd}
{cmd:gspstack} draws a classic stacked area chart of {it:raw yearly counts}. For each year, it sums every variable in {varlist}, pads missing years within the chosen window, then stacks the series as cumulative {it:counts} (not percentages). If you want a 100% share chart, see {help gspstackh}.

{pstd}
Legend entries use each variable’s {it:variable label} when present, otherwise the variable name. Any graph option can be overridden via {opt xopts()} (appended last in the {cmd:twoway} call).

{title:Data requirements}

{phang}
• {it:Year variable}: numeric integer years. Provide with {opt yearvar()} if not named {bf:year}.

{phang}
• {it:Series in varlist}: typically 0/1 indicators (the program sums to yearly counts). Use {opt strict} to enforce 0/1 (or missing) before collapsing.

{title:Options}

{phang}{opt yearvar(name)} — Name of the year variable (must be numeric).

{phang}{opt yrange(a b)} — Keep years {it:a}…{it:b}. Missing years inside the window are added so the x–axis is continuous.

{phang}{opt title("text")} — Graph title. Quotes are safely escaped.

{phang}{opt note("text")} {opt notesize(size)} — Footnote text and optional size (e.g., {it:tiny small medium}).

{phang}{opt outgraph("path")} — Export the graph (any format supported by {help graph export}).

{phang}{opt strict} — Assert that all series are 0/1 (or missing) prior to collapsing.

{phang}{opt debug} — Print a diagnostic table for computed yearly totals (post-collapse).

{phang}{opt xopts("...")} — Append arbitrary {help twoway} options (last-one-wins). Use for {bf:xlabel()}, {bf:legend()}, {bf:scheme()}, {bf:graphregion()}, etc.

{title:Graph details}

{phang}
• {it:Y–axis range}: computed automatically with ~4% headroom above the observed maximum (at least 1). Override with {cmd:xopts(yscale(range(0 #)))} if desired.

{phang}
• {it:X labels}: by default, only the years that existed pre-padding are labeled; override with {cmd:xopts(xlabel(...))}.

{phang}
• {it:Legend labels}: set via {cmd:label variable} (preferred), or override with {cmd:xopts(legend(label(# "...") ...))}.

{title:Returned values}

{pstd}
Scalars: {cmd:r(ymin)} {cmd:r(ymax)} (min/max year used){break}
Macros: {cmd:r(year)} (year variable name), {cmd:r(vars)} (plotted variables)

{title:Examples}

{pstd}Basic stack of counts over a window; custom x–axis labels via {cmd:xopts()}{p_end}
{phang2}{cmd:. gspstack ai_labor2 ai_natind ai_student ai_racial ai_radicalright ai_antigov ai_peasant ai_religious if inrange(year,1850,2016), yearvar(year) xopts(xlabel(1850(20)2010))}

{pstd}Use variable labels for a clean legend (recommended){p_end}
{phang2}{cmd:. label variable ai_labor2 "Labor"}{p_end}
{phang2}{cmd:. label variable ai_natind "Nationalist"}{p_end}
{phang2}{cmd:. label variable ai_student "Student/Youth"}{p_end}
{phang2}{cmd:. gspstack ai_labor2 ai_natind ai_student ai_racial ai_radicalright ai_antigov ai_peasant ai_environmentalist ai_religious if year>=1850 & year<=2016, yearvar(year) xopts(xlabel(1850(20)2010))}

{pstd}Override legend text without touching the data (last-one-wins via {cmd:xopts()}){p_end}
{phang2}{cmd:. gspstack ai_labor2 ai_natind ai_student ai_racial ai_radicalright ai_antigov ai_peasant ai_religious if inrange(year,1850,2016),}{break}
{phang2}{cmd: yearvar(year) xopts( legend(label(1 "Labor") label(2 "Nationalist") label(3 "Student/Youth") label(4 "Racial/Ethnic") label(5 "Radical Right") label(6 "Anti-Government") label(7 "Peasant") label(8 "Religious")) )}

{pstd}Add a title, small note, and angled x–labels{p_end}
{phang2}{cmd:. gspstack ai_labor2 ai_natind ai_student ai_racial if inrange(year,1850,2016), yearvar(year) title("Global protest categories (counts)") note("Offline, internal news only", size(tiny)) xopts(xlabel(1850(10)2010, angle(45)))}

{pstd}Strict 0/1 enforcement; export PNG to disk{p_end}
{phang2}{cmd:. gspstack ai_labor2 ai_natind ai_student if inrange(year,1850,2016), yearvar(year) strict outgraph("results/gspstack_global.png")}

{title:Troubleshooting}

{phang}
• {it:“No observations after filters”} — Check {opt yrange()}, {it:if/in}, and that your year variable is numeric and within the requested window.

{phang}
• {it:Empty years inside the window} are padded to 0 so the time axis remains continuous.

{title:Author}

{pstd}Sahan S. Karataşlı (UNCG). Feedback welcome.

{title:See also}

{pstd}{help gspstackh} (100% stacked share), {help twoway area}, {help graph export}, {help label variable}
