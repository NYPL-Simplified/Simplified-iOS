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

xcodebuild -project "$PROJECT_NAME" \
           -scheme "$SCHEME" \
           -destination platform=iOS\ Simulator,OS=15.0,name=iPhone\ 13 \
           clean test | \
           if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi
