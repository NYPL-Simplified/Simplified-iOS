#!/bin/bash

# SUMMARY
#   This script builds all the dependencies managed by Carthage.
#   It wipes the Carthage folder beforehand and runs `carthage update`
#   for every repo before building.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo:
#
#     ./scripts/build-carthage.sh [--no-private ]
#
# PARAMETERS
#   --no-private: skips building private repos.
#
# NOTE
#   This script is idempotent so it can be run safely over and over.
#   It assumes that the R2 repos are checked out as siblings of Simplified-iOS.

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Building Carthage..."
else
  echo "Building Carthage for [$BUILD_CONTEXT]..."
fi

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf Carthage

# build the Carthage folders of the R2 repos. This is needed in order for the
# `Simplified-R2dev` target to build correctly.
./scripts/build-carthage-R2.sh

if [ "$1" == "--no-private" ]; then
  carthage checkout
else
  carthage checkout --use-ssh
  ./Carthage/Checkouts/NYPLAEToolkit/scripts/fetch-audioengine.sh
fi

echo "List of carthage checkouts to be built:"
ls -la ./Carthage/Checkouts/

echo "Carthage build..."
carthage build --platform ios

