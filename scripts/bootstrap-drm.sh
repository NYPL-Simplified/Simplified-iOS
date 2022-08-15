#!/bin/bash

# SUMMARY
#   Checks out all dependent repos and sets them up for developing
#   SimplyE or Open eBooks with DRM support.
#
# WARNINGS
# 1. Run this script once on a fresh clone of the Simplified-iOS repo.
#    After that, you'll be better off running `build-dependencies.sh` instead.
# 2. This script is not idempotent.
#
# USAGE
#   Run it from the root of Simplified-iOS, e.g.:
#
#     ./scripts/bootstrap-drm.sh
#

cd ..
git clone git@github.com:NYPL-Simplified/DRM-iOS-AdeptConnector.git

cd Simplified-iOS
git checkout develop

./scripts/setup-repo-drm.sh

./scripts/build-dependencies.sh
