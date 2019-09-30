#!/bin/bash

echo "Enter build key"; read bamboo_build_key
echo "Enter scrip key"; read bamboo_script_key
echo "Enter Repo name"; read bamboo_gitrepo_name
cd /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}/
shopt -s dotglob
sudo rm -r *
git clone git@github.comcast.com:CRPL/${bamboo_gitrepo_name}.git /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_build_key}
git pull origin dev
git show-ref | head -3
cd /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_script_key}/
shopt -s dotglob
sudo rm -r *
git clone git@github.comcast.com:CRPL/${bamboo_gitrepo_name}.git /opt/home/xdeploy/bamboo-agent-home/xml-data/build-dir/${bamboo_script_key}
git pull origin dev
git show-ref | head -3



#git remote rm origin
#git remote add origin git@github.comcast.com:CRPL/${bamboo_gitrepo_name}.git
#git remote -v
#git checkout dev
#git pull origin dev
