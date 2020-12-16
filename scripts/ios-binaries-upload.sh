#!/bin/bash

# SUMMARY
#   Uploads an exported .ipa for SimplyE or Open eBooks to the
#   https://github.com/NYPL-Simplified/iOS-binaries repo.
#
# SYNOPSIS
#   ios-binaries-upload.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/ios-binaries-upload simplye

source "$(dirname $0)/xcode-settings.sh"

echo "Uploading $ARCHIVE_NAME to 'ios-binaries' repo..."

SIMPLIFIED_DIR=$PWD

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
  git clone git@github.com:NYPL-Simplified/iOS-binaries.git
fi

IOS_BINARIES_DIR_PATH="$PWD/$IOS_BINARIES_DIR_NAME"

cd "$SIMPLIFIED_DIR"
IPA_NAME="${ARCHIVE_NAME}.ipa"
echo "Copying .ipa to $IOS_BINARIES_DIR_PATH/$IPA_NAME"
cp "$ADHOC_EXPORT_PATH/$APP_NAME.ipa" "$IOS_BINARIES_DIR_PATH/$IPA_NAME"

cd "$IOS_BINARIES_DIR_PATH"
git add "$IPA_NAME"

if [ "$BUILD_CONTEXT" == "ci" ]; then
  git config --global user.email "ci@librarysimplified.org" ||
    fatal "could not configure git"
  git config --global user.name "Library Simplified CI" ||
    fatal "could not configure git"
fi

COMMIT_MSG="Add ${BUILD_NAME} build"
git commit -m "$COMMIT_MSG" || fatal "could not commit ${BUILD_NAME} binary"
git push --force || fatal "could not push ${BUILD_NAME} binary"
