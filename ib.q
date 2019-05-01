e.taq1:((`.ib;`reqMktData;;;"";0b;0b);             / (subscribe;unsubscribe) method with arguments
  (`.ib;`cancelMktData;))
x.topic:$[`~first x.topic:"S"$" " vs x`topic;      / configuration list of topics to subscribe to
  1_key e;x.topic inter 1_key e]

s:2!flip `to`sym`on!"ssb"$\:()                     / subscriptions table (to)pics;(sym)bols;(on)/off status

sub:{                                              / subscribe[topics;symbols] supporting all as `
  k:([]to:$[`~x;x.topic;(),x]) cross([]            / (topic;symbol) combination table of keys
    sym:$[`~y;x.sym;(),y]);
  s,:k!s k;                                        / insert into subscriptions table new (topics;symbols) with on:0b status
  update on:{value x;1b}'[e'[to;0;i;ce each sym]]  / run subscription(0) (e)xpressions where not on, then flip on to true
    from `s where not on;                          / in subscriptions table
  }
del:{                                              / unsubscribe[topics;symbols] supporting all as `
  c:$[`~y;();enlist (in;`sym;enlist y)];           / symbol constraint: sym in y
  c,:$[`~x;();enlist (in;`to;enlist x)];           / topic constraint: to in x
  a:parse"{value x;0b}'[e'[to;1;i]]";              / aggregation for "on" column: evaluate unsubscribe(e[;1;]) expression; then mark as off (0b)
  ![`s;enlist[`on],c;0b;enlist[`on]!enlist a];     / functional update of (s)ubscriptions table in place
  }

.ib.er:()!();                                      / error codes callbacks dict
.ib.er[300]:{x;y;}                                 / can't find request id. Trying to cancel non-existent id?
.ib.er[322]:{x;"Duplicate ticker id"~-19#y}        / request id already used
.ib.er[354]:{y;update on:0b from `s where i=x}     / subscription not purchased
.ib.reg[`error] {0N!x;.ib.er . x 1 0 2;}           / error callback: print error list (reqId;error code;message)
.ib.reg[;0N!] each `system`warning;

.ib.reg[;0N!] each `tickPrice`tickSize;

/
.ib.connect[x.host;x.port;1i]
sub[`;`]
del[`;`]