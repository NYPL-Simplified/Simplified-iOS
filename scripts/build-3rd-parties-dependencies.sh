#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-3rd-parties-dependencies.sh [--no-drm | --no-private]
#
# Parameters:
#   --no-drm: skips building the dependencies of the Adobe SDK (OpenSSL,
#             cURL, etc.) since they almost never change.
#   --no-private: skips building the dependencies of the Adobe SDK (OpenSSL,
#             cURL, etc.) and all private dependencies.
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all Carthage dependencies. It also rebuilds OpenSSL and cURL
#              from scratch.

echo "Building 3rd party dependencies..."

case $1 in
  --no-private )
    ;;
  *)
    # update dependencies from Certificates repo
    ./scripts/update-certificates.sh
    ;;
esac

case $1 in
  --no-drm | --no-private )
    echo "Skipping build of Adobe SDK dependencies..."
    ;;
  *)
    echo "Building Adobe SDK dependencies..."

    # this is required for the Adobe SDK
    ./scripts/build-openssl-curl.sh

    # these commands must always be run from the Simplified-iOS repo root.
    sh ./scripts/adobe-rmsdk-build.sh
    ;;
esac

(cd readium-sdk; sh MakeHeaders.sh Apple)

# rebuild all Carthage dependencies from scratch
./scripts/build-carthage.sh
