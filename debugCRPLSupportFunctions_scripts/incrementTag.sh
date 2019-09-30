#!/bin/bash

echo "Enter Repo Name"; read gitrepo_name
cd $gitrepo_name
git checkout dev; git pull origin dev
git fetch --all; git fetch --tags; git fetch
echo "Printing the pwd!"; pwd
VERSION=`git describe --tags $(git rev-list --tags --max-count=1)`

VERSION_BITS=(${VERSION//./ })

VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM3=$((VNUM3+1))

NEW_TAG="$VNUM1.$VNUM2.$VNUM3"

echo "Updating $VERSION to $NEW_TAG"

GIT_COMMIT=`git rev-parse HEAD`
NEEDS_TAG=`git describe --contains $GIT_COMMIT`

if [ -z "$NEEDS_TAG" ]; then
    echo "Tagged with $NEW_TAG"
    echo "Ignoring fatal:cannot describe - this means commit is untagged!"
    echo "Tagging now!"
    git tag $NEW_TAG dev
    git push --tags
    sed '/releaseVersion/d' ./gradle.properties > gradle.properties.new && mv gradle.properties.new gradle.properties
    echo “releaseVersion=$NEW_TAG” >> gradle.properties
    git push
else
    echo "Already a tag on this commit"
fi