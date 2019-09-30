#!/bin/bash

./gitpull.sh
./pnameprocess.sh > projectnames.txt
echo "Project names have been parsed from GIT repo and each project name will be saved to an array"
echo ""
echo ""
echo "Running storevar.sh now"
echo ""
echo ""
echo "Following are the projects:"
echo ""
./storevar.sh
echo ""
echo ""
echo "Pushing that to AWS Lambda now!"
echo ""
echo ""
./devdeploy.sh
echo ""
echo ""
