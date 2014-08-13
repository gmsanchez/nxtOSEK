#!/bin/sh
#
# Copyright (c) 2008 the NxOS developers
#
# See AUTHORS for a full list of the developers.
#
# Redistribution of this file is permitted under
# the terms of the GNU Public License (GPL) version 2.
#
# Build an ARM cross-compiler toolchain (including binutils, gcc and
# newlib) on autopilot.


################################
# Modification by loic.cuvillon :
# 1-august2009: download from NxOS website and modified a bit to build
# a nxtOSEK compatible toolchain 
#	-remove --with-float=soft
#	-add multibs options (mhard-float/msoft-float) to t-arm-elp (gcc/config)#	-add c++ compiler
#	-set compiler to gcc-4.2 (ubuntu 8.10)

# 30-january 2010: update to gcc 4.4 (ubuntu 9.10) and rectify flags for c++ support in gcc>4.0
#	-reverse to wget instead of curl to perform downloads
#	-add comments (#)
#	-add howto for manual installation at end of the file

# 1 may 2010: 
#	-comment gdb compilation

# Dec 21 2011
# Updated the gcc version to 4-6
# Fixed link to binutils-2.20.1.tar.bz2

# Aug 11 2014:
# Updated to gcc 4.4.7 for the arm toolchain (original with 4.4.2)
# Added patches for gcc and binutils to compile with texinfo 5

##################################################################
# set the right compiler
#	-change to gcc4-8 on ubuntu 14.04
#	-change to gcc4-6 on ubuntu 11.10
#	-change to gcc4-4 on ubuntu 9.10
#	-change to gcc4-2 on ubuntu 8.10 (gcc4-3 not working)
##################################################################
GCC_BINARY_VERSION=/usr/bin/gcc-4.8
if [ ! -e $GCC_BINARY_VERSION ]; then
        echo "Error:  $GCC_BINARY_VERSION not found, check GCC_BINARY_VERSION in script ";
	exit 1;
fi
export CC=$GCC_BINARY_VERSION


##################################################################
# set repertories for source(src), build and final toolchain(gnuarm)
# afer building, src and build can be deleted
#	-should not be modified
##################################################################
ROOT=`pwd`
SRCDIR=$ROOT/src
BUILDDIR=$ROOT/build
PREFIX=$ROOT/../gnuarm


##################################################################
# set url for download
#	-change URLs if not valid anymore (googling)
##################################################################
GCC_URL=http://ftp.gnu.org/pub/gnu/gcc/gcc-4.4.7/gcc-4.4.7.tar.bz2
GCC_VERSION=4.4.7
GCC_DIR=gcc-$GCC_VERSION

BINUTILS_URL=http://ftp.gnu.org/gnu/binutils/binutils-2.20.1.tar.bz2
BINUTILS_VERSION=2.20.1
BINUTILS_DIR=binutils-$BINUTILS_VERSION

#BINUTILS_URL=http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2
#BINUTILS_VERSION=2.24
#BINUTILS_DIR=binutils-$BINUTILS_VERSION

NEWLIB_URL=ftp://sources.redhat.com/pub/newlib/newlib-1.18.0.tar.gz
NEWLIB_VERSION=1.18.0
NEWLIB_DIR=newlib-$NEWLIB_VERSION

#GDB_URL=ftp://sourceware.org/pub/insight/releases/insight-6.8-1.tar.bz2
#GDB_VERSION=6.8-1
#GDB_DIR=insight-$GDB_VERSION


##################################################################
# display a summary on screen before compiling
##################################################################

echo "I will build an arm-elf cross-compiler:

  Prefix: $PREFIX
  Sources: $SRCDIR
  Build files: $BUILDDIR

  Software: Binutils $BINUTILS_VERSION
            Gcc $GCC_VERSION
            Newlib $NEWLIB_VERSION
            Gdb $GDB_VERSION (disable)
 
  Host compiler : $GCC_BINARY_VERSION

Press ^C now if you do NOT want to do this or any key to continue."
read IGNORE

##################################################################
# Helper functions.
# ensure source : check if software archive present or else download
# unpack_source : extract software source
##################################################################
ensure_source()
{
    URL=$1
    FILE=$(basename $1)

    if [ ! -e $FILE ]; then
        wget $URL  #or curl -L -O $URL
    fi
}

unpack_source()
{
(
    cd $SRCDIR
    ARCHIVE_SUFFIX=${1##*.}
    if [ "$ARCHIVE_SUFFIX" = "gz" ]; then
      tar zxvf $1
    elif [ "$ARCHIVE_SUFFIX" = "bz2" ]; then
      tar jxvf $1
    else
      echo "Unknown archive format for $1"
      exit 1
    fi
)
}

##################################################################
# Create all the directories we need.
# Grab all the source and unpack them
##################################################################

mkdir -p $SRCDIR $BUILDDIR $PREFIX

(
cd $SRCDIR

# First grab all the source files...
ensure_source $GCC_URL
ensure_source $BINUTILS_URL
ensure_source $NEWLIB_URL
#rboissat: Adding GNU gdb
#ensure_source $GDB_URL

# ... And unpack the sources.
unpack_source $(basename $GCC_URL)
unpack_source $(basename $BINUTILS_URL)
unpack_source $(basename $NEWLIB_URL)
#unpack_source $(basename $GDB_URL)
)

##################################################################
# Set the PATH to include the binaries we're going to build.
##################################################################

OLD_PATH=$PATH
export PATH=$PREFIX/bin:$PATH




##################################################################
# Stage 1: Build binutils 
##################################################################
(
patch -d $SRCDIR -p0 -i ../binutils-2.20.1-texinfo-5.patch
mkdir -p $BUILDDIR/$BINUTILS_DIR
cd $BUILDDIR/$BINUTILS_DIR

$SRCDIR/$BINUTILS_DIR/configure --target=arm-elf --prefix=$PREFIX \
    --disable-werror --enable-interwork --enable-multilib \
    && make all install
) || exit 1




##################################################################
# Stage 2: Patch the GCC multilib rules, then build the gcc compiler only
##################################################################
(
MULTILIB_CONFIG=$SRCDIR/$GCC_DIR/gcc/config/arm/t-arm-elf

echo "

MULTILIB_OPTIONS    += mhard-float/msoft-float
MULTILIB_DIRNAMES   += fpu soft
MULTILIB_EXCEPTIONS += *mthumb/*mhard-float*


MULTILIB_OPTIONS += mno-thumb-interwork/mthumb-interwork
MULTILIB_DIRNAMES += normal interwork



" >> $MULTILIB_CONFIG

patch -d $SRCDIR -p0 -i ../gcc-4.4.7-texinfo-5.patch
mkdir -p $BUILDDIR/$GCC_DIR
cd $BUILDDIR/$GCC_DIR

$SRCDIR/$GCC_DIR/configure --target=arm-elf --prefix=$PREFIX \
    --enable-interwork --enable-multilib \
    --disable-__cxa_atexit \
    --enable-languages="c,c++" --with-newlib \
    --with-headers=$SRCDIR/$NEWLIB_DIR/newlib/libc/include \
    && make all-gcc install-gcc
) || exit 1


##################################################################
# Stage 3: Build and install newlib
##################################################################
(
# And now we can build it.
mkdir -p $BUILDDIR/$NEWLIB_DIR
cd $BUILDDIR/$NEWLIB_DIR

$SRCDIR/$NEWLIB_DIR/configure --target=arm-elf --prefix=$PREFIX \
    --enable-interwork --enable-multilib \
    && make all install
) || exit 1


##################################################################
# Stage 4: Build and install the rest of GCC.
##################################################################
(
cd $BUILDDIR/$GCC_DIR

make all install
) || exit 1


##################################################################
# Stage 5: Build and install GDB
##################################################################
#(
#mkdir -p $BUILDDIR/$GDB_DIR
#cd $BUILDDIR/$GDB_DIR
#
#$SRCDIR/$GDB_DIR/configure --target=arm-elf --prefix=$PREFIX \
#    --disable-werror --enable-interwork --enable-multilib \
#    && make all install
#) || exit 1

echo "
Build complete!

"






##################################################################
##################################################################
#  HOWTO manual installation (ubuntu 8.10, gcc4.2)
##################################################################
# This is a manual installation with steps similar to those of the previous script.
#
#    *  Set the current terminal environment:
#          o prepare the path to the toolchain executables. It is assumed you choose to install the gnu-arm toolchain in the directory gnuarm at the root of your home (/home/[your-home]/gnuarm)
#          o set gcc-4.2 as compiler (gcc-4.3 can at the same time be installed but can not be used since it fails to compile this version of the toolchain)
#
#          ~$ export CC=/usr/bin/gcc-4.2
#          ~$ export PATH=$PATH:/home/[your-home]/gnuarm/bin
#
####################################
#    * Compilation of binutils:
#          o download binutils-2.18.50 source in any local folder other than /home/[your-home]/gnuarm
#          o note: binutils-2.18 version do not work.
#          o and run the following commands:
#
#          ~$ tar xf binutils-2.18.50.tar.bz2
#          ~$ mkdir binutils-build; cd binutils-build
#          ~$ ../binutils-2.18.50/configure --target=arm-elf --prefix=/home/[your-home]/gnuarm --enable-interwork --enable-multilib
#          ~$ make all install
#
#          o the binutils for arm architecture are now installed in the directory /home/[your-home]/gnuarm
#
########################################
#    * Compilation of arm-gcc compiler
#          o Download gcc-4.2.2 source and newlib-1.16.0 source in any local folder other than /home/[your-home]/gnuarm.
#
#          ~$ tar xf gcc-4.2.2.tar.bz2
#          ~$ tar xf newlib-1.16.0.tar.gz
#
#          o uncomment the 5 following lines (remove the char '#' in front) by edition the file gcc-4.2.2/gcc/config/arm/t-arm-elf
#
#          # MULTILIB_OPTIONS += mhard-float/msoft-float
#          # MULTILIB_DIRNAMES += fpu soft
#          # MULTILIB_EXCEPTIONS += *mthumb/*mhard-float*
#
#          # MULTILIB_OPTIONS += mno-thumb-interwork/mthumb-interwork
#          # MULTILIB_DIRNAMES += normal interwork
#
#          o note: this enables compilation of libraries for both hard and soft fpu (float point unit) needed to compile nxtOSEK, and so do NOT configure gcc and newlib with the option --with-float=soft
#           		
#          o and run the following commands:
#
#          ~$ mkdir gcc-build; cd gcc-build
#          ~$ ../gcc-4.2.2/configure --target=arm-elf --prefix=/home/[your-home]/gnuarm --enable-interwork --enable-multilib --enable-languages="c,c++" --disable-__cxa_atexit --with-newlib --with-headers=[absolute path to newlib-1.16.0 folder]/newlib/libc/include
#          ~$ make all-gcc install-gcc
#
########################################
#    * Compilation of newlib:
#          o run the following commands:
#
#          ~$ mkdir newlib-build; cd newlib-build
#          ~$ ../newlib-1.16.0/configure --target=arm-elf --prefix=/home/[your-home]/gnuarm/ --enable-interwork --enable-multilib
#          ~$ make all install
#
#    * Final compilation of gcc (libs):
#          o run the following commands:
#
#          ~$ cd gcc-build
#          ~$ make all install
#
########################################
#    * (Optional) compilation of gdb :
#          o download insight-6.6.tar.bz2 in any local folder other than /home/[your-home]/gnuarm
#          o and run the following commands:
#
#          ~$ tar xf insight-6.6.tar.bz2
#          ~$ mkdir insight-build; cd insight-build
#          ~$ ../insight-6.6/configure --target=arm-elf --prefix=/home/[your-home]/gnuarm --enable-interwork --enable-multilib
#          ~$ make all install
#
#          o the binutils for arm architecture are now installed in the directory /home/[your-home]/gnuarm
#
