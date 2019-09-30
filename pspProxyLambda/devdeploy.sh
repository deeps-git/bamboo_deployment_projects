#!/bin/bash

hostname

source /home/xdeploy/awsenv/awsenv.sh

echo "Downloading the .jar file from the Maven repo: http://maven.teamccp.com/content/groups/master/com/comcast/crpl/psp-proxy/0-SNAPSHOT/psp-proxy-0-SNAPSHOT.jar"
echo ""; echo ""

sudo wget http://maven.teamccp.com/content/groups/master/com/comcast/crpl/psp-proxy/0-SNAPSHOT/psp-proxy-0-SNAPSHOT.jar -O /tmp/psp-proxy-0-SNAPSHOT.jar

echo ""; echo ""

echo "Updating function code for the Lambda function name: pspProxyMessageWorker-Dev"

echo ""

aws lambda update-function-code --function-name pspProxyMessageWorker-Dev --zip-file fileb:///tmp/psp-proxy-0-SNAPSHOT.jar

echo ""; echo ""

echo "Parsing values from Worker.properties file to worker.txt file"

echo ""; echo ""

cat /home/xdeploy/awsenv/worker.properties > worker.txt
        PSP_SQS_AWS_ACCESS_KEY=$(grep "PSP_SQS_AWS_ACCESS_KEY" worker.txt | awk -F "=" '{print $2}')
        CRPL_OUT_QUEUE_NAME=$(grep "CRPL_OUT_QUEUE_NAME" worker.txt | awk -F "=" '{print $2}')
        CRPL_ERROR_QUEUE_NAME=$(grep "CRPL_ERROR_QUEUE_NAME" worker.txt | awk -F "=" '{print $2}')
        CRPL_SQS_AWS_ACCESS_KEY=$(grep "CRPL_SQS_AWS_ACCESS_KEY" worker.txt | awk -F "=" '{print $2}')
        CRPL_UNDELIVERABLE_QUEUE_NAME=$(grep "CRPL_UNDELIVERABLE_QUEUE_NAME" worker.txt | awk -F "=" '{print $2}')
        CRPL_SQS_AWS_SECRET_ACCESS_KEY=$(grep "CRPL_SQS_AWS_SECRET_ACCESS_KEY" worker.txt | awk -F "=" '{print $2}')
        PSP_SQS_REGION=$(grep "PSP_SQS_REGION" worker.txt | awk -F "=" '{print $2}')
        PSP_SQS_QUEUE_NAME=$(grep "PSP_SQS_QUEUE_NAME" worker.txt | awk -F "=" '{print $2}')
        PSP_SQS_AWS_SECRET_ACCESS_KEY=$(grep "PSP_SQS_AWS_SECRET_ACCESS_KEY" worker.txt | awk -F "=" '{print $2}')
        CRPL_SQS_REGION=$(grep "CRPL_SQS_REGION" worker.txt | awk -F "=" '{print $2}')

echo ""; echo ""

echo "Updating function configuration for the Lambda function name: pspProxyMessageWorker-Dev"

echo ""

aws lambda update-function-configuration --function-name pspProxyMessageWorker-Dev --environment "{\"Variables\":{\"PSP_SQS_AWS_ACCESS_KEY\":\"$PSP_SQS_AWS_ACCESS_KEY\",\"CRPL_OUT_QUEUE_NAME\":\"$CRPL_OUT_QUEUE_NAME\",\"CRPL_ERROR_QUEUE_NAME\":\"$CRPL_ERROR_QUEUE_NAME\",\"CRPL_SQS_AWS_ACCESS_KEY\":\"$CRPL_SQS_AWS_ACCESS_KEY\",\"CRPL_UNDELIVERABLE_QUEUE_NAME\":\"$CRPL_UNDELIVERABLE_QUEUE_NAME\",\"CRPL_SQS_AWS_SECRET_ACCESS_KEY\":\"$CRPL_SQS_AWS_SECRET_ACCESS_KEY\",\"PSP_SQS_REGION\":\"$PSP_SQS_REGION\",\"PSP_SQS_QUEUE_NAME\":\"$PSP_SQS_QUEUE_NAME\",\"PSP_SQS_AWS_SECRET_ACCESS_KEY\":\"$PSP_SQS_AWS_SECRET_ACCESS_KEY\",\"CRPL_SQS_REGION\":\"$CRPL_SQS_REGION\"}}"

echo ""; echo ""

echo "Updating function code for the Lambda function name: pspProxyMessageConsumer-Dev"

echo ""

aws lambda update-function-code --function-name pspProxyMessageConsumer-Dev --zip-file fileb:///tmp/psp-proxy-0-SNAPSHOT.jar

echo ""; echo ""

echo "Parsing values from Consumer.properties file to consumer.txt file"

cat /home/xdeploy/awsenv/consumer.properties > consumer.txt
	CODE_BIG_SECRET=$(grep "CODE_BIG_SECRET" consumer.txt | awk -F "=" '{print $2}')
        PSP_SQS_AWS_ACCESS_KEY=$(grep "PSP_SQS_AWS_ACCESS_KEY" consumer.txt | awk -F "=" '{print $2}')
        KMS_PASSWORD=$(grep "KMS_PASSWORD" consumer.txt | awk -F "=" '{print $2}')
        CODE_BIG_KEY=$(grep "CODE_BIG_KEY" consumer.txt | awk -F "=" '{print $2}')
        KMS_USER_NAME=$(grep "KMS_USER_NAME" consumer.txt | awk -F "=" '{print $2}')
        PSP_SQS_QUEUE_NAME=$(grep "PSP_SQS_QUEUE_NAME" consumer.txt | awk -F "=" '{print $2}')
        PSP_SQS_AWS_SECRET_ACCESS_KEY=$(grep "PSP_SQS_AWS_SECRET_ACCESS_KEY" consumer.txt | awk -F "=" '{print $2}')
        PSP_SQS_REGION=$(grep "PSP_SQS_REGION" consumer.txt | awk -F "=" '{print $2}')
        CODE_BIG_URL=$(grep "CODE_BIG_URL" consumer.txt | awk -F "=" '{print $2}')
        LAMBDA_WORKER_NAME=$(grep "LAMBDA_WORKER_NAME" consumer.txt | awk -F "=" '{print $2}')
        LAMBDA_REGION=$(grep "LAMBDA_REGION" consumer.txt | awk -F "=" '{print $2}')

echo ""; echo ""

echo "Updating function configuration for the Lambda function name: pspProxyMessageConsumer-Dev"

echo ""

aws lambda update-function-configuration --function-name pspProxyMessageConsumer-Dev --environment "{\"Variables\":{\"CODE_BIG_SECRET\":\"$CODE_BIG_SECRET\",\"PSP_SQS_AWS_ACCESS_KEY\":\"$PSP_SQS_AWS_ACCESS_KEY\",\"KMS_PASSWORD\":\"$KMS_PASSWORD\",\"CODE_BIG_KEY\":\"$CODE_BIG_KEY\",\"KMS_USER_NAME\":\"$KMS_USER_NAME\",\"PSP_SQS_QUEUE_NAME\":\"$PSP_SQS_QUEUE_NAME\",\"PSP_SQS_AWS_SECRET_ACCESS_KEY\":\"$PSP_SQS_AWS_SECRET_ACCESS_KEY\",\"PSP_SQS_REGION\":\"$PSP_SQS_REGION\",\"CODE_BIG_URL\":\"$CODE_BIG_URL\",\"LAMBDA_WORKER_NAME\":\"$LAMBDA_WORKER_NAME\",\"LAMBDA_REGION\":\"$LAMBDA_REGION\"}}"

echo "Updating function code & configuration for the functions:"
echo "pspProxyMessageWorker-Dev   |   pspProxyMessageConsumer-Dev"
echo "has been finished."
echo "Please look for errors and unusual log record"