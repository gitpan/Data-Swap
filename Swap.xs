/* $Id: Swap.xs,v 1.2 2003/06/30 19:34:14 xmath Exp $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef SV *SVref;

MODULE = Data::Swap  PACKAGE = Data::Swap

PROTOTYPES: DISABLE

void
swap(foo, bar)
	SVref foo
	SVref bar
    PREINIT:
	void *any;
	U32 flags;
	MAGIC *mg1 = NULL;
	MAGIC *mg2 = NULL;
    CODE:
	if (SvREADONLY(foo) || SvREADONLY(bar))
		croak(PL_no_modify);
	if (SvMAGICAL(foo) && (mg1 = mg_find(foo, '<')))
		SvUPGRADE(bar, SVt_PVMG);
	if (SvMAGICAL(bar) && (mg2 = mg_find(bar, '<')))
		SvUPGRADE(foo, SVt_PVMG);
	if (mg1 || mg2) {
		if (!mg1) {
			sv_magic(foo, NULL, '<', NULL, 0);
			mg1 = mg_find(foo, '<');
		}
		if (!mg2) {
			sv_magic(bar, NULL, '<', NULL, 0);
			mg2 = mg_find(bar, '<');
		}
		any = mg1->mg_obj;
		mg1->mg_obj = mg2->mg_obj;
		mg2->mg_obj = any;
	}
	any = foo->sv_any;
	flags = foo->sv_flags;
	foo->sv_any = bar->sv_any;
	foo->sv_flags = bar->sv_flags;
	bar->sv_any = any;
	bar->sv_flags = flags;
