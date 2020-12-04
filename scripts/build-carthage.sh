#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/build-carthage.sh [-skipR2]
#
# Parameters:
#     --skipR2: Avoid building the Carthage dependencies inside each R2 repo
#               (such as r2-shared-swift, etc)
#
# Description: This scripts wipes your Carthage folders, checks out and rebuilds
#              all dependencies. When `--skipR2` is omitted, it also updates
#              the cartfile for this and every R2 repo before building.

echo "Building Carthage..."

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf Carthage

# build the Carthage folders of the R2 repos. This is needed in order for the
# `Simplified-R2dev` target to build correctly.
if [ "$1" = "--skipR2" ]; then
  echo "Skipping rebuilding R2 Carthages."
else
  ./scripts/build-carthage-R2.sh
fi

carthage checkout --use-ssh

./Carthage/Checkouts/NYPLAEToolkit/fetch-audioengine.sh

echo "Building Carthage dependencies for Simplified-iOS..."
carthage build --platform ios
