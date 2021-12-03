#!/bin/bash

# SUMMARY
#   Sets up the Simplified-iOS repo for running SimplyE without DRM support.
#
# USAGE
#   You only have to run this script once after checking out the related repos.
#   Run it from the root of Simplified-iOS, e.g.:
#
#     ./scripts/setup-repo-nodrm.sh
#
# NOTES
#   1. Building Open eBooks without DRM is not supported.
#   2. On a fresh checkout this script will produce some errors while trying
#      to deinit the adobe repos. This is expected and does not affect the
#      build process.

set -eo pipefail

echo "Setting up repo for non-DRM build"

git submodule foreach --quiet 'git submodule deinit adept-ios'
git rm -rf adept-ios
git submodule foreach --quiet 'git submodule deinit NYPLAEToolkit'
git rm -rf NYPLAEToolkit
git submodule foreach --quiet 'git submodule deinit Axis-iOS'
git rm -rf Axis-iOS
git submodule foreach --quiet 'git submodule deinit audiobook-ios-overdrive'
git rm -rf audiobook-ios-overdrive
git submodule foreach --quiet 'git submodule deinit Certificates'
git rm -rf Certificates

git submodule update --init --recursive

# Remove private repos from Cartfile and Cartfile.resolved.
sed -i '' "s#.*lcp.*##" Cartfile
sed -i '' "s#.*lcp.*##" Cartfile.resolved

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
