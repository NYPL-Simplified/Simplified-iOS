#!/bin/bash

# SUMMARY
#   This script builds all the dependencies managed by Carthage.
#   It wipes the Carthage folder beforehand.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo:
#
#     ./scripts/build-carthage.sh [--no-private]
#
# PARAMETERS
#   --no-private: skips building private repos.
#
# NOTE
#   This script is idempotent so it can be run safely over and over.

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Building Carthage..."
else
  echo "Building Carthage for [$BUILD_CONTEXT]..."
fi

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf Carthage

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

