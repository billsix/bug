#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.68])
AC_INIT([bug],[0.0.2], [billsix@gmail.com])

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
		 ])
AC_SUBST(ac_unique_file)
AC_CONFIG_SRCDIR(src/config.scm.in)
AC_OUTPUT

