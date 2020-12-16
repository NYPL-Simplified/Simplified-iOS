#!/bin/bash

# SUMMARY
#   Archives and exports a build of SimplyE or Open eBooks and uploads it to
#   https://github.com/NYPL-Simplified/iOS-binaries repo, assuming all
#   third party dependencies have already been built.
#
# SYNOPSIS
#   archive-and-upload-adhoc.sh <app-name>
#
# PARAMETERS
#   See xcode-settings.sh for possible parameters.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo, e.g.:
#
#     ./scripts/archive-and-upload-adhoc simplye

source "$(dirname $0)/xcode-archive.sh"

source "$(dirname $0)/xcode-export-adhoc.sh"

source "$(dirname $0)/ios-binaries-upload.sh"
