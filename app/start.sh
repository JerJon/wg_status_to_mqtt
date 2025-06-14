#!/bin/ash

echo Starting wg_status_to_mqtt container....

# Load subroutines
. /app/version.sh
. /app/subroutines.sh

# Export environment setting defaults if not defined
export MQTT_IP=${MQTT_IP:-localhost}
export MQTT_USERNAME=${MQTT_USERNAME:-}
export MQTT_PASSWORD=${MQTT_PASSWORD:-}

echo "Configuration options are:
  MQTT_IP=$MQTT_IP
  MQTT_USERNAME=$MQTT_USERNAME
  MQTT_PASSWORD=Not Shown"

# Read Wireguard status using wg command (use show subcommand with dump option)
# Extract values for each peer in turn
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
  echo status $(check_status $latest_handshake)
  echo transfer_rx $transfer_rx
  echo transfer_tx $transfer_tx

  # Create Home Assistant entities for the peer using MQTT autodiscovery
  mqtt_autodiscovery $public_key_hash

done < <(wg show all dump | awk '{if (NF==9) print $0};')
