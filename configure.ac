#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])
AC_INIT([bug],[0.0.8], [billsix@gmail.com])

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL

# Checks for libraries.
# FIXME: Replace `main' with a function in `-ldl':
#AC_CHECK_LIB([dl], [main])
# FIXME: Replace `main' with a function in `-lgambc':
#AC_CHECK_LIB([gambc], [main])
# FIXME: Replace `main' with a function in `-link':
#AC_CHECK_LIB([ink], [main])
# FIXME: Replace `main' with a function in `-lm':
#AC_CHECK_LIB([m], [main])
# FIXME: Replace `main' with a function in `-lutil':
#AC_CHECK_LIB([util], [main])

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([Makefile
                 bug-gsc/Makefile
                 src/Makefile
		 src/config.scm
		 pkgconfig/libbug.pc
		 ])
GAMBITS_C_COMPILER=$(gambc-cc | grep '^C_COMPILER' | cut -d '"' -f 2)
AC_SUBST(GAMBITS_C_COMPILER)
LIB_EXTENSION=$(gambc-cc | grep '^LIB_EXTENSION' | cut -d '"' -f 2)
AC_SUBST(LIB_EXTENSION)
if gambc-cc | grep '^FLAGS_LIB'| grep '\-dynamiclib'
  then SHARED_LIB_FLAG=-dynamiclib;
  else SHARED_LIB_FLAG=-shared;
fi
AC_SUBST(SHARED_LIB_FLAG)

AC_SUBST(ac_unique_file)
AC_CONFIG_SRCDIR(src/config.scm.in)
AC_OUTPUT

