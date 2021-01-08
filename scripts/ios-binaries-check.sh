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

echo "Checking if $ARCHIVE_NAME.ipa already exists on 'iOS-binaries' repo..."

CURL_RESULT=`curl -I -s -o /dev/null -w "%{http_code}"  https://github.com/NYPL-Simplified/iOS-binaries/blob/master/$ARCHIVE_NAME.ipa`
echo "CURL_RESULT=$CURL_RESULT"

if [ "$CURL_RESULT" == 200 ]; then
  echo "Build ${ARCHIVE_NAME} already exists in iOS-binaries"
  exit 1
elif [ "$CURL_RESULT" != 404 ]; then
  echo "Obtained unexpected curl result for file named \"${ARCHIVE_NAME}.ipa\""
  exit 1
fi

echo "iOS-binaries check completed successfully"
