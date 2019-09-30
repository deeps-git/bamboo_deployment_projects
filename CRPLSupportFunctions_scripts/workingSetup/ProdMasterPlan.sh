#!/bin/bash

echo "Setting up variables for the run"
echo "Specify BUILD_BASE_PATH"; read BUILD_BASE_PATH; export BUILD_BASE_PATH=${BUILD_BASE_PATH};
echo "Specify BUILD_DIR"; read BUILD_DIR; export BUILD_DIR=${BUILD_DIR};
echo "Specify REPO_TO_BUILD"; read REPO_TO_BUILD; export REPO_TO_BUILD=${REPO_TO_BUILD};
echo "Specify BUILD_SCRIPTS_REPO"; read BUILD_SCRIPTS_REPO; export BUILD_SCRIPTS_REPO=${BUILD_SCRIPTS_REPO};
echo "Build Maven Path is com/comcast/xcal/crpl/awslambda/support"; export BUILD_MAVEN_PATH="com/comcast/xcal/crpl/awslambda/support";


echo "Git Repo URL is git@github.comcast.com:CRPL/${REPO_TO_BUILD}.git" ; export REPO_URL="git@github.comcast.com:CRPL/${REPO_TO_BUILD}.git"
./gitpull.sh
echo "Checking build type"

pushd ${BUILD_BASE_PATH}/${BUILD_DIR}/${REPO_TO_BUILD}
git fetch --tags ${REPO_URL}
git tag
echo "Specify the tag to deploy"; read releaseVersion;
if [[ -z "${releaseVersion}" ]]; then
        echo "Something went wrong with the releaseVersion";
else
        echo "Starting up PreProd deploy, releaseVersion="${releaseVersion}
        ENVIRONMENT="Prod"
fi
export RELEASE_VERSION=${releaseVersion}
export ENVIRONMENT="-"${ENVIRONMENT};
popd

echo "Following are the projects:"
echo ""
./pnameprocess.sh
echo "Pushing that to AWS Lambda now!"

./prodDeploy.sh

echo ""
echo ""
