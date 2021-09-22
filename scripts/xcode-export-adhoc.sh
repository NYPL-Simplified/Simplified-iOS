#!/bin/bash

# SUMMARY
#   Exports an archive for SimplyE / Open eBooks generating the related ipa.
#
# SYNOPSIS
#   xcode-export-adhoc.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/xcode-export-adhoc.sh simplye
#
# RESULTS
#   The generated .ipa is placed in its own directory inside
#   `./Build/exports-adhoc`.

source "$(dirname $0)/xcode-settings.sh"

echo "Exporting $ARCHIVE_NAME for Ad-Hoc distribution..."

mkdir -p "$ADHOC_EXPORT_PATH"

echo "ARCHIVE_PATH=$ARCHIVE_PATH"
echo "ADHOC_EXPORT_PATH=$ADHOC_EXPORT_PATH"

xcodebuild -archivePath "$ARCHIVE_PATH" \
            -exportOptionsPlist "$APP_NAME_FOLDER/exportOptions-adhoc.plist" \
            -exportPath "$ADHOC_EXPORT_PATH" \
            -allowProvisioningUpdates \
            -exportArchive | \
            if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi

# re-sign app because until we upgrade our build system to Big Sur/Xcode 13,
# the signature provided by Xcode 12 is not compatible with iOS 15,
# so ad-hoc builds won't be able to be installed on iOS 15 devices.
# Full discussion: https://developer.apple.com/forums/thread/682775
SIGNING_IDENTITY=`security find-identity -v -p codesigning | grep -i "The New York Library Astor, Lenox, and Tilden Foundations" | awk '{print $2}'`
echo "SIGNING_IDENTITY=$SIGNING_IDENTITY"
unzip "$ADHOC_EXPORT_PATH/$APP_NAME.ipa" -d "$ADHOC_EXPORT_PATH"
codesign -s "$SIGNING_IDENTITY" -f --preserve-metadata --generate-entitlement-der "$ADHOC_EXPORT_PATH/Payload/$APP_NAME.app"
rm "$ADHOC_EXPORT_PATH/$APP_NAME.ipa"
cd "$ADHOC_EXPORT_PATH"
zip -r "$APP_NAME.ipa" Payload
