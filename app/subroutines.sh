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

# Function to create Home Assistant entities via MQTT autodiscovery
mqtt_autodiscovery() {
  DEVICE_ID=$1

  mosquitto_pub -h $MQTT_IP -u $MQTT_USERNAME -P $MQTT_PASSWORD -t "homeassistant/binary_sensor/${DEVICE_ID}/online/config" -m \
    '{
     "state_topic": "'${TOPIC_ROOT}'/binary_sensor/online",
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