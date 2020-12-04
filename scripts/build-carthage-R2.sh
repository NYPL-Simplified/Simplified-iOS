#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-carthage-R2.sh
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all dependencies.

echo "Building Carthages for R2 dependencies..."

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

# also update SimplyE's dependencies so the framework versions all match
echo "Updating Simplified-iOS Carthage.resolved..."
carthage update --no-build

echo "Done with R2 Carthage dependencies."
