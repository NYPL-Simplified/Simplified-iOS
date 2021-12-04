#!/bin/bash

# SUMMARY
#   This script integrates secrets, regenerates Readium headers, and prepares
#   the set for the Carthage build. If this script is called to build the app
#   with DRM support or from a CI context, that's it. Otherwise, it will also
#   check out and rebuild all Carthage dependencies, and finally (for DRM
#   builds) build the NYPLAEToolkit framework.
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

# rebuild all Carthage dependencies from scratch. For a CI build with DRM,
# this results in just preparing the set for the carthage build, which happens
# later as a separate step in GitHub actions workflows.
./scripts/build-carthage.sh $1

# The NYPLAEToolkit build has to necessarily happen after the Carthage build,
# because the Carthage dependencies NYPLAEToolkit has are a subset of what we
# have in SimplyE/OpenE.
if [ "$1" != "--no-private" ]; then # include private libraries (e.g. for DRM support)
  if [ "$BUILD_CONTEXT" != "ci" ]; then # CI builds NYPLAEToolkit in a separate workflow step
    ./scripts/build-NYPLAEToolkit.sh
  fi
fi
