#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/setup-repo.sh
#
# Description: This scripts sets up the repo for building SimplyE or
#              Open eBooks without DRM support.

echo "Setting up repo for non-DRM build"

git submodule deinit adept-ios && git rm -rf adept-ios
git submodule deinit adobe-content-filter && git rm -rf adobe-content-filter
git submodule update --init --recursive

# Remove "NYPL-Simplified/NYPLAEToolkit" from Cartfile and Cartfile.resolved.
sed -i '' "s#.*NYPL-Simplified/NYPLAEToolkit.*##" Cartfile
sed -i '' "s#.*NYPL-Simplified/NYPLAEToolkit.*##" Cartfile.resolved

if [ ! -f "APIKeys.swift" ]; then
  cp Simplified/AppInfrastructure/APIKeys.swift.example Simplified/AppInfrastructure/APIKeys.swift
fi

# These will need to be filled in with real values
if [ ! -f "SimplyE/GoogleService-Info.plist" ]; then
  cp SimplyE/GoogleService-Info.plist.example SimplyE/GoogleService-Info.plist
fi
if [ ! -f "SimplyE/ReaderClientCert.sig" ]; then
  cp SimplyE/ReaderClientCert.sig.example SimplyE/ReaderClientCert.sig
fi
