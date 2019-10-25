# Building Project for interview

**Note:** This configuration is not currently supported. In the interim, you _should_ be able to get it to build via the following steps:

01. `git clone https://github.com/NYPL-Simplified/Simplified-iOS.git` or `git clone git@github.com:NYPL-Simplified/Simplified-iOS.git`
02. `cd Simplified-iOS`
03. `git submodule deinit adept-ios && git rm -rf adept-ios` (if you encounter error: could not lock config file, this is ok, continue to step 4)  
04. `git submodule deinit adobe-content-filter && git rm -rf adobe-content-filter` (if you encounter error: could not lock config file, this is ok, continue to step 5)  
05. `git submodule update --init --recursive`
06. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already.
07. Remove "NYPL-Simplified-iOS/" in `Cartfile`
08. Remove "NYPL-Simplified-iOS/NYPLAEToolkit" and "AudioEngine.json" `Cartfile.resolved`.
09. `carthage bootstrap --platform ios --use-ssh`
10. `cp APIKeys.swift.example Simplified/APIKeys.swift` and edit accordingly.
11. `cp Accounts.json.example Simplified/Accounts.json`.
12. `(cd readium-sdk; sh MakeHeaders.sh Apple)` (parentheses included) to generate the headers for Readium.
13. `open Simplified.xcodeproj`
14. Remove import of "Simplified+RMSDK.xcconfig" from "Simplified.xcconfig".
15. Delete `NYPLAEToolkit.framework` and `AudioEngine.framework` from "Link Binary with Libraries", and remove input and output filepaths for `AudioEngine.framework` and `NYPLAEToolkit.framework` from `Copy Frameworks (Carthage)`.
16. Note: For now, we recommend keeping any unstaged changes as a single git stash until better dynamic build support is added.
17. Build.

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
