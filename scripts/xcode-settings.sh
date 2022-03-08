#!/bin/bash

# SUMMARY
#   Configures common environment variables for building Simplified apps.
#
# USAGE
#   Source this script from other scripts (e.g. xcode-archive.sh)
#
#   in xcode-archive.sh:
#     source "path/to/xcode-settings.sh"
#     ...
#
#   invocation:
#     xcode-archive.sh <app_name>
#
#   The assumption here is that the app name (visible to the end-user)
#   coincides with the Xcode target and scheme names.
#
# PARAMETERS
#     <app_name> : Which app to build. Mandatory. Possible values:
#         [ simplye | SE | openebooks | OE ]

set -eo pipefail

fatal()
{
  echo "$0 error: $1" 1>&2
  exit 1
}

# determine which app we're going to work on
APPNAME_PARAM=`echo "$1" | tr '[:upper:]' '[:lower:]'`
case "$APPNAME_PARAM" in
  se | simplye)
    APP_NAME=SimplyE
    APP_NAME_FOLDER=SimplyE
    NEWRELIC_APP_TOKEN="AAd9210b74e40d09df10054d9466c4fccbcc37ac9d-NRMA"
    ;;
  oe | openebooks | open_ebooks)
    APP_NAME="Open eBooks"
    APP_NAME_FOLDER=OpenEbooks
    NEWRELIC_APP_TOKEN=""
    ;;
  *)
    echo "xcode-settings: please specify a valid app. Possible values: simplye | openebooks"
    exit 1
    ;;
esac
TARGET_NAME=$APP_NAME
SCHEME=$APP_NAME
GOOGLE_PLIST_PATH="./$APP_NAME/GoogleService-Info.plist"

# app-agnostic settings
PROV_PROFILES_DIR_PATH="$HOME/Library/MobileDevice/Provisioning Profiles"
PROJECT_NAME=Simplified.xcodeproj
BUILD_PATH="./Build"
BUILD_SETTINGS="`xcodebuild -project $PROJECT_NAME -showBuildSettings -target \"$TARGET_NAME\"`"
VERSION_NUM=`echo "$BUILD_SETTINGS" | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //'`
BUILD_NUM=`echo "$BUILD_SETTINGS" | grep "CURRENT_PROJECT_VERSION" | sed 's/[ ]*CURRENT_PROJECT_VERSION = //'`
SPM_ROOT=`echo "$BUILD_SETTINGS" | grep "OBJROOT" | sed 's/[ ]*OBJROOT = //'`/../../SourcePackages/
ARCHIVE_NAME="$APP_NAME-$VERSION_NUM.$BUILD_NUM"
ARCHIVE_FILENAME="$ARCHIVE_NAME.xcarchive"
ARCHIVE_DIR="$BUILD_PATH/$ARCHIVE_NAME"
ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_FILENAME"
ADHOC_EXPORT_PATH="$ARCHIVE_DIR/exports-adhoc"
APPSTORE_EXPORT_PATH="$ARCHIVE_DIR/exports-appstore"
PAYLOAD_DIR_NAME="$ARCHIVE_NAME-payload"
PAYLOAD_PATH="$ARCHIVE_DIR/$PAYLOAD_DIR_NAME"
DSYMS_PATH="$PAYLOAD_PATH"
UPLOAD_FILENAME="${ARCHIVE_NAME}.zip"
