#!/usr/bin/perl -I../blib/lib
# $Id: synopsis.t,v 1.3 2003/06/30 20:00:17 xmath Exp $

BEGIN { $\ = $/; print "1..3" }

use Data::Swap;

my $p = [];
my $q = {};
my $s = "$p $q";
print $s =~ s/^ARRAY(\(0x[0-9a-f]+\)) HASH(\(0x[0-9a-f]+\))\z/HASH$1 ARRAY$2/
	? "ok 1" : "not ok 1";
swap $p, $q;
print "$p $q" eq $s ? "ok 2" : "not ok 2";

my $x = {};
my $y = $x;                 # $x and $y point to the same thing
swap $x, [1, 2, 3];         # swap the referent with an array
print "@$y" eq "1 2 3" ? "ok 3" : "not ok 3";

# vim: ft=perl
