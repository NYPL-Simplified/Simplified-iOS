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
# RESULT CODES
#   0: if no build with the same filename exists on ios-binaries
#   1: if a build with the same filename exists on ios-binaries or an error occurred
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/ios-binaries-check simplye

source "$(dirname $0)/xcode-settings.sh"

echo ""
echo "Checking if $UPLOAD_FILENAME already exists on 'iOS-binaries' repo..."
echo "UPLOAD_FILENAME_URLENCODED=$UPLOAD_FILENAME_URLENCODED"

CURL_RESULT=`curl -I -s -o /dev/null -w "%{http_code}"  https://github.com/NYPL-Simplified/iOS-binaries/blob/master/$UPLOAD_FILENAME_URLENCODED`
echo "CURL_RESULT=$CURL_RESULT"

if [ "$CURL_RESULT" == 200 ]; then
  echo "Build for ${ARCHIVE_NAME} already exists in iOS-binaries"
  exit 1
elif [ "$CURL_RESULT" != 404 ]; then
  echo "Obtained unexpected curl result for file named \"$UPLOAD_FILENAME\""
  exit 1
fi

echo "iOS-binaries check completed successfully"
