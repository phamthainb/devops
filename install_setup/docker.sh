#!/bin/bash

# Update package index
sudo apt-get update

# Install packages to allow apt to use a repository over HTTPS
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository to APT sources
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update package index again to include Docker repository
sudo apt-get update

# Install the latest version of Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add current user to the Docker group
sudo usermod -aG docker $USER

# Enable Docker service on system boot
sudo systemctl enable docker

# Verify Docker installation by running the hello-world container
sudo docker run hello-world
