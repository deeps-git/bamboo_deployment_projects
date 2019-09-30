#!/bin/bash
export AWS_PROFILE=svc-primary-xbo

string=`cat demoprojectname.txt`
IFS=', ' read -r -a array <<< "$string"
bamboo_build_key="not_set"; bamboo_script_key="AWS-LAM-SCRIP";
bamboo_gitrepo_name="XboAWSLambdaSupportFunctions"; bamboo_maven_path="com/comcast/xcal/xbo/awslambda/support";
bamboo_function_ext="-PreProd"; bamboo_repo_url="git@github.comcast.com:xbo/XboAWSLambdaSupportFunctions.git"
export PATH="/home/xdeploy/.pythonbrew/pythons/Python-2.7/bin:${PATH}"
export JAVA_HOME="/usr/java/jdk1.8.0_05"
source /home/xdeploy/awsenv/nexusenv.sh
WORKDIR=`pwd`
echo "Welcome to PRE-PROD Stage";

        if [ ! -d ${bamboo_gitrepo_name} ] ; then
           git clone $bamboo_repo_url
        fi
        cd  ${bamboo_gitrepo_name}
        git fetch --tags $bamboo_repo_url
        latest_tag=`git describe --tags $(git rev-list --tags --max-count=1)`
        echo "The latest tag is : $latest_tag"
        echo "Below are the tags that we currently have:"
        git tag; git tag > /tmp/taglist.txt
        echo "Please enter the tag name you want to use to deploy to PRE-PROD: "

        read tag_input
        echo "You have entered: $tag_input"
        echo ""
        echo ""

        if [ -n "${tag_input// }" ]; then
            if grep -qw "$tag_input" /tmp/taglist.txt
                then
        source /home/xdeploy/awsenv/nexusenv.sh
        version=$tag_input
        git checkout $tag_input

echo "The version is: $tag_input"


for element in "${array[@]}"
do

    source /home/xdeploy/awsenv/nexusenv.sh
    echo "Build key is - ${bamboo_build_key}"; echo "Git repo name is - ${bamboo_gitrepo_name}"
    echo " "
    echo "Working on $element project"
    echo " "
    if [ -f ${WORKDIR}/${bamboo_gitrepo_name}/${element}/gradle.properties ]; then
    echo "Gradle.properties file NOT EMPTY!"
    wget --no-proxy "http://maven.teamccp.com/content/groups/master/${bamboo_maven_path}/${element}/${version}/${element}-${version}.zip" -O /tmp/${element}-${version}.zip
    echo "Working on - $element"
    rm -rf /tmp/unzipf/*; unzip -o -qq /tmp/${element}-${version}.zip -d /tmp/unzipf
    echo "$element has been unzipped"

    echo "decrypting gpg files"

    for file in `find /tmp/unzipf/config  -type f | grep .gpg`
    do
            outputFile=${file%.gpg}
            echo "decrypting $file"
            gpg --homedir ~/xbo/.xbo_gnupg --decrypt $file > $outputFile
    done

    swapfunc () {
    if [ -f /tmp/unzipf/config/${1} ] && [ -f /tmp/unzipf/config/${2} ]; then
            echo "$1 & $2 exist and are ready for swapping"
            cp -f /tmp/unzipf/config/$1 /tmp/unzipf/config/$2
            echo "config/$1 has been swapped with $2"
            echo "this is the current dir"; pwd;
            cd /tmp/unzipf/
            pwd
            zip -r -qq ${element}-${version}.zip *
            ls -lrt
            echo "Package has been rezipped to /tmp folder"
        else
            echo "The files $1 & $2 do NOT exist! Hence, NO swapping has been done"
            echo "BUT Config folder exist! Proceeding to upload the .zip to S3"
    fi
    }
    s3upload () {
        echo "uploading to AWS - S3"
        /usr/bin/aws s3 cp /tmp/unzipf/${element}-${version}.zip s3://xbo-lambda-functions/code/${bamboo_gitrepo_name}/${element}/$version/ --grants full=uri=http://acs.amazonaws.com/groups/global/AllUsers
    }
    cleaning () {
        echo "Removing the ${element}-${version}.zip file from present working directory & and cleaning /tmp directory"
        rm -rf /tmp/unzipf/*; rm /tmp/${element}*.zip; rm /tmp/taglist.txt;
    }
    if [ -d /tmp/unzipf/config ]; then
        echo "Config folder is present"
        swapfunc prod-config.properties application-config.properties
        swapfunc dependency-config-prod.properties dependency-config.properties
        swapfunc prod-Rules.json Rules.json
    else
        echo "The folder Config inside the ${element}-${version}.zip does NOT exist! Proceeding to upload the ${element}-${version}.zip to S3"
    fi
    s3upload
    cleaning
    errstring='ResourceNotFoundException'; echo "Printing the value for errstring = $errstring"
    cat ${WORKDIR}/${bamboo_gitrepo_name}/${element}/gradle.properties > gradleprop.txt
        awsfunctionname=$(grep "aws.function.name" gradleprop.txt | awk -F "=" '{print $2}')
        awsruntime=$(grep "aws.runtime" gradleprop.txt | awk -F "=" '{print $2}')
        awshandler=$(grep "aws.handler" gradleprop.txt | awk -F "=" '{print $2}')
        awsmemsize=$(grep "aws.memory-size" gradleprop.txt | awk -F "=" '{print $2}')
        awstimeout=$(grep "aws.timeout" gradleprop.txt | awk -F "=" '{print $2}')
        awsdescription=$(grep "aws.description" gradleprop.txt | awk -F "=" '{print $2}')" version=${version}"
        awsrole=$(grep "aws.role" gradleprop.txt | awk -F "=" '{print $2}')
        awscode=$(grep "aws.code" gradleprop.txt | awk -F "=" '{print $2 "=" $3 "=" $4}')
        awscode=$(echo $awscode | sed "s/SUBSTITUTED_VERSION/$version/g")
        awsvpcconfig=$(grep "aws.vpc-config" gradleprop.txt | awk -F "=" '{print $2 "=" $3 "=" $4}')
        if [ -n "${awsfunctionname// }" ]; then

        funcoutput=$((aws lambda get-function --function-name ${awsfunctionname}${bamboo_function_ext} --qualifier "\$LATEST") 2>&1)
        echo "Printing lambda get function"
        echo $funcoutput
        echo "Error string = $errstring"
        echo "Function-Name=$awsfunctionname"; echo "Runtime=$awsruntime"; echo "Handler=$awshandler"; echo "Memory-size=$awsmemsize"; echo "Timeout=$awstimeout"; echo "Description=$awsdescription"; echo "Role=$awsrole"; echo "Code=$awscode"; echo "VPC-Config=$awsvpcconfig";
        if [ -n "${awshandler// }" ]; then
            if [[ $funcoutput == *"$errstring"* ]]; then
                echo "Function not found"
                /usr/bin/aws lambda create-function --function-name ${awsfunctionname}${bamboo_function_ext} --runtime $awsruntime --role $awsrole --handler $awshandler --code "$awscode" --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
else
            echo "Function found"
            aws lambda update-function-code --function-name ${awsfunctionname}${bamboo_function_ext} --s3-bucket xbo-lambda-functions --s3-key code/${bamboo_gitrepo_name}/${element}/$version/${element}-${version}.zip
            aws lambda update-function-configuration --function-name ${awsfunctionname}${bamboo_function_ext} --runtime $awsruntime --role $awsrole --handler $awshandler --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
fi
        else
        echo " "
        echo "Function $element does NOT have AWSHandler declared in the gradle.properties file"
        echo " "
        echo "Skipping to the next function"
        echo " "
        fi
        else
        echo "aws.function.name has NOT been found. Skipping to the next function now!"
        fi
    else
    echo " "
    echo "The gradle.properties file has NOT been found for $element. Skipping to the next function now! "
    echo " "
    fi
done
else
        echo " "
        echo "Function: $tag_input has NOT been found"
        echo " "
        echo "Please make sure that the input matches the tag name exactly as it is stored."
        echo "For example: 99.0.1"
        echo " "
        echo "Exiting. Please run the 'preProd_deploy.sh' again"
        exit;
    fi
else
    echo " "
    echo "You have entered nothing or white spaces. Please enter a valid service name!"
    echo " "
    echo "Please make sure that the input matches the tag name exactly as it is stored."
    echo "For example: 99.0.1"
    echo " "
    echo "Exiting. Please run the 'preProd_deploy.sh' again"
    exit;
fi
