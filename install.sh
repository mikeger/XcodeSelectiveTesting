#!/bin/bash -e

CUR=$PWD

# Build for macOS universal
echo "** Clean/Build..."
rm -rf .build
swift build -c release --arch arm64 --arch x86_64

echo "** Install..."
cd .build/apple/Products/Release
tar -cvzf xcode-selective-test.tar.gz xcode-selective-test
mv xcode-selective-test.tar.gz "$CUR"

cd "$CUR"
echo "** Output file is xcode-selective-test.tar.gz"
echo "** Done."