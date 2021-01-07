#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-carthage-R2.sh
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all dependencies.
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
carthage update --platform iOS

echo "Building r2-lcp-swift Carthage dependencies..."
cd ../r2-lcp-swift
rm -rf Carthage
swift ../Certificates/SimplyE/iOS/LCPLib.swift -f
carthage update --platform iOS

echo "Building r2-streamer-swift Carthage dependencies..."
cd ../r2-streamer-swift
rm -rf Carthage
carthage update --platform iOS

echo "Building r2-navigator-swift Carthage dependencies..."
cd ../r2-navigator-swift
rm -rf Carthage
carthage update --platform iOS

echo "Done with R2 Carthage dependencies."
cd ..

# remove R2 dependencies from Carthage since we'll build them in the R2 workspace
sed -i '' "s|github \"NYPL-Simplified/r2|#github \"NYPL-Simplified/r2|" Cartfile
sed -i '' "s|github \"NYPL-Simplified/r2||" Cartfile.resolved

carthage checkout
./Carthage/Checkouts/NYPLAEToolkit/scripts/fetch-audioengine.sh

# also update SimplyE's dependencies so the framework versions all match
carthage build --platform ios
