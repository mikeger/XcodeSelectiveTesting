#!/bin/bash -e

VERSION=$1
ARTIFACT_BUNDLE=xcode-selective-test.artifactbundle

usage() {
    echo "[Usage] $0 <VERSION>"
}

if [ "$VERSION" = "" ]; then
    usage
    echo "VERSION is required"
    exit 1
fi

echo "** Zip artifact bundle..."

rm -rf $ARTIFACT_BUNDLE
mkdir $ARTIFACT_BUNDLE

mkdir -p $ARTIFACT_BUNDLE/xcode-selective-test/bin
tar -xzf xcode-selective-test.tar.gz -C $ARTIFACT_BUNDLE/xcode-selective-test/bin

sed 's/__VERSION__/'"${VERSION}"'/g' spm-artifact-bundle-info.template > "${ARTIFACT_BUNDLE}/info.json"
cp LICENSE ACKNOWLEDGEMENTS $ARTIFACT_BUNDLE

zip -yr - $ARTIFACT_BUNDLE > "${ARTIFACT_BUNDLE}.zip"
rm -rf $ARTIFACT_BUNDLE

echo "** Done."