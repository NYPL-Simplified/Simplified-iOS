#!/bin/bash

# SUMMARY
#   Deep cleans everything that might affect carthage rebuilding.
#
# SYNOPSIS
#     ./scripts/clean-carthage.sh
#
# USAGE
#   Make sure to run this script from the root of Simplified-iOS.

set -eo pipefail

rm -rf Carthage
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf ~/Library/Caches/carthage
