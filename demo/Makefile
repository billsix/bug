all: demo

%.scm : %.bscm
	bug-gscpp $< $@ 

%.c : %.scm
	gsc -c $< 

%.o : %.c
	gsc -obj $< 

target = demo
sources = ../src/lang.scm ../src/lang-macros.scm demo.c

$(target):  $(sources)
	gsc -link demo.c
	gsc -obj demo.c demo_.c
	gcc -o demo ../src/libbug.a demo.o demo_.o    -lgambc -lm -ldl -lutil

clean:
	-rm demo.c demo_.c *.o
	-rm $(target)

.PHONY: all clean
