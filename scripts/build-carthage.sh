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

# make CardCreator use the same carthage folder as SimplyE by adding a
# symlink if that's missing
cd CardCreator-iOS
if [[ ! -L ./Carthage ]]; then
  ln -s ../Carthage ./Carthage
fi
cd ..

# additional setup for builds with DRM
if [ "$1" != "--no-private" ]; then
  if [ "$BUILD_CONTEXT" == "ci" ]; then
    # in a CI context we cannot have siblings repos, so we check them out nested
    CERTIFICATES_PATH_PREFIX="."
  else
    CERTIFICATES_PATH_PREFIX=".."
  fi

  ./NYPLAEToolkit/scripts/fetch-audioengine.sh

  # make NYPLAEToolkit use the same carthage folder as SimplyE by adding a
  # symlink if that's missing
  cd NYPLAEToolkit
  if [[ ! -L ./Carthage ]]; then
    ln -s ../Carthage ./Carthage
  fi
  echo "NYPLAEToolkit contents:"
  ls -l . Carthage/
  cd ..

  # r2-lcp requires a private client library, available via Certificates repo
  echo "Fixing up the Cartfile for LCP..."
  swift $CERTIFICATES_PATH_PREFIX/Certificates/SimplyE/iOS/LCPLib.swift
fi

if [ "$BUILD_CONTEXT" != "ci" ] || [ "$1" == "--no-private" ]; then
  echo "Carthage bootstrap..."
  carthage bootstrap --platform ios --use-xcframeworks
fi
