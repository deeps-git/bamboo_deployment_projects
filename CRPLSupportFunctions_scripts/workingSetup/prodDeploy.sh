#!/bin/bash
#env
hostname
REPO_DIR="${BUILD_BASE_PATH}/${BUILD_DIR}/${REPO_TO_BUILD}"
cd "${REPO_DIR}"
S3_DEPLOY_BASE="release"
echo "$(pwd)"
read -r -a array <<< "$(./gradlew projects | grep -o "Project ':.*'" | grep -o "CRPL.*" | cut -d"'" -f1)"

. ${BUILD_BASE_PATH}/${BUILD_DIR}/${BUILD_SCRIPTS_REPO}/CRPLSupportFunctions_scripts/workingSetup/functions.sh
echo "The extension is ${ENVIRONMENT}";
echo "Checking RELEASE_VERSION for the build..."

echo "The RELEASE_VERSION is: ${RELEASE_VERSION}"
echo "Checking out as dev again!"; git checkout dev;

declare -a region_array=("us-west-2")

        for element in "${array[@]}"
            do
            echo " "
            echo "Working on $element project"
            echo " "
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
                   #     echo "Aws code printed = ${awscode}"
                        awsvpcconfig=$(grep "aws.vpc-config" gradleprop.txt | awk -F "=" '{print $2 "=" $3 "=" $4}')
                        s3Key=$(grep  "aws.code" gradleprop.txt | sed -e "s/0-SNAPSHOT/${RELEASE_VERSION}/g" | sed -e "s/code/${S3_DEPLOY_BASE}/g"  | cut -d"=" -f4-)
#                        s3BucketName=$(grep "aws.code" gradleprop.txt | awk -F "=" '{print $3}' |awk -F "," '{print $1}')
#                        hardcoding it for now

                        if [[ -n "${awsfunctionname}" && -n "${awshandler}" ]]; then
                            for region_array_element in "${region_array[@]}"
                                do
# TODO : Change all git repos to have the correct bucketName
                                    s3BucketName="crpl-support-functions-${region_array_element}";

                                    funcoutput=$((aws lambda get-function --region "${region_array_element}" --function-name ${awsfunctionname}${ENVIRONMENT} --qualifier "\$LATEST") 2>&1) &&
                                    echo "Function-Name=$awsfunctionname"; echo "Runtime=$awsruntime"; echo "Handler=$awshandler"; echo "Memory-size=$awsmemsize"; echo "Timeout=$awstimeout"; echo "Description=$awsdescription"; echo "Role=$awsrole"; echo "Code=$awscode"; echo "VPC-Config=$awsvpcconfig";
                                    if [[ $funcoutput == *"$errstring"* ]]; then
                                        awsCode="S3Bucket=${s3BucketName},S3Key=${s3Key}"
				echo "Aws code printed = ${awsCode}"
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
                        else
                            echo "aws.function.name or aws.handler has NOT been found. Skipping to the next function now!"
                        fi
            done



