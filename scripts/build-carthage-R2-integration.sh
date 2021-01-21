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

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf Carthage

echo "Building r2-shared-swift Carthage dependencies..."
cd ../r2-shared-swift
rm -rf Carthage
carthage checkout
carthage build --platform iOS

echo "Building r2-lcp-swift Carthage dependencies..."
cd ../r2-lcp-swift
rm -rf Carthage
swift ../Certificates/SimplyE/iOS/LCPLib.swift -f
carthage checkout
carthage build --platform iOS

echo "Building r2-streamer-swift Carthage dependencies..."
cd ../r2-streamer-swift
rm -rf Carthage
carthage checkout
carthage build --platform iOS

echo "Building r2-navigator-swift Carthage dependencies..."
cd ../r2-navigator-swift
rm -rf Carthage
carthage checkout
carthage build --platform iOS

echo "Done with R2 Carthage dependencies."
cd ../Simplified-iOS

# remove R2 dependencies from Carthage since we'll build them in the R2 workspace
sed -i '' "s|github \"NYPL-Simplified/r2|#github \"NYPL-Simplified/r2|" Cartfile
sed -i '' "s|github \"NYPL-Simplified/r2.*||" Cartfile.resolved

carthage checkout
./Carthage/Checkouts/NYPLAEToolkit/scripts/fetch-audioengine.sh

# also update SimplyE's dependencies so the framework versions all match
carthage build --platform ios
