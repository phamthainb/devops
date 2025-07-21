#!/bin/bash

set -e

# Get PostgreSQL version from argument or default to 14
PG_VERSION=${1:-14}

echo "========================================="
echo "This script will install PostgreSQL ${PG_VERSION}"
echo "It will also create users: admin, backend, dev_readonly"
echo "and create database: dbMain with privileges"
echo "========================================="

read -p "Do you want to continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# Add PostgreSQL APT repository if not already added
if ! [ -f /etc/apt/sources.list.d/pgdg.list ]; then
  echo "[+] Adding PostgreSQL APT repository"
  sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
fi

# Update package index
echo "[+] Updating package index"
sudo apt-get update

# Install OpenSSL if missing
if ! which openssl >/dev/null 2>&1; then
  echo "[+] Installing OpenSSL..."
  sudo apt-get install -y openssl
fi

# Install PostgreSQL
echo "[+] Installing PostgreSQL ${PG_VERSION}"
sudo apt-get install -y "postgresql-${PG_VERSION}"

# Generate random passwords for roles
ADMIN_PASSWORD=$(openssl rand -base64 12)
BACKEND_PASSWORD=$(openssl rand -base64 12)
DEV_PASSWORD=$(openssl rand -base64 12)

# Create roles and database
echo "[+] Creating roles and database"

sudo -i -u postgres psql <<EOF
CREATE ROLE admin WITH LOGIN PASSWORD '${ADMIN_PASSWORD}' SUPERUSER;
CREATE ROLE backend WITH LOGIN PASSWORD '${BACKEND_PASSWORD}' SUPERUSER;
CREATE ROLE dev_readonly WITH LOGIN PASSWORD '${DEV_PASSWORD}' NOSUPERUSER;

CREATE DATABASE dbMain WITH ENCODING='UTF8' LC_CTYPE='en_US.UTF-8' LC_COLLATE='en_US.UTF-8' OWNER=backend TEMPLATE=template0 CONNECTION LIMIT=-1;

GRANT ALL PRIVILEGES ON DATABASE dbMain TO admin, backend;
GRANT CONNECT ON DATABASE dbMain TO dev_readonly;
GRANT USAGE ON SCHEMA public TO dev_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dev_readonly;
EOF

# Restart PostgreSQL service
echo "[+] Restarting PostgreSQL service"
sudo systemctl restart postgresql

# Display generated credentials
echo ""
echo "====================================="
echo "PostgreSQL ${PG_VERSION} installed successfully"
echo ">> admin password:        ${ADMIN_PASSWORD}"
echo ">> backend password:      ${BACKEND_PASSWORD}"
echo ">> dev_readonly password: ${DEV_PASSWORD}"
echo "====================================="
