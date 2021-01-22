#!/bin/bash

# SUMMARY
#   Exports an SimplyE / Open eBooks archive for App Store distribution
#   generating the related ipa.
#
# SYNOPSIS
#   xcode-export-appstore.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/xcode-export-appstore.sh simplye
#
# RESULTS
#   The generated .ipa is placed in its own directory inside
#   `./Build/exports-appstore`.

source "$(dirname $0)/xcode-settings.sh"

echo "Exporting $ARCHIVE_NAME for AppStore distribution..."

mkdir -p "$APPSTORE_EXPORT_PATH"

xcodebuild -archivePath "$ARCHIVE_PATH.xcarchive" \
            -exportOptionsPlist "$APP_NAME_FOLDER/exportOptions-appstore.plist" \
            -exportPath "$APPSTORE_EXPORT_PATH" \
            -allowProvisioningUpdates \
            -exportArchive | \
            if command -v xcpretty &> /dev/null; then xcpretty; else cat; fi
