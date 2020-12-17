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
#   xcode-settings.sh)and its name contains current version and build
#   number specified in the Xcode project

source "$(dirname $0)/xcode-settings.sh"

echo "Building $ARCHIVE_NAME... "
echo "Build will be available at $ARCHIVE_PATH"

# prepare
mkdir -p $BUILD_PATH

# build
xcodebuild -project $PROJECT_NAME \
           -scheme $SCHEME \
           -sdk iphoneos \
           -configuration Release \
           -archivePath $ARCHIVE_PATH \
           clean archive | \
           if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi
