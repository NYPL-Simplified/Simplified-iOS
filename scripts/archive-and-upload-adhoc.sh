#!/bin/bash

# SUMMARY
#   Archives and exports a build of SimplyE or Open eBooks and uploads it to
#   https://github.com/NYPL-Simplified/iOS-binaries repo.
#
# SYNOPSIS
#   archive-and-upload-adhoc.sh [<app-name>] [skipping-adobe]
#
# PARAMETERS
#   <app-name>     : Which app to build. If missing it defaults to SimplyE.
#                    Possible values: simplye | SE | openebooks | OE
#
#   skipping-adobe : Build the app but skip rebuilding the Adobe SDK as well as
#                    Readium 1 headers, since both rarely (if ever) change.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/archive-and-upload-adhoc simplye

./scripts/build-3rd-parties-dependencies.sh $2

source "$(dirname $0)/xcode-archive.sh"

source "$(dirname $0)/xcode-export-adhoc.sh"

source "$(dirname $0)/ios-binaries-upload.sh"
