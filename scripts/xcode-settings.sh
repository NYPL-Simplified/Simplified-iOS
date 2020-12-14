#!/bin/bash

# SUMMARY
# Configures common environment variables for building Simplified apps.
#
# USAGE
# Source this script from other scripts (e.g. xcode-archive.sh)
#
# in xcode-archive.sh:
#   source "path/to/xcode-settings.sh"
#   ...
#
# invocation:
#   xcode-archive.sh SimplyE
#
# The assumption here is that the app name (visible to the end-user) coincides
# with the Xcode target and scheme names.

set -eo pipefail

case $1 in
  --SE | SE | SimplyE | simplye | "")
    APP_NAME=SimplyE
    APP_NAME_FOLDER=SimplyE
    ;;
  --OE | OE | OpenEbooks | Open_eBooks | "Open eBooks" | openebooks | open_ebooks)
    APP_NAME="Open eBooks"
    APP_NAME_FOLDER=OpenEbooks
    ;;
  *)
    echo "xcode-settings: please specify a valid app. Possible values: simplye | openebooks"
    exit 1
    ;;
esac

# app settings
BUILD_PATH='./Build'
PROJECT_NAME=Simplified.xcodeproj
TARGET_NAME=$APP_NAME
SCHEME=$APP_NAME

# app agnostic build settings
BUILD_SETTINGS="`xcodebuild -project $PROJECT_NAME -showBuildSettings -target \"$TARGET_NAME\"`"
VERSION_NUM=`echo "$BUILD_SETTINGS" | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //'`
BUILD_NUM=`echo "$BUILD_SETTINGS" | grep "CURRENT_PROJECT_VERSION" | sed 's/[ ]*CURRENT_PROJECT_VERSION = //'`
BUILD_NAME="$APP_NAME-$VERSION_NUM.$BUILD_NUM"
BUILD_DATE=`date "+%Y%m%d"`
ARCHIVE_NAME="$BUILD_NAME-$BUILD_DATE"
ARCHIVE_PATH="$BUILD_PATH/$ARCHIVE_NAME"
ADHOC_EXPORT_PATH="$BUILD_PATH/exports-adhoc/$ARCHIVE_NAME"
