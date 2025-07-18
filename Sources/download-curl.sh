#!/usr/bin/env sh

version=$1
exptected_checksum=$2

curl --location --remote-name --progress-bar "https://github.com/greatfire/curl-apple/releases/download/$version/curl.xcframework.zip"

actual=$(shasum -a 256 curl.xcframework.zip | awk '{print $1}')

if [ $actual != $exptected_checksum ]; then
    echo "ERROR: Checksum verification failed."

    exit 1
fi

rm -rf curl.xcframework
unzip curl.xcframework.zip
rm curl.xcframework.zip
