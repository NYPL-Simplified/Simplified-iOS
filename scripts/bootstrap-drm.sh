#!/bin/bash

# SUMMARY
#   Checks out all dependent repos and sets them up for developing
#   SimplyE or Open eBooks with DRM support.
#
# USAGE
#   You only have to run this script once.
#   Run it from the root of Simplified-iOS, e.g.:
#
#     ./scripts/bootstrap-drm.sh
#

cd ..
git clone git@github.com:NYPL-Simplified/Certificates.git
git clone git@github.com:NYPL-Simplified/DRM-iOS-AdeptConnector.git

cd Simplified-iOS
git checkout develop

./scripts/setup-repo-drm.sh

./scripts/build-dependencies.sh
