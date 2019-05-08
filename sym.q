.utl.require"qspec"
.tst.tstPath:hsym `$x.db
.tst.fixture[`C];                                  / loads C.csv into C table
.tst.fixture[`Ex];                                 / loads Ex.csv into Ex table
update ex:^[last@' string id;ex] from `Ex;         / auto-generate single character (ex)change code; will be used in table schemas
sym1:first ` vs                                    / fungible asset symbol from `symbol.exchange
ex:Ex.ex Ex.id?last ` vs                           / single char exchange code from `symbol.exchange
exib:Ex.ex Ex.ib?                                  / single char exchange code from IB exchange symbol
p:{`$x[":";string y]}                              / parse/unparse string/symbol containing :
ce:`conId`exchange!                                / from `symbol.exchange to `conId`exchange dict (IBKR compatible)
  (C.ib C.sym?;p[sv] Ex.ib Ex.id?p[vs] last` vs)@\:
x.sym:$[`~first x.sym:"S"$" " vs x`sym;            / config of symbols to subscribe to (also parsed from .ini file)
  C.sym;x.sym inter C.sym]