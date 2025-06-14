#!/bin/ash

# Load subroutines
. /app/subroutines.sh

# Export environment setting defaults if not defined
export MQTT_IP=${MQTT_IP:-localhost}
export MQTT_USERNAME=${MQTT_USERNAME:-}
export MQTT_PASSWORD=${MQTT_PASSWORD:-}

# Main Loop
# Based on credits:
# https://gist.github.com/mehstg/466045bbd0316d7be0a196c1a049477e
# https://gist.github.com/kafeg/51689dcad1b175481d7586d36a2b5af8
while IFS= read -r RESULT; do
  public_key_hash=$(echo $RESULT | awk '{print $2}' | md5sum | cut -d ' ' -f1)
  endpoint_ip=$(echo $RESULT | awk '{print $4}' | cut -d: -f1)
  allowed_ips=$(echo $RESULT | awk '{print $5}')
  latest_handshake=$(echo $RESULT | awk '{print $6}')
  transfer_rx=$(echo $RESULT | awk '{print $7}')
  transfer_tx=$(echo $RESULT | awk '{print $8}')

  echo public_key_hash $public_key_hash
  echo endpoint_ip $endpoint_ip
  echo allowed_ips $allowed_ips
  echo latest_handshake $latest_handshake
  echo transfer_rx $transfer_rx
  echo transfer_tx $transfer_tx

done < <(wg show all dump | awk '{if (NF==9) print $0};')
