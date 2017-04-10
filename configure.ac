#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([libbug],[0.1.0], [billsix@gmail.com])
# Checks for programs.
AC_CONFIG_HEADER([config.h])
AC_PROG_CC
AC_PROG_INSTALL

AC_CANONICAL_SYSTEM

AC_CONFIG_FILES([Makefile
                 bug-gsc/Makefile
                 bug-gsc/bug-gsi-config.h
		 demo/env.sh
                 man/bug-create-project.1
                 man/bug-gscpp.1
                 man/bug-gsi.1
                 src/Makefile
		 src/config.scm
		 pkgconfig/libbug.pc
                 bug-create-project
])


case "$target_os" in
     mingw* | cygwin*)
             LIB_EXTENSION=".dll"
             SHARED_LIB_FLAG="-shared"
	     LIBRARY_NAME=$PACKAGE_NAME$LIB_EXTENSION
	     SO_FLAGS=-lws2_32
             ;;
    darwin*)
             LIB_EXTENSION=".dylib"
             SHARED_LIB_FLAG="-dynamiclib"
	     LIBRARY_NAME=$PACKAGE_NAME$LIB_EXTENSION
	     SO_FLAGS=
             ;;
          *)
             LIB_EXTENSION=".so"
             SHARED_LIB_FLAG="-shared"
	     LIBRARY_NAME=$PACKAGE_NAME$LIB_EXTENSION
	     SO_FLAGS=-Wl,-soname=$LIBRARY_NAME
             ;;
esac

AC_SUBST(LIB_EXTENSION)
AC_SUBST(SHARED_LIB_FLAG)
AC_SUBST(LIBRARY_NAME)
AC_SUBST(SO_FLAGS)



AC_CHECK_PROG(GSC_CHECK,gsc,yes)
if test x"$GSC_CHECK" != x"yes" ; then
    AC_MSG_ERROR([Please install Gambit before installing.])
fi



AC_ARG_ENABLE(pdf,
              AC_HELP_STRING([--enable-pdf],
                             [build the PDF version of the code (default is NO)]),
              ENABLE_PDF=$enableval,
              ENABLE_PDF=no)
if test "$ENABLE_PDF" = yes; then
   AC_CHECK_PROG(PDFLATEX_CHECK,pdflatex,yes)
   if test x"$PDFLATEX_CHECK" != x"yes" ; then
      AC_MSG_ERROR([Please install "pdflatex" if you want to enable creation of the PDF])
   fi
   AC_CHECK_PROG(MAKEINDEX_CHECK,makeindex,yes)
   if test x"$MAKEINDEX_CHECK" != x"yes" ; then
      AC_MSG_ERROR([Please install texlive before installing.])
   fi

fi
AC_SUBST(ENABLE_PDF)

BUG_BUILD_DATE=$(date +'%d %B %Y')
AC_SUBST(BUG_BUILD_DATE)

AC_SUBST(ac_unique_file)
AC_CONFIG_SRCDIR(src/config.scm.in)
AC_OUTPUT


