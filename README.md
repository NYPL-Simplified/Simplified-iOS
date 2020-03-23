# System Requirements

- Install the latest Xcode in `/Applications`, open it and make sure to install additional components if it asks you.
- Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already. Using `brew` is recommended.

# Building With Adobe DRM

## Building the Application

01. Contact project lead and ensure you have repo access to all required submodules, including private ones. Also request a copy of the Adobe RMSDK archive, which is currently not on Github, unzip it and place it in a place of your choice.
02. Then run:
```bash
git clone git@github.com:NYPL-Simplified/Simplified-iOS.git
git clone git@github.com:NYPL-Simplified/Certificates.git
cd Simplified-iOS
ln -s <rmsdk_path>/DRM_Connector_Prerelease adobe-rmsdk
git checkout develop
git submodule update --init --recursive
```
03. Build dependencies (carthage, OpenSSL, cURL). You can also use this script at any other time if you ever need to rebuild them: it should be idempotent. The non-optional parameter specifies which configuration of the AudioEngine framework to use. Note that the Release build of AudioEngine does not contain slices for Simulator architectures, causing a Carthage build failure.
```bash
./build-3rd-parties-dependencies.sh <Debug | Release>
```
04. Generate NYPLSecrets.swift from Simplified-iOS folder. Executing the script without argument will generate the .swift file in /Simplified-iOS/Simplified/.
```bash
swift ../Certificates/SimplyE/iOS/KeyObfuscator.swift
```
 You can also add an output path as the argument.
 ```bash
 swift ../Certificates/SimplyE/iOS/KeyObfuscator.swift /Simplified/Utilities/
 ```

05. Open Simplified.xcodeproj and Build!


## Building Dependencies Individually

To build all Carthage dependencies from scratch you can use the following script. Note that this will wipe the Carthage folder if you already have it:
```bash
./build-carthage.sh <Debug | Release>
```
To run a `carthage update`, use the following script to avoid AudioEngine errors. Note, this will rebuild all Carthage dependencies:
```bash
./carthage-update-simplye.sh <Debug | Release>
```
To build OpenSSL and cURL from scratch, you can use the following script:
```bash
./build-openssl-curl.sh
```
Both scripts must be run from the Simplified-iOS repo root.

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
