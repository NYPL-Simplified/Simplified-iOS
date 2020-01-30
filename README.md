# Building With Adobe DRM

## Building the Application

01. Install the latest Xcode in `/Applications`, open it and make sure to install additional components if it asks you.
02. Fork https://github.com/NYPL-Simplified/Simplified-iOS
03. `git clone git@github.com:<YOUR_GITHUB>/Simplified-iOS.git`
04. Clone external repo containing various private details (in particular, API keys, AudioEngine binary for NYPLAEToolkit, and a script to upload symbols to Bugsnag): `git clone git@github.com:NYPL-Simplified/Certificates.git`
05. `cd Simplified-iOS; git checkout master`
06. `git submodule update --init --recursive` (please check you have repo access to the submodules, notably the private repos)
07. `cp ../Certificates/SimplyE/iOS/AudioEngine.json ../Certificates/SimplyE/iOS/bugsnag-dsym-upload.rb .`
08. `cp ../Certificates/SimplyE/iOS/APIKeys.swift Simplified/`
09. Build Carthage libraries following "Building Carthage Dependencies" section below.
08. Symlink an unzipped copy of Adobe RMSDK to "adobe-rmsdk" within the "Simplified-iOS" directory. (You will need to have obtained this archive from Adobe; please contact team lead for this archive)
07. Build OpenSSL and cURL as described in the following "Building OpenSSL and cURL" section. Ensure you're in the "Simplified-iOS" directory before continuing to the next step.
08. `sh adobe-rmsdk-build.sh`
09. `(cd readium-sdk; sh MakeHeaders.sh Apple)` (parentheses included) to generate the headers for Readium.
12. `open Simplified.xcodeproj`
13. Build

## Building Carthage Dependencies

01. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already. Using `brew` is recommended.
02. `carthage checkout --use-ssh`

Hack alert! Simplified-iOS and NYPLAEToolkit depend on the AudioEngine framework. The AudioEngine zip specified in the Certificates repo contains 2 versions of the framework (Debug and Release) and carthage does not allow that, and therefore cannot resolve the dependency. Therefore we are manually installing the Debug build -- this is for development purposes, similar steps would apply for building for Release.

03. `cd Carthage`
04. `AUDIOENGINE_ZIP_URL=$( ../../Certificates/SimplyE/iOS/AudioEngineZipURLExtractor.swift ../../Certificates/SimplyE/iOS/AudioEngine.json )`
05. `curl -O $AUDIOENGINE_ZIP_URL`
06. ``unzip `basename $AUDIOENGINE_ZIP_URL` ``
07. `mkdir -p Build/iOS`
08. `cp -R AudioEngine/Debug/AudioEngine.framework Build/iOS`
09. Carthage gets confused by the fact that NYPLAEToolkit expresses a dependency on AudioEngine in its Cartfile and Cartfile.resolved: but since we've already addressed that dependency at steps above, let's remove it from Carthage eyes.:
```
sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile
sed -i '' '/binary "AudioEngine.json".*/d' Checkouts/NYPLAEToolkit/Cartfile.resolved
```
10. `cd .. && carthage build --platform ios`


## Building OpenSSL and cURL

In theory, following the instructions in "adobe-rmsdk/RMSDK_User_Manual(obj).pdf", you should be able to build OpenSSL (section 12.1) and cURL (section 12.3) since Adobe provides this package to their developers.
The following are some smoother steps to achieving this:
01. From `adobe-rmsdk/thirdparty/openssl` run `mkdir public; mv iOS-openssl/ public/ios/`
02. Download openssl 1.0.1 (1.0.1u should suffice) to `adobe-rmsdk/thirdparty/openssl/public/ios/openssl-1.0.1u.tar.gz` (note that the build script is expecting a tarball; as of this writing the download can be found at: https://www.openssl.org/source/old/1.0.1/)
03. Modify the `adobe-rmsdk/thirdparty/openssl/public/ios/build.sh` such that:
    - `OPENSSL_VERSION` reflects the version you downloaded, in this case "1.0.1u"
    - `SDK_VERSION` reflects the iOS SDK you're using (you can check what you have installed using `xcodebuild -showsdks`)
    - `MIN_VERSION` is "9.0"
04. From the directory of the build script (this will take a while): `bash ./build.sh`
05. Download curl (7.64.1 is known to work) to `adobe-rmsdk/thirdparty/curl/ios-libCurl/curl-7.64.1.zip` (note that the build script expects a ZIP, not tarball; as of this writing this download can be found at: https://curl.haxx.se/download/)
06. Replace `adobe-rmsdk/thirdparty/curl/ios/build.sh` with `build_curl.sh`, a fixed version of the build script
07. Modify the build script similary to the openssl one:
    - `CURL_VERSION` reflects the version you downloaded, in this case "7.64.1"
    - `SDK_VERSION` reflects the iOS SDK you're using (you can check what you have installed using `xcodebuild -showsdks`)
    - `MIN_VERSION` is "9.0"
08. From the directory of the build script (this will take a while): `bash ./build.sh` (or whatever you named the copied script)

Be sure to note the following:

* You will need to verify and edit the "build.sh" scripts for both OpenSSL and cURL to reflect the correct version numbers and local directory names (lines 11–24).
* You must add `--enable-ipv6` to line 80 of Adobe's "build.sh" script used for building cURL. This necessary both due to Apple's requirements for IPv6 support and because the library may not build against recent iOS SDKs otherwise.
* cURL 7.57.0 is known _not_ to work and later versions are unlikely to work either. 7.50.0 is recommended.

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
