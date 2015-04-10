#!/bin/sh

###########################################################################
#
#  Automatic build script for openssl-for-android 
#  for Android arm5
#  Created by Ruslan Salikhov
#
#  https://wiki.openssl.org/index.php/Android
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
    echo "Warning: ANDROID_NDK_ROOT is no set"
    export ANDROID_NDK_ROOT=/jenkins/tools/android-ndk
fi
if [ ! -e $ANDROID_NDK_ROOT ]; then
    echo "Error: Cannot find Android NDK"
    exit 1
fi

. $BASEDIR/setenv.sh

#export ANDROID_NDK_HOST=linux-x86_64
#export ANDROID_NDK_PLATFORM=android-9
#export ANDROID_TOOLCHAIN_NAME=arm-linux-androideabi
#export ANDROID_TOOLCHAIN_VERSION=4.8
#export ANDROID_NDK_TOOLCHAIN_VERSION=${ANDROID_TOOLCHAIN_VERSION}
#export ANDROID_TOOLCHAIN=${ANDROID_TOOLCHAIN_NAME}-${ANDROID_TOOLCHAIN_VERSION}
#export ANDROID_ARCH=armeabi
#export ARCH=arm

#export PATH=$ANDROID_NDK_ROOT:$PATH

#export CC=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-$ANDROID_TOOLCHAIN_VERSION/prebuilt/$ANDROID_NDK_HOST/bin/arm-linux-androideabi-gcc
#export AR=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-$ANDROID_TOOLCHAIN_VERSION/prebuilt/$ANDROID_NDK_HOST/bin/arm-linux-androideabi-ar
#export ANDROID_DEV=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm/usr

set -e
if [ ! -e openssl-${VERSION}.tar.gz ]; then
  echo "Downloading openssl-${VERSION}.tar.gz"
  curl https://www.openssl.org/source/openssl-${VERSION}.tar.gz -o openssl-${VERSION}.tar.gz
else
  echo "Using openssl-${VERSION}.tar.gz"
fi

rm -rf ${BASEDIR}/src
rm -rf ${BASEDIR}/target

mkdir -p "${BASEDIR}/src"
mkdir -p "${BASEDIR}/target"

tar zxf openssl-${VERSION}.tar.gz -C "${BASEDIR}/src"

pushd "${BASEDIR}/src/openssl-${VERSION}"

# Preparing sources
patch -Np1 -i ${BASEDIR}/armv5-support.patch
perl -pi -e 's/install: all install_docs install_sw/install: install_sw/g' Makefile.org
export CC="gcc -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 -mfloat-abi=softfp"

# Building
./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$BASEDIR/target/

make depend
make all

make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib

popd

pushd target/lib
rm -f libssl.so libcrypto.so
rm -rf pkgconfig
mv libssl.so.1.0.0 libssl.so
mv libcrypto.so.1.0.0 libcrypto.so
rpl -R -e libcrypto.so.1.0.0 "libcrypto.so\x00\x00\x00\x00\x00\x00" .
rpl -R -e libssl.so.1.0.0 "libssl.so\x00\x00\x00\x00\x00\x00" .
popd

popd
