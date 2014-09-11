all:
	gsc -c system/lang.scm
	gsc -c system/collections/list.scm
	gsc -link system/lang.c system/collections/list.c
	gsc -obj system/lang.c system/collections/list.c system/collections/list_.c
	gcc -o test system/lang.o system/collections/list.o system/collections/list_.o -lgambc -lm -ldl -lutil
clean:
	-rm test
	-rm system/lang.o
	-rm system/lang.c
	-rm system/collections/list.o
	-rm system/collections/list.c
	-rm system/collections/list_.o
	-rm system/collections/list_.c


