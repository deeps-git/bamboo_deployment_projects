#!/bin/bash
./pnameprocess.sh > projectnames.txt
echo "Please enter the service name you want to deploy to PROD: "
read project_input
echo "You have entered: $project_input"
echo ""
echo ""
if [ -n "${project_input// }" ]; then
    if grep -qw "$project_input" projectnames.txt
        then
aws --profile svc_primary_xbo lambda list-versions-by-function --function-name  ${project_input}
echo ""
echo ""
echo "Please enter the version number from the existing versions"
read version_number
echo "Working on: $project_input"
echo "Version Number: $version_number"
source /home/xdeploy/awsenv/awsenv.sh
echo ""
echo ""
aws --profile svc_primary_xbo lambda list-aliases --function-name ${project_input}
    aliasprod=$((aws --profile svc_primary_xbo lambda list-aliases --function-name ${project_input}) 2>&1)
    matchalias='"Name": "PROD"'
            if [[ $aliasprod == *"$matchalias"* ]]; then
            echo " "
            echo "$project_input contains PROD alias"
            echo "Updating the PROD alias of $project_input"
            aws --profile svc_primary_xbo lambda update-alias --function-name ${project_input} --name PROD --function-version "${version_number}"
            else
            echo "$project_input DOESN'T contain PROD alias"
            echo " "
            echo "Creating a PROD alias for $project_input now!"
            aws --profile svc_primary_xbo lambda create-alias --function-name ${project_input} --name PROD --function-version "${version_number}"
            fi          
    else
        echo " "
        echo "Function: $project_input has NOT been found"
        echo " "
        echo "Please make sure that the input matches the service name exactly as it is stored. It is Case-Sensitive too!"
        echo "For example: XBOAccountProduct, XBOGetAccount, XBOGetDevice, XBOModelUpdate, XBOMoveDevices, XBONotificationHandler"
        echo " "
        echo "Exiting. Please run the 'prod_deploy.sh' again"
    fi
else
    echo " "
    echo "You have entered nothing or white spaces. Please enter a valid service name!"
    echo " "
    echo "Please make sure that the input matches the service name exactly as it is stored. It is Case-Sensitive too!"
    echo "For example: XBOAccountProduct, XBOGetAccount, XBOGetDevice, XBOModelUpdate, XBOMoveDevices, XBONotificationHandler"
    echo " "
    echo "Exiting. Please run the 'prod_deploy.sh' again"   
fi