#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     build-3rd-parties-dependencies.sh
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all Carthage dependencies. It also rebuilds OpenSSL and cURL
#              from scratch.

# update dependencies from Certificates repo
./update-certificates.sh

# rebuild all Carthage dependencies from scratch
./build-carthage.sh

# this is required for the Adobe SDK
./build-openssl-curl.sh

# these commands must always be run from the Simplified-iOS repo root.
sh adobe-rmsdk-build.sh
(cd readium-sdk; sh MakeHeaders.sh Apple)

