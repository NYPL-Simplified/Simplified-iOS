#!/bin/bash

# SUMMARY
#   This scripts wipes your Carthage folders and rebuilds
#   all Carthage dependencies for working on R2 integration.
#
# SYNOPSIS
#   ./scripts/build-carthage-R2-integration.sh [--no-private]
#
# PARAMETERS
#   --no-private: skips integrating private repos for DRM support.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo.
#
#   You can use the `checkout-r2-branch.sh` script to easily toggle
#   all R2 repos between the stable release we use in production builds,
#   and the most recent code on `develop`.
#
#   Use this script in conjunction with the SimplifiedR2.workspace. This
#   assumes that you have the R2 repos checked out as siblings of
#   Simplified-iOS.
#
# NOTES
#   This is meant to be used locally. It won't work in a GitHub Actions CI
#   context. For the latter, use `build-carthage.sh` instead.

echo "Building Carthages for R2 dependencies..."

CURRENT_DIR=`pwd`

# deep clean to avoid any caching issues
./scripts/clean-carthage.sh

echo "Building r2-shared-swift Carthage dependencies..."
cd ../r2-shared-swift
rm -rf Carthage
carthage checkout
mkdir -p Carthage/Build/iOS
carthage build --use-xcframeworks --platform iOS

if [ "$1" != "--no-private" ]; then # include private libraries (e.g. for DRM support)
  echo "Building r2-lcp-swift Carthage dependencies..."
  cd ../r2-lcp-swift
  rm -rf Carthage
  carthage checkout
  mkdir -p Carthage/Build/iOS
  carthage build --use-xcframeworks --platform iOS
fi

echo "Building r2-streamer-swift Carthage dependencies..."
cd ../r2-streamer-swift
rm -rf Carthage
carthage checkout
mkdir -p Carthage/Build/iOS
carthage build --use-xcframeworks --platform iOS

echo "Building r2-navigator-swift Carthage dependencies..."
cd ../r2-navigator-swift
rm -rf Carthage
carthage checkout
mkdir -p Carthage/Build/iOS
carthage build --use-xcframeworks --platform iOS

echo "Done with R2 Carthage dependencies."
cd $CURRENT_DIR

# remove R2 dependencies from Carthage since we'll build them in the R2 workspace
sed -i '' "s|github \"readium/r2|#github \"readium/r2|" Cartfile
sed -i '' "s|github \"NYPL-Simplified/r2|#github \"NYPL-Simplified/r2|" Cartfile
sed -i '' "s|github \"readium/r2.*||" Cartfile.resolved
sed -i '' "s|github \"NYPL-Simplified/r2.*||" Cartfile.resolved

./scripts/build-carthage.sh $1
