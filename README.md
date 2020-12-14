# System Requirements

- Install Xcode 11.5 in `/Applications`, open it and make sure to install additional components if it asks you.
- Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already. Using `brew` is recommended.

# Building without Adobe DRM nor Private Repos

```bash
git clone git@github.com:NYPL-Simplified/Simplified-iOS.git
cd Simplified-iOS
git checkout develop

# one-time set-up
./scripts/setup-repo-nodrm.sh

# idempotent script to rebuild all dependencies
./scripts/build-3rd-party-dependencies.sh --no-private
```

Open `Simplified.xcodeproj` and build the `SimplyE-noDRM` target.


# Building With Adobe DRM

## Building the Application

01. Contact project lead and ensure you have access to all required submodules and other repos, including private ones.
02. Then simply run:
```bash
git clone git@github.com:NYPL-Simplified/Simplified-iOS.git
cd Simplified-iOS
./scripts/bootstrap-drm.sh
```
03. Open Simplified.xcodeproj and build the `SimplyE` or `Open eBooks` target.


## Building Dependencies Individually

The `scripts` directory contains a number of scripts to build dependencies and perform other build/setup tasks, such as archiving and exporting. All these scripts must be run from the root of the Simplified-iOS repo, not from the `scripts` directory.

To build all Carthage dependencies from scratch you can use the `build-carthage.sh` script. Note that this will wipe the Carthage folder if you already have it:
```bash
./scripts/build-carthage.sh
```
To run a `carthage update`, use the `update-carthage.sh` script. As the previous script, this also rebuilds the Carthage dependencies from scratch:
```bash
./scripts/update-carthage.sh
```
To build DRM-related dependencies, you can use the `adobe-rmsdk-build.sh` or `/build-openssl-curl.sh` scripts.

# Building Secondary Targets

The Xcode project contains 3 additional targets beside the main one referenced earlier:

- **SimplyECardCreator**: This is a convenience target to use when making changes to the [CardCreator-iOS](https://github.com/NYPL-Simplified/CardCreator-iOS) framework. It takes the framework out of the normal Carthage build to instead build it directly via Xcode. Use this in conjunction with the `SimplifiedCardCreator` workspace. It requires DRM.
- **Open eBooks**: This is an app primarily targeted toward the education space. It requires DRM.

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
