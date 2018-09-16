GSC=gsc

bin_PROGRAMS = bugdemo
bugdemo_SOURCES = bugdemo.c \
	bugdemo_.c

bugdemo.c: bugdemo.scm
	$(GSC) -c bugdemo.scm

bugdemo.o: bugdemo.scm
	$(GSC) -link -l @LIBBUG_INCLUDE_DIR@libbug bugdemo.scm
	$(GSC) -obj bugdemo.c bugdemo_.c

bugdemo_.o: bugdemo.o
