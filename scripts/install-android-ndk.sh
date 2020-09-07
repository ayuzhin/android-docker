#!/bin/bash
# Download and unpack the Android NDK
# Companion script for the Docker image a12e/docker-qt
# Aurélien Brooke - License: MIT

if [ -z "$NDK_VERSION" ]; then
    echo "Please define the NDK_VERSION environment variable as desired, e.g. r21d"
    exit 1
fi

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "Please define the ANDROID_NDK_ROOT environment variable as desired"
    exit 1
fi

set -e #quit on error

mkdir /tmp/android
cd /tmp/android
curl -Lo ndk.zip "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip"
unzip -q ndk.zip
mv android-ndk-* $ANDROID_NDK_ROOT
chmod -R +rX $ANDROID_NDK_ROOT
rm -rf /tmp/android 
