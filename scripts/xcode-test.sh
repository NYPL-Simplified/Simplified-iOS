#!/bin/bash

# SUMMARY
#   Runs the unit tests for SimplyE / Open eBooks.
#
# SYNOPSIS
#   xcode-test.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/xcode-test.sh simplye

source "$(dirname $0)/xcode-settings.sh"

echo "Running unit tests for $APP_NAME..."

# `-disableAutomaticPackageResolution` is for making sure to always resolve
# packages with the version checked in in Package.resolved
xcodebuild -project "$PROJECT_NAME" \
           -scheme "$SCHEME" \
           -destination platform=iOS\ Simulator,OS=17.2,name=iPhone\ 15 \
           -disableAutomaticPackageResolution \
           clean test | \
           if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi
