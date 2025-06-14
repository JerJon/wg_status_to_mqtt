#!/bin/ash

# Function to detect online status (handshake <= 5 minutes ago)
check_status() {
 seconds=$(($(date +%s) - $1))

  if [[ $seconds -lt 300 ]]; then
    echo "On"
  else
    echo "Off"
  fi
}
