#!/bin/bash
hostname
strings=`cat projectnames.txt`
IFS=', ' read -r -a array <<< "$strings"
for piece in "${array[@]}"
do
    export bamboo_function_ext; echo $bamboo_function_ext; export bamboo_build_key;
    echo "Working on: $piece"
    source /home/xdeploy/awsenv/awsenv.sh
    cat /home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}/${piece}/gradle.properties > gradleprop.txt
    awsfunctionname=$(grep "aws.function.name" gradleprop.txt | awk -F "=" '{print $2}')
    funcout=$((aws --profile svc_primary_xbo lambda get-function --function-name ${awsfunctionname}${bamboo_function_ext} --qualifier "\$LATEST") 2>&1) &&
    errstrings='ResourceNotFoundException'
    if [[ $funcout != *"$errstrings"* ]]; then
        echo "Function has been found"
        aws --profile svc_primary_xbo lambda publish-version --function-name ${awsfunctionname}${bamboo_function_ext} --description "published version of ${piece} Latest to next version" > descr.txt
        cat descr.txt
        versionFromPublish=$(grep "Version" descr.txt | awk -F '[^0-9]*' '$0=$2')
        echo " "
        echo "The version number from the publish is $versionFromPublish"
        echo " "
        aliasdescr=$((aws --profile svc_primary_xbo lambda list-aliases --function-name ${awsfunctionname}${bamboo_function_ext}) 2>&1)
        matchalias='"Name": "QA"'
        if [[ $aliasdescr == *"$matchalias"* ]]; then
        echo "$piece contains alias with the name QA"
        echo "Updating $piece"
        echo $aliasdescr
        aws --profile svc_primary_xbo lambda update-alias --function-name ${awsfunctionname}${bamboo_function_ext} --name QA --function-version "${versionFromPublish}"
        else
        echo "$piece contains no alias named QA"
        echo "Creating a new alias named QA for $piece"
        aws --profile svc_primary_xbo lambda create-alias --function-name ${awsfunctionname}${bamboo_function_ext} --name QA --function-version "${versionFromPublish}"
        fi        
    else
        echo " "
        echo "Function $piece has NOT been found"
        echo " "
        echo "Skipping to the next function"
        echo " "
    fi
done