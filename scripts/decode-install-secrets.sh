#!/bin/bash

# run from root of repo

set -eo pipefail

PROV_PROFILES_DIR_PATH="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROV_PROFILES_DIR_PATH"

# decode SimplyE / Open eBooks provisioning profiles for Ad Hoc distribution
# to the NYPL-Simplified/iOS-binaries repo.
base64 -d -o "$PROV_PROFILES_DIR_PATH"/SimplyE_Ad_Hoc.mobileprovision <<< "$SE_PROV_PROFILE_ADHOC"
base64 -d -o "$PROV_PROFILES_DIR_PATH"/Open_eBooks_Ad_Hoc.mobileprovision <<< "$OE_PROV_PROFILE_ADHOC"
echo "Decoded provisioning profiles:"
ls -la "$PROV_PROFILES_DIR_PATH"

# decode identity (cert+key)
base64 -d -o ios_distribution.p12 <<< "$IOS_DISTR_IDENTITY_BASE64"
echo "Decoded identity:"
ls -la ios_distribution.p12

echo "Default keychain:"
security default-keychain

# create a new keychain for our stuff
#KEYCHAIN_PASSPHRASE="" #TODO: add secret for this after verify it works with ""
KEYCHAIN_PASSPHRASE="$IOS_DISTR_IDENTITY_PASSPHRASE"
security create-keychain -p "$KEYCHAIN_PASSPHRASE" build.keychain
echo "Created build.keychain:"
ls -la $HOME/Library/Keychains

# add distribution certificate+key to keychain
security import ios_distribution.p12 -t agg -k $HOME/Library/Keychains/build.keychain -P "$KEYCHAIN_PASSPHRASE" -A
echo "Imported ios_distribution identity"

# clean up
rm -f ios_distribution.p12

# set our keychain as default keychain and unlock it
security list-keychains -s $HOME/Library/Keychains/build.keychain
echo "Completed setting search list to build.keychain"

security default-keychain -s $HOME/Library/Keychains/build.keychain
echo "Completed setting build keychain as default"

security unlock-keychain -p "$KEYCHAIN_PASSPHRASE" $HOME/Library/Keychains/build.keychain
echo "Unlocked build keychain"

# enable keychain so that we can use to codesign our builds
security set-key-partition-list -S apple-tool:,apple: -s \
    -k "$KEYCHAIN_PASSPHRASE" ~/Library/Keychains/build.keychain
