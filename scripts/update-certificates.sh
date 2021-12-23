#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/update-certificates.sh
#

set -eo pipefail

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Updating repo with info from Certificates repo..."
else
  echo "Updating repo with info from Certificates repo for [$BUILD_CONTEXT]..."
fi

CERTIFICATES_PATH="./Certificates"

# SimplyE-specific stuff
cp $CERTIFICATES_PATH/SimplyE/iOS/GoogleService-Info.plist SimplyE/
cp $CERTIFICATES_PATH/SimplyE/iOS/ReaderClientCertProduction.sig SimplyE/ReaderClientCert.sig

# OpenEbooks-specific stuff
cp $CERTIFICATES_PATH/OpenEbooks/iOS/ReaderClientCert.sig OpenEbooks/
cp $CERTIFICATES_PATH/OpenEbooks/iOS/GoogleService-Info.plist OpenEbooks/

git update-index --skip-worktree Simplified/NYPLSecrets.swift

echo "Obfuscating keys..."
swift $CERTIFICATES_PATH/SimplyE/iOS/KeyObfuscator.swift "$CERTIFICATES_PATH/SimplyE/iOS/APIKeys.json"

echo "update-certificates: finished"
