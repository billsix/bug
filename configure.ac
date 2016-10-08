#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([libbug],[0.0.8], [billsix@gmail.com])
# Checks for programs.
AC_CONFIG_HEADER([config.h])
AC_PROG_CC
AC_PROG_INSTALL

AC_CANONICAL_SYSTEM

AC_CONFIG_FILES([Makefile
                 bug-gsc/Makefile
                 bug-gsc/bug-gsi-config.h
		 demo/env.sh
                 src/Makefile
		 src/config.scm
		 pkgconfig/libbug.pc
		 ])


case "$target_os" in
     mingw* | cygwin*)
             LIB_EXTENSION=".dll"
             ;;
    darwin*)
             LIB_EXTENSION=".dylib"
             SHARED_LIB_FLAG="-dynamiclib"
             ;;
          *)
             LIB_EXTENSION=".so"
             SHARED_LIB_FLAG="-shared"
             ;;
esac

AC_SUBST(LIB_EXTENSION)
AC_SUBST(SHARED_LIB_FLAG)


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


AC_SUBST(ac_unique_file)
AC_CONFIG_SRCDIR(src/config.scm.in)
AC_OUTPUT


