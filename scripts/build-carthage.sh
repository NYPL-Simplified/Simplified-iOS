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
#
# NOTES
#   If working on R2 integration, use the `build-carthage-R2-integration.sh`
#   script instead.

set -eo pipefail

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Building Carthage..."
else
  echo "Building Carthage for [$BUILD_CONTEXT]..."
fi

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit

if [ "$1" != "--no-private" ]; then
  if [ "$BUILD_CONTEXT" == "ci" ]; then
    # in a CI context we cannot have siblings repos, so we check them out nested
    CERTIFICATES_PATH_PREFIX="."
  else
    CERTIFICATES_PATH_PREFIX=".."

    # checkout NYPLAEToolkit to use the private script to fetch AudioEngine.
    # We can only do it from outside of a GitHub Actions CI context, because
    # git authentication is not passed correctly to Carthage there.
    echo "Checking out NYPLAEToolkit to fetch AudioEngine binary before carthage bootstrap..."
    carthage checkout NYPLAEToolkit
    ./Carthage/Checkouts/NYPLAEToolkit/scripts/fetch-audioengine.sh
  fi

  # r2-lcp requires a private client library, available via Certificates repo
  echo "Fixing up the Cartfile for LCP..."
  swift $CERTIFICATES_PATH_PREFIX/Certificates/SimplyE/iOS/LCPLib.swift
fi

if [ "$BUILD_CONTEXT" != "ci" ] || [ "$1" == "--no-private" ]; then
  echo "Carthage build..."
  carthage bootstrap --platform ios
fi
