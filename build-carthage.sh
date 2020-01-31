#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     build-carthage.sh <Debug | Release>
#
# The parameter indicates which configuration of AudioEngine should be used.
# The Debug build includes simulator slices, while the Release does not.
# One parameter must be specified.
#
# NOTE: The current Release configuration of the AudioEngine framework
#       specified in Certificates repo will cause a build failure because it
#       does not contain any slices for x86_64 (simulator) architectures.
#
# Description: This scripts wipes your Carthage folder, checks out and rebuilds
#              all dependencies.

if [ $# -eq 0 ]; then
  echo "Please specify which AudioEngine configuration you would like to use:"
  echo "    $0 [Debug | Release]"
  exit 1
fi

rm -rf Carthage
carthage checkout --use-ssh

# Simplified-iOS and NYPLAEToolkit depend on the AudioEngine framework. Normally
# one would express this dependency by adding this line to Cartfile.resolved:
#
#   binary "AudioEngine.json" "6.1.15"
#
# However, the AudioEngine zip specified in the Certificates repo contains 2 builds
# of the framework (Debug and Release) and since Carthage no longer allows that,
# it cannot resolve the dependency and would produce an error along these lines:
#
#   A shell task (/usr/bin/xcrun dwarfdump --uuid /Users/xyz/git/NYPLAEToolkit/Carthage/Build/iOS/AudioEngine.framework/AudioEngine) failed with exit code 1:
#   error: /Users/xyz/git/NYPLAEToolkit/Carthage/Build/iOS/AudioEngine.framework/AudioEngine: Invalid data was encountered while parsing the file
#
# We maintain a fork of Carthage that solved the dwarfdump issue above, but using
# that will produce the following error:
#
#   Invalid archive - Found multiple frameworks with the same unarchiving destination:
#    	file:///var/folders/..../AudioEngine/Release/AudioEngine.framework/
#     file:///var/folders/..../AudioEngine/Debug/AudioEngine.framework/
#       to:
#     file:///Users/xyz/git/Simplified-iOS/Carthage/Build/iOS/AudioEngine.framework/
#
# Therefore, we are renouncing to use Carthage for managing this dependency.
# Since it's a dylib binary, the cost is not too high: there's nothing to
# actually build, all we need to do is placing the framework into the correct
# location with the other Carthage frameworks. Here we're using Debug build for
# development purposes (since it includes Simulator lipo slices, which the
# Release build does not), but similar steps would apply for building for Release.

cd Carthage
AE_BUILD_CONFIG=$1
chmod u+x ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift
AUDIOENGINE_ZIP_URL=$( ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift ../../Certificates/SimplyE/iOS/AudioEngine.json )
curl -O $AUDIOENGINE_ZIP_URL
unzip `basename $AUDIOENGINE_ZIP_URL`
mkdir -p Build/iOS
echo "Using $AE_BUILD_CONFIG configuration for AudioEngine..."
cp -R AudioEngine/$AE_BUILD_CONFIG/AudioEngine.framework Build/iOS

# Carthage gets confused by the fact that NYPLAEToolkit expresses a dependency
# on AudioEngine in its Cartfile and Cartfile.resolved: but since we've already
# addressed that dependency at steps above, let's remove it from Carthage's
# eyes before building:

sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile
sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile.resolved
cd ..
carthage build --platform ios
