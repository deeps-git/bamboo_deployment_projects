#!/bin/bash
WORKDIR=`pwd`
export bamboo_deploy_servicename
export bamboo_deploy_pname

# get java version from the pom
     TARGET_VERSION=`grep "/target" ../../sourcedir/pom.xml | head -1 | sed -e 's,<, ,g' -e 's,>, ,g' -e 's,{, ,g' -e 's,}, ,g' | awk '{print $2}'`

     if [ "${TARGET_VERSION}" == "\$" ] ; then
          TARGET_VAR=`grep "/target" pom.xml | head -1 | sed -e 's,{, ,g' -e 's,}, ,g'  | awk '{print $2}'`
          TARGET_VERSION=`grep "/${TARGET_VAR}" pom.xml | head -1 | sed -e 's,<, ,g' -e 's,>, ,g' | awk '{print $2}' `
     fi

     if  [ "${TARGET_VERSION}" == "1.6" ]; then
           export JAVA_HOME="/usr/java/jdk1.6.0_45"
     elif [ "${TARGET_VERSION}" == "1.7" ]; then
          export JAVA_HOME="/usr/java/jdk1.7.0_45"
     elif [ "${TARGET_VERSION}" == "1.8" ]; then
          export JAVA_HOME="/usr/java/jdk1.8.0_05"
     fi
     echo "TARGET_VERSION is set to ${TARGET_VERSION} and JAVA_HOME is set to ${JAVA_HOME}"


# build latest snapshot
cd ../../sourcedir
if [ "${1}" != "skipmaven" ] ; then 
   echo "running maven commands"
   ${WORKDIR}/completely_replace_pom_file_version.rb CCP-LATEST-SNAPSHOT
   export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=1024m -Dmaven.test.compile.encoding=UTF-8 -Dmaven.test.failure.ignore=false"
   /opt/xcal/tools/maven/bin/mvn -U -DskipTests clean install deploy
else
   echo "skipping the maven commands in the script because the skipmaven arg has been set"
fi

# deploy the latest snapshot
if [ -d "/home/xdeploy/git/xbo-ds-cap-scripts" ];
    then
       cd /home/xdeploy/git/xbo-ds-cap-scripts
       git fetch --all
       git reset --hard origin/dev
       git checkout dev
       cap deploy app=${bamboo_deploy_servicename} env=green3 version=CCP-LATEST pname=${bamboo_deploy_pname} snapshotOrRelease=snapshot options=parallel,skip-prime
    else
        mkdir -p /home/xdeploy/git
        cd /home/xdeploy/git
        git clone git@github.comcast.com:xbo/xbo-ds-cap-scripts.git
        cd xbo-ds-cap-scripts
        git checkout dev
        cap deploy app=${bamboo_deploy_servicename} env=green3 version=CCP-LATEST pname=${bamboo_deploy_pname} snapshotOrRelease=snapshot options=parallel,skip-prime

fi
