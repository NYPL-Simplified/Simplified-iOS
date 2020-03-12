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

# deep clean to avoid any caching issues
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf Carthage

carthage checkout --use-ssh

# Simplified-iOS and NYPLAEToolkit depend on the AudioEngine framework. Normally
# one would express this dependency by adding this line to Cartfile.resolved:
#
#   binary "AudioEngine.json" "6.1.15"
#
# We've experienced build issues where Carthage may error out with something like:
#
#   A shell task (/usr/bin/xcrun dwarfdump --uuid /Users/xyz/git/NYPLAEToolkit/Carthage/Build/iOS/AudioEngine.framework/AudioEngine) failed with exit code 1:
#   error: /Users/xyz/git/NYPLAEToolkit/Carthage/Build/iOS/AudioEngine.framework/AudioEngine: Invalid data was encountered while parsing the file
#
# E.g. That seems to happen when building with `carthage build --configuration Release`
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
# The problem is that the AudioEngine zip specified in the Certificates repo contains
# 2 builds of the framework (Debug and Release) but Carthage no longer allows that, per
# https://github.com/Carthage/Carthage#archive-prebuilt-frameworks-into-one-zip-file .
# Occasionally Carthage may be still able to build, but it is not certain which
# build of AudioEngine is actually going to use. To control this better, especially
# when preparing app Release builds) we are manually managing this dependency by
# copying the pre-built framework binary into the location Carthage expects it:

cd Carthage
AE_BUILD_CONFIG=$1
chmod u+x ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift
AUDIOENGINE_ZIP_URL=$( ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift ../../Certificates/SimplyE/iOS/AudioEngine.json )
curl -O $AUDIOENGINE_ZIP_URL
unzip `basename $AUDIOENGINE_ZIP_URL`
mkdir -p Build/iOS
echo "Using $AE_BUILD_CONFIG configuration for AudioEngine..."
cp -R AudioEngine/$AE_BUILD_CONFIG/AudioEngine.framework Build/iOS

# Carthage may also get confused by the fact that NYPLAEToolkit expresses the same dependency
# on AudioEngine. Since we've already handled that, we can just remove it from there:

sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile
sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile.resolved
cd ..
sed -i '' '/binary "AudioEngine.json".*/d' Cartfile.resolved
carthage build --platform ios
