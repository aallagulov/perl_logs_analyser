perl_logs_analyser

Installation steps:
1. I hope you have unix-based OS with Perl installed - if not -> pls install Perl somehow
2. You need only some additional Perl modules, which could be installed as a package:
```
apt install libtext-csv-perl
apt install libmoo-perl
```

Usage:
```$ perl cli.pl -f sample_csv.txt```

Stdout:
```
2019-02-08 00:10:50 - 2019-02-08 00:11:00: Hits stats for routes: /api - 1;
2019-02-08 00:11:00 - 2019-02-08 00:11:10: Hits stats for routes: /api - 58; /report - 31;
2019-02-08 00:11:10 - 2019-02-08 00:11:20: Hits stats for routes: /api - 59; /report - 28;
2019-02-08 00:11:20 - 2019-02-08 00:11:30: Hits stats for routes: /api - 63; /report - 31;
2019-02-08 00:11:30 - 2019-02-08 00:11:40: Hits stats for routes: /api - 60; /report - 31;
...
```

Testing:
```$ prove t```

Stdout:
```
t/hits_alert.t .. ok
t/hits_stat.t ... ok
All tests successful.
Files=2, Tests=61,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.12 cusr  0.02 csys =  0.16 CPU)
Result: PASS
```