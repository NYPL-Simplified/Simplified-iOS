#!/bin/bash

# TODO: Remove the script in Certificate repo
# for extracting AudioEngine URL when this is being merge

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-carthage.sh
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all dependencies.

echo "Building Carthage for [$BUILD_CONTEXT]..."

if [ "$BUILD_CONTEXT" != "ci" ]; then
  # deep clean to avoid any caching issues
  rm -rf ~/Library/Caches/org.carthage.CarthageKit
  rm -rf Carthage
  carthage checkout --use-ssh
fi

./Carthage/Checkouts/NYPLAEToolkit/scripts/fetch-audioengine.sh

echo "List of carthage checkouts to be built:"
ls -la ./Carthage/Checkouts/

echo "Carthage build..."
carthage build --platform ios

