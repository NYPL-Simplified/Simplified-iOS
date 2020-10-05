#!/bin/bash

# Usage: run this script from the root of Simplified-iOS repo.
# Note: this script assumes you have the Certificates repo cloned as a sibling of Simplified-iOS.

cp ../Certificates/SimplyE/iOS/AudioEngine.json .
cp ../Certificates/SimplyE/iOS/GoogleService-Info.plist .
cp ../Certificates/SimplyE/iOS/APIKeys.swift Simplified/
cp ../Certificates/SimplyE/iOS/ReaderClientCertProduction.sig Simplified/ReaderClientCert.sig

cp ../Certificates/OpenEbooks/iOS/ReaderClientCert.sig Simplified/OpenEbooks/Resources/ReaderClientCert.sig

git update-index --skip-worktree Simplified/NYPLSecrets.swift
swift ../Certificates/SimplyE/iOS/KeyObfuscator.swift

