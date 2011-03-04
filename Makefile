# Copyright (C) The IETF Trust (2011)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=00
VERS=01

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: draft-williams-rpcsecgssv3-$(VERS).txt

html: draft-williams-rpcsecgssv3-$(VERS).html

nr: draft-williams-rpcsecgssv3-$(VERS).nr

xml: draft-williams-rpcsecgssv3-$(VERS).xml

clobber:
	$(RM) draft-williams-rpcsecgssv3-$(VERS).txt \
		draft-williams-rpcsecgssv3-$(VERS).html \
		draft-williams-rpcsecgssv3-$(VERS).nr
	export SPECVERS := $(VERS)
	export VERS := $(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f draft-williams-rpcsecgssv3-$(VERS).xml
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

draft-williams-rpcsecgssv3-$(VERS).txt: draft-williams-rpcsecgssv3-$(VERS).xml
	rm -f $@ draft-tmp.txt
	sh xml2rfc_wrapper.sh draft-williams-rpcsecgssv3-$(VERS).xml draft-tmp.txt
	mv draft-tmp.txt $@

draft-williams-rpcsecgssv3-$(VERS).html: draft-williams-rpcsecgssv3-$(VERS).xml
	rm -f $@ draft-tmp.html
	sh xml2rfc_wrapper.sh draft-williams-rpcsecgssv3-$(VERS).xml draft-tmp.html
	mv draft-tmp.html $@

draft-williams-rpcsecgssv3-$(VERS).nr: draft-williams-rpcsecgssv3-$(VERS).xml
	rm -f $@ draft-tmp.nr
	sh xml2rfc_wrapper.sh draft-williams-rpcsecgssv3-$(VERS).xml $@.tmp
	mv draft-tmp.nr $@

rpcsecgssv3_front_autogen.xml: rpcsecgssv3_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < rpcsecgssv3_front.xml > rpcsecgssv3_front_autogen.xml

rpcsecgssv3_rfc_start_autogen.xml: rpcsecgssv3_rfc_start.xml Makefile
	sed -e s/VERSIONVAR/${VERS}/g < rpcsecgssv3_rfc_start.xml > rpcsecgssv3_rfc_start_autogen.xml

AUTOGEN =	\
		rpcsecgssv3_front_autogen.xml \
		rpcsecgssv3_rfc_start_autogen.xml

START_PREGEN = rpcsecgssv3_rfc_start.xml
START=	rpcsecgssv3_rfc_start_autogen.xml
END=	rpcsecgssv3_rfc_end.xml

FRONT_PREGEN = rpcsecgssv3_front.xml

IDXMLSRC_BASE = \
	rpcsecgssv3_middle_start.xml \
	rpcsecgssv3_middle_introduction.xml \
	rpcsecgssv3_middle_iana.xml \
	rpcsecgssv3_middle_end.xml \
	rpcsecgssv3_back_front.xml \
	rpcsecgssv3_back_references.xml \
	rpcsecgssv3_back_acks.xml \
	rpcsecgssv3_back_back.xml

IDCONTENTS = rpcsecgssv3_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = rpcsecgssv3_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do echo '<?rfc include="'$$i'"?>' >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

draft-williams-rpcsecgssv3-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		draft-williams-rpcsecgssv3-$(PREVVERS).txt \
		draft-$(VERS) \
		draft-williams-rpcsecgssv3-$(VERS).txt \
		draft-williams-rpcsecgssv3-$(VERS).html \
		draft-williams-rpcsecgssv3-dot-x-04.txt \
		draft-williams-rpcsecgssv3-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: 
	rm -rf testx.d
	mkdir testx.d
	( cd testx.d ; \
		rpcgen -a rpcsecgssv3.x ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; spell +dictionary.txt $$f; done

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	draft-williams-rpcsecgssv3-$(VERS).txt \
	draft-williams-rpcsecgssv3-$(VERS).html \
	draft-williams-rpcsecgssv3-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar
