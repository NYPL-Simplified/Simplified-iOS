#!/bin/bash

# SUMMARY
#   Creates a new "build" keychain, installs an Apple distribution identity
#   in it for code signing, restricts keychain search list to this new keychain
#   and downloads production provisioning profiles.
#
# DESCRIPTION
#   This script is meant to be used in a CI context only. There's no need to
#   do any of this in a local developer machine because it's
#   typically configured for iOS development via the UI.
#
#   The codesigning identity is added from the related GitHub secret, passed
#   in here via the IOS_DISTR_IDENTITY_BASE64 env variable. The identity is
#   protected by a passphrase (IOS_DISTR_IDENTITY_PASSPHRASE).
#
#   Provisioning profiles are downloaded with Fastlane from the Apple Developer
#   Portal using FASTLANE_USER / FASTLANE_PASSWORD. Note that because all
#   newly created Apple IDs have 2 Factor Authentication enabled by default
#   and it's not possible to disable that, authentication via Fastlane
#   requires a valid login session with apple, which can be created with:
#
#       `fastlane spaceauth -u <apple-id@exammple.com`
#
#   This login session can then be provided to Fastlane via the
#   FASTLANE_SESSION env variable, as explained here:
#   https://docs.fastlane.tools/best-practices/continuous-integration/#spaceauth
#
# ENVIRONMENT VARIABLES
#   IOS_DISTR_IDENTITY_BASE64: base64 encoded version of the production
#     identity (certificate + key).
#   IOS_DISTR_IDENTITY_PASSPHRASE: passphrase to unlock the build keychain.
#   FASTLANE_USER: The Apple ID to use to authenticate with Apple.
#   FASTLANE_PASSWORD: The Apple ID password used to authenticate with Apple.
#   FASTLANE_SESSION: Login session for the Apple ID. This works in lieu of
#     2FA if the Apple ID has 2FA on.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo in a CI context, e.g.:
#
#       ./scripts/decode-install-secrets.sh
#

set -eo pipefail

if [ "$BUILD_CONTEXT" != "ci" ]; then
  echo "This script should be only used in a CI context because it manipulates keychain search lists"
  exit 1
fi

echo "Default keychain:"
security default-keychain

# decode identity (cert+key)
base64 -d -o ios_distribution.p12 <<< "$IOS_DISTR_IDENTITY_BASE64"
echo "Decoded identity:"
ls -la ios_distribution.p12

# create a new keychain for our stuff
# Note that we cannot save the new keychain under the usual ~/Library/Keychains
# because if we did that, Xcode will open up a modal window during archiving,
# which will make the build hang forever since the UI is not reachable from a
# CI context. See: https://github.com/actions/virtual-environments/issues/1820
export KEYCHAIN_PATH=$RUNNER_TEMP/build.keychain

KEYCHAIN_PASSPHRASE="$IOS_DISTR_IDENTITY_PASSPHRASE"
security create-keychain -p "$KEYCHAIN_PASSPHRASE" "$KEYCHAIN_PATH"
echo "Created build.keychain:"
ls -la "$KEYCHAIN_PATH"

# Config keychain and import cert
Security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH" # lock it after 6h
security unlock-keychain -p "$KEYCHAIN_PASSPHRASE" "$KEYCHAIN_PATH"
echo "Unlocked build keychain"
security import ios_distribution.p12 -P "$KEYCHAIN_PASSPHRASE" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
# security import ios_distribution.p12 -t agg -k "$KEYCHAIN_PATH" -P "$KEYCHAIN_PASSPHRASE" -A
echo "Imported ios_distribution identity"
rm -f ios_distribution.p12
security list-keychains -d user -s "$KEYCHAIN_PATH"
echo "Completed setting search list to build.keychain"
# set our keychain as default keychain
# security list-keychains -s "$KEYCHAIN_PATH"
# security default-keychain -s "$KEYCHAIN_PATH"

# enable keychain so that we can use its keys to codesign our builds
security unlock-keychain -p "$KEYCHAIN_PASSPHRASE" "$KEYCHAIN_PATH"
echo "Unlocked build keychain to enable codesigning"
security set-key-partition-list -S apple-tool:,apple: -s \
    -k "$KEYCHAIN_PASSPHRASE" "$KEYCHAIN_PATH"

# download and install appstore and adhoc prod provisioning profiles
fastlane fetch_install_provisioning
echo "Downloaded provisioning profiles:"
ls -la "$HOME/Library/MobileDevice/Provisioning Profiles"
