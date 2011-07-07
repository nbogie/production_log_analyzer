= production_log_analyzer

* http://seattlerb.rubyforge.org/production_log_analyzer
* http://rubyforge.org/projects/seattlerb

== DESCRIPTION

production_log_analyzer lets you find out which actions on a Rails
site are slowing you down.

Bug reports:

http://rubyforge.org/tracker/?func=add&group_id=1513&atid=5921

== About

production_log_analyzer provides three tools to analyze log files
created by SyslogLogger.  pl_analyze for getting daily reports,
action_grep for pulling log lines for a single action and
action_errors to summarize errors with counts.

The analyzer currently requires the use of SyslogLogger because the
default Logger doesn't give any way to associate lines logged to a
request.

The PL Analyzer also includes action_grep which lets you grab lines from a log
that only match a single action.

  action_grep RssController#uber /var/log/production.log

== About this fork

This fork adds support for formats.  It will count (say) JSON requests
of an action separately from counts for the same action's XML.

This fork also adds an experimental report diff tool, pl_analyze_diff.
Given two reports made previously with pl_analyze, this will tell you 
which actions have become faster or slower, or how their request counts 
differed.  It also mentions requests which appear in one report but not 
the other.

== Installing

  sudo gem install production_log_analyzer

=== Setup

First:

Set up SyslogLogger according to the instructions here:

http://seattlerb.rubyforge.org/SyslogLogger/

Then:

Set up a cronjob (or something like that) to run log files through pl_analyze.

== Using pl_analyze

To run pl_analyze simply give it the name of a log file to analyze.

  pl_analyze /var/log/production.log

If you want, you can run it from a cron something like this:

  /usr/bin/gzip -dc /var/log/production.log.0.gz | /usr/local/bin/pl_analyze /dev/stdin

Or, have pl_analyze email you (which is preferred, because tabs get preserved):

  /usr/bin/gzip -dc /var/log/production.log.0.gz | /usr/local/bin/pl_analyze /dev/stdin -e devnull@robotcoop.com -s "pl_analyze for `date -v-1d "+%D"`"

In the future, pl_analyze will be able to read from STDIN.

== Sample output

  Request Times Summary:          Count   Avg     Std Dev Min     Max
  ALL REQUESTS:                   11      0.576   0.508   0.000   1.470
  
  ThingsController#view:          3       0.716   0.387   0.396   1.260
  TeamsController#progress:       2       0.841   0.629   0.212   1.470
  RssController#uber:             2       0.035   0.000   0.035   0.035
  PeopleController#progress:      2       0.489   0.489   0.000   0.977
  PeopleController#view:          2       0.731   0.371   0.360   1.102
  
  Average Request Time: 0.634
  Request Time Std Dev: 0.498
  
  Slowest Request Times:
          TeamsController#progress took 1.470s
          ThingsController#view took 1.260s
          PeopleController#view took 1.102s
          PeopleController#progress took 0.977s
          ThingsController#view took 0.492s
          ThingsController#view took 0.396s
          PeopleController#view took 0.360s
          TeamsController#progress took 0.212s
          RssController#uber took 0.035s
          RssController#uber took 0.035s
  
  ------------------------------------------------------------------------
  
  DB Times Summary:               Count   Avg     Std Dev Min     Max
  ALL REQUESTS:                   11      0.366   0.393   0.000   1.144
  
  ThingsController#view:          3       0.403   0.362   0.122   0.914
  TeamsController#progress:       2       0.646   0.497   0.149   1.144
  RssController#uber:             2       0.008   0.000   0.008   0.008
  PeopleController#progress:      2       0.415   0.415   0.000   0.830
  PeopleController#view:          2       0.338   0.149   0.189   0.486
  
  Average DB Time: 0.402
  DB Time Std Dev: 0.394
  
  Slowest Total DB Times:
          TeamsController#progress took 1.144s
          ThingsController#view took 0.914s
          PeopleController#progress took 0.830s
          PeopleController#view took 0.486s
          PeopleController#view took 0.189s
          ThingsController#view took 0.173s
          TeamsController#progress took 0.149s
          ThingsController#view took 0.122s
          RssController#uber took 0.008s
          RssController#uber took 0.008s
  
  ------------------------------------------------------------------------
  
  Render Times Summary:           Count   Avg     Std Dev Min     Max
  ALL REQUESTS:                   11      0.219   0.253   0.000   0.695
  
  ThingsController#view:          3       0.270   0.171   0.108   0.506
  TeamsController#progress:       2       0.000   0.000   0.000   0.000
  RssController#uber:             2       0.012   0.000   0.012   0.012
  PeopleController#progress:      2       0.302   0.302   0.000   0.604
  PeopleController#view:          2       0.487   0.209   0.278   0.695
  
  Average Render Time: 0.302
  Render Time Std Dev: 0.251
  
  Slowest Total Render Times:
          PeopleController#view took 0.695s
          PeopleController#progress took 0.604s
          ThingsController#view took 0.506s
          PeopleController#view took 0.278s
          ThingsController#view took 0.197s
          ThingsController#view took 0.108s
          RssController#uber took 0.012s
          RssController#uber took 0.012s
          TeamsController#progress took 0.000s
          TeamsController#progress took 0.000s

== Using pl_analyze_diff

To run the report diff tool, simply give it the names of two reports you wish to
compare.

Here's an example invocation:

    pl_analyze_diff report_b.txt report_a.txt > report_diff.txt

And here's some sample output:

    Request_Times_Summary:                 Count                Avg                  Max                 
    ALL_REQUESTS                           +1.4(16515->22909)   -2.2(0.405->0.18)    -1.6(59.678->37.721)

    SleepwalkersController#update.PUT.xml  +1.4(6249->8793)     -1.1(0.079->0.07)    -2.7(8.328->3.103)  
    SleepwalkersController#update.PUT.csv  +1.4(6245->8807)     -1.0(0.099->0.097)   +1.2(2.536->3.02)   
    SleepwalkersController#show.GET        +1.4(509->710)       -1.2(0.072->0.061)   -2.3(3.505->1.504)  
    SleepwalkersController#show.GET.json   +1.4(496->702)       -1.2(0.076->0.064)   -7.3(4.874->0.663)  
    AccomplicesController#history.GET.csv  +1.4(470->680)       -3.3(5.35->1.618)    -1.5(20.681->13.692)
    WindsController#feeds.GET              +1.4(237->320)       -1.1(0.201->0.183)   +1.5(1.304->1.989)  
    ScamsController#show.GET               +1.3(236->317)       -3.0(11.793->3.869)  -1.6(59.678->37.721)
    SleepwalkersController#update.PUT      -1.1(9->8)           -1.1(0.051->0.047)   -1.2(0.09->0.076)   
    AccomplicesController#show.GET.xml      1.0(2->2)           -1.0(0.102->0.1)     -1.0(0.184->0.179)  
    ScamsController#map.GET                +6.0(2->12)          -3.5(1.075->0.305)   +1.1(2.008->2.112)  
    WindsController#feeds.GET.atom          1.0(1->1)           -1.1(0.061->0.058)   -1.1(0.061->0.058)  
    ScamsController#tag.GET.rss             1.0(1->1)           -1.0(0.134->0.129)   -1.0(0.134->0.129)  

    Unmatched_Actions: 

    ScamsController#index.GET.json                               only in report_a.txt
    Api::V1::MisinterpretationsController#destroy.DELETE.        only in report_a.txt

== What's missing

* More reports
* Command line arguments including:
  * Help
  * What type of log file you've got (if somebody sends patches with tests)
* Read from STDIN
* Have the diff tool output JSON.
