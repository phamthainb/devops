#!/bin/bash

# Set the swap file size in gigabytes
swap_file_size=2

# Create a swap file
sudo fallocate -l ${swap_file_size}G /swapfile

# Set the correct permissions on the swap file
sudo chmod 600 /swapfile

# Format the swap file as swap space
sudo mkswap /swapfile

# Activate the swap file immediately
sudo swapon /swapfile

# Make the swap file permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
