#!/bin/bash

# SUMMARY
#   This scripts wipes your Carthage folder, checks out and rebuilds
#   all Carthage dependencies for working on R2 integration.
#
# SYNOPSIS
#     ./scripts/build-carthage-R2-integration.sh
#
# USAGE
#   Run this script from the root of Simplified-iOS repo.
#   Use this script in conjuction with the SimplifiedR2.workspace. This
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
git checkout 2.0.1
rm -rf Carthage
carthage checkout
mkdir -p Carthage/Build/iOS
carthage build --use-xcframeworks --platform iOS

echo "Building r2-lcp-swift Carthage dependencies..."
cd ../r2-lcp-swift
git checkout 2.0.0
rm -rf Carthage
carthage checkout
mkdir -p Carthage/Build/iOS
carthage build --use-xcframeworks --platform iOS

echo "Building r2-streamer-swift Carthage dependencies..."
cd ../r2-streamer-swift
git checkout 2.0.0
rm -rf Carthage
carthage checkout
mkdir -p Carthage/Build/iOS
carthage build --use-xcframeworks --platform iOS

echo "Building r2-navigator-swift Carthage dependencies..."
cd ../r2-navigator-swift
git checkout 2.0.0
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

./scripts/build-carthage.sh
