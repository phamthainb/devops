#!/bin/bash

# Update the package list
sudo apt-get update

# Install git
sudo apt-get install git -y

# Install nodejs and npm
sudo apt-get install nodejs npm -y

# Install pm2
sudo npm install -g pm2

# Install Redis
sudo apt-get install redis-server -y

# Install nginx
sudo apt-get install nginx -y

# Enable and start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

sudo systemctl enable redis-server
sudo systemctl start redis-server

# Install netstat
apt install net-tools

# check and install node lts
npm i -g n
n lts

# Output a message to indicate successful installation
echo "Installation of services complete!"
