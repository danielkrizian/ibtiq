.utl.require"qspec"
.tst.tstPath:hsym `$x.db
.tst.fixture[`C];                                  / loads C.csv into C table
.tst.fixture[`Ex];                                 / loads Ex.csv into Ex table
p:{`$x[":";string y]}                              / parse/unparse string/symbol containing :
ce:`conId`exchange!                                / convert from symbol to `conId`exchange dict
  (C.ib C.sym?;p[sv] Ex.ib Ex.ex?p[vs] last` vs)@\:
x.sym:$[`~first x.sym:"S"$" " vs x`sym;            / config of symbols to subscribe to (also parsed from .ini file)
  C.sym;x.sym inter C.sym]
