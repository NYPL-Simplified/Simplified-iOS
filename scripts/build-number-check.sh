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

echo ""
echo "Checking if we need to build a new archive of $APP_NAME based on version and build number..."

# when we merge the source branch to develop, the TARGET branch is defined
# github event's ref.
# (NB: For a PR event, the GITHUB_REF is the source branch instead.)
echo "GITHUB_REF=$GITHUB_REF"
echo "COMMIT_BEFORE_MERGE=$COMMIT_BEFORE_MERGE"

cd tmpSimplified
git checkout $COMMIT_BEFORE_MERGE

# now let's determine the version currently on the branch we're merging to
BASE_BUILD_SETTINGS="`xcodebuild -project $PROJECT_NAME -showBuildSettings -target \"$TARGET_NAME\"`"
BASE_VERSION_NUM=`echo "$BASE_BUILD_SETTINGS" | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //'`
BASE_BUILD_NUM=`echo "$BASE_BUILD_SETTINGS" | grep "CURRENT_PROJECT_VERSION" | sed 's/[ ]*CURRENT_PROJECT_VERSION = //'`
BASE_ARCHIVE_NAME="$APP_NAME-$BASE_VERSION_NUM.$BASE_BUILD_NUM"
echo "Base app name + version + build number on commit $COMMIT_BEFORE_MERGE: $BASE_ARCHIVE_NAME"
echo "Proposed app name + version + build number: $ARCHIVE_NAME"

# restore 
#cd ..

if [ "$ARCHIVE_NAME" != "$BASE_ARCHIVE_NAME" ]; then
  echo "Version or build number for $APP_NAME changed"
  exit 1
fi

echo "No changes in version or build number detected for $APP_NAME"
exit 0

