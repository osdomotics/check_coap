check_coap
==========

check-coap plugins for Nagios monitoring system

=== Install OMD Debian PC or Raspberry Pi ===

Install GPG Key

First step is to import the gpg key. This step has to be done only once.

  gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7
  gpg --armor --export F8C1CA08A57B9ED7 | apt-key add -

  echo 'deb http://labs.consol.de/repo/stable/debian wheezy main' >> /etc/apt/sources.list
  apt-get update
  apt-get install omd

or over wget

 wget https://labs.consol.de/repo/stable/debian/dists/wheezy/main/binary-armhf/omd-1.00_0.wheezy_armhf.deb
 dpkg -i omd-1.00_0.wheezy_armhf.deb


# Debian install
apt-get install libnagios-plugin-perl libnetaddr-ip-perl

check_coap needs coap-client tool
install libcoap:

German instructions: http://osdwiki.open-entry.com/doku.php/de:ideen:firststepsmerkurboard#coap-client

wget http://downloads.sourceforge.net/project/libcoap/coap-18/libcoap-4.0.3.tar.gz

tar -xzf libcoap-4.0.3.tar.gz

cd libcoap-4.0.3

autoconf

./configure

make

cp examples/coap-client /usr/local/bin/

=== check_coap_alive.pl ===

Usage: check_coap_alive.pl -H <host> [-m <match>] [ -p ]
  [ -w <warning> ] [ -c <critical> ] [ -t <timeout> ]

Example:
./check_coap_alive.pl -H aaaa::221:2eff:ff00:1ef9


=== check_coap.pl ===

Usage: check_coap.pl -H <host> -u <coap uri> [ -p ]
  [ -w <warning> ] [ -c <critical> ] [ -t <timeout> ]

Example:
./check_coap.pl -H fd00::221:2eff:ff00:1ef9 -u s/battery -w 2.100: -c 2.000: -D 100 -p

COAP OK - sensors/battery is 24.5 | s/battery=24.5;2.100:;2.000:

=== OMD ===

Now create a monitoring instance (OMD calls this “site”):

 omd create mysite

And let's start Nagios and all other processes:

 omd start mysite

If you are use OMD (Open Monitorin Distribution) copy the check_coap scripts to:

/omd/sites/mysite/lib/nagios/plugins

Copy the config scripts to
/omd/sites/mysite/etc/nagios/conf.d


Links:

http://labs.consol.de/repo/stable/#_debian_wheezy_7_0
http://omdistro.org/doc/quickstart_debian_ubuntu

