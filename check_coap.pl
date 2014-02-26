#!/usr/bin/perl -w
#
# check_coap.pl
#
# v1.0 2013-05-13 GS (goesta@smekal.at)
#
# check CoAP resources using libcoap example client

use strict;
use Nagios::Plugin;
use NetAddr::IP;

# create a brand new Nagios::Plugin object, including basic documentation.
my $plugin = Nagios::Plugin->new(
  usage => "Usage: %s -H <host> -u <coap uri> [ -p ]
  [ -w <warning> ] [ -c <critical> ] [ -t <timeout> ]",
  blurb => "Compares a coap uri to two thresholds.",
  version => 'v1.0',
);

# add the required commandline parameters
$plugin->add_arg(
  spec => 'host|H=s',
  help => 'hostname',
  required => 1,
);
$plugin->add_arg(
  spec => 'uri|u=s',
  help => 'coap uri',
  required => 1,
);
$plugin->add_arg(
  spec => 'type|y=s',
  help => 'expected data type [s|n] (default: numeric)',
  default => 'n',
);
$plugin->add_arg(
  spec => 'string|s=s',
  help => 'expected string (perl regexp - for string data type)',
);
$plugin->add_arg(
  spec => 'perfdata|p',
  help => 'output performance data',
);
$plugin->add_arg(
  spec => 'warning|w=s',
  help => 'warning threshold',
  default => 10,
);
$plugin->add_arg(
  spec => 'critical|c=s',
  help => 'critical threshold',
  default => 100,
);
$plugin->add_arg(
  spec => 'debug|d',
  help => 'debug output',
);
$plugin->add_arg(
  spec => 'divider|D=f',
  help => 'divide sensor reading (i.e. 1000 for battery, 100 for cputemp)',
  default => 1,
);
$plugin->add_arg(
  spec => 'kelvin|K',
  help => 'convert thresholds and measurement to Kelvin before comparison',
);

# get and process commandline options
$plugin->getopts;

my $debug = 1 if $plugin->opts->debug;

sub add_threshold_offset {
# add a fixed offset to a nagios style threshold
# returns undef if the pattern is no valid nagios threshold
  my $returnvalue;
  my $thresh = shift;
  my $offset = shift;
  # dissect a legal nagios threshold
  if ( $thresh =~ /^([~@]?)([-+]?\d*)(:?)([-+]?\d*)$/ ) {
    my ($pre, $lower, $colon, $upper) = ($1, $2, $3, $4);
    $lower += $offset if $lower;
    $upper += $offset if $upper;
    # reassemble the parts
    $returnvalue = $pre . $lower . $colon . $upper;
  }
  return $returnvalue;
}

# if we get a naked IPv6 address, we must armor it with square brackets
my $host = $plugin->opts->host;
my $iptest = NetAddr::IP->new($host);
if ( $iptest ) {
  $host = "[".$host."]";
}

my $warning = $plugin->opts->warning;
my $critical = $plugin->opts->critical;
my $nagios_value;
# Nagios::Plugin does not handle negative values too well - there are no
# temperatures below zero Kelvin ;-)
if ( $plugin->opts->kelvin ) {
  $warning = add_threshold_offset($warning, 273.15);
  $plugin->nagios_die('please provide a valid nagios warning threshold.')
    unless $warning;
  $critical = add_threshold_offset($critical, 273.15);
  $plugin->nagios_die('please provide a valid nagios critical threshold.')
    unless $critical;
}

my $coap_value;
# fetching data from the node ...
eval {
  print "entering eval ..." if $debug;
  alarm($plugin->opts->timeout);	# set timeout trigger
  open (COAP, "coap-client -m get coap://".$host.":5683/".$plugin->opts->uri." 2>/dev/null |")
      or $plugin->nagios_die ("Cannot contact CoAP host:\n$!");
  print "open done.\n" if $debug;
  while (<COAP>) {
    print "$_" if $debug;
    next unless (/^([-0-9\.]+)/);
    print ("'",$1,"' '",$plugin->opts->divider,"'\n") if $debug;
    $coap_value = $1 / $plugin->opts->divider;
    if ( $plugin->opts->kelvin ) { $nagios_value = $coap_value + 273.15; }
    else { $nagios_value = $coap_value; }
  }
  print "... eval done\n" if $debug;
  alarm(0);
};
if ($@) {
  $plugin->nagios_die ("network timeout.");
}
print "network done.\n" if $debug;
close (COAP);

unless ($coap_value) {
  $plugin->nagios_exit(
    return_code => 3,
    message => 'did not get valid response from sensor',
  );
}

# in case we want to draw a silly graph ...
if (defined $plugin->opts->perfdata) {
  $plugin->add_perfdata(
    label => $plugin->opts->uri,
    value => $coap_value,
    warning => $plugin->opts->warning,
    critical => $plugin->opts->critical,
  ); # we also could add 'min' and 'max' if we liked ... maybe later
}

# now do the dirty work
$plugin->nagios_exit(
  return_code => $plugin->check_threshold( 
    check => $nagios_value, warning => $warning, critical => $critical
  ),
  message => $plugin->opts->uri." is ".$coap_value,
);

