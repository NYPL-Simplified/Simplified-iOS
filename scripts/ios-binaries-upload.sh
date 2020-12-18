#!/bin/bash

# SUMMARY
#   Uploads an exported .ipa for SimplyE or Open eBooks to the
#   https://github.com/NYPL-Simplified/iOS-binaries repo.
#
# SYNOPSIS
#   ios-binaries-upload.sh [ simplye | SE | openebooks | OE ]
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/ios-binaries-upload simplye

source "$(dirname $0)/xcode-settings.sh"

echo "Uploading $ARCHIVE_NAME to 'ios-binaries' repo..."

SIMPLIFIED_DIR=$PWD
cd ..
if [[ -d "iOS-binaries" ]]; then
  echo "iOS-binaries repo appears to be cloned already..."
  IOS_BINARIES_DIR=iOS-binaries
elif [[ -d "NYPL-iOS-binaries" ]]; then
  echo "iOS-binaries repo appears to be cloned already..."
  IOS_BINARIES_DIR=NYPL-iOS-binaries
else
  git clone git@github.com:NYPL-Simplified/iOS-binaries.git
  IOS_BINARIES_DIR=iOS-binaries
fi

cd "$SIMPLIFIED_DIR"
IPA_NAME="${ARCHIVE_NAME}.ipa"
echo "Copying .ipa to $PWD/../$IOS_BINARIES_DIR/$IPA_NAME"
cp "$ADHOC_EXPORT_PATH/$APP_NAME.ipa" "../$IOS_BINARIES_DIR/$IPA_NAME"

cd "../$IOS_BINARIES_DIR"
git add "$IPA_NAME"

# enable once we have CI
# git config --global user.email "ci@librarysimplified.org" ||
#   fatal "could not configure git"
# git config --global user.name "Library Simplified CI" ||
#   fatal "could not configure git"

COMMIT_MSG="Add ${BUILD_NAME} build"
git commit -m "$COMMIT_MSG" || fatal "could not commit ${BUILD_NAME} binary"
git push --force || fatal "could not push ${BUILD_NAME} binary"
