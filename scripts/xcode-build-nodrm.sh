#!/bin/bash

# SUMMARY
#   Builds SimplyE without DRM support.
#
# SYNOPSIS
#   xcode-build-nodrm.sh
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/xcode-build-nodrm.sh

set -eo pipefail

echo "Building SimplyE without DRM support..."

xcodebuild -project Simplified.xcodeproj \
           -scheme SimplyE-noDRM \
           -destination platform=iOS\ Simulator,OS=13.5,name=iPhone\ 11\ Pro\
           clean build | \
           if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi
