#!/usr/bin/env bash

function copyConfig () {
    if [ -f ${1} ] && [ -f ${2} ]; then
            echo "${1} & ${2} exist and are ready for swapping"
            cat ${1} > ${2}
            echo "config/${1} has been swapped with ${2}"
        else
            echo "The files $1 & $2 do NOT exist! Hence, NO swapping has been done"
    fi
    }

function decrypt () {
        for file in `find ${TMP_DIR}/unzipf/config  -type f | grep .gpg`
        do
                outputFile=${file%.gpg}
                echo "Printing outputFile - $outputFile"
                echo "decrypting $file"
                gpg --homedir ~/xbo/.xbo_gnupg --decrypt $file > ${TMP_DIR}/unzipf/config/$outputFile
                echo "Deleting $file"
                [ -f "$file" ] && rm "$file" && echo " $file deleted"
                echo "The outputFile is - $outputFile"
        done
        echo "Config files have been decrypted"
        echo "Deleting the gpg files now before zipping the function"
#       sudo rm -rf /tmp/unzipf/config/*.gpg
    }

function    getLogGroupForCloudwatchSubscription () {
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

   function s3upload () {
#                        source /home/xdeploy/awsenv/awsenv.sh
                        echo "/usr/bin/aws s3 cp ${1} ${2} --region ${3}"
                        /usr/bin/aws s3 cp ${1} ${2} --region ${3}
                    }
