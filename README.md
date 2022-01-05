[![SimplyE and Open eBooks Build](https://github.com/NYPL-Simplified/Simplified-iOS/workflows/SimplyE%20and%20Open%20eBooks%20Build/badge.svg)](https://github.com/NYPL-Simplified/Simplified-iOS/actions?query=workflow%3A%22SimplyE%20and%20Open%20eBooks%20Build%22) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# SimplyE and Open eBooks

This repo contains the client-side code for the New York Public Library's [SimplyE](https://www.nypl.org/books-music-movies/ebookcentral/simplye) and [Open eBooks](https://openebooks.net) apps.

The 2 apps share most of the code base. App-specific source files will have a `SE` / `OE` prefix or suffix, while configuration files reside in the `SimplyE` and `OpenEbooks` directories at the root of the repo. 

Consequently, [releases](https://github.com/NYPL-Simplified/Simplified-iOS/releases) in this repo track both apps. However, you won't see any Open eBooks versions before 1.9.0 because historically Open eBooks lived in a separate repo. Releases that lack an app specifier, i.e. any version such as v3.6.1 and earlier, are SimplyE releases.

# System Requirements

- Install Xcode 13.1 in `/Applications`, open it and make sure to install additional components if it asks you.
- Install [Carthage](https://github.com/Carthage/Carthage) 0.38 or newer if you haven't already. Using `brew` is recommended.

# Building without DRM support

```bash
git clone git@github.com:NYPL-Simplified/Simplified-iOS.git
cd Simplified-iOS
git checkout develop

# one-time set-up
./scripts/setup-repo-nodrm.sh

# idempotent script to rebuild all dependencies
./scripts/build-dependencies.sh --no-private
```
Open `Simplified.xcodeproj` and build the `SimplyE-noDRM` target.

# Building with DRM Support

## Building from Scratch

01. Contact project lead and ensure you have access to all the required private repos.
02. Build the dependencies (typically you'll need to run this only once):
```bash
git clone git@github.com:NYPL-Simplified/Simplified-iOS.git
cd Simplified-iOS
./scripts/bootstrap-drm.sh
```
03. Open Simplified.xcodeproj and build the `SimplyE` or `Open eBooks` targets.

## Building Dependencies Individually

Unless the DRM dependencies change (which is very seldom) you shouldn't need to run the `bootstrap-drm.sh` script more than once.

Other dependencies are managed via Carthage and a few git submodules. To rebuild them you can use the following idempotent script:
```bash
cd Simplified-iOS #repo root
./scripts/build-dependencies.sh
```
The `scripts` directory contains a number of other scripts to build dependencies more granularly and also to build/archive/test the app from the command line. These scripts are the same used by our CI system. All these scripts must be run from the root of the Simplified-iOS repo, not from the `scripts` directory.

# Building for Readium 2 Integration

Before working on R2 integration, make sure you can build the app by following the steps listed above.

For working on integrating R2 into SimplyE, first clone the following repo as a sibling of `Simplified-iOS` on the file system:
```bash
cd Simplified-iOS/..
git clone https://github.com/readium/swift-toolkit
```
Then rebuild the dependencies:
```bash
cd Simplified-iOS
./scripts/build-carthage-R2-integration.sh
```
Finally, open `SimplifiedR2.workspace` and use the `SimplyE-R2dev` target to build the app.

# Building Open eBooks

Open eBooks is an app primarily targeted toward the education space. It requires DRM. Follow the same steps as indicated above and use the "Open eBooks" Xcode target.

# Contributing

This codebase follows Google's [Swift](https://google.github.io/swift/) and [Objective-C](https://google.github.io/styleguide/objcguide.xml) style guides, including the use of two-space indentation. More details are available in [our wiki](https://github.com/NYPL-Simplified/Simplified/wiki/Mobile-client-applications#code-style-1).

Most of the code follows Apple's usual pattern of passive views,
relatively passive models, and one-off controllers for integrating everything.
Immutability is preferred wherever possible.

Questions, suggestions, and general discussion occurs via Slack: Email
`swans062@umn.edu` for access.

## Branching and CI

`develop` is the main development branch.

Release branch names follow the convention: `release/simplye/<version>` or `release/openebooks/<version>`. For example, `release/simplye/3.7.0`.

Feature branch names (for features whose development is a month or more): `feature/<feature-name>`, e.g. `feature/my-new-screen`.

[Continuous integration](https://github.com/NYPL-Simplified/Simplified/wiki/iOS-CI-CD) is enabled on push events on `develop`, release and feature branches. SimplyE device builds are uploaded to Firebase and, for release builds, also to TestFlight.

# License

Copyright © 2015-2022 The New York Public Library, Astor, Lenox, and Tilden Foundations

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
