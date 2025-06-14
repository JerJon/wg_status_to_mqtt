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
  DEVICE_ID=$(echo $1 | md5sum | cut -d ' ' -f1)
  DEVICE_NAME=$(get_friendly_name $1)
  TOPIC_ROOT=wg_status_to_mqtt/$DEVICE_ID

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${DEVICE_ID}/name/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'",
     "value_template": "{{ value_json.device_name }}",
     "device": {
      "identifiers": [
      "'${DEVICE_ID}'"
      ],
      "manufacturer": "wg_status_to_mqtt",
      "model": "Wireguard Status to MQTT",
      "name": "'${DEVICE_NAME}'",
      "sw_version": "'${SW_VERSION}'"
     },
     "device_class": "None",
     "icon": "mdi:identifier",
     "name": "Name",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_name"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${DEVICE_ID}/endpoint/config" -m \
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
     "device_class": "None",
     "icon": "mdi:ip-outline",
     "name": "Endpoint IP",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_endpoint"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${DEVICE_ID}/allowed_ips/config" -m \
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
     "device_class": "None",
     "icon": "mdi:ip",
     "name": "Allowed IPs",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_allowed_ips"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${DEVICE_ID}/handshake/config" -m \
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
     "icon": "mdi:timeline-clock",
     "name": "Latest Handshake",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_handshake"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${DEVICE_ID}/rx/config" -m \
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
     "name": "Data Received",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_rx"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/sensor/${DEVICE_ID}/tx/config" -m \
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
     "name": "Data Transmitted",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_tx"
    }'

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "homeassistant/binary_sensor/${DEVICE_ID}/online/config" -m \
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
     "name": "Online",
     "qos": "1",
     "unique_id": "'${DEVICE_ID}'_online"
    }'

}

# Function to publish values to MQTT state topics
publish_state_topics(){
  PUBLIC_KEY=$1
  DEVICE_ID=$(echo $PUBLIC_KEY | md5sum | cut -d ' ' -f1)
  DEVICE_NAME=$(get_friendly_name $1)
  TOPIC_ROOT=wg_status_to_mqtt/$DEVICE_ID
  ENDPOINT_IP=$2
  ALLOWED_IPS=$3
  LATEST_HANDSHAKE=$4
  ONLINE=$(check_status $LATEST_HANDSHAKE)
  TRANSFER_RX=$5
  TRANSFER_TX=$6

  mosquitto_pub -h $MQTT_IP -p $MQTT_PORT -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${TOPIC_ROOT}" -m \
    '{
      "device_name": "'${DEVICE_NAME:=-}'",
      "endpoint_ip": "'${ENDPOINT_IP:=-}'",
      "allowed_ips": "'${ALLOWED_IPS:=-}'",
      "latest_handshake": "'${LATEST_HANDSHAKE:=-}'",
      "online": "'${ONLINE:-Off}'",
      "transfer_rx": "'${TRANSFER_RX:=-}'",
      "transfer_tx": "'${TRANSFER_TX:=-}'"
    }'

}