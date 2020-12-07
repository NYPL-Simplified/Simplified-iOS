#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-3rd-parties-dependencies.sh [skipping-adobe]
#
# Parameters:
#   skipping-adobe: skips building the dependencies of the Adobe SDK (OpenSSL,
#                   cURL, etc as well as generating the R1 headers. All this
#                   stuff almost never changes.
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all Carthage dependencies. It also rebuilds OpenSSL and cURL
#              from scratch.

echo "Building 3rd party dependencies..."

# update dependencies from Certificates repo
./scripts/update-certificates.sh

case $1 in
  skipping-adobe | skip-adobe | no-adobe )
    echo "Skipping build of Adobe SDK dependencies..."
    ;;
  *)
    echo "Building Adobe SDK dependencies..."

    # this is required for the Adobe SDK
    ./scripts/build-openssl-curl.sh

    # these commands must always be run from the Simplified-iOS repo root.
    sh ./scripts/adobe-rmsdk-build.sh
    (cd readium-sdk; sh MakeHeaders.sh Apple)
    ;;
esac

# rebuild all Carthage dependencies from scratch
./scripts/build-carthage.sh
