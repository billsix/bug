all: libbug.a

%.scm : %.bscm
	bug-gscpp $< $@ 

%.c : %.scm
	gsc -c $< 

%.o : %.c
	gsc -obj $< 

libbug.a: lang-macros.scm lang.o collections/list.o
	ar rcs libbug.a lang.o collections/list.o

clean:
	-rm libbug.a collections/list.o  lang.o lang.scm lang-macros.scm

install:
	install -d $(DESTDIR)$(libdir)
	install -m 0755 libbug.a $(DESTDIR)$(libdir)

uninstall:
	rm $(DESTDIR)$(libdir)/libbug.a 

.PHONY: all clean install uninstall
