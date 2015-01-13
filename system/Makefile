all: test


test: lang-macros.scm lang.c collections/list.c
	gsc -link lang.c collections/list.c
	gsc -obj lang.c collections/list.c collections/list_.c
	gcc lang.o collections/list.o collections/list_.o -lgambc -lm -ldl -lutil -o $@


lang-macros.scm: lang-macros.bscm
	bug-gscpp lang-macros.bscm lang-macros.scm

lang.c: lang.bscm
	bug-gscpp lang.bscm lang.scm
	gsc -c lang.scm

collections/list.c: collections/list.bscm
	bug-gscpp collections/list.bscm collections/list.scm
	gsc -c collections/list.scm

clean:
	-rm test
	-rm lang.o
	-rm lang.c
	-rm lang.scm
	-rm lang-macros.scm
	-rm collections/list.o
	-rm collections/list.c
	-rm collections/list.scm
	-rm collections/list_.o
	-rm collections/list_.c


.PHONY: all clean
