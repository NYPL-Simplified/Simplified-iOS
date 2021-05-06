#!/bin/bash

# SUMMARY
#   Uploads an exported .ipa for SimplyE or Open eBooks to Firebase.
#
# SYNOPSIS
#   firebase-upload.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/firebase-upload simplye

source "$(dirname $0)/xcode-settings.sh"

echo "Uploading $ARCHIVE_NAME binary to Firebase..."

if [ "$BUILD_CONTEXT" == "ci" ]; then
  CERTIFICATES_PATH="./Certificates"
else
  CERTIFICATES_PATH="../Certificates"
fi

FIREBASE_TOKEN=$(head -n 1 "$CERTIFICATES_PATH/Firebase/token.txt") ||
  fatal "could not read firebase token from Certificates repo"

FIREBASE_APP_ID=`/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" "$CERTIFICATES_PATH/$APP_NAME_FOLDER/iOS/GoogleService-Info.plist"`

# find ipa
if [[ -d "$ADHOC_EXPORT_PATH" ]]; then
  IPA_PATH="$ADHOC_EXPORT_PATH/$APP_NAME.ipa"
else
  fatal "Unable to upload to firebase: missing ad-hoc export!"
fi

# upload app binary
echo "Using ipa at $IPA_PATH"
firebase appdistribution:distribute \
  --token "${FIREBASE_TOKEN}" \
  --app "${FIREBASE_APP_ID}" \
  "${IPA_PATH}"

# upload symbols
./scripts/firebase-upload-symbols.sh "$APPNAME_PARAM" "$DSYMS_PATH"

echo "firebase-upload.sh: Completed with return code $?"
