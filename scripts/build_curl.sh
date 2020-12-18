#!/bin/bash

# This script builds a static version of
# curl ${CURL_VERSION} for iOS 9.0 that contains code for
# arm64, armv7, arm7s, i386 and x86_64.

# Based off of build script from RMSDK
# Patched by cross-referencing with: https://github.com/sinofool/build-libcurl-ios

set -x

# Setup paths to stuff we need

CURL_VERSION="7.64.1"

DEVELOPER="/Applications/Xcode.app/Contents/Developer"

SDK_VERSION="12.2"
MIN_VERSION="9.0"

IPHONEOS_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
IPHONEOS_SDK="${IPHONEOS_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"
IPHONEOS_GCC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

IPHONESIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
IPHONESIMULATOR_SDK="${IPHONESIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"
IPHONESIMULATOR_GCC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

# Make sure things actually exist

if [ ! -d "$IPHONEOS_PLATFORM" ]; then
  echo "Cannot find $IPHONEOS_PLATFORM"
  exit 1
fi

if [ ! -d "$IPHONEOS_SDK" ]; then
  echo "Cannot find $IPHONEOS_SDK"
  exit 1
fi

if [ ! -x "$IPHONEOS_GCC" ]; then
  echo "Cannot find $IPHONEOS_GCC"
  exit 1
fi

if [ ! -d "$IPHONESIMULATOR_PLATFORM" ]; then
  echo "Cannot find $IPHONESIMULATOR_PLATFORM"
  exit 1
fi

if [ ! -d "$IPHONESIMULATOR_SDK" ]; then
  echo "Cannot find $IPHONESIMULATOR_SDK"
  exit 1
fi

if [ ! -x "$IPHONESIMULATOR_GCC" ]; then
  echo "Cannot find $IPHONESIMULATOR_GCC"
  exit 1
fi

# Clean up whatever was left from our previous build

rm -rf lib include-32 include-64
rm -rf /tmp/curl-${CURL_VERSION}-*
rm -rf /tmp/curl-${CURL_VERSION}-*.*-log

build()
{
    HOST=$1
    ARCH=$2
    SDK=$3
    MOREFLAGS=$4
    rm -rf "curl-${CURL_VERSION}"
    unzip "curl-${CURL_VERSION}.zip" -d "."
    pushd .
    cd "curl-${CURL_VERSION}"
    export IPHONEOS_DEPLOYMENT_TARGET=${MIN_VERSION}
    export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${SDK} -miphoneos-version-min=${MIN_VERSION}"
    export CPPFLAGS=${MOREFLAGS}
    export LDFLAGS="-arch ${ARCH} -isysroot ${SDK}"
    ./configure --disable-shared --enable-static --enable-ipv6 --host=${HOST} --prefix="/tmp/curl-${CURL_VERSION}-${ARCH}" --with-darwinssl --without-libidn2 --enable-threaded-resolver &> "/tmp/curl-${CURL_VERSION}-${ARCH}.log"
    make -j `sysctl -n hw.logicalcpu_max` &> "/tmp/curl-${CURL_VERSION}-${ARCH}-build.log"
    make install &> "/tmp/curl-${CURL_VERSION}-${ARCH}-install.log"
    popd
    rm -rf "curl-${CURL_VERSION}"
}

build "armv7-apple-darwin"  "armv7"  "${IPHONEOS_SDK}" ""
build "armv7s-apple-darwin" "armv7s" "${IPHONEOS_SDK}" ""
build "arm-apple-darwin"    "arm64"  "${IPHONEOS_SDK}" ""
build "i386-apple-darwin"   "i386"   "${IPHONESIMULATOR_SDK}" "-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
build "x86_64-apple-darwin" "x86_64" "${IPHONESIMULATOR_SDK}" "-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"

mkdir -p ../public/ios/lib ../public/ios/include-32 ../public/ios/include-64
cp -r /tmp/curl-${CURL_VERSION}-i386/include/curl ../public/ios/include-32/
cp -r /tmp/curl-${CURL_VERSION}-x86_64/include/curl ../public/ios/include-64/
lipo \
"/tmp/curl-${CURL_VERSION}-armv7/lib/libcurl.a" \
"/tmp/curl-${CURL_VERSION}-armv7s/lib/libcurl.a" \
"/tmp/curl-${CURL_VERSION}-arm64/lib/libcurl.a" \
"/tmp/curl-${CURL_VERSION}-i386/lib/libcurl.a" \
"/tmp/curl-${CURL_VERSION}-x86_64/lib/libcurl.a" \
-create -output ../public/ios/lib/libcurl.a

rm -rf "/tmp/curl-${CURL_VERSION}-*"
rm -rf "/tmp/curl-${CURL_VERSION}-*.*-log"
