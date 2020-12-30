#!/bin/bash

# SUMMARY
#   Checks if a binary with the current build number already exists on the
#   https://github.com/NYPL-Simplified/iOS-binaries repo.
#
# SYNOPSIS
#   ios-binaries-check.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/ios-binaries-check simplye

source "$(dirname $0)/xcode-settings.sh"

echo "Checking if $ARCHIVE_NAME already exists on 'iOS-binaries' repo..."

# In a GitHub Actions CI context we can't clone a repo as a sibling
if [ "$BUILD_CONTEXT" != "ci" ]; then
  cd ..
fi

if [[ -d "iOS-binaries" ]]; then
  echo "iOS-binaries repo appears to be cloned already..."
  IOS_BINARIES_DIR_NAME=iOS-binaries
elif [[ -d "NYPL-iOS-binaries" ]]; then
  echo "iOS-binaries repo appears to be cloned already..."
  IOS_BINARIES_DIR_NAME=NYPL-iOS-binaries
else
  IOS_BINARIES_DIR_NAME=iOS-binaries
  git clone https://${GITHUB_TOKEN}@github.com/NYPL-Simplified/iOS-binaries.git
fi

IOS_BINARIES_DIR_PATH="$PWD/$IOS_BINARIES_DIR_NAME"

FOUND_BUILD=`find "$IOS_BINARIES_DIR_PATH" -name ${BUILD_NAME}*`
if [ "$FOUND_BUILD" != "" ]; then
  echo "Build ${BUILD_NAME} already exists in iOS-binaries"
  exit 1
fi

echo "iOS binaries check completed"
