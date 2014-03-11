#!/usr/bin/perl -w
#
# check_coap_alive.pl
#
# v1.0 2013-05-13 GS (goesta@smekal.at)
#
# check CoAP host for resource /info

use strict;
use Nagios::Plugin;
use NetAddr::IP;
use Time::HiRes qw( gettimeofday tv_interval );

# create a brand new Nagios::Plugin object, including basic documentation.
my $plugin = Nagios::Plugin->new(
  usage => "Usage: %s -H <host> [-m <match>] [ -p ]
  [ -w <warning> ] [ -c <critical> ] [ -t <timeout> ]",
  blurb => "Checks weather CoAP UIR /info contains a keyword.",
  version => 'v1.0',
);

# add the required commandline parameters
$plugin->add_arg(
  spec => 'host|H=s',
  help => 'hostname',
  required => 1,
);
$plugin->add_arg(
  spec => 'match|m=s',
  help => 'keyword',
  default => 'version',
);
$plugin->add_arg(
  spec => 'perfdata|p',
  help => 'output performance data',
);
$plugin->add_arg(
  spec => 'warning|w=s',
  help => 'warning threshold /s',
  default => 5,
);
$plugin->add_arg(
  spec => 'critical|c=s',
  help => 'critical threshold /s',
  default => 10,
);
$plugin->add_arg(
  spec => 'debug|d',
  help => 'debug output',
);

# get and process commandline options
$plugin->getopts;

my $debug = 1 if $plugin->opts->debug;

# if we get a naked IPv6 address, we must armor it with square brackets
my $host = $plugin->opts->host;
my $iptest = NetAddr::IP->new($host);
if ( $iptest ) {
  $host = "[".$host."]";
}

my $warning = $plugin->opts->warning;
my $critical = $plugin->opts->critical;
my $time_elapsed;
my $matchstring = $plugin->opts->match;
my $matchcount;

# fetching data from the node ...
eval {
  print "entering eval ..." if $debug;
  alarm($plugin->opts->timeout);	# set timeout trigger
  my $time_start = [gettimeofday];
  open (COAP, "coap-client -m get coap://".$host.":5683/info 2>/dev/null |")
      or $plugin->nagios_die ("Cannot contact CoAP host:\n$!");
  print "open done.\n" if $debug;
  while (<COAP>) {
    print "$_" if $debug;
    next unless (/"$matchstring"/);
    ++$matchcount;
  }
  close (COAP);
  $time_elapsed = tv_interval ( $time_start );
  print "... eval done\n" if $debug;
  alarm(0);
};
if ($@) {
  $plugin->nagios_die ("network timeout.");
}
print "network done.\n" if $debug;

unless ($matchcount) {
  $plugin->nagios_exit(
    return_code => 3,
    message => 'did not get valid response from sensor',
  );
}

# in case we want to draw a silly graph ...
if (defined $plugin->opts->perfdata) {
  $plugin->add_perfdata(
    label => 'CoAP latency',
    value => $time_elapsed,
    uom => 's',
    warning => $plugin->opts->warning,
    critical => $plugin->opts->critical,
  ); # we also could add 'min' and 'max' if we liked ... maybe later
}

# now do the dirty work
$plugin->nagios_exit(
  return_code => $plugin->check_threshold( 
    check => $time_elapsed, warning => $warning, critical => $critical
  ),
  message => "response time ".$time_elapsed." s",
);

