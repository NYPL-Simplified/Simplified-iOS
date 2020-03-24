#~/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     build-3rd-parties-dependencies.sh <Debug | Release>
#
# The non-optional parameter indicates which configuration of AudioEngine
# should be used. The Debug build includes simulator slices, while the
# Release does not.
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all Carthage dependencies. It also rebuilds OpenSSL and cURL
#              from scratch.

if [ $# -eq 0 ]; then
  echo "Please specify which AudioEngine configuration you would like to use:"
  echo "    $0 [Debug | Release]"
  exit 1
fi

AE_BUILD_CONFIG=$1

cp ../Certificates/SimplyE/iOS/AudioEngine.json .
cp ../Certificates/SimplyE/iOS/GoogleService-Info.plist .
cp ../Certificates/SimplyE/iOS/APIKeys.swift Simplified/
cp ../Certificates/SimplyE/iOS/ReaderClientCertProduction.sig Simplified/ReaderClientCert.sig
./build-carthage.sh $AE_BUILD_CONFIG
./build-openssl-curl.sh

# these commands must always be run from the Simplified-iOS repo root.
sh adobe-rmsdk-build.sh
(cd readium-sdk; sh MakeHeaders.sh Apple)
