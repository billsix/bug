#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])
AC_INIT([bug],[0.0.8], [billsix@gmail.com])
# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL


AC_CONFIG_FILES([Makefile
                 bug-gsc/Makefile
                 src/Makefile
		 src/config.scm
		 pkgconfig/libbug.pc
		 ])
GAMBITS_C_COMPILER=$(gambcomp-C | grep '^C_COMPILER' | cut -d '"' -f 2)
AC_SUBST(GAMBITS_C_COMPILER)
LIB_EXTENSION=$(gambcomp-C | grep '^LIB_EXTENSION' | cut -d '"' -f 2)
AC_SUBST(LIB_EXTENSION)
if gambcomp-C | grep '^FLAGS_LIB'| grep '\-dynamiclib'
  then SHARED_LIB_FLAG=-dynamiclib;
  else SHARED_LIB_FLAG=-shared;
fi
AC_SUBST(SHARED_LIB_FLAG)


AC_ARG_ENABLE(pdf,
              AC_HELP_STRING([--enable-pdf],
                             [build the PDF version of the code (default is NO)]),
              ENABLE_DOC=$enableval,
              ENABLE_DOC=no)
dnl if test "$ENABLE_DOC" = yes; then
dnl   need to test for pdflatex
dnl fi
AC_SUBST(ENABLE_DOC)

AC_SUBST(ac_unique_file)
AC_CONFIG_SRCDIR(src/config.scm.in)
AC_OUTPUT


