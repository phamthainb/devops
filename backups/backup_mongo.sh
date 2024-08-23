#!/bin/bash

# Variables
MONGO_URI="mongodb://xx:x@127.0.0.1:27017/xx?directConnection=true&authSource=admin"
MONGO_DATABASE="xx"
DUMP_DIR="/opt/dump_db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ZIP_FILE="$DUMP_DIR/$MONGO_DATABASE-$TIMESTAMP.zip"
TELEGRAM_BOT_TOKEN="xx:xx"
CHAT_ID="-xxx"

# Dump the MongoDB database
echo "Dumping MongoDB database: $MONGO_DATABASE"
mongodump --uri="$MONGO_URI" --db=$MONGO_DATABASE --out=$DUMP_DIR

# Zip the dump folder

echo "Zipping the dump directory..."
zip -r "$ZIP_FILE" "$DUMP_DIR/$MONGO_DATABASE"

# Send the ZIP file to Telegram
echo "Sending ZIP file to Telegram..."

curl --http1.1 -4 -s -S -L -w"\n" -o- \
    -F document=@"$ZIP_FILE" \
    -F caption="${MONGO_DATABASE} ${TIMESTAMP}" \
    -F chat_id="${CHAT_ID}" \
    -X POST https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument

# Clean up
echo "Cleaning up..."
rm -rf "$DUMP_DIR/$MONGO_DATABASE"
rm -rf "$ZIP_FILE"

echo "Done!"
