#!/bin/bash

# SUMMARY
#   Sets up the Simplified-iOS repo for running SimplyE and Open eBooks
#   with DRM support.
#
# USAGE
#   You only have to run this script once after checking out the related repos.
#   Run it from the root of Simplified-iOS, e.g.:
#
#     ./scripts/setup-repo-drm.sh
#

set -eo pipefail

if [ "$BUILD_CONTEXT" == "" ]; then
  echo "Setting up repo for building with DRM support..."
else
  echo "Setting up repo for building with DRM support for [$BUILD_CONTEXT]..."
fi

git submodule update --init --recursive

if [ "$BUILD_CONTEXT" == "ci" ]; then
  ADOBE_SDK_PATH=./DRM-iOS-AdeptConnector
else
  ADOBE_SDK_PATH=../DRM-iOS-AdeptConnector
fi

ln -s $ADOBE_SDK_PATH adobe-rmsdk

cd $ADOBE_SDK_PATH
./uncompress.sh

if [ "$BUILD_CONTEXT" != "ci" ]; then
  git clone git@github.com:NYPL-Simplified/Axis-iOS.git
fi
