#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/update-certificates.sh
#
# Note: this script assumes you have the Certificates repo cloned as a sibling of Simplified-iOS.

set -eo pipefail

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Updating repo with info from Certificates repo..."
else
  echo "Updating repo with info from Certificates repo for [$BUILD_CONTEXT]..."
fi

if [ "$BUILD_CONTEXT" == "ci" ]; then
  CERTIFICATES_PATH="./Certificates"
else
  CERTIFICATES_PATH="../Certificates"
fi

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
