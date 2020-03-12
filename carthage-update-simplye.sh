#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Please specify which AudioEngine configuration you would like to use:"
  echo "    $0 [Debug | Release]"
  exit 1
fi

AE_BUILD_CONFIG=$1

carthage update --no-build

./build-carthage.sh $AE_BUILD_CONFIG
