check_coap
==========

check coap  for monitoring systems

# Debian install
apt-get install libnagios-plugin-perl libnetaddr-ip-perl


=== check_coap_alive.pl ===

Usage: check_coap_alive.pl -H <host> [-m <match>] [ -p ]
  [ -w <warning> ] [ -c <critical> ] [ -t <timeout> ]

Example:
./check_coap_alive.pl -H [aaaa::221:2eff:ff00:1ef9]


=== check_coap.pl ===

Usage: check_coap.pl -H <host> -u <coap uri> [ -p ]
  [ -w <warning> ] [ -c <critical> ] [ -t <timeout> ]

Example:
./check_coap.pl -H [aaaa::221:2eff:ff00:1ef9] -u sensors/battery -w 2.100: -c 2.000: -D 100 -p

COAP OK - sensors/battery is 24.5 | sensors/battery=24.5;2.100:;2.000: