#!/bin/bash

curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
apt-get update
sudo apt-get install -y nodejs git -y python-pip nginx

npm install pm2 -g

dir=/opt/data/app
mkdir -p $dir
cd $dir
git clone https://github.com/roosri/sloth.git .
pm2 start app.js
