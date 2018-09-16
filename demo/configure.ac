AC_PREREQ([2.68])

AC_INIT([bugdemo], [0.0.1], [William Emerison Six <billsix@gmail.com>], [bugdemo])
AC_CANONICAL_SYSTEM
AC_CONFIG_SRCDIR([src/bugdemo.scm])
AC_CONFIG_HEADER([config.h])
AC_CHECK_HEADER([stdio.h])
AM_INIT_AUTOMAKE()
AC_PROG_CC
AC_PROG_INSTALL
AC_CONFIG_FILES([Makefile
        src/Makefile
        src/config.scm])

export LIBBUG_INCLUDE_DIR=$(pkg-config --variable=includedir libbug)
AC_SUBST(LIBBUG_INCLUDE_DIR)
export LIBBUG_LOADABLE_LIBS=$(pkg-config --variable=loadablelibs libbug)
AC_SUBST(LIBBUG_LOADABLE_LIBS)
export LIBBUG_LIB_DIR=$(pkg-config --variable=libdir libbug)
AC_SUBST(LIBBUG_LIB_DIR)

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

LDFLAGS+="$LIBBUG_LIB_DIR/libbug$LIB_EXTENSION -lgambit -lm -ldl -lutil"

AC_OUTPUT
