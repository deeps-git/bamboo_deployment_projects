#!/bin/bash
export bamboo_build_key; export bamboo_gitrepo_name
cd /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}/
git remote rm origin
git remote add origin git@github.comcast.com:xbo/${bamboo_gitrepo_name}.git
git remote -v
git checkout dev
git pull origin dev