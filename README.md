# Building With Adobe DRM

## Building the Application

01. Install the latest Xcode in `/Applications`, open it and make sure to install additional components if it asks you.
02. Contact project lead and ensure you have repo access to all required submodules, including private ones. Also request a copy of the Adobe RMSDK archive, which is currently not on Github.
03. Fork https://github.com/NYPL-Simplified/Simplified-iOS
04. Run:
```bash
git clone git@github.com:<YOUR_GITHUB>/Simplified-iOS.git
git clone git@github.com:NYPL-Simplified/Certificates.git
cd Simplified-iOS
git checkout master
git submodule update --init --recursive
cp ../Certificates/SimplyE/iOS/AudioEngine.json ../Certificates/SimplyE/iOS/bugsnag-dsym-upload.rb .
cp ../Certificates/SimplyE/iOS/APIKeys.swift Simplified/
```
04. Build Carthage libraries following "Building Carthage Dependencies" section below.
05. Symlink the unzipped Adobe RMSDK to "adobe-rmsdk" within the "Simplified-iOS" directory, e.g.:
```bash
ln -s ~/Documents/AdobeRMSDK/DRM_Connector_Prerelease adobe-rmsdk
```
07. Build OpenSSL and cURL as described in the following "Building OpenSSL and cURL" section.
08. Ensure you're in the "Simplified-iOS" directory before continuing to the next step, then run:
```bash
sh adobe-rmsdk-build.sh
(cd readium-sdk; sh MakeHeaders.sh Apple)
```
09. Open Simplified.xcodeproj and Build!

## Building Carthage Dependencies

Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already. Using `brew` is recommended.
```bash
carthage checkout --use-ssh
```
Hack alert! Simplified-iOS and NYPLAEToolkit depend on the AudioEngine framework. The AudioEngine zip specified in the Certificates repo contains 2 versions of the framework (Debug and Release) and since Carthage no longer allows that, it cannot resolve the dependency. Therefore we are manually installing the Debug build -- this is for development purposes, similar steps would apply for building for Release.
```bash
cd Carthage
chmod ugo+x ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift
AUDIOENGINE_ZIP_URL=$( ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift ../../Certificates/SimplyE/iOS/AudioEngine.json )
curl -O $AUDIOENGINE_ZIP_URL
unzip `basename $AUDIOENGINE_ZIP_URL`
mkdir -p Build/iOS
cp -R AudioEngine/Debug/AudioEngine.framework Build/iOS
```
Carthage gets confused by the fact that NYPLAEToolkit expresses a dependency on AudioEngine in its Cartfile and Cartfile.resolved: but since we've already addressed that dependency at steps above, let's remove it from Carthage's eyes before building:
```bash
sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile
sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile.resolved
cd ..
carthage build --platform ios
```

## Building OpenSSL and cURL

In theory, following the instructions in "adobe-rmsdk/RMSDK_User_Manual(obj).pdf", you should be able to build OpenSSL (section 12.1) and cURL (section 12.3) since Adobe provides this package to their developers. The following are some smoother steps to achieving that.

Note: if you want/need to use an Xcode installed at a location other than `/Applications`, you'll need to update the $DEVELOPER env variable mentioned at the top of both the `build.sh` / `build_curl.sh` scripts below.

With the assumption that we are still in the root of Simplified-iOS:
```bash
cp build_curl.sh adobe-rmsdk/thirdparty/curl/iOS-libcurl/
SDKVERSION=`xcodebuild -version -sdk iphoneos | grep SDKVersion | sed 's/SDKVersion[: ]*//'`

cd adobe-rmsdk/thirdparty/openssl
mkdir public
mv iOS-openssl/ public/ios/
cd public/ios
curl -O https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz
sed -i '' 's/OPENSSL_VERSION=".*"/OPENSSL_VERSION="1.0.1u"/' build.sh
sed -i '' "s/SDK_VERSION=\".*\"/SDK_VERSION=\"$SDKVERSION\"/" build.sh
sed -i '' 's/MIN_VERSION=".*"/MIN_VERSION="9.0"/' build.sh
bash ./build.sh  #this will take a while

cd ../../../curl/iOS-libcurl
curl -O https://curl.haxx.se/download/curl-7.64.1.zip
sed -i '' 's/CURL_VERSION=".*"/CURL_VERSION="7.64.1"/' build_curl.sh
sed -i '' "s/SDK_VERSION=\".*\"/SDK_VERSION=\"$SDKVERSION\"/" build_curl.sh
sed -i '' 's/MIN_VERSION=".*"/MIN_VERSION="9.0"/' build_curl.sh
bash ./build_curl.sh  #this will take a while
```

# Building Without Adobe DRM

**Note:** This configuration is not currently supported. In the interim, you _should_ be able to get it to build via the following steps:

01. `git clone https://github.com/NYPL-Simplified/Simplified-iOS.git` or `git clone git@github.com:NYPL-Simplified/Simplified-iOS.git`
02. `cd Simplified-iOS`
03. `git submodule deinit adept-ios && git rm -rf adept-ios`
04. `git submodule deinit adobe-content-filter && git rm -rf adobe-content-filter`
05. `git submodule update --init --recursive`
06. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already.
07. Remove "NYPL-Simplified/NYPLAEToolkit" and "AudioEngine.json" in `Cartfile` and `Cartfile.resolved`.
08. `carthage bootstrap --platform ios --use-ssh`
09. `cp APIKeys.swift.example Simplified/APIKeys.swift` and edit accordingly.
10. `cp Accounts.json.example Simplified/Accounts.json`.
11. `(cd readium-sdk; sh MakeHeaders.sh Apple)` (parentheses included) to generate the headers for Readium.
12. `open Simplified.xcodeproj`
13. Remove import of "Simplified+RMSDK.xcconfig" from "Simplified.xcconfig".
14. Delete `NYPLAEToolkit.framework` and `AudioEngine.framework` from "Link Binary with Libraries", and remove input and output filepaths for `AudioEngine.framework` and `NYPLAEToolkit.framework` from `Copy Frameworks (Carthage)`.
15. Note: For now, we recommend keeping any unstaged changes as a single git stash until better dynamic build support is added.
16. Build.

# Contributing

This codebase follows [Google's Objective-C Style Guide](https://google.github.io/styleguide/objcguide.xml)
including the use of two-space indentation. Both Objective-C and Swift may be
used for new code.

The primary services/singletons within the program are as follows:

* `NYPLAccount`
* `NYPLBookCoverRegistry` (used directly only by `NYPLBookRegistry`)
* `NYPLBookRegistry`
* `NYPLConfiguration`
* `NYPLKeychain`
* `NYPLMyBooksDownloadCenter`
* `NYPLMigrationManager`

All of the above contain appropriate documentation in the header files.

The rest of the program follows Apple's usual pattern of passive views,
relatively passive models, and one-off controllers for integrating everything.
Immutability is preferred wherever possible.

Questions, suggestions, and general discussion occurs via Slack: Email
`swans062@umn.edu` for access.

# License

Copyright © 2015 The New York Public Library, Astor, Lenox, and Tilden Foundations

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
