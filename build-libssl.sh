#!/bin/sh

###########################################################################
#
#  Automatic build script for openssl-for-android 
#  for Android arm5
#  Created by Ruslan Salikhov
#
#  References:
#  https://wiki.openssl.org/index.php/Android
#  https://github.com/x2on/OpenSSL-for-iPhone
#  https://github.com/stdchpie/android-openssl (patching SONAME)
#
###########################################################################
#
#  Change values here
#

VERSION="1.0.2a"

#
###########################################################################
#
# Don't change anything under this line!
#
###########################################################################

BASEDIR=$(dirname $0)
pushd $BASEDIR
BASEDIR=`pwd`

if [ -z $ANDROID_NDK_ROOT ]; then
    echo "Error: ANDROID_NDK_ROOT is no set"
    exit 1
fi
if [ ! -e $ANDROID_NDK_ROOT ]; then
    echo "Error: Cannot find Android NDK"
    exit 1
fi


set -e

# Getting sources
if [ ! -e openssl-${VERSION}.tar.gz ]; then
  echo "Downloading openssl-${VERSION}.tar.gz"
  curl https://www.openssl.org/source/openssl-${VERSION}.tar.gz -o openssl-${VERSION}.tar.gz
else
  echo "Using openssl-${VERSION}.tar.gz"
fi

# Getting setup android envitonment script
if [ ! -e Setenv-android.sh ]; then
  echo "Downloading Setenv-android.sh"
  curl http://wiki.openssl.org/images/7/70/Setenv-android.sh -o Setenv-android.sh
else
  echo "Using Setenv-android.sh"
fi

ls
chmod a+x Setenv-android.sh
. ./Setenv-android.sh

# Removing possible temp folders
rm -rf src
rm -rf lib
rm -rf include
rm -rf install

mkdir -p src

tar zxf openssl-${VERSION}.tar.gz -C "./src"

pushd "${BASEDIR}/src/openssl-${VERSION}"

# Preparing sources
perl -pi -e 's/install: all install_docs install_sw/install: install_sw/g' Makefile.org

# Building
./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$BASEDIR/install/

# patch SONAME
# took from https://github.com/stdchpie/android-openssl
perl -pi -e 's/SHLIB_EXT=\.so\.\$\(SHLIB_MAJOR\)\.\$\(SHLIB_MINOR\)/SHLIB_EXT=\.so/g' Makefile
perl -pi -e 's/SHARED_LIBS_LINK_EXTS=\.so\.\$\(SHLIB_MAJOR\) \.so//g' Makefile
perl -pi -e 's/SHLIB_MAJOR=1/SHLIB_MAJOR=`/g' Makefile
perl -pi -e 's/SHLIB_MINOR=0.0/SHLIB_MINOR=`/g' Makefile

make clean
make depend
make all

mkdir -p $BASEDIR/lib
mkdir -p $BASEDIR/include
cp -v libssl.{a,so} libcrypto.{a,so} $BASEDIR/lib
cp -rvL include/openssl $BASEDIR/include

#make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib

popd

popd

exit 0
