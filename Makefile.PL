# $Id: Makefile.PL,v 1.1 2003/06/30 19:18:33 xmath Exp $

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Data::Swap',
	VERSION_FROM	=> 'lib/Data/Swap.pm',
	ABSTRACT_FROM	=> 'lib/Data/Swap.pm',
	AUTHOR		=> 'Matthijs van Duin <xmath@cpan.org>'
);
