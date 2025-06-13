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
while IFS= read -r RESULT
do
    WG=$(wg)
    IP=$(echo $WG | grep -A 4 $RESULT | grep 'endpoint' | sed s'/endpoint://' | sed -e 's/^[[:space:]]*//')
    LASTSEEN=$(echo $WG | grep -A 4 $RESULT | grep 'latest' | sed s'/latest handshake://' | sed -e 's/^[[:space:]]*//')
    DATA=$(echo $WG | grep -A 4 $RESULT | grep 'transfer' | sed s'/transfer://' | sed -e 's/^[[:space:]]*//')
    PEER_ID_CLEAN=$(echo $RESULT | tr -d '+#/=,')

    FINAL='{"Client":"'"$PEER_ID_CLEAN"'","IP":"'"$IP"'","Last Seen":"'"$LASTSEEN"'","Data":"'"$DATA"'"}'

    echo WG $WG
    echo IP $IP
    echo LASTSEEN $LASTSEEN
    echo DATA $DATA
    echo PEER_ID_CLEAN $PEER_ID_CLEAN
    echo FINAL $FINAL

done < <(wg | grep peer: | cut -d" " -f2)