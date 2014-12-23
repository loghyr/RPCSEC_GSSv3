# Copyright (C) The IETF Trust (2011-2013)
#
# Manage the .xml for the RPCSEC_GSS version3 document.
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=10
VERS=11

XML2RFC=xml2rfc

DRAFT_BASE=draft-ietf-nfsv4-rpcsec-gssv3
DOC_PREFIX=rpcsecgssv3

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@( cd dotx.d ; m4 `basename $<` > ../$@.tmp )
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt dotx dotx-txt

#
# Build the stuff needed to ensure integrity of document.
common: testx dotx html dotx-txt

txt: ${DRAFT_BASE}-$(VERS).txt

html: ${DRAFT_BASE}-$(VERS).html

nr: ${DRAFT_BASE}-$(VERS).nr


#
# Builds the I-D that has just the .x file
#

xml: ${DRAFT_BASE}-$(VERS).xml

clobber:
	$(RM) ${DRAFT_BASE}-$(VERS).txt \
		${DRAFT_BASE}-$(VERS).html \
		${DRAFT_BASE}-$(VERS).nr
	export SPECVERS=$(VERS)
	export VERS=$(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f ${DRAFT_BASE}-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall:
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

${DRAFT_BASE}-$(VERS).txt: ${DRAFT_BASE}-$(VERS).xml
	$(XML2RFC) --text ${DRAFT_BASE}-$(VERS).xml -o $@

${DRAFT_BASE}-$(VERS).html: ${DRAFT_BASE}-$(VERS).xml
	$(XML2RFC) --html ${DRAFT_BASE}-$(VERS).xml -o $@

${DRAFT_BASE}-$(VERS).nr: ${DRAFT_BASE}-$(VERS).xml
	$(XML2RFC) --nroff ${DRAFT_BASE}-$(VERS).xml -o $@

${DOC_PREFIX}_middle_errortoop_autogen.xml: ${DOC_PREFIX}_middle_errors.xml
	./errortbl < ${DOC_PREFIX}_middle_errors.xml > ${DOC_PREFIX}_middle_errortoop_autogen.xml

${DOC_PREFIX}_front_autogen.xml: ${DOC_PREFIX}_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < ${DOC_PREFIX}_front.xml > ${DOC_PREFIX}_front_autogen.xml

${DOC_PREFIX}_rfc_start_autogen.xml: ${DOC_PREFIX}_rfc_start.xml Makefile
	sed -e s/DRAFTVERSION/${DRAFT_BASE}-${VERS}/g < ${DOC_PREFIX}_rfc_start.xml > ${DOC_PREFIX}_rfc_start_autogen.xml

AUTOGEN =	\
		${DOC_PREFIX}_front_autogen.xml \
		${DOC_PREFIX}_rfc_start_autogen.xml \

START_PREGEN = ${DOC_PREFIX}_rfc_start.xml
START=	${DOC_PREFIX}_rfc_start_autogen.xml
END=	${DOC_PREFIX}_rfc_end.xml

FRONT_PREGEN = ${DOC_PREFIX}_front.xml

IDXMLSRC_BASE = \
	${DOC_PREFIX}_middle_start.xml \
	${DOC_PREFIX}_middle_introduction.xml \
	${DOC_PREFIX}_middle_iana.xml \
	${DOC_PREFIX}_middle_end.xml \
	${DOC_PREFIX}_back_front.xml \
	${DOC_PREFIX}_back_references.xml \
	${DOC_PREFIX}_back_acks.xml \
	${DOC_PREFIX}_back_back.xml

IDCONTENTS = ${DOC_PREFIX}_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = ${DOC_PREFIX}_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) ${DOC_PREFIX}_front_autogen.xml Makefile $(END) $(IDCONTENTS) $(AUTOGEN)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do cat $$i >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

${DRAFT_BASE}-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		./rfcincfill.pl draft-tmp.xml $@

genhtml: Makefile gendraft html txt dotx dotx-txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		${DRAFT_BASE}-$(PREVVERS).txt \
		draft-$(VERS) \
		${DRAFT_BASE}-$(VERS).txt \
		${DRAFT_BASE}-$(VERS).html \
		dotx.d/nfsv42.x \
		draft-$(VERS).tar.gz

testx:
	rm -rf testx.d
	mkdir testx.d
	$(MAKE) dotx
	# In Linux, authunix is still used.
	# In Linux, the RPCSEC_GSS library/API has
	# a conflicting data type.
	# In Linux, the gssapi and RPCSEC_GSS headers
	# are placed in bizarre places.
	# In Linux, rpcgen produces a makefile name that
	# just *has* to be different from Solaris.
	( \
		if [ -f /usr/include/rpc/auth_sys.h ]; then \
			cp dotx.d/nfsv42.x testx.d ; \
		else \
			sed s/authsys/authunix/g < dotx.d/nfsv42.x | \
			sed s/auth_sys/auth_unix/g | \
			sed s/AUTH_SYS/AUTH_UNIX/g | \
			sed s/gss_svc/Gss_Svc/g > testx.d/nfsv42.x ; \
		fi ; \
	)
	( cd testx.d ; \
		rpcgen -a nfsv42.x ; )
	( cd testx.d ; \
		rpcgen -a nfsv42.x ; \
		if [ ! -f /usr/include/rpc/auth_sys.h ]; then \
			ln Make* make ; \
			CFLAGS="-I /usr/include/gssglue -I /usr/include/tirpc" ; export CFLAGS ; \
		fi ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; aspell check -p dictionary.pws $$f; done
	cd dotx-id.d ; SPECVERS=$(VERS) $(MAKE) spellcheck

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	${DRAFT_BASE}-$(VERS).txt \
	${DRAFT_BASE}-$(VERS).html \
	${DRAFT_BASE}-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES) dotx.d/nfsv4.x
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		`cat dotx.d/tmp.filelist` \
		`cat dotx-id.d/tmp.filelist`; \
		gzip draft-$(VERS).tar
