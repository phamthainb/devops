#!/bin/bash

# Set domain name
DOMAIN_NAME="example.com"

# Allow incoming traffic on port 80 from the specified domain and its subdomains
ufw allow from $DOMAIN_NAME to any port 80
ufw allow from *.$DOMAIN_NAME to any port 80

# Block all other incoming traffic on port 80
ufw deny 80/tcp

# Reload ufw to apply changes
ufw reload
