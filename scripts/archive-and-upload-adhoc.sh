#!/bin/bash

# SUMMARY
#   Archives and exports a build of SimplyE or Open eBooks and uploads it to
#   https://github.com/NYPL-Simplified/iOS-binaries repo.
#
# SYNOPSIS
#   archive-and-upload-adhoc.sh [ simplye | SE | openebooks | OE ]
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/archive-and-upload-adhoc simplye

#./scripts/build-3rd-parties-dependencies

source "$(dirname $0)/xcode-archive.sh"

source "$(dirname $0)/xcode-export-adhoc.sh"

source "$(dirname $0)/ios-binaries-upload.sh"
