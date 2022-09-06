#!/bin/bash

# SUMMARY
#   Creates an archive for SimplyE or Open eBooks
#
# SYNOPSIS
#   xcode-archive.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/xcode-archive.sh simplye
#
# RESULTS
#   The generated archive is placed inside the `./Build/` directory (per
#   xcode-settings.sh) and its name contains current version and build
#   number specified in the Xcode project

source "$(dirname $0)/xcode-settings.sh"

echo "Building $ARCHIVE_NAME... "
echo "Archive will be available at $ARCHIVE_PATH"

# prepare
mkdir -p "$ARCHIVE_DIR"

if [ "$BUILD_CONTEXT" == "ci" ]; then
  echo "Valid identities in keychain able to satisfy code signing policy:"
  security find-identity -p codesigning -v
fi

echo "Current build dir: `pwd`"
echo "Carthage contents:"
ls -la Carthage/Build

# build
# Note: xcodebuild creates archive `ARCHIVE_NAME.xcarchive` inside ARCHIVE_DIR
# Also note: `-disableAutomaticPackageResolution` is for making sure to always
# resolve packages with the version checked in in Package.resolved
xcodebuild -project $PROJECT_NAME \
           -scheme "$SCHEME" \
           -sdk iphoneos \
           -configuration Release \
           -archivePath "$ARCHIVE_DIR/$ARCHIVE_NAME" \
           -disableAutomaticPackageResolution \
           clean archive | \
           if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi

echo "Collecting dSYMs... "
mkdir -p "$DSYMS_PATH"
find "$ARCHIVE_PATH" -name "*.dSYM"  | xargs -t -I{} cp -R {} "$DSYMS_PATH"
cp -R ./NYPLAEToolkit/build/AudioEngine-iphoneos.framework.dSYM "$DSYMS_PATH"

echo "dSYMs are available at $DSYMS_PATH:"
ls -l "$DSYMS_PATH"
