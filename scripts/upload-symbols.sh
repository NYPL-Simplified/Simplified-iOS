#!/bin/bash

# SUMMARY
#   This script facilitates uploading dSYMs to Firebase and/or New Relic for
#   SimplyE and Open eBooks.
#
# USAGE
#   Run this script from the root of Simplified-iOS repo. Note that both
#   parameters are mandatory and must appear in this order:
#
#     ./scripts/upload-symbols.sh <app-name>
#
# PARAMETERS
#   <app-name> : simplye | openebooks

source "$(dirname $0)/xcode-settings.sh"

#echo "Uploading $APP_NAME dSYMs to Firebase..."
#echo "Using Google plist: $GOOGLE_PLIST_PATH"
#./scripts/firebase/upload-symbols -gsp "$GOOGLE_PLIST_PATH" -p ios "$DSYMS_PATH"
#FIREBASE_UPLOAD_RESULT_UNIX=$?

echo "Uploading $APP_NAME dSYMs to New Relic..."
echo "SPM_ROOT=$SPM_ROOT"
NEWRELIC_UPLOAD_RESULT=`$SPM_ROOT/artifacts/NewRelic/NewRelic.xcframework/Resources/generateMap.py "$DSYMS_PATH" $NEWRELIC_APP_TOKEN`
NEWRELIC_UPLOAD_RESULT_UNIX=$?

echo "New Relic upload result code: $NEWRELIC_UPLOAD_RESULT"
if [[ -f "upload_dsym_results" ]]; then
  echo "======== upload_dsym_results ========"
  cat upload_dsym_results
  echo "====================================="
fi

echo "upload-symbols.sh: Completed with unix return code $NEWRELIC_UPLOAD_RESULT_UNIX"

