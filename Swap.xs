/* $Id: Swap.xs,v 1.6 2004/09/29 14:45:24 xmath Exp $ */

/* Copyright (C) 2003, 2004  Matthijs van Duin <xmath@cpan.org>
 *
 * You may distribute under the same terms as perl itself, which is either 
 * the GNU General Public License or the Artistic License.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_MAGIC_backref
#define PERL_MAGIC_backref '<'
#endif

#ifndef packWARN
#define packWARN(w) (w)
#endif

#define DA_SWAP_OVERLOAD_ERR \
	"Can't swap an overloaded object with a non-overloaded one"
#define DA_DEREF_ERR "Can't deref string (\"%.32s\")"

STATIC MAGIC *mg_extract(SV *sv, int type) {
	MAGIC **mgp, *mg;
	for (mgp = &SvMAGIC(sv); (mg = *mgp); mgp = &mg->mg_moremagic) {
		if (mg->mg_type == type) {
			*mgp = mg->mg_moremagic;
			mg->mg_moremagic = NULL;
			return mg;
		}
	}
	return NULL;
}


MODULE = Data::Swap  PACKAGE = Data::Swap

PROTOTYPES: DISABLE

BOOT:
	CvLVALUE_on(get_cv("Data::Swap::deref", TRUE));

void
deref(...)
    PREINIT:
	I32 i, n = 0;
	SV *sv;
    PPCODE:
	for (i = 0; i < items; i++) {
		if (!SvROK(ST(i))) {
			STRLEN z;
			if (SvOK(ST(i)))
				Perl_croak(aTHX_ DA_DEREF_ERR, SvPV(ST(i), z));
			if (ckWARN(WARN_UNINITIALIZED))
				Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED),
					PL_warn_uninit, " in ", "deref");
			continue;
		}
		sv = SvRV(ST(i));
		switch (SvTYPE(sv)) {
			I32 x;
		case SVt_PVAV:
			if (!(x = av_len((AV *) sv) + 1))
				continue;
			SP += x;
			break;
		case SVt_PVHV:
			if (!(x = HvKEYS(sv)))
				continue;
			SP += x * 2;
			break;
		case SVt_PVCV:
			Perl_croak(aTHX_ "Can't deref subroutine reference");
		case SVt_PVFM:
			Perl_croak(aTHX_ "Can't deref format reference");
		case SVt_PVIO:
			Perl_croak(aTHX_ "Can't deref filehandle reference");
		default:
			SP++;
		}
		ST(n++) = ST(i);
	}
	EXTEND(SP, 0);
	for (i = 0; n--; ) {
		SV *sv = SvRV(ST(n));
		I32 x = SvTYPE(sv);
		if (x == SVt_PVAV) {
			i -= x = AvFILL((AV *) sv) + 1;
			Copy(AvARRAY((AV *) sv), SP + i + 1, x, SV *);
		} else if (x == SVt_PVHV) {
			HE *entry;
			HV *hv = (HV *) sv;
			i -= x = hv_iterinit(hv) * 2;
			PUTBACK;
			while ((entry = hv_iternext(hv))) {
				sv = hv_iterkeysv(entry);
				SPAGAIN;
				SvREADONLY_on(sv);
				SP[++i] = sv;
				sv = hv_iterval(hv, entry);
				SPAGAIN;
				SP[++i] = sv;
			}
			i -= x;
		} else {
			SP[i--] = sv;
		}
	}

void
swap(r1, r2)
	SV *r1
	SV *r2
    PREINIT:
	void *any;
	U32 flags;
	MAGIC *mg1 = NULL;
	MAGIC *mg2 = NULL;
    CODE:
	if (!SvROK(r1) || !(r1 = SvRV(r1)) || !SvROK(r2) || !(r2 = SvRV(r2)))
		Perl_croak(aTHX_ "Not a reference");
	if (SvREADONLY(r1) || SvREADONLY(r2))
		Perl_croak(aTHX_ PL_no_modify);
	if ((SvFLAGS(ST(0)) ^ SvFLAGS(ST(1))) & SVf_AMAGIC)
		Perl_croak(aTHX_ DA_SWAP_OVERLOAD_ERR);
	if (SvMAGICAL(r1))
		mg1 = mg_extract(r1, PERL_MAGIC_backref);
	if (SvMAGICAL(r2))
		mg2 = mg_extract(r2, PERL_MAGIC_backref);
	any = r1->sv_any;
	flags = r1->sv_flags;
	r1->sv_any = r2->sv_any;
	r1->sv_flags = r2->sv_flags;
	r2->sv_any = any;
	r2->sv_flags = flags;
	if (mg1) {
		SvUPGRADE(r1, SVt_PVMG);
		mg1->mg_moremagic = SvMAGIC(r1);
		SvMAGIC(r1) = mg1;
	}
	if (mg2) {
		SvUPGRADE(r2, SVt_PVMG);
		mg2->mg_moremagic = SvMAGIC(r2);
		SvMAGIC(r2) = mg2;
	}
