#!/bin/bash

# SUMMARY
#   This script integrates secrets, regenerates Readium headers, wipes
#   the Carthage folder, and finally checks out and rebuilds all Carthage
#   dependencies.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo:
#
#     ./scripts/build-dependencies.sh [--no-private]
#
# PARAMETERS
#   --no-private: skips integrating private secrets.
#
# NOTE
#   This script is idempotent so it can be run safely over and over.

set -eo pipefail

fatal()
{
  echo "$0 error: $1" 1>&2
  exit 1
}

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Building dependencies..."
else
  echo "Building dependencies for [$BUILD_CONTEXT]..."
fi

case $1 in
  --no-private )
    ;;
  *)
    # update dependencies from Certificates repo
    ./scripts/update-certificates.sh
    ;;
esac

(cd readium-sdk; sh MakeHeaders.sh Apple) || fatal "Error making Readium headers"

# rebuild all Carthage dependencies from scratch
./scripts/build-carthage.sh $1

if [ "$1" != "--no-private" ]; then
  # build NYPLAEToolkit
  cd ./NYPLAEToolkit
  # make NYPLAEToolkit use the same carthage folder as SimplyE (since its
  # dependencies are a subset) by adding a symlink if that's missing.
  if [[ ! -L ./Carthage ]]; then
    ln -s ../Carthage ./Carthage
  fi
  echo "Contents of ./NYPLAEToolkit/Carthage:"
  ls -l . Carthage/
  ./scripts/fetch-audioengine.sh
  ./scripts/build-xcframework.sh
  cd ..
fi
