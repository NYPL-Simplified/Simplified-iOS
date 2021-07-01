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

set -eo pipefail

echo "Detecting which app to build..."

echo "Target branch: [$TARGET_BRANCH]"

SIMPLYE_CHANGED=`./scripts/build-number-check.sh simplye`
OPENEBOOKS_CHANGED=`./scripts/build-number-check.sh openebooks`

if [ "$SIMPLYE_CHANGED" == "0" ] && [ "$OPENEBOOKS_CHANGED" == "0" ]; then
  echo "Version or build numbers were not changed for either SimplyE or Open eBooks"
  exit 1
fi

echo "Version or build numbers for either SimplyE ($SIMPLYE_CHANGED) or Open eBooks ($OPENEBOOKS_CHANGED) were changed"
