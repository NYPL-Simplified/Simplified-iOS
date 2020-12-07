#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-3rd-parties-dependencies.sh
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all Carthage dependencies. It also rebuilds OpenSSL and cURL
#              from scratch.

echo "Building 3rd party dependencies..."

# update dependencies from Certificates repo
./scripts/update-certificates.sh

# this is required for the Adobe SDK
./scripts/build-openssl-curl.sh

# these commands must always be run from the Simplified-iOS repo root.
sh ./scripts/adobe-rmsdk-build.sh
(cd readium-sdk; sh MakeHeaders.sh Apple)

# rebuild all Carthage dependencies from scratch
./scripts/build-carthage.sh
