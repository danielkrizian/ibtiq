/ v2008.09.09

\d .u
init:{w::t!(count t::tables`.)#()}                 / .u.t: tables; .u.w: tables!(subscrbr conn handles; sym subsc list)

del:{w[x]_:w[x;;0]?y}                              / delete table subscription (x) from handle (y)
.z.pc:{del[;x]each t}                              / on handle (x) close - delete all table subscriptions to it

sel:{$[`~y;x;select from x where sym in y]}        / filter tick table (x) for subscrptn sym topics (y)

pub:{[t;x]                                         / publish table (t) data (x) to each handle according to .u.w interests
  {[t;x;w]                                         / [table; data; table's subscriber (handle;sym topics) from .u.w]
    if[count x:sel[x]w 1;(neg first w)(`upd;t;x)]  / .u.w is (handle;sym topics); call upd[table;topic data] on remote handle
    }[t;x]each w t}                                / publish each table in .u.w to its subscriber handles, filtered by sym topic

add:{                                              / add subscrptn to .u.w dict by .z.w handle, for (x) table, (y) sym topics
  $[(count w x)>i:w[x;;0]?.z.w;                    / does subscrptn exist already for the .z.w handle?
    .[`.u.w;(x;i;1); union;y];                     / yes: append new sym topics (y) to it
    w[x],:enlist(.z.w;y)];                         / no: add new (handle;sym topics) subscrptn to the table topic (x)
  (x;$[99=type v:value x;                          / output: (table name; table schema), where the latter is:
      sel[v]y;                                     / if (x) is keyed table, filter (y) topics, return ktable
      0#v])}                                       / if (x) not keyed, return empty table schema

sub:{
  if[x~`; :sub[;y]each t];                         / if ` supplied, subscribe to all tickerplant tables .u.t
  if[not x in t;'x];                               / otherwise throw error if (x) not a table in .u.t
  del[x].z.w;                                      / delete table (x) subscrptn of .z.w handle first
  add[x;y]}                                        / finally subscribe

end:{(neg union/[w[;;0]])@\:(`.u.end;x)}           / send .u.end[date] message to every subscriber handle in .u.w dict

/
examples:
.u.del[`trade;5]
.u.sel[trade;`MSFT`AAPL]
.u.pub[`trade;select from trade where time>09:00.03.000]
.u.add[`trade;`MSFT`AAPL]
.u.sub[`trade;`]; .u.sub[`;`]
.u.end[2019.04.17]
