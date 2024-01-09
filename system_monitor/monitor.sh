#!/bin/bash

# crontab -e >> * * * * * /path/to/your/script.sh >> /path/to/your/logfile.log 2>&1

TELEGRAM_BOT_TOKEN="xxx"
CHAT_ID="xx"

# list port need monitor
PORT_SERVICES=(
    80:"nginx"
    3000:"web"
)

# disk
THRESHOLD_PERCENT_DISK=95
# cpu
THRESHOLD_PERCENT_CPU=95

# Get the current hostname
HOSTNAME=$(hostname)

# Function to send a message to Telegram
send_telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$1"
}

# Monitor Disk Usage
disk_usage=$(df -h --output=pcent / | awk 'NR==2 {print $1}' | tr -d '%')
if [ "$disk_usage" -ge "$THRESHOLD_PERCENT_DISK" ]; then
    send_telegram_message "[$HOSTNAME] Disk usage is high: $disk_usage%."
fi

# Monitor CPU Load
cpu_load=$(top -bn1 | awk '/^%Cpu/ {print $2}' | cut -d. -f1)
if [ "$cpu_load" -ge "$THRESHOLD_PERCENT_CPU" ]; then
    send_telegram_message "[$HOSTNAME] High CPU load: $cpu_load%."
fi

# Check if multiple ports are down
for port_service in "${PORT_SERVICES[@]}"; do
    IFS=':' read -ra port_info <<< "$port_service"
    port="${port_info[0]}"
    service="${port_info[1]}"

    if ! nc -zv localhost "$port" &> /dev/null; then
        send_telegram_message "[$HOSTNAME] Service $service on port $port is down."
    fi
done

echo "[$(date)] Run done."
