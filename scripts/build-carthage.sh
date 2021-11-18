#!/bin/bash

# SUMMARY
#   Sets up and build dependencies for the SimplyE, SimplyE-noDRM and
#   Open eBooks targets.
#
# SYNOPSIS
#     ./scripts/build-carthage.sh [--no-private ]
#
# PARAMETERS
#     --no-private: skips setting up LCP dependencies.
#
# USAGE
#   Make sure to run this script from a clean checkout and from the root
#   of Simplified-iOS, e.g.:
#
#     git checkout Cartfile
#     git checkout Cartfile.resolved
#     ./scripts/build-carthage.sh
#
# NOTES
#   If working on R2 integration, use the `build-carthage-R2-integration.sh`
#   script instead.

set -eo pipefail

./scripts/prepare-carthage.sh $1

if [ "$BUILD_CONTEXT" != "ci" ] || [ "$1" == "--no-private" ]; then
  echo "Building Carthage..."
  carthage bootstrap --platform ios --use-xcframeworks --cache-builds
fi
