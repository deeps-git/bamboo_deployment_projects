#!/bin/bash
echo "Please note that running this script requires you to have -PreProd already deployed!"
echo "Please enter the service name with the extension -PreProd, for eg. XBOCoastTransfers-PreProd, that you want to deploy to PROD: "
read project_input
echo "You have entered: $project_input"
echo ""
echo ""
declare -a region_array=("us-east-1" "us-west-1")
for region_array_element in "${region_array[@]}"
do
if [ -n "${project_input// }" ]; then
        echo
                aws --profile svc_primary_xbo lambda list-versions-by-function --function-name  ${project_input}
                echo ""
                echo ""
                echo "Working on: $project_input"
                echo ""
                echo "In Region $region_array_element"
                source /home/xdeploy/awsenv/awsenv.sh
                echo ""
                echo ""
                errstring='ResourceNotFoundException'; errstring2='ResourceConflictException';
                funcoutput=$((aws lambda get-function --region ${region_array_element} --function-name ${project_input} --qualifier \$LATEST) 2>&1)
                echo $funcoutput > /tmp/propfile.txt
                if [[ $funcoutput == *"$errstring"* ]]; then
                echo "Function has NOT been found."
                echo "Please enter the right project name"; echo "Exiting!"
                exit;
                        else
                        echo "Function has been found"
                        templink=$(cat /tmp/propfile.txt | awk -F '"Location":' '{print $2}' | awk -F '"' '{print $2}')
                        echo "Here is the link $templink"
                        echo "Downloading the .zip file for the project: $project_input for region $region_array_element"; echo " ";
                        wget -O ${project_input}.zip "$templink"; echo "The .zip has been downloaded"; echo " ";
                        awsfunctionname=$(cat /tmp/propfile.txt | awk -F '"FunctionName":' '{print $2}' | awk -F '"' '{print $2}' | sed -e 's,-Pre,-,g')
                        echo "awsfunctionname: $awsfunctionname"
        				awsruntime=$(cat /tmp/propfile.txt | awk -F '"Runtime":' '{print $2}' | awk -F '"' '{print $2}')
        				echo "awsruntime: $awsruntime"
        				awshandler=$(cat /tmp/propfile.txt | awk -F '"Handler":' '{print $2}' | awk -F '"' '{print $2}')
        				echo "awshandler: $awshandler"
        				awsmemsize=$(cat /tmp/propfile.txt | awk -F '"MemorySize":' '{print $2}' | awk -F ',' '{print $1}')
        				echo "awsmemsize: $awsmemsize"
        				awstimeout=$(cat /tmp/propfile.txt | awk -F '"Timeout": ' '{print $2}' | awk -F ',' ' {print $1}')
        				echo "awstimeout: $awstimeout"
        				awsdescription=$(cat /tmp/propfile.txt | awk -F '"Description":' '{print $2}' | awk -F '"' '{print $2}')
        				echo "awsdescription: $awsdescription"
        				awsrole=$(cat /tmp/propfile.txt | awk -F '"Role":' '{print $2}' | awk -F '"' '{print $2}')
        				echo "awsrole: $awsrole"; echo " ";
        				
                        funcoutput2=$((aws lambda get-function --region ${region_array_element} --function-name ${awsfunctionname} --qualifier \$LATEST) 2>&1)
                        if [[ $funcoutput2 == *"$errstring"* ]]; then
                            echo "Function has NOT been found for $awsfunctionname"
                            echo "Creating PROD function now for $project_input for region $region_array_element"; echo " ";
                            aws lambda create-function --region ${region_array_element} --function-name ${awsfunctionname} --runtime $awsruntime --role $awsrole --handler $awshandler --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription" --zip-file "fileb://${project_input}.zip"
                            echo "Creating Alias for $awsfunctionname"; echo " ";
                            aws --profile svc_primary_xbo lambda create-alias --function-name $awsfunctionname --name PROD --function-version "\$LATEST"
                        else             
                            echo "Function $awsfunctionname already exists"; echo ""; echo "UPDATING the function $awsfunctionname now!";
                            aws lambda update-function-code --region ${region_array_element} --function-name ${awsfunctionname} --zip-file "fileb://${project_input}.zip"
                            aws lambda update-function-configuration --region ${region_array_element} --function-name ${awsfunctionname} --runtime $awsruntime --role $awsrole --handler $awshandler --memory-size $awsmemsize --timeout $awstimeout --description "$awsdescription"
                            echo "UPDATING the PROD alias now"
                            aws --profile svc_primary_xbo lambda update-alias --function-name $awsfunctionname --name PROD
                        fi
                fi
                echo ""
                echo "Cleaning"; rm ${project_input}.zip;
                echo ""; echo "Finished deploying";
else
    echo " "
    echo "You have entered nothing or white spaces. Please enter a valid service name!"
    echo " "
    echo "Please make sure that the input matches the service name exactly as it is stored. It is Case-Sensitive too!"
    echo "For example: XBOAccountProduct, XBOGetAccount, XBOGetDevice, XBOModelUpdate, XBOMoveDevices, XBONotificationHandler"
    echo " "
    echo "Exiting. Please run the 'prod_deploy.sh' again"; exit; 
fi
done
