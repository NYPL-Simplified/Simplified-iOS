#!/bin/sh

# SUMMARY
#   Builds the NYPLAEToolkit framework.
#
# SYNOPSIS
#     ./scripts/build-NYPLAEToolkit.sh
#
# USAGE
#   Make sure to run this script from the root of Simplified-iOS.
#   Also note that this script assumes that the Carthage dependencies for
#   SimplyE / OpenE have already been built in ./Carthage.
#

set -eo pipefail

echo "Building NYPLAEToolkit..."

cd ./NYPLAEToolkit

# build NYPLAEToolkit use the same carthage folder as SimplyE (since its
# dependencies are a subset) by adding a symlink if that's missing.
if [[ ! -L ./Carthage ]]; then
  ln -s ../Carthage ./Carthage
fi

echo "Contents of ./NYPLAEToolkit/:"
ls -l .
echo "Contents of ./NYPLAEToolkit/Carthage/Build:"
ls -l Carthage/Build

./scripts/fetch-audioengine.sh
./scripts/build-xcframework.sh

cd ..
