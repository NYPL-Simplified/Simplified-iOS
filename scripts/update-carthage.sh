#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/carthage-update-simplye
#

carthage update --no-build

./scripts/build-carthage.sh
