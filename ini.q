/ q ini.q [initfile] [section]
.utl.require"qutil/opts.q"
.utl.require"qutil/config_parse.q"

.utl.addArg["S";`.ini;0;                          / [initfile] cmdline arg
  (`x;{.utl.parseConfig hsym x})]
.utl.addArg["*";"";0;                              / [section] cmdline arg: selects section of file or first section
  {.[`x;();@;] $[count x;x;first key get `x]}]
.utl.parseArgs[]                                   / parse declarations above

x:{                                                / cast: keys as symbols, values according to "cast" key
  `cast _x!$[99h=type z;"*"^z x;"*"]$y
  }[`$key x;value x;eval parse x"cast"]

if[count x`load;                                  / load files, if provided via "load" key
  {system"l ",x}each " " vs x`load];


/ output: global var x holding a dictionary of typed program parameters