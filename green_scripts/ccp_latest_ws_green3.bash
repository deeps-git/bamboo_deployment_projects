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
SOURCEDIR=`pwd`
if [ "${1}" != "skipmaven" ] ; then 
   echo "running maven commands"
   ${WORKDIR}/completely_replace_pom_file_version.rb CCP-LATEST-SNAPSHOT
   export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=1024m -Dmaven.test.compile.encoding=UTF-8 -Dmaven.test.failure.ignore=false"
   /opt/xcal/tools/maven/bin/mvn -U -DskipTests clean install deploy
else
   echo "skipping the maven commands in the script because the skipmaven arg has been set"
fi


# keep svn up to date for consec
#if [ -d /home/xdeploy/svn/trunk ]; then
#   echo "updating svn"
#   cd  /home/xdeploy/svn/trunk
#   svn up
#else
#   echo "checking out svn"
#   mkdir -p /home/xdeploy/svn
#   cd /home/xdeploy/svn
#   svn co https://svn.teamccp.com:8092/svn/excalibur/services/metadata/build/xcap/trunk
#fi

# deploy the latest snapshot
if [ -d "/home/xdeploy/git/xbo-ws-cap-scripts" ];
    then
       cd /home/xdeploy/git/xbo-ws-cap-scripts
       git fetch --all
       git reset --hard origin/dev
       git checkout dev
    else
        mkdir -p /home/xdeploy/git
        cd /home/xdeploy/git
        git clone git@github.comcast.com:xbo/xbo-ws-cap-scripts.git
        cd xbo-ws-cap-scripts
        git checkout dev

fi
     cd /home/xdeploy/utils/xbogreen3
    ./little_button.show_serial_bamboo_git ${bamboo_deploy_servicename} trunk
    ./deploy_serial_${bamboo_deploy_servicename} xbogreen3
    if [ "$?" != 0 ] ; then exit 1 ; fi
    /bin/rm deploy_serial_${bamboo_deploy_servicename}
    
# now run int tests
if [ "${bamboo_deploy_servicename}" != "businessObjectWebService" ] && [ "${bamboo_deploy_servicename}" != "sessionBOWS" ] && [ "${bamboo_deploy_servicename}" != "deviceBOWS" ] && [ "${bamboo_deploy_servicename}" != "accountBOWS" ]; then
   cd ${SOURCEDIR}/webapp
   pwd
   sed -i -e 's,'"${bamboo_deploy_servicename}"'.PROXY_HOST=.*$,'"${bamboo_deploy_servicename}"'.PROXY_HOST=proxy,g' -e 's,'"${bamboo_deploy_servicename}"'.PROXY_PORT=.*$,'"${bamboo_deploy_servicename}"'.PROXY_PORT=3128,g' config/DS_Configuration.properties
   /opt/xcal/tools/maven/bin/mvn -e -Pgbtest-remote -DpropFile="green_ci_test.properties" -DhostName="$HOSTNAME" verify
fi
