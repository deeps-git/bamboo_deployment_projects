#!/bin/bash

string=`cat projectnames.txt`
IFS=', ' read -r -a array <<< "$string"
for element in "${array[@]}"
do
    echo "$element"
done