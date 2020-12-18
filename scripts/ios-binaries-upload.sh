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
  git clone https://${GITHUB_TOKEN}@github.com/NYPL-Simplified/iOS-binaries.git
fi

IOS_BINARIES_DIR_PATH="$PWD/$IOS_BINARIES_DIR_NAME"

cd "$SIMPLIFIED_DIR"
IPA_NAME="${ARCHIVE_NAME}.ipa"
echo "Copying .ipa to $IOS_BINARIES_DIR_PATH/$IPA_NAME"
cp "$ADHOC_EXPORT_PATH/$APP_NAME.ipa" "$IOS_BINARIES_DIR_PATH/$IPA_NAME"

cd "$IOS_BINARIES_DIR_PATH"
git add "$IPA_NAME"
git status

if [ "$BUILD_CONTEXT" == "ci" ]; then
  git config --global user.email "ci@librarysimplified.org"
  git config --global user.name "Library Simplified CI"
fi

COMMIT_MSG="Add ${BUILD_NAME} iOS build"
git commit -m "$COMMIT_MSG"
echo "Committed."
git push -f
