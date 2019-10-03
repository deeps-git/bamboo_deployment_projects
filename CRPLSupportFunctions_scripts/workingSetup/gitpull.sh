#!/bin/bash
echo "my new dir is ${BUILD_BASE_PATH}/${BUILD_DIR}/"
sudo mkdir -p ${BUILD_BASE_PATH}/${BUILD_DIR}/
//sudo chown -R jenkins ${BUILD_BASE_PATH}/${BUILD_DIR}
cd ${BUILD_BASE_PATH}/${BUILD_DIR}/
echo "$(pwd)"
shopt -s dotglob
sudo rm -r *

echo "====================================================="
echo "Cloning ${BUILD_SCRIPTS_REPO} at $(pwd)"
git clone git@github.comcast.com:CRPL/${BUILD_SCRIPTS_REPO}.git ${BUILD_SCRIPTS_REPO}
pushd ${BUILD_SCRIPTS_REPO}
git pull origin dev
git show-ref | head -3
popd

echo "====================================================="
echo "Cloning ${REPO_TO_BUILD} at $(pwd)"
git clone git@github.comcast.com:CRPL/${REPO_TO_BUILD}.git ${REPO_TO_BUILD}
pushd ${REPO_TO_BUILD}
git pull origin dev
git show-ref | head -3
popd



#git remote rm origin
#git remote add origin git@github.comcast.com:CRPL/${bamboo_gitrepo_name}.git
#git remote -v
#git checkout dev
#git pull origin dev
