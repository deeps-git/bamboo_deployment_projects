#!/bin/bash
export bamboo_build_key
cd /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}/
cat settings.gradle | grep "include" settings.gradle | grep -v "//" | sed 's/include//g' | sed "s/'//g"