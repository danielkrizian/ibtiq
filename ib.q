e.taq1:((`.ib;`reqMktData;;;"";0b;0b);             / topic!(subscribe f;unsubscribe f;schemas)
  (`.ib;`cancelMktData;);`trade`quote`ohlcv)
x.topic:$[`~first x.topic:"S"$" " vs x`topic;      / configuration list of topics to subscribe to
  1_key e;x.topic inter 1_key e]

{system"l ",x,".q";} each string key 1_e;          / load schemas for each topic
s:flip `to`sym`on`smart!"ssb*"$\:()                / subscriptions table (to)pics;(sym)bols;(on)/off status
l:()!();                                           / last record of each table
{l[x]:`id xkey update id:"j"$() from 0#get x       / initialize (l)ast tables ...
  }''[(1_e)[;2]];                                  / ... for each topic and each table name
l[`ex]:1!flip`id`bex`aex`ti!"j**n"$\:()            / last bid and ask exchanges

sub:{                                              / subscribe[topics;symbols] supporting all as `
  k:([]to:$[`~x;x.topic;(),x]) cross([]            / (topic;symbol) combination table of keys
    sym:$[`~y;x.sym;(),y]);
  2!`s;s,:k!s k;0!`s;                              / insert into subscriptions table new (topics;symbols) with on:0b status
  update on:{value x;1b}'[e'[to;0;i;ce each sym]]  / run subscription(0) (e)xpressions where not on, then flip on to true
    from `s where not on;                          / in subscriptions table
  exec {l[x 0],:y}[t;([]id;sym;ex)] by t
    from ungroup select
    t:e'[to;2],id:i,sym:sym1'[sym],ex:ex'[sym]
    from s;
  }

del:{                                              / unsubscribe[topics;symbols] supporting all as `
  c:$[`~y;();enlist (in;`sym;enlist y)];           / symbol constraint: sym in y
  c,:$[`~x;();enlist (in;`to;enlist x)];           / topic constraint: to in x
  a:parse"{value x;0b}'[e'[to;1;i]]";              / aggregation for "on" column: evaluate unsubscribe(e[;1;]) expression; then mark as off (0b)
  ![`s;enlist[`on],c;0b;enlist[`on]!enlist a];     / functional update of (s)ubscriptions table in place
  }

/ error handlers; see https://interactivebrokers.github.io/tws-api/message_codes.html
.ib.er:()!()                                       / error codes callbacks dict
.ib.er[300]:{[x;y]}                                / can't find request id. Trying to cancel non-existent id?
.ib.er[322]:{x;"Duplicate ticker id"~-19#y}        / request id already used
.ib.er[354 504]:{y;update on:0b from `s where i=x} / subscription not purchased | not connected
.ib.er[1100]:{y;update on:0b from `s}              / connectivity lost
.ib.er[2103]:{[x;y]}                               / broken market data farm connection:[name]
.ib.er[2104]:{[x;y]}                               / OK market data farm connection:[name]
.ib.er[2147483647]:{x;                             / exchange closed for given contract: unable to retrieve bbo
  "Unable to retrieve smart components for "~-2#y}
.ib.reg[`error] {0N!x;.ib.er . x 1 0 2;}           / error callback: print error list (reqId;error code;message)
.ib.reg[;0N!] each `system`warning;

/ tick type parsers and processors; see https://interactivebrokers.github.io/tws-api/tick_types.html
o:45 84 1 2 4 0 3 5 6 7 8 9                        / order of tick types arrival - fyi only
tick:`quote`trade`ohlcv`ex!                        / tickids representing columns within table schemas
  (0N 0N 1 2 0 3 0Ni;45 0N 4 5 84i;0N 0N 14 6 7 9 8 0Ni;0N 32 33 0Ni)
tick:{                                             / tickid!(table;column) dict from table!(tickid positions)
  u:where count each x;                            / table names where each tick belongs
  v:raze {@[cols;x;cols l x]} each key x;          / column names which each tick represents
  w:(raze x)!flip (u;v);                           / tickid!(table;column)
  _[;0N] over w}[tick]                             / drop 0N keys from the dict
upd:{l[x],:y;h(".u.upd";x;value l[x;y`id]);}       / default: update last table and send the last record to downstream
tick:tick,\:(::),upd;                              / tickid!(table;column;parser;processor)

/ custom tick type parsers
tick[45;2]:"n"${"z"$-10957+x%8.64e4}"J"$           / last timestamp parser: from unix time string to kdb timespan
tick[84;2]:first                                   / last exchange parser

/ custom tick type processors
tick[32 33;3]:{[x;y]}                              / bid exchange,ask exchange; not used
tick[45;3]:{l[x],:y;}                              / last timestamp: incomplete record til sz arrival
tick[84;3]:{if[count ib:s[y`id;`smart;y`ex;0];     / exchange of last trade; if SMART contract:
    y[`ex]:exib ib;l[x],:y;];}                     / convert from IB ex code to our nomenclature
tick[4;3]:{l[x],:y;l[x;y`id;`sz]:0Nj;}             / last price: incomplete record til sz arrives; mark sz as yet missing
tick[5;3]:{                                        / last size;
  if[(l[x;y`id;`sz]=y`sz) &                        / if unchanged size ..
    9e6>y[`ti]-l[x;y`id;`ti];                      / and if not older than 9ms from previous update
    : ::];                                         / then ignore this duplicate trade; this is known IBKR bug
  upd[x;y];}                                       / otherwise finalize complete trade
tick[49;3]:{0N!(x;y)}                              / TODO: tickType 49: Halted (tickGeneric)

/ register callbacks
.ib.reg[;{                                         / x:(subscriptionid;tickid;value)
    t:tick[x 1];                                   / (table;column;parser)
    d:(`ti`id,t 1)!(.z.n;x 0;t[2]@x 2);            / parse tick
    t[3].(t 0;d);                                  / process tick
    }] each `tickPrice`tickSize`tickString`tickGeneric;
.ib.reg[`tickReqParams;                            / contract details retrieved upon subscription request
  {update bbo:x 2,tck:x 1,ssp:x 3                  / SMART contract bbo exchanges code;tick size;snapshot permissions
    from `s where i=x 0;                           / for request id
   exec .ib.reqSmartComponents'[i;string bbo]      / populate SMART exchanges for each bbo code;
    from `s where not null bbo;
    }]
.ib.reg[`smartComponents;                          / x:(requestid;ib exchange id;ib exch name;single char exch identifier)
  {update smart:(0<count x 0)#enlist x[3]!flip x 2 1
    from `s where i in x 0 ;
    }]                                             / smart exchanges will be later used to populate ex field for each tick of SMART contract

.ib.connect[x.host;x.port;1i];                     / connect
sub[x.topic;x.sym];                                / subscribe
if[not h:neg@[hopen;`$":",x.tplant;0];             / if unable to connect to tickerplant, will capture data locally
  .u.upd:insert]                                   / define capture function locally
/
globals used
x - init configuration
e - topics
s - subscriptions
l - last

/ OPTIONAL: collecting SMART quotes broken down by bbo exchanges.
/  WARNING: SMART sizes are aggregate, hence are omitted (null) for individual exchanges
tick[32;3]:{l[x],:y;bex:y`bex;aex:l[x;y`id;`aex];
  j:bex inter aex;
  `quote insert flip update ex:j from `asz`bsz _l[`quote;y`id];
  `quote insert flip update ex:bex except j from `ask`asz`bsz _l[`quote;y`id];}
tick[33;3]:{l[x],:y;aex:y`aex;bex:l[x;y`id;`bex];
  j:bex inter aex;
  `quote insert flip update ex:j from `asz`bsz _l[`quote;y`id];
  `quote insert flip update ex:aex except j from `bid`bsz`asz _l[`quote;y`id];}