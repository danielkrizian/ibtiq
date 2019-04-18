/ q tick/r.q [tickerplant host:port] [hdb host:port] -p 5011

if[not "w"=first string .z.o;system "sleep 1"];

upd:insert                                         / what to do about incoming data: just insert record into the resp. table

.u.x:.z.x,(count .z.x)_(":5010";":5012")           / get the ticker plant and history ports, defaults are 5010,5012

.u.end:{                                           / end of day: save, clear, hdb reload (x) date partition
  t:tables`.;                                      / all tables in the process
  t@:where `g=attr each t@\:`sym;                  / filter only tables having `g (grouped) attribute on sym column
  .Q.hdpf[`$":",.u.x 1;`:.;x;`sym];                / save all tables in the (h)istorical port;(d)irectory;partition with (x) date and field to have (`p)arted attribute applied
  @[;`sym;`g#] each t;                             / reapply `g attribute to all tables with the sym column
  }

.u.rep:{                                           / replay log; (x) table schemas; (y) (log rows;log filepath)
  (.[;();:;].)each x;                              / init schema using empty tables from tickerplant to replicate the same schemas
  if[null first y;:()];                            / exit if empty log
  -11!y;                                           / replay first (y 0) log records into tables;
  system "cd ",1_-10_string first reverse y        / cd to hdb so client save can run; HARDCODE \cd if other than logdir/db
  }

/ connect to ticker plant for (schema;(logcount;log)), subscribe to all tables and replay
.u.rep .(hopen `$":",.u.x 0)"(.u.sub[`;`];`.u `i`L)"


/
examples:
.u.end[2019.04.18]
.u.rep[0#tbl;(4;`:logs/sym2019.04.18)]