#!/bin/bash

# SUMMARY
#   Use this script to easily toggle all R2 repos between the stable release
#   we use in production builds and the most recent code on `develop`.
#
# SYNOPSIS
#   ./scripts/checkout-r2-branch.sh [develop]
#
# PARAMETERS
#   develop: check out the develop branch of every R2 frameworks we use.
#            If missing, it will check out the tags we officially use in
#            SimplyE / Open eBooks.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo.
#
#   This script assumes that you have the R2 repos checked out as siblings of
#   Simplified-iOS.
#
#   Use this script in conjunction with the build-carthage-R2-integration.sh
#   to build the checked out code.

if [ "$1" == "develop" ]; then

  echo "Checking out 'develop' on readium/swift-toolkit..."
  cd ../swift-toolkit
  git checkout develop

else

  echo "Checking out latest stable tag on readium/swift-toolkit..."
  cd ../swift-toolkit
  git checkout 2.2.0

fi
