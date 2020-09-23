# System Requirements

- Install the latest Xcode (11.4 or higher) in `/Applications`, open it and make sure to install additional components if it asks you.
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
04. Open Simplified.xcodeproj and build the SimplyE target.

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
07. Remove "NYPL-Simplified/NYPLAEToolkit" from `Cartfile` and `Cartfile.resolved`.
08. `carthage bootstrap --platform ios --use-ssh`
09. `cp APIKeys.swift.example Simplified/APIKeys.swift` and edit accordingly.
10. `cp Accounts.json.example Simplified/Accounts.json`.
11. `cp GoogleService-Info.plist.example GoogleService-Info.plist` and edit with you firebase project config.
12. `cp ReaderClientCert.sig.example Simplified/ReaderClientCert.sig` **Note:** This is skeleton only, contact project admins to obtain a copy of a real file.
13. `(cd readium-sdk; sh MakeHeaders.sh Apple)` (parentheses included) to generate the headers for Readium.
14. `open Simplified.xcodeproj`
15. Comment out/remove line with include of "Simplified+RMSDK.xcconfig" in "Simplified.xcconfig".
16. Remove `FEATURE_DRM_CONNECTOR` entries in _Build Settings_ -> _Swift Compiler - Custom Flags_ -> _Active Compilation Conditions_ in project settings
17. Delete `NYPLAEToolkit.framework`, `AudioEngine.framework`, `libADEPT.a` and `libAdobe Content Filter.a` from _General_ -> _Frameworks, Libraries, and Embedded Content_ section in project settings.
18. Remove input and output filepaths for `AudioEngine.framework` and `NYPLAEToolkit.framework` from `Copy Frameworks (Carthage)` _Build Phase_ in project settings.
19. Note: For now, we recommend keeping any unstaged changes as a single git stash until better dynamic build support is added.
20. Build.

# Building for Readium 2 Integration

For working on integrating R2 into SimplyE, use the `feature/readium2` branch. First build the app following the steps above for building with/without DRM.

Then we recommend using the `SimplifiedR2.workspace`. This assumes you have checked out the following frameworks (clone them as siblings of `Simplified-iOS` on the file system):
```bash
cd Simplified-iOS/..
git clone https://github.com/NYPL-Simplified/r2-shared-swift
git clone https://github.com/NYPL-Simplified/r2-streamer-swift
git clone https://github.com/readium/r2-navigator-swift
```
The first 2 repos contain patched versions of `R2Shared` and `R2Streamer` to enable Adobe DRM in Readium 2.

Build their own Carthage dependencies first:
```bash
cd r2-shared-swift
carthage checkout --use-ssh
carthage build --platform ios
cd ../r2-streamer-swift
carthage checkout --use-ssh
carthage build --platform ios
cd ../r2-navigator-swift
carthage checkout --use-ssh
carthage build --platform ios
```
Then finally build Carthage for SimplyE (for a faster build, you can remove the related R2 lines from SimplyE's Cartfile since the `SimplyE-R2dev` target in `SimplifiedR2.workspace` refers to the manually cloned R2 repos):
```bash
./carthage-update-simplye.sh Debug
```
Finally, open the workspace and use the `SimplyE-R2dev` target to build the app.

# Building Secondary Targets

The Xcode project contains 3 additional targets beside the main one referenced earlier:

- **SimplyECardCreator**: This is a convenience target to use when making changes to the [CardCreator-iOS](https://github.com/NYPL-Simplified/CardCreator-iOS) framework. It takes the framework out of the normal Carthage build to instead build it directly via Xcode. Use this in conjunction with the `SimplifiedCardCreator` workspace.
- **Open eBooks**: This is related to a project currently under development. It is not functional at the moment.
- **SimplyETests**: Suite of unit tests.

# Contributing

This codebase follows Google's  [Swift](https://google.github.io/swift/) and [Objective-C](https://google.github.io/styleguide/objcguide.xml) style guides,
including the use of two-space indentation. More details are available in [our wiki](https://github.com/NYPL-Simplified/Simplified/wiki/Mobile-client-applications#code-style-1).

The primary services/singletons within the program are as follows:

* `AccountsManager`
* `NYPLUserAccount`
* `NYPLBookRegistry`
* `NYPLKeychain`
* `NYPLMyBooksDownloadCenter`
* `NYPLMigrationManager`
* `NYPLSettings`
* `NYPLSettingsNYPLProblemDocumentCacheManager`

Most of the above contain appropriate documentation in the header files.

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
