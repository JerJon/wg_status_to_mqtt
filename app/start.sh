#!/bin/ash
set -e

echo Starting wg_status_to_mqtt container....
echo Iain Bullock June 2025
echo https://github.com/iainbullock/wg_status_to_mqtt

# Load subroutines
. /app/version.sh
. /app/subroutines.sh

# Export environment setting defaults if not defined
export MQTT_IP=${MQTT_IP:-127.0.0.1}
export MQTT_PORT=${MQTT_PORT:-1883}
export MQTT_USERNAME=${MQTT_USERNAME:-user}
export MQTT_PASSWORD=${MQTT_PASSWORD:-pass}

echo "Configuration options are:
  MQTT_IP=$MQTT_IP
  MQTT_PORT=$MQTT_PORT
  MQTT_USERNAME=$MQTT_USERNAME
  MQTT_PASSWORD=Not Shown"

# Read Wireguard status using wg command (use show subcommand with dump option)
# Extract values for each peer in turn
while IFS= read -r RESULT; do
  public_key=$(echo $RESULT | awk '{print $2}')
  endpoint_ip=$(echo $RESULT | awk '{print $4}' | cut -d: -f1)
  allowed_ips=$(echo $RESULT | awk '{print $5}')
  latest_handshake=$(echo $RESULT | awk '{print $6}')
  transfer_rx=$(echo $RESULT | awk '{print $7}')
  transfer_tx=$(echo $RESULT | awk '{print $8}')

  echo Obtaining status for $(get_friendly_name $public_key)
  #echo public_key $public_key
  #echo endpoint_ip $endpoint_ip
  #echo allowed_ips $allowed_ips
  #echo latest_handshake $latest_handshake
  #echo status $(check_status $latest_handshake)
  #echo transfer_rx $transfer_rx
  #echo transfer_tx $transfer_tx

  # Create Home Assistant entities for the peer using MQTT autodiscovery
  mqtt_autodiscovery $public_key

  # Send values to state topics
  publish_state_topics $public_key $endpoint_ip $allowed_ips $latest_handshake $transfer_rx $transfer_tx
done < <(wg show all dump | awk '{if (NF==9) print $0};')
