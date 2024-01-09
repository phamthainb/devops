#!/bin/bash

# Check the current time zone
timedatectl

# List all available time zones
#timedatectl list-timezones

# Set the desired time zone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Verify the new time zone
timedatectl
