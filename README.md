# Building With Adobe DRM

## Building the Application

01. `git clone https://github.com/NYPL-Simplified/Simplified-iOS.git` or `git clone git@github.com:NYPL-Simplified/Simplified-iOS.git`
02. `cd Simplified-iOS`
03. Ensure you have xcode CLI tools installed; `xcode-select --install`
04. `git submodule update --init --recursive` (please check you have repo access to the submodules, notably the private repos)
05. Populate the following files accordingly (external to repo for security reasons; please contact team lead for locating these files):
    - `AudioEngine.json` (as a requirement to build NYPLAEToolkit)
    - `bugsnag-dsym-upload.rb` (a post-build script to upload symbols to bugsnag)
    - `Simplified/ReaderClientCert.sig` (RMSDK certificate)
    - `Simplified/APIKeys.swift` (file that holds various API keys; sample exists in repo at `APIKeys.swift.example`)
06. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already.
07. `carthage bootstrap --platform ios --use-ssh`. Note: If `carthage bootstrap` fails, you may need to create an installer package from our fork: https://github.com/NYPL-Simplified/Carthage. Specifically, there is a branch `dwarfdump-fix` which resolves https://github.com/Carthage/Carthage/issues/2514
08. Symlink an unzipped copy of Adobe RMSDK to "adobe-rmsdk" within the "Simplified-iOS" directory. (You will need to have obtained this archive from Adobe; please contact team lead for this archive)
07. Build OpenSSL and cURL as described in the following "Building OpenSSL and cURL" section. Ensure you're in the "Simplified-iOS" directory before continuing to the next step.
08. `sh adobe-rmsdk-build.sh`
09. `(cd readium-sdk; sh MakeHeaders.sh Apple)` (parentheses included) to generate the headers for Readium.
12. `open Simplified.xcodeproj`
13. Build

## Building OpenSSL and cURL

In theory, following the instructions in "adobe-rmsdk/RMSDK_User_Manual(obj).pdf", you should be able to build OpenSSL (section 12.1) and cURL (section 12.3) since Adobe provides this package to their developers.
The following are some smoother steps to achieving this:
- From `adobe-rmsdk/thirdparty/openssl` run `mkdir public; mv iOS-openssl/ public/ios/`
- Download openssl 1.0.1 (1.0.1u should suffice) to `adobe-rmsdk/thirdparty/openssl/public/ios/openssl-1.0.1u.tar.gz` (note that the build script is expecting a tarball; as of this writing the download can be found at: https://www.openssl.org/source/old/1.0.1/)
- Modify the `adobe-rmsdk/thirdparty/openssl/public/ios/build.sh` such that:
    - `OPENSSL_VERSION` reflects the version you downloaded, in this case "1.0.1u"
    - `SDK_VERSION` reflects the iOS SDK you're using (you can check what you have installed using `xcodebuild -showsdks`)
    - `MIN_VERSION` is "9.0"
- From the directory of the build script (this will take a while): `bash ./build.sh`
- Download curl (7.64.1 is known to work) to `adobe-rmsdk/thirdparty/curl/ios-libCurl/curl-7.64.1.zip` (note that the build script expects a ZIP, not tarball; as of this writing this download can be found at: https://curl.haxx.se/download/)
- Replace `adobe-rmsdk/thirdparty/curl/ios/build.sh` with `build_curl.sh`, a fixed version of the build script
- Modify the build script similary to the openssl one:
    - `CURL_VERSION` reflects the version you downloaded, in this case "7.64.1"
    - `SDK_VERSION` reflects the iOS SDK you're using (you can check what you have installed using `xcodebuild -showsdks`)
    - `MIN_VERSION` is "9.0"
- From the directory of the build script (this will take a while): `bash ./build.sh` (or whatever you named the copied script)

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
