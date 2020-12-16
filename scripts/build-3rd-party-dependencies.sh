#!/bin/bash

# SUMMARY
#   This script integrates secrets, regenerates Readium headers, wipes
#   the Carthage folder, and finally checks out and rebuilds all Carthage
#   dependencies.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo:
#
#     ./scripts/build-3rd-party-dependencies.sh [--no-private]
#
# PARAMETERS
#   --no-private: skips integrating private secrets.
#
# NOTE
#   This script is idempotent so it can be run safely over and over.

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Building 3rd party dependencies..."
else
  echo "Building 3rd party dependencies for [$BUILD_CONTEXT]..."
fi

case $1 in
  --no-private )
    ;;
  *)
    # update dependencies from Certificates repo
    ./scripts/update-certificates.sh
    ;;
esac

(cd readium-sdk; sh MakeHeaders.sh Apple)

if [ "$BUILD_CONTEXT" != "ci" ]; then
  # rebuild all Carthage dependencies from scratch
  ./scripts/build-carthage.sh $1
fi
