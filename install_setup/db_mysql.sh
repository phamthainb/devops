#!/bin/bash

set -e

# Update package list and install MySQL server
echo "Updating package list..."
sudo apt update -y

echo "Installing MySQL server..."
sudo apt install mysql-server -y

# Secure MySQL installation (automated)
echo "Securing MySQL installation..."
sudo mysql --user=root <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Enable and start MySQL service
echo "Enabling and starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql

# Generate secure passwords
ADMIN_PASSWORD=$(openssl rand -base64 12)
BACKEND_PASSWORD=$(openssl rand -base64 12)
DEV_PASSWORD=$(openssl rand -base64 12)

# Create roles and database
echo "Creating database and users..."
sudo mysql --user=root <<EOF
CREATE DATABASE dbMain CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'admin'@'localhost' IDENTIFIED BY '${ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;

CREATE USER 'backend'@'localhost' IDENTIFIED BY '${BACKEND_PASSWORD}';
GRANT ALL PRIVILEGES ON dbMain.* TO 'backend'@'localhost';

CREATE USER 'dev_readonly'@'localhost' IDENTIFIED BY '${DEV_PASSWORD}';
GRANT SELECT ON dbMain.* TO 'dev_readonly'@'localhost';

FLUSH PRIVILEGES;
EOF

echo "Restarting MySQL for changes to take effect..."
sudo systemctl restart mysql

# Output generated passwords
echo "> admin password: ${ADMIN_PASSWORD}"
echo "> backend password: ${BACKEND_PASSWORD}"
echo "> dev_readonly password: ${DEV_PASSWORD}"
