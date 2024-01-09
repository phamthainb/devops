#!/bin/bash

set -e

# Add the PostgreSQL 12 repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package manager
sudo apt-get update

if ! which openssl >/dev/null 2>&1; then
echo "OpenSSL not found. Installing OpenSSL..."
sudo apt-get update
sudo apt-get install openssl -y
fi

# Install PostgreSQL 12
sudo apt-get install postgresql-12 -y

# Create roles
ADMIN_PASSWORD=$(openssl rand -base64 12)
sudo -i -u postgres psql -c "CREATE ROLE admin WITH LOGIN PASSWORD '${ADMIN_PASSWORD}'  SUPERUSER;"

BACKEND_PASSWORD=$(openssl rand -base64 12)
sudo -i -u postgres psql -c "CREATE ROLE backend WITH LOGIN PASSWORD '${BACKEND_PASSWORD}' SUPERUSER;"

DEV_PASSWORD=$(openssl rand -base64 12)
sudo -i -u postgres psql -c "CREATE ROLE dev_readonly WITH LOGIN PASSWORD '${DEV_PASSWORD}' NOSUPERUSER;"

# Create database
sudo -i -u postgres psql -c "CREATE DATABASE dbMain WITH ENCODING='UTF8' LC_CTYPE='en_US.UTF-8' LC_COLLATE='en_US.UTF-8' OWNER=backend TEMPLATE=template0 CONNECTION LIMIT=-1;"

# Grant permissions
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dbMain TO admin, backend;"
sudo -i -u postgres psql -c "GRANT CONNECT ON DATABASE dbMain TO dev_readonly;"
sudo -i -u postgres psql -c "GRANT USAGE ON SCHEMA public TO dev_readonly;"
sudo -i -u postgres psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO dev_readonly;"

# Restart PostgreSQL for changes to take effect
sudo systemctl restart postgresql


echo "> admin password: ${ADMIN_PASSWORD}"
echo "> backend password: ${BACKEND_PASSWORD}"
echo "> dev_readonly password: ${DEV_PASSWORD}"


