#!/bin/ash

# Parse and update values for each peer
update_values() {
  # Extract values for each peer in turn, and publish to MQTT
  while IFS= read -r RESULT; do
    public_key=$(echo $RESULT | awk '{print $2}')
    endpoint_ip=$(echo $RESULT | awk '{print $4}' | cut -d: -f1)
    allowed_ips=$(echo $RESULT | awk '{print $5}')
    latest_handshake=$(echo $RESULT | awk '{print $6}')
    transfer_rx=$(echo $RESULT | awk '{print $7}')
    transfer_tx=$(echo $RESULT | awk '{print $8}')

    echo Obtaining status for $(get_friendly_name $public_key)

    # Send values to state topics
    publish_state_topics $public_key $endpoint_ip $allowed_ips $latest_handshake $((transfer_rx / 1048576)) $((transfer_tx / 1048576))
  done < <(wg show all dump | awk '{if (NF==9) print $0};')
}

# Send autodiscovery messages for each peer
update_autodiscovery() {
  echo Sending MQTT autodiscovery messages

  # Extract public key for each peer in turn, and send autodiscovery messages
  while IFS= read -r RESULT; do
    public_key=$(echo $RESULT | awk '{print $2}')
    mqtt_autodiscovery $public_key
  done < <(wg show all dump | awk '{if (NF==9) print $0};')
}

# Function to detect online status (handshake <= 5 minutes ago)
check_status() {
 seconds=$(($(date +%s) - $1))

  if [[ $seconds -lt 300 ]]; then
    echo "ON"
  else
    echo "OFF"
  fi
}

# Look up public key in friendly name file, return matching name, or md5 hash if no match
get_friendly_name() {
  public_key=$1
  set +e
  f_name=$(awk -v pk=$public_key '{if ($1==pk) print $2}' /config/friendly_names.conf)
  set -e
  if [ -z "${f_name}" ]; then
    echo $public_key | md5sum | cut -d ' ' -f1
  else
    echo $f_name
  fi
}

# Function to create Home Assistant entities via MQTT autodiscovery
mqtt_autodiscovery() {
  PEER_ID=$(echo $1 | md5sum | cut -d ' ' -f1)
  PEER_NAME=$(get_friendly_name $1)
  TOPIC_ROOT=wg_status_to_mqtt/$PEER_ID
  DEVICE_ID=wg_status_to_mqtt_$DEVICE_NAME

#  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${PEER_ID}/name/config" -m \
#    '{
#     "state_topic": "'${TOPIC_ROOT}'",
#     "value_template": "{{ value_json.peer_name }}",
#     "device": {
#      "identifiers": [
#      "'${DEVICE_ID}'"
#      ],
#      "manufacturer": "wg_status_to_mqtt",
#      "model": "Wireguard Status to MQTT",
#      "name": "'${DEVICE_NAME}'",
#      "sw_version": "'${SW_VERSION}'"
#     },
#     "icon": "mdi:identifier",
#     "name": "Name",
#     "qos": "1",
#     "unique_id": "'${PEER_ID}'_name"
#    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${PEER_ID}/endpoint/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.endpoint_ip }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "icon": "mdi:ip-outline",
     "name": "'${PEER_NAME}' Endpoint",
     "qos": "1",
     "unique_id": "'${PEER_ID}'_endpoint"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${PEER_ID}/allowed_ips/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.allowed_ips }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "icon": "mdi:ip",
     "name": "'${PEER_NAME}' IPs",
     "qos": "1",
     "unique_id": "'${PEER_ID}'_allowed_ips"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${PEER_ID}/handshake/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.latest_handshake }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "device_class": "timestamp",
     "icon": "mdi:timeline-clock",
     "name": "'${PEER_NAME}' Handshake",
     "qos": "1",
     "unique_id": "'${PEER_ID}'_handshake"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${PEER_ID}/rx/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.transfer_rx }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "device_class": "data_size",
     "unit_of_measurement": "MB",
     "icon": "mdi:database-arrow-left-outline",
     "name": "'${PEER_NAME}' Rx",
     "qos": "1",
     "unique_id": "'${PEER_ID}'_rx"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${PEER_ID}/tx/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.transfer_tx }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "device_class": "data_size",
     "unit_of_measurement": "MB",
     "icon": "mdi:database-arrow-right-outline",
     "name": "'${PEER_NAME}' Tx",
     "qos": "1",
     "unique_id": "'${PEER_ID}'_tx"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/binary_sensor/${PEER_ID}/online/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.online }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "device_class": "connectivity",
     "icon": "mdi:check-network-outline",
     "name": "'${PEER_NAME}' Online",
     "qos": "1",
     "unique_id": "'${PEER_ID}'_online"
    }'

}

# Function to publish values to MQTT state topics
publish_state_topics(){
  PUBLIC_KEY=$1
  #DEVICE_ID=$(echo $PUBLIC_KEY | md5sum | cut -d ' ' -f1)
  PEER_NAME=$(get_friendly_name $1)
  TOPIC_ROOT=wg_status_to_mqtt/$(echo $PUBLIC_KEY | md5sum | cut -d ' ' -f1)
  ENDPOINT_IP=$2
  ALLOWED_IPS=$3
  LATEST_HANDSHAKE=$(date -d @$4 +'%Y-%m-%d %H:%M:%S+00:00')
  ONLINE=$(check_status $4)
  TRANSFER_RX=$5
  TRANSFER_TX=$6

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${TOPIC_ROOT}" -m \
    '{
      "peer_name": "'${PEER_NAME:=-}'",
      "endpoint_ip": "'${ENDPOINT_IP:=-}'",
      "allowed_ips": "'${ALLOWED_IPS:=-}'",
      "latest_handshake": "'"${LATEST_HANDSHAKE:=-}"'",
      "online": "'${ONLINE:-Off}'",
      "transfer_rx": "'${TRANSFER_RX:=-}'",
      "transfer_tx": "'${TRANSFER_TX:=-}'"
    }'

}