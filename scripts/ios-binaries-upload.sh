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

 # check we didn't already upload this build
ZIP_FULLPATH="$IOS_BINARIES_DIR_PATH/$UPLOAD_FILENAME"
if [[ -f "$ZIP_FULLPATH" ]]; then
  echo "${ARCHIVE_NAME} already exists on iOS-binaries"
  exit 1
fi

# put .ipa with rest of files to be uploaded
cd "$SIMPLIFIED_DIR"
IPA_NAME="${ARCHIVE_NAME}.ipa"
cp "$ADHOC_EXPORT_PATH/$APP_NAME.ipa" "$PAYLOAD_PATH/$IPA_NAME"

# zip .ipa with dSYMs
cd "$PAYLOAD_PATH/.."
zip -r "$ZIP_FULLPATH" "$PAYLOAD_DIR_NAME"

# upload to iOS-binaries repo
cd "$IOS_BINARIES_DIR_PATH"
git add "$ZIP_FULLPATH"
git status

if [ "$BUILD_CONTEXT" == "ci" ]; then
  git config --global user.email "librarysimplifiedci@nypl.org"
  git config --global user.name "Library Simplified CI"
fi

COMMIT_MSG="Add ${ARCHIVE_NAME} build"
git commit -m "$COMMIT_MSG"
echo "Committed."
git push -f
