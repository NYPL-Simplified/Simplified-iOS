#!/bin/bash

# SUMMARY
#   Checks if the given app's build number in a GitHub PR changed in relation
#   to the target branch.
#
# SYNOPSIS
#   build-number-check.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# RETURN CODES
#   0: if no changes in version/build number were detected
#   1: if a change in version/build number was detected
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/build-number-check simplye

source "$(dirname $0)/xcode-settings.sh"

echo "Checking if we need to build a new archive based on version and build number..."

echo "Source branch: [$GITHUB_REF]"
echo "Target branch: [$TARGET_BRANCH]"

# now let's determine the version currently on the branch we're merging to
git checkout $GITHUB_BASE_REF
BASE_BUILD_SETTINGS="`xcodebuild -project $PROJECT_NAME -showBuildSettings -target \"$TARGET_NAME\"`"
BASE_VERSION_NUM=`echo "$BASE_BUILD_SETTINGS" | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //'`
BASE_BUILD_NUM=`echo "$BASE_BUILD_SETTINGS" | grep "CURRENT_PROJECT_VERSION" | sed 's/[ ]*CURRENT_PROJECT_VERSION = //'`
BASE_ARCHIVE_NAME="$APP_NAME-$BASE_VERSION_NUM.$BASE_BUILD_NUM"
echo "Base app name + version + build number on $GITHUB_BASE_REF: $BASE_ARCHIVE_NAME"
echo "Proposed app name + version + build number: $ARCHIVE_NAME"

# restore branch
git checkout $GITHUB_REF

if [ "$ARCHIVE_NAME" != "$BASE_ARCHIVE_NAME" ]; then
  echo "Version or build number for $APP_NAME changed"
  exit 1
fi

echo "No changes in version or build number detected for $APP_NAME"
exit 0

