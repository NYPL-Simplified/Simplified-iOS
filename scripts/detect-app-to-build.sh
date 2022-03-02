#!/bin/bash

# SUMMARY
#   Detects which app we should build based on which build number
#   changed in the PR's source branch compared to the target branch.
#
# SYNOPSIS
#   detect-app-to-build.sh
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/detect-app-to-build.sh
#
# SIDE EFFECTS
#   1. This script sets 2 GitHub actions outputs, `simplye_changed` and
#      `openebooks_changed`, whose values can be either 1 or 0, respectively
#      if the script did (1) or did NOT (0) detect a change in the build
#      number for each app.
#   2. This script clones the Simplified-iOS repo in a nested directory named
#      `SimplifiedBeforeMerge` for the purpose of checking out the commit
#      before the merge point and avoid messing up the currently working clone.
#      TODO: This might not be necessary and could be replaced by `git stash`
#            and other commands.


# this should be disabled because we need to continue even for return codes != 0
#set -eo pipefail

echo "Detecting which app to build..."

git clone https://github.com/NYPL-Simplified/Simplified-iOS.git SimplifiedBeforeMerge

./scripts/build-number-check.sh simplye
SIMPLYE_CHANGED=1

./scripts/build-number-check.sh openebooks
OPENEBOOKS_CHANGED=$?

echo ""
echo "** Version / build number changes **"
echo "SimplyE: ($SIMPLYE_CHANGED)"
echo "Open eBooks: ($OPENEBOOKS_CHANGED)"

echo "::set-output name=simplye_changed::$SIMPLYE_CHANGED"
echo "::set-output name=openebooks_changed::$OPENEBOOKS_CHANGED"

