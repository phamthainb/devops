#!/bin/bash
set -e

# check update
apt update
apt install dirmngr gnupg apt-transport-https ca-certificates software-properties-common

# Import the MongoDB public key
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

# Create a MongoDB list file
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

# Update the package list and install MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Check the status of MongoDB
sudo systemctl status mongod
