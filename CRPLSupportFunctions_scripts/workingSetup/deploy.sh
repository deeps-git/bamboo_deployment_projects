#!/bin/bash
#env
hostname
REPO_DIR="${BUILD_BASE_PATH}/${BUILD_DIR}/${REPO_TO_BUILD}"
cd "${REPO_DIR}"
TMP_DIR="${BUILD_BASE_PATH}/${BUILD_DIR}/tmp"
S3_DEPLOY_BASE="code";
export TMP_DIR;
echo "Creating tmp directory";
sudo mkdir -p ${TMP_DIR}
sudo chown -R crpl ${TMP_DIR}

echo "$(pwd)"
read -r -a array <<< "$(./gradlew projects | grep -o "Project ':.*'" | grep -o "CRPL.*" | cut -d"'" -f1)"
echo "array---${array}"
. ${BUILD_BASE_PATH}/${BUILD_DIR}/${BUILD_SCRIPTS_REPO}/CRPLSupportFunctions_scripts/workingSetup/functions.sh
echo "The extension is ${ENVIRONMENT}"; dvar="-Dev"; svar="-Stage", prevar="-PreProd";
echo "Checking RELEASE_VERSION for the build..."

echo "The RELEASE_VERSION is: ${RELEASE_VERSION}"
echo "Checking out as dev again!"; git checkout dev;

declare -a region_array=("us-east-1" "us-west-1" "us-east-2")

function cleaning () {
                        echo "Removing the ${element}-${RELEASE_VERSION}.zip file from present working directory & and cleaning ${TMP_DIR}/ directory"
                        rm -rf ${TMP_DIR}/unzipf/*; rm ${TMP_DIR}/${element}*.zip;
                    }


        for element in "${array[@]}"
            do
            echo "Build DIR is - ${BUILD_BASE_PATH}/${BUILD_DIR}"; echo "Git repo name is - ${REPO_TO_BUILD}"
            echo " "
            echo "Working on $element project"
            echo " "
                if [ -f ./${element}/gradle.properties ]; then
                    echo "Gradle.properties file NOT EMPTY!"

                    wget --no-proxy "https://maven.teamccp.com/content/groups/master/${BUILD_MAVEN_PATH}/${element}/${RELEASE_VERSION}/${element}-${RELEASE_VERSION}.zip" -O ${TMP_DIR}/${element}-${RELEASE_VERSION}.zip &&

                    echo "Working on - $element"

                    unzip -o -qq ${TMP_DIR}/${element}-${RELEASE_VERSION}.zip -d ${TMP_DIR}/unzipf
                    echo "$element has been unzipped"

                    decrypt

                    if [ -f ${TMP_DIR}/${element}-${RELEASE_VERSION}.zip ]; then
                        if [ -d ${TMP_DIR}/unzipf/config ] && [ -d ${TMP_DIR}/unzipf/config ]; then
                            if [ "${ENVIRONMENT}" == "${dvar}" ]; then
                                echo "Bamboo extension is -Dev hence swapping dev-config with application-config & dependency-config-dev with dependency-config"
                                pushd ${TMP_DIR}/unzipf/config/
                                copyConfig dev-config.properties application-config.properties
                                copyConfig dependency-config-dev.properties dependency-config.properties
                                copyConfig dev-Rules.json Rules.json
                            elif [ "${ENVIRONMENT}" == "${svar}" ]; then
                                echo "The present working directory is:"; pwd;
                                echo "Config folder is present"
                                pushd ${TMP_DIR}/unzipf/config/
                                copyConfig ci-config.properties application-config.properties
                                copyConfig dependency-config-ci.properties dependency-config.properties
                                copyConfig ci-Rules.json Rules.json
                            elif [ "${ENVIRONMENT}" == "${prevar}" ]; then
                                echo "The present working directory is:"; pwd;
                                echo "Config folder is present"
                                S3_DEPLOY_BASE="release"
                                pushd ${TMP_DIR}/unzipf/config/
                                copyConfig prod-config.properties application-config.properties
                                copyConfig dependency-config-prod.properties dependency-config.properties
                                copyConfig prod-Rules.json Rules.json
                            fi
                        else
                            echo "The folder Config inside the ${element}-${RELEASE_VERSION}.zip does NOT exist! Proceeding to upload the ${element}-${RELEASE_VERSION}.zip to S3"
                        fi
                    fi
                        echo "Zipping it back again..."
                        rm -rf ${TMP_DIR}/${element}-${RELEASE_VERSION}.zip
			pushd ${TMP_DIR}/unzipf/
                        zip -r -qq "${TMP_DIR}/${element}-${RELEASE_VERSION}.zip" "."
                        popd
			popd


                        errstring='ResourceNotFoundException'
                        cat ./${element}/gradle.properties > gradleprop.txt
                        awsfunctionname=$(grep "aws.function.name" gradleprop.txt | awk -F "=" '{print $2}')
                        awsruntime=$(grep "aws.runtime" gradleprop.txt | awk -F "=" '{print $2}')
                        awshandler=$(grep "aws.handler" gradleprop.txt | awk -F "=" '{print $2}')
                        awsmemsize=$(grep "aws.memory-size" gradleprop.txt | awk -F "=" '{print $2}')
                        awstimeout=$(grep "aws.timeout" gradleprop.txt | awk -F "=" '{print $2}')
                        awsdescription=$(grep "aws.description" gradleprop.txt | awk -F "=" '{print $2}')" version=${RELEASE_VERSION}"
                        #awsrole=$(grep "aws.role" gradleprop.txt | awk -F "=" '{print $2}')
                        awsrole="arn:aws:iam::453246518757:role/OneCloud/lambda_basic_execution"
                        kinesisStreamName="SupportFunctionsLogs"
                        echo "Aws code printed = ${awscode}"
                        awsvpcconfig=$(grep "aws.vpc-config" gradleprop.txt | awk -F "=" '{print $2 "=" $3 "=" $4}')
                        s3Key=$(grep  "aws.code" gradleprop.txt | sed -e "s/0-SNAPSHOT/${RELEASE_VERSION}/g" | sed -e "s/code/${S3_DEPLOY_BASE}/g"  | cut -d"=" -f4-)
#                        s3BucketName=$(grep "aws.code" gradleprop.txt | awk -F "=" '{print $3}' |awk -F "," '{print $1}')
#                        hardcoding it for now

                        if [[ -n "${awsfunctionname}" && -n "${awshandler}" ]]; then
                            for region_array_element in "${region_array[@]}"
                                do
# TODO : Change all git repos to have the correct bucketName
                                    s3BucketName="crpl-support-functions-${region_array_element}";
                                    s3upload ${TMP_DIR}/${element}-${RELEASE_VERSION}.zip s3://crpl-support-functions-${region_array_element}/${S3_DEPLOY_BASE}/${REPO_TO_BUILD}/${element}/$RELEASE_VERSION/  ${region_array_element}
                                    funcoutput=$((aws lambda get-function --region "${region_array_element}" --function-name ${awsfunctionname}${ENVIRONMENT} --qualifier "\$LATEST") 2>&1) &&
                                    echo "Function-Name=$awsfunctionname"; echo "Runtime=$awsruntime"; echo "Handler=$awshandler"; echo "Memory-size=$awsmemsize"; echo "Timeout=$awstimeout"; echo "Description=$awsdescription"; echo "Role=$awsrole"; echo "Code=${awsCode}"; echo "VPC-Config=$awsvpcconfig";
                                    if [[ $funcoutput == *"$errstring"* ]]; then
                                        awsCode="S3Bucket=${s3BucketName},S3Key=${s3Key}"
                                        echo "Function not found"
                                        /usr/bin/aws lambda create-function --region ${region_array_element} --function-name ${awsfunctionname}${ENVIRONMENT} --runtime $awsruntime --role $awsrole --handler $awshandler --code "${awsCode}" --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
                                        echo "Running aws logs put subscription filter"
                                        aws logs put-subscription-filter --region ${region_array_element} --log-group-name /aws/lambda/${awsfunctionname}${ENVIRONMENT} --filter-name /aws/lambda/${region_array_element}/${awsfunctionname}${ENVIRONMENT} --destination-arn arn:aws:kinesis:${region_array_element}:453246518757:stream/$kinesisStreamName${ENVIRONMENT} --filter-pattern "" --role-arn arn:aws:iam::453246518757:role/OneCloud/Kinesis-to-Cloudwatch

                                    else
                                        echo "Function found"
                                        aws lambda update-function-code --region ${region_array_element} --function-name ${awsfunctionname}${ENVIRONMENT} --s3-bucket ${s3BucketName} --s3-key ${s3Key}
                                        aws lambda update-function-configuration --region ${region_array_element}  --function-name ${awsfunctionname}${ENVIRONMENT} --runtime $awsruntime --role $awsrole --handler $awshandler --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
                                        echo "Running aws logs put subscription filter"
                                       # aws logs put-subscription-filter --region ${region_array_element} --log-group-name /aws/lambda/${awsfunctionname}${ENVIRONMENT} --filter-name /aws/lambda/${region_array_element}/${awsfunctionname}${ENVIRONMENT} --destination-arn arn:aws:kinesis:${region_array_element}:453246518757:stream/$kinesisStreamName${ENVIRONMENT} --filter-pattern "" --role-arn arn:aws:iam::453246518757:role/OneCloud/Kinesis-to-Cloudwatch
                                    fi
                                done
                                    cleaning
                        else
                            echo "aws.function.name or aws.handler has NOT been found. Skipping to the next function now!"
                        fi
                else
                     echo " "
                     echo "The gradle.properties file has NOT been found for $element. Skipping to the next function now! "
                     echo " "
                fi
            done



