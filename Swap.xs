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

#ifndef PERL_COMBI_VERSION
#define PERL_COMBI_VERSION (PERL_REVISION * 1000000 + PERL_VERSION * 1000 + \
				PERL_SUBVERSION)
#endif

#if (PERL_COMBI_VERSION >= 5009003)
#define custom_warn_uninit(opdesc) \
	Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED), \
		PL_warn_uninit, "", " in ", opdesc)
#define BACKREFS_IN_HV 1
#else
#define custom_warn_uninit(opdesc) \
	Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED), \
		PL_warn_uninit, " in ", opdesc)
#define BACKREFS_IN_HV 0
#endif

#define DA_SWAP_OVERLOAD_ERR \
	"Can't swap an overloaded object with a non-overloaded one"
#define DA_DEREF_ERR "Can't deref string (\"%.32s\")"

STATIC AV *extract_backrefs(pTHX_ SV *sv) {
	AV *av = NULL;

#if BACKREFS_IN_HV
	if (SvTYPE(sv) == SVt_PVHV && SvOOK(sv)) {
		AV **const avp = Perl_hv_backreferences_p(aTHX_ (HV *) sv);
		av = *avp;
		*avp = NULL;
	}
#endif

	if (!av && SvRMAGICAL(sv)) {
		MAGIC *const mg = mg_find(sv, PERL_MAGIC_backref);
		if (mg) {
			av = (AV *) mg->mg_obj;
			mg->mg_obj = NULL;
			mg->mg_virtual = NULL;
			sv_unmagic(sv, PERL_MAGIC_backref);
		}
	}

	return av;
}

STATIC void install_backrefs(pTHX_ SV *sv, AV *backrefs) {
	if (!backrefs)
		return;

#if BACKREFS_IN_HV
	if (SvTYPE(sv) == SVt_PVHV) {
		AV **const avp = Perl_hv_backreferences_p(aTHX_ (HV *) sv);
		*avp = backrefs;
		return;
	}
#endif

	sv_magic(sv, (SV *) backrefs, PERL_MAGIC_backref, NULL, 0);
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
				custom_warn_uninit("deref");
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
	AV *br1, *br2;
	SV tmp;
    CODE:
	if (!SvROK(r1) || !(r1 = SvRV(r1)) || !SvROK(r2) || !(r2 = SvRV(r2)))
		Perl_croak(aTHX_ "Not a reference");
	if (SvREADONLY(r1) || SvREADONLY(r2))
		Perl_croak(aTHX_ PL_no_modify);
	if (SvAMAGIC(ST(0)) ^ SvAMAGIC(ST(1)))
		Perl_croak(aTHX_ DA_SWAP_OVERLOAD_ERR);
	br1 = extract_backrefs(aTHX_ r1);
	br2 = extract_backrefs(aTHX_ r2);
	tmp = *r1;
	*r1 = *r2;
	*r2 = tmp;
	install_backrefs(aTHX_ r1, br1);
	install_backrefs(aTHX_ r2, br2);
