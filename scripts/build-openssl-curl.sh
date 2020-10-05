#!/bin/bash

# Usage: run this script from the root of the Simplified-iOS repo.
#
# Summary: this script rebuilds OpenSSL 1.0.1u and cURL 7.64.1 which are
#              required by the Adobe RMSDK.
#
# In theory, following the instructions in "adobe-rmsdk/RMSDK_User_Manual(obj).pdf",
# you should be able to build OpenSSL (section 12.1) and cURL (section 12.3)
# since Adobe provides this package to their developers. The following are some
# smoother steps to achieve that.

# Note: if you want/need to use an Xcode installed at a location other than
# /Applications, you'll need to update the $DEVELOPER env variable mentioned
# at the top of both the build.sh / build_curl.sh scripts below.

cp scripts/build_curl.sh adobe-rmsdk/thirdparty/curl/iOS-libcurl/
SDKVERSION=`xcodebuild -version -sdk iphoneos | grep SDKVersion | sed 's/SDKVersion[: ]*//'`

# edit as required if OpenSSL and cURL need updating or retargeting
OPENSSL_VERSION="1.0.1u"
OPENSSL_URL="https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz"
CURL_VERSION="7.64.1"
CURL_URL="https://curl.haxx.se/download/curl-7.64.1.zip"

echo "======================================="
echo "Building OpenSSL..."
cd adobe-rmsdk/thirdparty/openssl
mkdir -p public
[ -d "iOS-openssl" ] && [ ! -d "public/ios" ] && mv iOS-openssl public/ios
cd public/ios
curl -O $OPENSSL_URL
sed -i '' "s/OPENSSL_VERSION=\".*\"/OPENSSL_VERSION=\"$OPENSSL_VERSION\"/" build.sh
sed -i '' "s/SDK_VERSION=\".*\"/SDK_VERSION=\"$SDKVERSION\"/" build.sh
sed -i '' 's/MIN_VERSION=".*"/MIN_VERSION="9.0"/' build.sh
bash ./build.sh  #this will take a while

echo "======================================="
echo "Building cURL..."
cd ../../../curl/iOS-libcurl
curl -O $CURL_URL
sed -i '' "s/CURL_VERSION=\".*\"/CURL_VERSION=\"$CURL_VERSION\"/" build_curl.sh
sed -i '' "s/SDK_VERSION=\".*\"/SDK_VERSION=\"$SDKVERSION\"/" build_curl.sh
sed -i '' 's/MIN_VERSION=".*"/MIN_VERSION="9.0"/' build_curl.sh
bash ./build_curl.sh  #this will take a while

echo "Finished building OpenSSL and cURL."
