#!/bin/bash
set -e

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
telegram_bot_token="<your_bot_token>"
telegram_chat_id="<your_chat_id>"
telegram_message="Deployment completed!"

curl -s -X POST "https://api.telegram.org/bot$telegram_bot_token/sendMessage" \
     -d chat_id="$telegram_chat_id" \
     -d text="$telegram_message" > /dev/null
