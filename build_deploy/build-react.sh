#!/bin/bash
set -e

# Load variables from config file
source config.sh

should_npm_install=false
# Check if package.json has changed
if git diff origin/$(git rev-parse --abbrev-ref HEAD) HEAD --name-only | grep -q 'package.json'; then
  echo "Package.json has changed. Running npm install..."
  should_npm_install=true
fi

# Pull the latest changes from git
git pull
echo "Git pull done!"

# check should_npm_install 
if [ "$should_npm_install" = true ]; then
  npm install
fi

# Build the React app
echo "Building React app..."
npm run build

# Deploy the app to web server directory
echo "Deploying to web server directory..."
rm -rf /var/www/player/html/*
cp -r dist/* /var/www/player/html

echo "Done!"


# Send a message to the Telegram bot
telegram_message="Deployment completed! Version: $APP_VERSION"
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
     -d chat_id="$TELEGRAM_CHAT_ID" \
     -d text="$telegram_message" > /dev/null
