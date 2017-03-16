bin_PROGRAMS = bugdemo
bugdemo_SOURCES = bugdemo.c \
	bugdemo_.c

bugdemo.scm: bugdemo.bug.scm
	bug-gscpp bugdemo.bug.scm bugdemo.scm

bugdemo.c: bugdemo.scm
	gsc -c bugdemo.scm

bugdemo.o: bugdemo.scm
	gsc -link -l @LIBBUG_INCLUDE_DIR@libbug bugdemo.scm
	gsc -obj bugdemo.c bugdemo_.c

bugdemo_.o: bugdemo.o

