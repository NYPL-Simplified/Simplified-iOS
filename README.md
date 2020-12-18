[![Unit Tests](https://github.com/NYPL-Simplified/Simplified-iOS/workflows/Unit%20Tests/badge.svg?branch=develop)](https://github.com/NYPL-Simplified/Simplified-iOS/actions?query=workflow%3A%22Unit+Tests%22)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# SimplyE and Open eBooks

This repo contains the client-side code for the New York Public Library's [SimplyE](https://www.nypl.org/books-music-movies/ebookcentral/simplye) and [Open eBooks](https://openebooks.net) apps.

The 2 apps share most of the code base. App-specific source files will have a `SE` / `OE` prefix or suffix, while configuration files reside under the `SimplyE` and `OpenEbooks` directories at the root of the repo. 

Consequently, [releases](https://github.com/NYPL-Simplified/Simplified-iOS/releases) in this repo track both apps. However, you won't see any Open eBooks versions before 1.9.0 because historically Open eBooks lived in a separate repo. Releases that lack an app specifier, i.e. any version before v3.6.2, are SimplyE releases.

# System Requirements

- Install Xcode 11.5 in `/Applications`, open it and make sure to install additional components if it asks you. (We have not upgraded to Xcode 12 yet because of issues related to Carthage.)
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

## Building the Application from Scratch

01. Contact project lead and ensure you have access to all the required private repos.
02. Then simply run:
```bash
git clone git@github.com:NYPL-Simplified/Simplified-iOS.git
cd Simplified-iOS
./scripts/bootstrap-drm.sh
```
03. Open Simplified.xcodeproj and build the `SimplyE` or `Open eBooks` targets.

## Building Dependencies Individually

After bootstrapping, it's unlikely you'll need to do that again, because the DRM dependencies very rarely change. 

More common is the case of needing to update/rebuild the 3rd party dependencies managed by Carthage. To that end (and more), the `scripts` directory contains a number of scripts to rebuild them and perform other build/setup tasks from the command line, such as archiving and exporting. All these scripts must be run from the root of the Simplified-iOS repo, not from the `scripts` directory.

For instance, to build all 3rd party dependencies minus DRM:
```bash
./scripts/build-3rd-party-dependencies.sh
```
Both scripts must be run from the Simplified-iOS repo root.

## Building for Readium 2 Integration

Before working on R2 integration, make sure you can build the app without R2. Follow the steps listed above for building the app with DRM.

For working on integrating R2 into SimplyE, first clone the following frameworks as siblings of `Simplified-iOS` on the file system:
```bash
cd Simplified-iOS/..
git clone https://github.com/NYPL-Simplified/r2-shared-swift
git clone https://github.com/NYPL-Simplified/r2-streamer-swift
git clone https://github.com/NYPL-Simplified/r2-navigator-swift
git clone https://github.com/NYPL-Simplified/r2-lcp-swift
```
The first 2 repos are patched versions of `R2Shared` and `R2Streamer` to enable Adobe DRM and LCP DRM support in Readium 2.

Then use the `feature/readium2` branch and rebuild the dependencies. This will take longer than on `develop`, because there are more Carthage dependencies to build and keep in sync:
```bash
cd Simplified-iOS
git checkout feature/readium2
./scripts/build-3rd-party-dependencies.sh
```
Finally, open `SimplifiedR2.workspace` and use the `SimplyE-R2dev` target to build the app.

# Building Secondary Targets

The Xcode project contains 2 additional targets beside the main one referenced earlier and the unit tests:

- **SimplyECardCreator**: This is a convenience target to use when making changes to the [CardCreator-iOS](https://github.com/NYPL-Simplified/CardCreator-iOS) framework. It takes the framework out of the normal Carthage build to instead build it directly via Xcode. Use this in conjunction with the `SimplifiedCardCreator` workspace. It requires DRM.
- **Open eBooks**: This is an app primarily targeted toward the education space. It requires DRM.

# Contributing

This codebase follows Google's [Swift](https://google.github.io/swift/) and [Objective-C](https://google.github.io/styleguide/objcguide.xml) style guides, including the use of two-space indentation. More details are available in [our wiki](https://github.com/NYPL-Simplified/Simplified/wiki/Mobile-client-applications#code-style-1).

The primary services/singletons within the program are as follows:

* `AccountsManager`
* `NYPLUserAccount`
* `NYPLBookRegistry`
* `NYPLMyBooksDownloadCenter`
* `NYPLSettings`
* `NYPLKeychain`

Most of the above contain appropriate documentation in the header files.

The rest of the program follows Apple's usual pattern of passive views,
relatively passive models, and one-off controllers for integrating everything.
Immutability is preferred wherever possible.

Questions, suggestions, and general discussion occurs via Slack: Email
`swans062@umn.edu` for access.

# License

Copyright © 2015-2020 The New York Public Library, Astor, Lenox, and Tilden Foundations

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
