package =  bug
version = 0.0.1
tarname = $(package)
distdir = $(tarname)-$(version)
prefix = /usr/local
export prefix
exec_prefix = $(prefix)
export exec_prefix 
bindir=$(exec_prefix)/bin
export bindir
libdir=$(exec_prefix)/lib
export libdir
all libbug.a install uninstall:
	cd src && $(MAKE) $@

dist: $(distdir).tar.gz

$(distdir).tar.gz : $(distdir)
	tar chof - $(distdir) | gzip -9 -c > $@
	rm -rf $(distdir)

$(distdir): FORCE
	mkdir -p $(distdir)/bug-gsc
	cp bug-gsc/bug-gscpp $(distdir)/bug-gsc/bug-gscpp
	cp bug-gsc/foo.scm $(distdir)/bug-gsc/foo.scm
	mkdir -p $(distdir)/demo
	cp demo/Makefile $(distdir)/demo/Makefile
	cp demo/demo.scm $(distdir)/demo/demo.scm
	cp README $(distdir)/README
	cp LICENSE-2.0.txt $(distdir)/LICENSE-2.0.txt
	cp LGPL.txt $(distdir)/LGPL.txt
	cp Makefile $(distdir)/Makefile
	mkdir -p $(distdir)/src/
	cp src/lang#.scm $(distdir)/src/lang#.scm
	mkdir -p $(distdir)/src/collections/
	cp src/collections/list.bscm $(distdir)/src/collections/list.bscm
	cp src/collections/list#.scm $(distdir)/src/collections/list#.scm
	cp src/lang.bscm $(distdir)/src/lang.bscm
	cp src/Makefile $(distdir)/src/Makefile
	cp src/lang-macros.bscm $(distdir)/src/lang-macros.bscm

distcheck: $(distdir).tar.gz
	gzip -cd $(distdir).tar.gz | tar xvf -
	cd $(distdir) && $(MAKE) demo
	cd $(distdir) && $(MAKE) DESTDIR=$${PWD}/_inst install
	cd $(distdir) && $(MAKE) DESTDIR=$${PWD}/_inst uninstall
	@remaining="`find $${PWD}/$(distdir)/_inst -type f | wc -l`"; \
	if test "$${remaining}" -ne 0; then \
	  echo "*** $${remaining} file(s) remaining in stage directory!"; \
	exit 1; \
	fi	
	cd $(distdir) && $(MAKE) clean
	rm -rf $(distdir)
	@echo "*** Package $(distdir).tar.gz is read for distribution"



FORCE:
	-rm -rf $(distdir).tar.gz >/dev/null 2>&1
	-rm -rf $(distdir) >/dev/null 2>&1

clean:
	cd src && $(MAKE) $@
	cd demo && $(MAKE) $@
	-rm $(distdir).tar.gz

demo: libbug.a
	cd demo && $(MAKE) $@


.PHONY: FORCE all clean install uninstall
