#!/usr/bin/env bash

echo "This script installs Chef on your server (debian/ubuntu)"
echo "Enter 'none' when prompted for a Chef URL"
echo "Press return key to continue or CTRL-C to abort"
read x

echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
sudo mkdir -p /etc/apt/trusted.gpg.d
sudo mkdir -p /etc/apt/trusted.gpg.d
gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
sudo apt-get -y update
sudo apt-get -y install opscode-keyring
sudo apt-get -y upgrade
sudo apt-get -y install chef

