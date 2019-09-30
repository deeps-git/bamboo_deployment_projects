#!/bin/bash
#env
hostname
string=`cat projectnames.txt`
IFS=', ' read -r -a array <<< "$string"
export bamboo_build_key; export bamboo_script_key; export bamboo_gitrepo_name; export bamboo_maven_path; export bamboo_function_ext; export bamboo_repo_url; export bamboo_scrip_path; export PATH="/home/xdeploy/.pythonbrew/pythons/Python-2.7/bin:${PATH}";

echo "The extension is ${bamboo_function_ext}"; dvar="-Dev"; svar="-Stage"; snapversion="0-SNAPSHOT";
if [[ "${bamboo_function_ext}" == "$dvar" ]]; then
        echo "Because the extension is -Dev, declaring snapversion as 0-SNAPSHOT!"
        snapversion="0-SNAPSHOT"
    else
        echo "Printing scripting key"
        echo "$bamboo_script_key"
        cd /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_script_key}/
        echo "Printing git repo url"
        echo "$bamboo_repo_url"
        git fetch --tags $bamboo_repo_url
        NEW_TAG=`git describe --tags $(git rev-list --tags --max-count=1)`
        snapversion=$NEW_TAG
        git checkout $NEW_TAG
        sed '/releaseVersion/d' ./gradle.properties > gradle.properties.new && mv gradle.properties.new gradle.properties
        echo releaseVersion=$NEW_TAG >> gradle.properties
        git push
        echo "Gradle.properties changed!"
        echo "Currently the repo is pointing at the below tag"; git describe --tags;
        echo "Running Graddle wrapper to -::::rebuild clean install uploadArchives::::-"
        ./gradlew -C rebuild clean build uploadArchives -i
fi
echo "The snapversion is: $snapversion"
echo "Checking out as dev again!"; git checkout dev;

declare -a region_array=("us-east-1" "us-west-1" "us-east-2")
for region_array_element in "${region_array[@]}"
do
for element in "${array[@]}"
do
    echo "Build key is - ${bamboo_build_key}"; echo "Git repo name is - ${bamboo_gitrepo_name}"
    echo " "
    echo "Working on $element project"
    echo " "
    if [ -f /home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}/${element}/gradle.properties ]; then
    echo "Gradle.properties file NOT EMPTY!"
    wget --no-proxy "https://maven.teamccp.com/content/groups/master/${bamboo_maven_path}/${element}/${snapversion}/${element}-${snapversion}.zip" -O /tmp/${element}-${snapversion}.zip &&
    echo "Working on - $element"
    rm -rf /tmp/unzipf/*; unzip -o -qq /tmp/${element}-${snapversion}.zip -d /tmp/unzipf
    echo "$element has been unzipped"
    decrypting
    subslogfunc () {
        if [ "$1" = "us-east-1" ]; then
            echo "CRPLLogs"
        elif [[ "$1" = "us-east-2" ]]; then
            echo "CRPLLogs-US-EAST-2"
        elif [[ "$1" = "us-west-1" ]]; then
            echo "CRPLLogs-US-WEST-1"
        else
            echo ""
            #statements
        fi
    }
    swapfunc () {
    if [ -f /tmp/unzipf/config/${1} ] && [ -f /tmp/unzipf/config/${2} ]; then
            echo "$1 & $2 exist and are ready for swapping"
            cp -f /tmp/unzipf/config/$1 /tmp/unzipf/config/$2
            echo "config/$1 has been swapped with $2"
            cd /tmp/unzipf
            echo "Printing config files before zipping"
            ls /tmp/unzipf/config/
#           rm -rf /tmp/unzipf/config/*.gpg
            zip -r -qq /tmp/${element}-${snapversion}.zip .
#           zip -r -qq /tmp/${element}-${snapversion}.zip /tmp/unzipf
            echo "Package has been rezipped to /tmp folder"
        else
            echo "The files $1 & $2 do NOT exist! Hence, NO swapping has been done"
            echo "BUT Config folder exist! Proceeding to upload the .zip to S3"
    fi
    }
    s3upload () {
        source /home/xdeploy/awsenv/awsenv.sh
        echo "uploading to AWS - S3"
        /usr/bin/aws s3 cp /tmp/${element}-${snapversion}.zip s3://crpl-lambda-functions-${region_array_element}/code/${bamboo_gitrepo_name}/${element}/$snapversion/ --region ${region_array_element} --grants full=uri=http://acs.amazonaws.com/groups/global/AllUsers
    }
    cleaning () {
        echo "Removing the ${element}-${snapversion}.zip file from present working directory & and cleaning /tmp directory"
        rm -rf /tmp/unzipf/*; rm /tmp/${element}*.zip;
    }
    decrypting () {
        for file in `find /tmp/unzipf/config  -type f | grep .gpg`
        do
                outputFile=${file%.gpg}
                echo "Printing outputFile - $outputFile"
                echo "decrypting $file"
                gpg --homedir ~/xbo/.xbo_gnupg --decrypt $file > $outputFile
                echo "Deleting $file"
                [ -f "$file" ] && rm "$file" && echo " $file deleted"
                echo "The outputFile is - $outputFile"
        done
        echo "Config files have been decrypted"
        echo "Deleting the gpg files now before zipping the function"
#       sudo rm -rf /tmp/unzipf/config/*.gpg
    }
    echo "Removing leftover zip files"
    [ -f /tmp/${element}-${snapversion}.zip ]
    if [ -d /tmp/unzipf/config ] && [ "${bamboo_function_ext}" == "$dvar" ]; then
        echo "Bamboo extension is -Dev hence swapping dev-config with application-config & dependency-config-dev with dependency-config"
        swapfunc dev-config.properties application-config.properties
        swapfunc dependency-config-dev.properties dependency-config.properties
        swapfunc dev-Rules.json Rules.json
    else
        if [ -d /tmp/unzipf/config ]; then
        echo "The present working directory is:"; pwd;
        echo "Config folder is present"
        swapfunc ci-config.properties application-config.properties
        swapfunc dependency-config-ci.properties dependency-config.properties
        swapfunc ci-Rules.json Rules.json
        else
        echo "The folder Config inside the ${element}-${snapversion}.zip does NOT exist! Proceeding to upload the ${element}-${snapversion}.zip to S3"
        fi
    fi
    s3upload
    cleaning

    errstring='ResourceNotFoundException'
    cat /home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}/${element}/gradle.properties > gradleprop.txt
        awsfunctionname=$(grep "aws.function.name" gradleprop.txt | awk -F "=" '{print $2}')
        awsruntime=$(grep "aws.runtime" gradleprop.txt | awk -F "=" '{print $2}')
        awshandler=$(grep "aws.handler" gradleprop.txt | awk -F "=" '{print $2}')
        awsmemsize=$(grep "aws.memory-size" gradleprop.txt | awk -F "=" '{print $2}')
        awstimeout=$(grep "aws.timeout" gradleprop.txt | awk -F "=" '{print $2}')
        awsdescription=$(grep "aws.description" gradleprop.txt | awk -F "=" '{print $2}')" version=${snapversion}"
        awsrole=$(grep "aws.role" gradleprop.txt | awk -F "=" '{print $2}')
        code1=$(grep "aws.code" gradleprop.txt | awk -F "=" '{print $2 "=" $3}' |awk -F "," '{print $1}')
        s3Key1=$(grep "aws.code" gradleprop.txt |awk -F "," '{print $2}' )
        s3bucketname="${code1}-${region_array_element}"
        kinesisStreamName="$(subslogfunc ${region_array_element})";
        awscode="${s3bucketname},${s3Key1}"
        awscode=$(echo $awscode | sed "s/SUBSTITUTED_VERSION/$snapversion/g")
        awsvpcconfig=$(grep "aws.vpc-config" gradleprop.txt | awk -F "=" '{print $2 "=" $3 "=" $4}')
        if [ -n "${awsfunctionname// }" ]; then

        funcoutput=$((aws lambda get-function --region ${region_array_element} --function-name ${awsfunctionname}${bamboo_function_ext} --qualifier "\$LATEST") 2>&1) &&
        echo "Function-Name=$awsfunctionname"; echo "Runtime=$awsruntime"; echo "Handler=$awshandler"; echo "Memory-size=$awsmemsize"; echo "Timeout=$awstimeout"; echo "Description=$awsdescription"; echo "Role=$awsrole"; echo "Code=$awscode"; echo "VPC-Config=$awsvpcconfig";
        if [ -n "${awshandler// }" ]; then
            if [[ $funcoutput == *"$errstring"* ]]; then
                echo "Function not found"
                /usr/bin/aws lambda create-function --region ${region_array_element} --function-name ${awsfunctionname}${bamboo_function_ext} --runtime $awsruntime --role $awsrole --handler $awshandler --code "$awscode" --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
                echo "Running aws logs put subscription filter"
                aws logs put-subscription-filter --region ${region_array_element} --log-group-name /aws/lambda/${awsfunctionname}${bamboo_function_ext} --filter-name /aws/lambda/${region_array_element}/${awsfunctionname}${bamboo_function_ext} --destination-arn arn:aws:kinesis:${region_array_element}:747386316553:stream/$kinesisStreamName${bamboo_function_ext} --filter-pattern "" --role-arn arn:aws:iam::747386316553:role/CWLtoKinesisAllLogsRole
            else
            echo "Function found"
            aws lambda update-function-code --region ${region_array_element} --function-name ${awsfunctionname}${bamboo_function_ext} --s3-bucket crpl-lambda-functions-${region_array_element} --s3-key code/${bamboo_gitrepo_name}/${element}/$snapversion/${element}-${snapversion}.zip
            aws lambda update-function-configuration --region ${region_array_element}  --function-name ${awsfunctionname}${bamboo_function_ext} --runtime $awsruntime --role $awsrole --handler $awshandler --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
            echo "Running aws logs put subscription filter"
#                aws logs put-subscription-filter --region ${region_array_element} --log-group-name /aws/lambda/${awsfunctionname}${bamboo_function_ext} --filter-name /aws/lambda/${region_array_element}/${awsfunctionname}${bamboo_function_ext} --destination-arn arn:aws:kinesis:${region_array_element}:747386316553:stream/$kinesisStreamName${bamboo_function_ext} --filter-pattern "" --role-arn arn:aws:iam::747386316553:role/CWLtoKinesisAllLogsRole
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
done