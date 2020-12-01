#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
#
#     ./scripts/update-certificates.sh
#
# Note: this script assumes you have the Certificates repo cloned as a sibling of Simplified-iOS.

cp ../Certificates/SimplyE/iOS/APIKeys.swift Simplified/AppInfrastructure/

# SimplyE-specific stuff
cp ../Certificates/SimplyE/iOS/GoogleService-Info.plist SimplyE/
cp ../Certificates/SimplyE/iOS/ReaderClientCertProduction.sig SimplyE/ReaderClientCert.sig

# OpenEbooks-specific stuff
cp ../Certificates/OpenEbooks/iOS/ReaderClientCert.sig OpenEbooks/
cp ../Certificates/OpenEbooks/iOS/GoogleService-Info.plist OpenEbooks/

git update-index --skip-worktree Simplified/NYPLSecrets.swift
swift ../Certificates/SimplyE/iOS/KeyObfuscator.swift
swift ../Certificates/SimplyE/iOS/LCPLib.swift
