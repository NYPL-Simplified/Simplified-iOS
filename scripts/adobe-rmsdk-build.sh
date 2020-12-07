#!/bin/bash

set -e

echo "Building Adobe RMSDK..."

ADOBE_RMSDK="`pwd`/adobe-rmsdk"
CONFIGURATIONS=(Debug Release)
SDKS=(iphoneos iphonesimulator)

for SDK in ${SDKS[@]}; do
  if [ $SDK == "iphoneos" ]; then
    ARCHS="arm64 armv7 armv7s"
  else
    ARCHS="i386 x86_64"
  fi
  for CONFIGURATION in ${CONFIGURATIONS[@]}; do
    cd "$ADOBE_RMSDK/dp/build/xc5"
    xcodebuild \
      -project dp.xcodeproj \
      -configuration ${CONFIGURATION} \
      -target dp-iOS-noDepend \
      ONLY_ACTIVE_ARCH=NO \
      ENABLE_BITCODE=NO \
      ARCHS="${ARCHS}" \
      -sdk ${SDK} \
      build
    cd "$ADOBE_RMSDK"
    cp \
      dp/build/xc5/Build/${CONFIGURATION}-${SDK}/libdp-iOS.a \
      lib/ios/${CONFIGURATION}-${SDK}
  done
done
