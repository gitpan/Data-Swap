# $Id: Swap.pm,v 1.5 2003/07/03 09:36:50 xmath Exp $

package Data::Swap;

=head1 NAME

Data::Swap - Swap referenced variables, type-agnostic

=head1 SYNOPSIS

    use Data::Swap;

    my $p = [];
    my $q = {};
    print "$p $q\n";		# ARRAY(0x965cc) HASH(0x966b0)
    swap $p, $q;
    print "$p $q\n";		# HASH(0x965cc) ARRAY(0x966b0)

    my $x = {};
    my $y = $x;			# $x and $y point to the same thing
    swap $x, [1, 2, 3];		# swap the referent with an array
    print "@$y\n";

=head1 DESCRIPTION

Should be fairly self-explanatory.  This module allows you to swap two 
variables by reference.  The module doesn't care about their type.

My own application of this function is to change the base type of an object 
after it has been created, like:

    swap $self, bless $replacement, $newclass;

(for on-demand loading of objects)

=head1 FUNCTIONS

This module has only one function, which is exported by default:

=over 4

=item swap($ref1, $ref2)

Swaps the variable referenced by $ref1 by the one referenced by $ref2.  The 
two variables may be of different types.

You can't swap an overloaded object with a non-overloaded one.

=back

=head1 KNOWN ISSUES

Don't change the type of a directly accessible variable.. that is, don't do 
stuff like:

    my ($x, @y);
    swap \$x, \@y;
    print "@y";

Unless you enjoy segfaults ofcourse.

Unforunately, there is no good way for me detect this situation during swap.

=head1 AUTHOR

Matthijs van Duin <xmath@cpan.org>

Copyright (C) 2003  Matthijs van Duin.  All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.02';

use base 'Exporter';
use base 'DynaLoader';
use base 'AutoLoader';

our @EXPORT = qw(swap);

bootstrap Data::Swap $VERSION;

1;
