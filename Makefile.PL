# $Id: Makefile.PL,v 1.3 2004/09/29 14:45:24 xmath Exp $

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Data::Swap',
	VERSION_FROM	=> 'lib/Data/Swap.pm',
	ABSTRACT_FROM	=> 'lib/Data/Swap.pm',
	AUTHOR		=> 'Matthijs van Duin <xmath@cpan.org>',
	NO_META		=> 42
);
