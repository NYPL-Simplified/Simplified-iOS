# Building Without DRM

1. `git clone https://github.com/NYPL/Simplified-iOS.git`
2. `cd Simplified-iOS`
3. `git submodule update --init --recursive`
4. [Install Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started) if you haven't already.
5. `pod install`
6. `open Simplified.xcworkspace` and build as normal.

# Building With Adobe DRM

1. Complete the steps in "Building without DRM".
1. Symlink the "DRM_Connector_Prerelease" directory to "Simplified-iOS/adobe-rmsdk".
2. In "RMSDK_User_Manual(obj).pdf", follow the instructions to build OpenSSL (section 12.1) and cURL (section 12.3).
3. `sh adobe-rmsdk-build.sh`
4. Add the configuration file "Simplified+RMSDK.xcconfig" to the target "Simplified".
5. Add "libADEPT.a" and other related libraries to the "Link Binary With Libraries" section of the target "Simplified".
6. Build.

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
`jamesenglish@nypl.org` for access.

# License

```
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
```
