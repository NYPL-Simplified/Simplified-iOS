#!/bin/bash

# SUMMARY
#   Sets things up for building carthage dependencies for the SimplyE,
#   SimplyE-noDRM and Open eBooks targets.
#
# SYNOPSIS
#     ./scripts/prepare-carthage.sh [--no-private ]
#
# PARAMETERS
#     --no-private: skips setting up LCP dependencies.
#
# ENVIRONMENT VARIABLES
#     BUILD_CONTEXT: Must be set to `ci` for a CI build.
#
# USAGE
#   Make sure to run this script from a clean checkout and from the root
#   of Simplified-iOS, e.g.:
#
#     git checkout Cartfile
#     git checkout Cartfile.resolved
#     ./scripts/prepare-carthage.sh
#
# NOTES
#   If working on R2 integration, use the `build-carthage-R2-integration.sh`
#   script instead.

set -eo pipefail

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Preparing Carthage build..."
else
  echo "Preparing Carthage build for [$BUILD_CONTEXT]..."
fi

# currently disabled since we don't support LCP at the moment
## additional setup for builds with DRM
#if [ "$1" != "--no-private" ]; then
#  # LCP support in R2 requires a private client library, available via Certificates repo
#  echo "Fixing up the Cartfile for LCP..."
#  swift ./Certificates/SimplyE/iOS/LCPLib.swift
#fi
