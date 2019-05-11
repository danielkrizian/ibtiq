/ v2014.03.12 from https://github.com/KxSystems/kdb-tick/blob/master/tick.q
/ q tick.q [schema] [destination directory] [-t milisecond batches] -p 5010 [-o h]
/ q tick.q sym . -p 5001 </dev/null >foo 2>&1 &
system"l ",(src:first .z.x,enlist"sym"),".q"

if[not system"p";system"p 5010"]

\l tick/u.q
\d .u
ld:{                                               / create the log .u.L in (x) dir or get the log count and open it
  if[not type key L::`$(-10_string L),string x;    / x:.u.d (date)
    .[L;();:;()]];
  i::j::-11!(-2;L);                                / .u.i:(number of valid chunks; length of valid part in bytes)
  if[0<=type i;                                    / corrupt because list, not atom; see -11!(-2;)
    -2 (string L),                                 / stderr message
    " is a corrupt log. Truncate to length ",
    (string last i)," and restart";
    exit 1];
  hopen L}                                         / return opened handle to the log file for appending

tick:{                                             / (x) source file with table schemas; (y) log file path
  init[];                                          / run .u.init[] to create .u.t and .u.w
  if[not min(`ti`sym~2#key flip value@)each t;     / check that all .u.t tables have both `time`sym cols
    '`timesym];                                    / if not - throw error
  @[;`sym;`g#]each t;                              / set group attribute to sym col; speeds up .u.sel query
  d::.z.D;                                         / set .u.d as today's date
  if[l::count y;                                   / if log destination provided:
    L::`$":",y,"/",x,10#".";                       / set .u.L as log filename with padding for date,eg `:./logs/sym..........
    l::ld d];                                      / set .u.l as handle to log file for today's date
  }

endofday:{
  end d; d+:1;                                     / alerts clients that end of day reached, increment .u.d to next day
  if[l; hclose l; l::0(`.u.ld;d)];                 / rollover log file to next day; .u.l: handle to new log file
  }

ts:{                                               / checks current date (x) if end of day to be run
  if[d<x;
    if[d<x-1;
      system"t 0";
      '"more than one day?"];
    endofday[]];
  }

if[system"t";                                      / batch mode - publishes every -t N ms; defines .z.ts and .u.upd
  .z.ts:{
    pub'[t;value each t];                          / publish to subscribers accumulated tables
    @[`.;t;@[;`sym;`g#]0#];                        / reset tables, reapply `g# (grouped) attribute to each table
    i::j;                                          / log file msg count increased by buffer msg count
    ts .z.D;                                       / check end of day
    };
  upd:{[t;x]                                       / function called by feedhandler when it has data for the tickerplant
    if[not -16=type first first x;                 / if no timespan first column: will add timespan
      if[d<"d"$a:.z.P; .z.ts[]];                   / manually publish first time right after midnight, then run end of day
      a:"n"$a;                                     / current timespan
      x:$[0>type first x;                          / enrich (x) data with timespan:
          a,x;                                     / when (x) is atom
          (enlist(count first x)#a),x]];           / when (x) is multi-record list, add timespan to every record
    t insert x;                                    / insert to in-memory table buffer
    if[l;l enlist (`upd;t;x);j+:1];                / append data to log; increment .u.j
    }
  ];

if[not system"t";                                  / immediate mode; defines .z.ts and .u.upd
  system"t 1000";                                  / set 1s timer for:
  .z.ts:{ts .z.D};                                 / check end of day every 1s
  upd:{[t;x]                                       / function called by feedhandler when it has data for the tickerplant
    ts"d"$a:.z.P;                                  / check for and process if end of day
    if[not -16=type first first x;                 / if no timespan first column:
      a:"n"$a;                                     / current timespan
      x:$[0>type first x;                          / enrich (x) with timespan:
        a,x;                                       / when (x) is atom
        (enlist(count first x)#a),x]];             / when (x) is multi-record list, add timespan to every record
    f:key flip value t;                            / fields (column names) of the table schema
    pub[t;$[0>type first x;enlist f!x;flip f!x]];  / publish to subscribers column names enriched (x) data: be it single or multi-records
    if[l;l enlist (`upd;t;x);i+:1];                / append data to log; increment .u.i
    }
  ];

\d .
.u.tick[src;.z.x 1];                               / start up tickerplant with schema and log directory

/
 globals used
 .u.w - dictionary of tables->(handle;syms)
 .u.i - msg count in log file
 .u.j - total msg count (log file plus those held in buffer)
 .u.t - table names
 .u.L - tp log filename, e.g. `:./sym2008.09.11
 .u.l - handle to tp log file
 .u.d - date
/test
>q tick.q
>q tick/ssl.q
/run
>q tick.q sym  .  -p 5010	/tick
>q tick/r.q :5010 -p 5011	/rdb
>q sym            -p 5012	/hdb
>q tick/ssl.q sym :5010		/feed

examples:
.u.ld[`:./logs]
.u.tick["sym";"./logs"]
.u.endofday[]
.u.ts[17:00:00.001]