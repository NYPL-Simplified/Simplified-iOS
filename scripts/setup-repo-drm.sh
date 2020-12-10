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

echo "Setting up repo for building with DRM support"

git submodule update --init --recursive

ln -s ../DRM-iOS-AdeptConnector adobe-rmsdk

cd ../DRM-iOS-AdeptConnector
./uncompress.sh
