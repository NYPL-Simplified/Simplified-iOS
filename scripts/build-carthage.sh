#!/bin/bash

# SUMMARY
#   Sets up and build dependencies for the SimplyE, SimplyE-noDRM and
#   Open eBooks targets.
#
# SYNOPSIS
#     ./scripts/build-carthage.sh [--no-private ]
#
# PARAMETERS
#     --no-private: skips building private repos.
#
# USAGE
#   Make sure to run this script from a clean checkout and from the root
#   of Simplified-iOS, e.g.:
#
#     git checkout Cartfile
#     git checkout Cartfile.resolved
#     ./scripts/build-carthage.sh

set -eo pipefail

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Building Carthage..."
else
  echo "Building Carthage for [$BUILD_CONTEXT]..."
fi

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit

# In a CI context we are unable to pass the proper git authentication to
# the `carthage` commands, so we skip them here
if [ "$BUILD_CONTEXT" != "ci" ] && [ "$1" != "--no-private" ]; then
  # checkout NYPLAEToolkit to use the private script to fetch AudioEngine
  carthage checkout NYPLAEToolkit
  ./Carthage/Checkouts/NYPLAEToolkit/scripts/fetch-audioengine.sh
fi

if [ "$BUILD_CONTEXT" != "ci" ] || [ "$1" == "--no-private" ]; then
  echo "Carthage build..."
  carthage bootstrap --platform ios
fi
