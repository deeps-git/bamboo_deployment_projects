#!/bin/bash

source /home/xdeploy/awsenv/awsenv.sh

echo "Downloading the .jar file from the Maven repo: http://maven.teamccp.com/content/groups/master/com/comcast/crpl/psp-proxy/0-SNAPSHOT/psp-proxy-0-SNAPSHOT.jar"
echo ""; echo ""

sudo wget http://maven.teamccp.com/content/groups/master/com/comcast/crpl/psp-proxy/0-SNAPSHOT/psp-proxy-0-SNAPSHOT.jar -O /tmp/psp-proxy-0-SNAPSHOT.jar

echo ""; echo ""

echo "Updating function code for the Lambda function name: pspProxyMessageWorker-Prod"

echo ""

aws lambda update-function-code --function-name pspProxyMessageWorker-Prod --zip-file fileb:///tmp/psp-proxy-0-SNAPSHOT.jar

echo ""; echo ""

echo "Parsing values from Workerprod.properties file to workerprod.txt file"

echo ""; echo ""

cat /home/xdeploy/awsenv/workerprod.properties > workerprod.txt
        PSP_SQS_AWS_ACCESS_KEY=$(grep "PSP_SQS_AWS_ACCESS_KEY" workerprod.txt | awk -F "=" '{print $2}')
        CRPL_OUT_QUEUE_NAME=$(grep "CRPL_OUT_QUEUE_NAME" workerprod.txt | awk -F "=" '{print $2}')
        CRPL_ERROR_QUEUE_NAME=$(grep "CRPL_ERROR_QUEUE_NAME" workerprod.txt | awk -F "=" '{print $2}')
        CRPL_SQS_AWS_ACCESS_KEY=$(grep "CRPL_SQS_AWS_ACCESS_KEY" workerprod.txt | awk -F "=" '{print $2}')
        CRPL_UNDELIVERABLE_QUEUE_NAME=$(grep "CRPL_UNDELIVERABLE_QUEUE_NAME" workerprod.txt | awk -F "=" '{print $2}')
        CRPL_SQS_AWS_SECRET_ACCESS_KEY=$(grep "CRPL_SQS_AWS_SECRET_ACCESS_KEY" workerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_REGION=$(grep "PSP_SQS_REGION" workerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_QUEUE_NAME=$(grep "PSP_SQS_QUEUE_NAME" workerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_AWS_SECRET_ACCESS_KEY=$(grep "PSP_SQS_AWS_SECRET_ACCESS_KEY" workerprod.txt | awk -F "=" '{print $2}')
        CRPL_SQS_REGION=$(grep "CRPL_SQS_REGION" workerprod.txt | awk -F "=" '{print $2}')

echo ""; echo ""

echo "Updating function configuration for the Lambda function name: pspProxyMessageWorker-Prod"

echo ""

aws lambda update-function-configuration --function-name pspProxyMessageWorker-Prod --environment "{\"Variables\":{\"PSP_SQS_AWS_ACCESS_KEY\":\"$PSP_SQS_AWS_ACCESS_KEY\",\"CRPL_OUT_QUEUE_NAME\":\"$CRPL_OUT_QUEUE_NAME\",\"CRPL_ERROR_QUEUE_NAME\":\"$CRPL_ERROR_QUEUE_NAME\",\"CRPL_SQS_AWS_ACCESS_KEY\":\"$CRPL_SQS_AWS_ACCESS_KEY\",\"CRPL_UNDELIVERABLE_QUEUE_NAME\":\"$CRPL_UNDELIVERABLE_QUEUE_NAME\",\"CRPL_SQS_AWS_SECRET_ACCESS_KEY\":\"$CRPL_SQS_AWS_SECRET_ACCESS_KEY\",\"PSP_SQS_REGION\":\"$PSP_SQS_REGION\",\"PSP_SQS_QUEUE_NAME\":\"$PSP_SQS_QUEUE_NAME\",\"PSP_SQS_AWS_SECRET_ACCESS_KEY\":\"$PSP_SQS_AWS_SECRET_ACCESS_KEY\",\"CRPL_SQS_REGION\":\"$CRPL_SQS_REGION\"}}"

echo ""; echo ""

echo "Updating function code for the Lambda function name: pspProxyMessageConsumer-Prod"

echo ""

aws lambda update-function-code --function-name pspProxyMessageConsumer-Prod --zip-file fileb:///tmp/psp-proxy-0-SNAPSHOT.jar

echo ""; echo ""

echo "Parsing values from Consumerprod.properties file to consumerprod.txt file"

cat /home/xdeploy/awsenv/consumerprod.properties > consumerprod.txt
	CODE_BIG_SECRET=$(grep "CODE_BIG_SECRET" consumerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_AWS_ACCESS_KEY=$(grep "PSP_SQS_AWS_ACCESS_KEY" consumerprod.txt | awk -F "=" '{print $2}')
        KMS_PASSWORD=$(grep "KMS_PASSWORD" consumerprod.txt | awk -F "=" '{print $2}')
        CODE_BIG_KEY=$(grep "CODE_BIG_KEY" consumerprod.txt | awk -F "=" '{print $2}')
        KMS_USER_NAME=$(grep "KMS_USER_NAME" consumerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_QUEUE_NAME=$(grep "PSP_SQS_QUEUE_NAME" consumerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_AWS_SECRET_ACCESS_KEY=$(grep "PSP_SQS_AWS_SECRET_ACCESS_KEY" consumerprod.txt | awk -F "=" '{print $2}')
        PSP_SQS_REGION=$(grep "PSP_SQS_REGION" consumerprod.txt | awk -F "=" '{print $2}')
        CODE_BIG_URL=$(grep "CODE_BIG_URL" consumerprod.txt | awk -F "=" '{print $2}')
        LAMBDA_WORKER_NAME=$(grep "LAMBDA_WORKER_NAME" consumerprod.txt | awk -F "=" '{print $2}')
        LAMBDA_REGION=$(grep "LAMBDA_REGION" consumerprod.txt | awk -F "=" '{print $2}')

echo ""; echo ""

echo "Updating function configuration for the Lambda function name: pspProxyMessageConsumer-Prod"

echo ""

aws lambda update-function-configuration --function-name pspProxyMessageConsumer-Prod --environment "{\"Variables\":{\"CODE_BIG_SECRET\":\"$CODE_BIG_SECRET\",\"PSP_SQS_AWS_ACCESS_KEY\":\"$PSP_SQS_AWS_ACCESS_KEY\",\"KMS_PASSWORD\":\"$KMS_PASSWORD\",\"CODE_BIG_KEY\":\"$CODE_BIG_KEY\",\"KMS_USER_NAME\":\"$KMS_USER_NAME\",\"PSP_SQS_QUEUE_NAME\":\"$PSP_SQS_QUEUE_NAME\",\"PSP_SQS_AWS_SECRET_ACCESS_KEY\":\"$PSP_SQS_AWS_SECRET_ACCESS_KEY\",\"PSP_SQS_REGION\":\"$PSP_SQS_REGION\",\"CODE_BIG_URL\":\"$CODE_BIG_URL\",\"LAMBDA_WORKER_NAME\":\"$LAMBDA_WORKER_NAME\",\"LAMBDA_REGION\":\"$LAMBDA_REGION\"}}"

echo "Updating function code & configuration for the functions:"
echo "pspProxyMessageWorker-Prod   |   pspProxyMessageConsumer-Prod"
echo "has been finished."
echo "Please look for errors and unusual log record"