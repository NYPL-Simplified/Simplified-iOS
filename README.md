# Building With Adobe DRM

## Building the Application

01. `git clone https://github.com/NYPL/Simplified-iOS.git` or `git clone git@github.com:NYPL-Simplified/Simplified-iOS.git`
02. `cd Simplified-iOS`
03. `git submodule update --init --recursive`
04. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already.
05. `carthage bootstrap --platform ios --use-ssh`
06. Symlink the "DRM_Connector_Prerelease" directory to "adobe-rmsdk" within the "Simplified-iOS" directory. (You will need to have obtained the Adobe DRM Connector prerelease from Adobe.)
07. Build OpenSSL and cURL as described in the following "Building OpenSSL and cURL" section. Ensure you're in the "Simplified-iOS" directory before continuing to the next step.
08. `sh adobe-rmsdk-build.sh`
09. `cp APIKeys.swift.example Simplified/APIKeys.swift` and edit accordingly.
10. Copy `ReaderClientCert.sig` (obtained elsewhere) to `Simplified/ReaderClientCert.sig`.
11. Copy `Accounts.json` (obtained elsewhere) to `Simplified/Accounts.json`.
12. `open Simplified.xcodeproj`
13. Build.

## Building OpenSSL and cURL

Follow the instructions in "adobe-rmsdk/RMSDK_User_Manual(obj).pdf" to build OpenSSL (section 12.1) and cURL (section 12.3). Be sure to note the following:

* You will need to verify and edit the "build.sh" scripts for both OpenSSL and cURL to reflect the correct version numbers and local directory names (lines 11–24).
* You must add `--enable-ipv6` to line 80 of Adobe's "build.sh" script used for building cURL. This necessary both due to Apple's requirements for IPv6 support and because the library may not build against recent iOS SDKs otherwise.
* cURL 7.57.0 is known _not_ to work and later versions are unlikely to work either. 7.50.0 is recommended.

# Building Without DRM

**Note:** This configuration is not currently supported. In the interim, you _should_ be able to get it to build via the following steps:

01. `git clone https://github.com/NYPL/Simplified-iOS.git` or `git clone git@github.com:NYPL-Simplified/Simplified-iOS.git`
02. `cd Simplified-iOS`
03. `git submodule deinit adept-ios && git rm -rf adept-ios`
04. `git submodule deinit adobe-content-filter && git rm -rf adobe-content-filter`
05. `git submodule update --init --recursive`
06. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already.
07. `carthage bootstrap --platform ios --use-ssh`
08. `cp APIKeys.swift.example Simplified/APIKeys.swift` and edit accordingly.
09. `open Simplified.xcodeproj`
10. Remove "Simplified+RMSDK.xcconfig" from the project.
11. Delete "libADEPT.a" and "libAdobe Content Filter.a" from "Link Binary with Libraries" for the "SimplyE" target.
12. Copy `Accounts.json` (obtained elsewhere) to `Simplified/Accounts.json`.
13. Build.

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

All of the above contain appropriate documentation in the header files.

The rest of the program follows Apple's usual pattern of passive views,
relatively passive models, and one-off controllers for integrating everything.
Immutability is preferred wherever possible.

Questions and suggestions should be submitted as GitHub issues and tagged with
the appropriate labels. More in-depth discussion occurs via Slack: Email
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
