#!/bin/sh

# SUMMARY
#   This script facilitates uploading dSYMs to Firebase for SimplyE and
#   Open eBooks.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo. Note that both
#   parameters are mandatory and must appear in this order:
#
#     ./scripts/firebase-upload-symbols.sh <app-name> <dSYMs-dir-path>
#
# PARAMETERS
#   <app-name> : simplye | openebooks
#   <dSYMs-dir-path> : absolute path to the directory containing the dSYMs
#       for the build you need to update. Given an archive, typically this is
#       ~/Library/Developer/Xcode/Archives/<date>/<archive-name>.xcarchive/dSYMs

set -eo pipefail

echo "Uploading dSYMs for $1..."

# lower case of app name param
APPNAME=`echo "$1" | tr '[:upper:]' '[:lower:]'`

case $APPNAME in
  simplye | se)
    GOOGLE_PLIST_PATH="./SimplyE/GoogleService-Info.plist"
    ;;
  openebooks | oe | open_ebooks)
    GOOGLE_PLIST_PATH="./OpenEbooks/GoogleService-Info.plist"
    ;;
  *)
    echo "firebase-upload-symbols.sh: please specify a valid app. Possible values: simplye | openebooks"
    exit 1
    ;;
esac

echo "Using Google plist: $GOOGLE_PLIST_PATH"

./scripts/firebase/upload-symbols -gsp "$GOOGLE_PLIST_PATH" -p ios "$2"

echo "firebase-upload-symbols.sh: Completed with return code $?"
