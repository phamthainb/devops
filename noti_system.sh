#!/bin/bash

# Set the maximum disk usage percentage
max_disk_usage=90

# Set the maximum memory usage percentage
max_mem_usage=80

# Set the Telegram bot token and chat ID
bot_token="YOUR_TELEGRAM_BOT_TOKEN"
chat_id="YOUR_TELEGRAM_CHAT_ID"

while true; do
  # Get the current disk usage percentage
  disk_usage=$(df -h / | awk '{print $5}' | tail -n1 | tr -d '%')

  # Get the current memory usage percentage
  mem_usage=$(free | awk '/Mem/{printf("%.2f"), $3/$2*100}')

  # Check if the disk usage is above the threshold
  if [ "$disk_usage" -gt "$max_disk_usage" ]; then
    # Send a notification via Telegram
    message="Disk usage is at ${disk_usage}%. Please free up some space."
    curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
      -d chat_id="${chat_id}" \
      -d text="$message"
  fi

  # Check if the memory usage is above the threshold
  if [ "$(printf "%.0f" "$mem_usage")" -gt "$max_mem_usage" ]; then
    # Send a notification via Telegram
    message="Memory usage is at ${mem_usage}%. Please free up some memory."
    curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
      -d chat_id="${chat_id}" \
      -d text="$message"
  fi

  # Wait for 1 minute before checking again
  sleep 60
done
