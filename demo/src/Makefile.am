SUFFIXES = .bug.scm .o

.bug.scm.o:
	bug-gscpp bug-demo.bug.scm bug-demo.scm
	gsc -link -l @LIBBUG_INCLUDE_DIR@libbug bug-demo.scm
	gsc -obj bug-demo.c
	gsc -obj bug-demo_.c


bin_PROGRAMS = bug-demo
bug_demo_SOURCES = bug-demo.bug.scm
bug_demo_LDFLAGS = @LIBBUG_LIB_DIR@/libbug.so -lgambit -lm -ldl -lutil bug-demo_.o 

