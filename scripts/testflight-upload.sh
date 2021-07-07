#!/bin/bash

# SUMMARY
#   Uploads an exported .ipa for SimplyE or Open eBooks to TestFlight.
#
# SYNOPSIS
#   testflight-upload.sh <app_name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/testflight-upload simplye

source "$(dirname $0)/xcode-settings.sh"

IPA_PATH="$APPSTORE_EXPORT_PATH/$APP_NAME.ipa"
echo "Uploading $IPA_PATH to TestFlight..."

if [ "$BUILD_CONTEXT" == "ci" ]; then
  export KEYCHAIN_PATH=$RUNNER_TEMP/build.keychain
  security unlock-keychain -p "$IOS_DISTR_IDENTITY_PASSPHRASE" "$KEYCHAIN_PATH"
fi

#fastlane deliver --ipa "$IPA_PATH" \
#  --skip_screenshots --skip_metadata --skip_app_version_update \
#  --precheck_include_in_app_purchases false \
#  --force
