#!/usr/bin/env bash

echo "This script installs Chef on your server (debian/ubuntu)"
echo "Press return key to continue or CTRL-C to abort"
read x

if [ -f /etc/apt/trusted.gpg.d/opscode-keyring.gpg ] then
 sudo rm -f /etc/apt/sources.list.d/opscode.list 
 echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
 sudo mkdir -p /etc/apt/trusted.gpg.d
 sudo mkdir -p /etc/apt/trusted.gpg.d
 gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
 sudo rm -f /etc/apt/trusted.gpg.d/opscode-keyring.gpg
 gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
 sudo apt-get -y update
 sudo apt-get -y install opscode-keyring
fi

sudo apt-get -y upgrade

sudo apt-get -y remove chef chef-server
sudo apt-get -y autoremove
sudo apt-get -y autoclean
sudo rm -rf /etc/chef
sudo apt-get -y install chef chef-server

rm -rf .chef
mkdir -p .chef
cp /etc/chef/validation .chef/
cp /etc/chef/webui.pem .chef/

knife configure -i

