#
# Semigroups GAP package
#
# This file is part of the build system of a GAP kernel extension.
# Requires GNU autoconf, GNU automake and GNU libtool.
#

dnl ##
dnl ## Setup autoconf
dnl ##
AC_PREREQ([2.68])
AC_INIT([semigroups], m4_esyscmd([tr -d '\n' < .VERSION]))
AC_CONFIG_SRCDIR([src/pkg.cc])
AC_CONFIG_HEADER([src/_pkgconfig.h:cnf/pkgconfig.h.in])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([cnf])

dnl ##
dnl ## Get canonical host info
dnl ##
AC_CANONICAL_HOST

dnl ##
dnl ## Setup automake
dnl ##
AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects nostdinc])
AM_SILENT_RULES([yes])
AM_PROG_AR

AX_PREFIX_CONFIG_H([src/semigroups-config.h],[],[src/_pkgconfig.h])

dnl ## abs_top_builddir seems to hold the top build dir for the subpackage
dnl ## libsemigroups which is why this contains ../ 
dnl ## FIXME figure out how to do this properly
AC_PREFIX_DEFAULT('${abs_top_builddir}/../bin/')

dnl ##
dnl ## Set the language
dnl ##
AC_PROG_CXX
AC_LANG([C++])

AX_CXX_COMPILE_STDCXX_11(,[mandatory])

dnl ##
dnl ## Setup libtool (for building the GAP kernel extension)
dnl ##
LT_PREREQ([2.4.2])
LT_INIT([disable-static dlopen win32-dll])

dnl ##
dnl ## Locate the GAP root dir
dnl ##
FIND_GAP

dnl ##
dnl ## Check for pthread, this seems to be required to compile with GCC
dnl ##
AX_PTHREAD(,[AC_MSG_ERROR([pthread is required])])
AC_CHECK_LIB([pthread], [pthread_create])

dnl ##
dnl ## Detect Windows resp. Cygwin
dnl ##
case $host_os in
  *cygwin* ) CYGWIN=yes;;
         * ) CYGWIN=no;;
esac
AM_CONDITIONAL([SYS_IS_CYGWIN], [test "$CYGWIN" = "yes"])
if test "$CYGWIN" = "yes"; then
  AC_DEFINE(SYS_IS_CYGWIN32, 1, are we on CYGWIN?)
else
  AC_DEFINE(SYS_IS_CYGWIN32, 0, are we on CYGWIN?)
fi

dnl ## Check for libsemigroups
AX_CHECK_LIBSEMIGROUPS

dnl ## User setting: Debug mode (off by default)
AC_ARG_ENABLE([debug],
    [AS_HELP_STRING([--enable-debug], [enable debug mode])],
    [AC_DEFINE([KERNEL_DEBUG], [1], [define if building in debug mode])],
    [enable_debug=no]
    )
AC_MSG_CHECKING([whether to enable debug mode])
AC_MSG_RESULT([$enable_debug])

## TODO check that the compiler supports these flags
AS_IF([test "x$enable_debug" = xyes],
    [AC_SUBST(CXXFLAGS, '-g3 -O0 -Wall -Wextra -Wno-unused-parameter -Wtype-limits -Wformat-security -Wpointer-arith -Wno-div-by-zero -Wreturn-type -Wswitch -Wsizeof-array-argument -Wunused-label -fno-omit-frame-pointer -Wno-c++11-extensions -Wshadow -Wint-conversion')])

AS_IF([test "x$enable_debug" = xyes],
    [AC_SUBST(CFLAGS, '-g3 -O0 -Wall -Wextra -Wno-unused-parameter -Wtype-limits -Wformat-security -Wpointer-arith -Wno-div-by-zero -Wreturn-type -Wswitch -Wsizeof-array-argument -Wunused-label -fno-omit-frame-pointer -Wshadow -Wint-conversion')])

AM_CONDITIONAL([KERNEL_DEBUG], [test "x$enable_debug" = xyes])

AC_ARG_WITH([march-native],
            [AS_HELP_STRING([--without-march-native], 
                            [do not use compile flag -march=native even if available])]
           )

AS_IF([test "x$with_march_native" == "xno" ],
      [AC_MSG_NOTICE([the compile flag -march=native will not be used even if available])])

AS_IF([test "x$with_march_native" != "xno"],
      [AX_CHECK_COMPILE_FLAG(-march=native, AX_APPEND_FLAG(-march=native))])

dnl ##
dnl ## Output everything
dnl ##
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
