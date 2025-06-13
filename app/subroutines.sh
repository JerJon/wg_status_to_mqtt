#!/bin/ash

# Function to parse the transfer line and convert units to bytes
# Credit: https://gist.github.com/kafeg/51689dcad1b175481d7586d36a2b5af8)
parse_transfer_line() {
  local line="$1"

  # Split the line by spaces and extract the values and units
  local received_value=$(echo "$line" | awk '{print $1}')
  local received_unit=$(echo "$line" | awk '{print $2}')
  local sent_value=$(echo "$line" | awk '{print $3}')
  local sent_unit=$(echo "$line" | awk '{print $4}')

  # Convert received to bytes
  case "$received_unit" in
    "GiB")
      received_bytes=$(echo "$received_value * 1024 * 1024 * 1024" | bc | awk '{print int($1)}')
      ;;
    "MiB")
      received_bytes=$(echo "$received_value * 1024 * 1024" | bc | awk '{print int($1)}')
      ;;
    "TiB")
      received_bytes=$(echo "$received_value * 1024 * 1024 * 1024 * 1024" | bc | awk '{print int($1)}')
      ;;
    "KiB")
      received_bytes=$(echo "$received_value * 1024" | bc | awk '{print int($1)}')
      ;;
    "B")
      received_bytes=$(echo "$received_value" | awk '{print int($1)}')
      ;;
  esac

  # Convert sent to bytes
  case "$sent_unit" in
    "GiB")
       sent_bytes=$(echo "$sent_value * 1024 * 1024 * 1024" | bc | awk '{print int($1)}')
       ;;
    "MiB")
      sent_bytes=$(echo "$sent_value * 1024 * 1024" | bc | awk '{print int($1)}')
      ;;
    "TiB")
      sent_bytes=$(echo "$sent_value * 1024 * 1024 * 1024 * 1024" | bc | awk '{print int($1)}')
      ;;
    "KiB")
      sent_bytes=$(echo "$sent_value * 1024" | bc | awk '{print int($1)}')
      ;;
    "B")
      sent_bytes=$(echo "$sent_value" | awk '{print int($1)}')
      ;;
  esac

  # Print the received and sent bytes
  echo "$received_bytes $sent_bytes"
}
