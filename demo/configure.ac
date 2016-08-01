AC_PREREQ([2.68])

AC_INIT([bug-demo], [0.0.1], [William Emerison Six <billsix@gmail.com>], [bug-demo])
AC_CANONICAL_SYSTEM
AC_CONFIG_SRCDIR([src/bug-demo.bug.scm])
AC_CONFIG_HEADER([config.h])
AC_CHECK_HEADER([stdio.h])
AC_PROG_CC
AC_PROG_INSTALL
AC_CONFIG_FILES([Makefile src/Makefile])

export LIBBUG_INCLUDE_DIR=$(pkg-config --variable=includedir libbug)
AC_SUBST(LIBBUG_INCLUDE_DIR)
export LIBBUG_LOADABLE_LIBS=$(pkg-config --variable=loadablelibs libbug)
AC_SUBST(LIBBUG_LOADABLE_LIBS)
export LIBBUG_LIB_DIR=$(pkg-config --variable=libdir libbug)
AC_SUBST(LIBBUG_LIB_DIR)


AC_OUTPUT
