# @configure_input@

package = @PACKAGE_NAME@
version = @PACKAGE_VERSION@
tarname = @PACKAGE_TARNAME@
distdir = $(tarname)-$(version)
prefix = @prefix@
exec_prefix = @exec_prefix@
bindir = @bindir@
libdir = @libdir@

all:  bug-gscpp bug-gsi



bug-gscpp: bug-gscpp.c
	$(CC) -std=gnu99 bug-gscpp.c  -o bug-gscpp

bug-gsi: bug-gsi.c
	$(CC) -std=gnu99 bug-gsi.c  -o bug-gsi


install:
	install -d $(DESTDIR)$(bindir)
	install -m 0755 bug-gscpp $(DESTDIR)$(bindir)
	install -m 0755 bug-gsi $(DESTDIR)$(bindir)
	install -m 0755 bug2tex $(DESTDIR)$(bindir)

uninstall:
	rm $(DESTDIR)$(bindir)/bug-gscpp
	rm $(DESTDIR)$(bindir)/bug-gsi
	rm $(DESTDIR)$(bindir)/bug2tex

Makefile: Makefile.in ../config.status
	cd .. && ./config.status $@

../config.status: ../configure
	cd .. && ./config.status --recheck


.PHONY: all clean
