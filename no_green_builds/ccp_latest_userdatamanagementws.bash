#!/bin/bash

# For User Data Management Web Service CCP-LATEST-SNAPSHOT build.
bamboo_version="XBOCI-BUILDUSERDATAMANAGEMENTWEBSERVICE-JOB1"

# Turn on error checking
set -e

# Make sure path is sourced, so that we know where maven is
source /home/xdeploy/.bash_profile

# Steps:
# 1) Bamboo plan waits for a successful build of trunk-manual version
# 2) This script gets invoked
# 3) Delete everything in this instance
rm -rf $bamboo_version
mkdir $bamboo_version
# 4) Copy over everyting from  trunk-manual version (bamboo 3.0 path)
echo "Copying over trunk version from bamboo.xbo.chalybs.net"
rsync -r --exclude=.svn /opt/xcal/services/Bamboo/xml-data/build-dir/$bamboo_version .
# 5) Change the pom file names to CCP-LATEST-SNAPSHOT
cd $bamboo_version
../completely_replace_pom_file_version.rb CCP-LATEST-SNAPSHOT
# 7) Build and deploy
export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=1024m -Dmaven.test.compile.encoding=UTF-8 -Dmaven.test.failure.ignore=false"
/opt/xcal/tools/maven/bin/mvn -DskipTests clean install deploy
