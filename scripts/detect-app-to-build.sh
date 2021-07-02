#!/bin/bash

# SUMMARY
#   Detect which app we should build based on which target build number
#   changed in the PR's source branch compared to the target branch.
#
# SYNOPSIS
#   detect-app-to-build.sh
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/detect-app-to-build.sh

# disabled becauswe might need to continue even for return code == 1
#set -eo pipefail

echo "Detecting which app to build..."

git clone https://github.com/NYPL-Simplified/Simplified-iOS.git tmpSimplified

./scripts/build-number-check.sh simplye
SIMPLYE_CHANGED=$?

./scripts/build-number-check.sh openebooks
OPENEBOOKS_CHANGED=$?

#if [ "$SIMPLYE_CHANGED" == 0 ] && [ "$OPENEBOOKS_CHANGED" == 0 ]; then
#  echo "Version + build number were not changed for SimplyE or Open eBooks"
#  #exit 1
#fi

echo ""
echo "** Version / build number changes **"
echo "SimplyE: ($SIMPLYE_CHANGED)"
echo "Open eBooks: ($OPENEBOOKS_CHANGED)"

echo "::set-output name=simplye_changed::$SIMPLYE_CHANGED"
echo "::set-output name=openebooks_changed::$OPENEBOOKS_CHANGED"

