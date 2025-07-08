#!/bin/bash

# === CONFIGURATION ===
RTSP_URL="rtsp://admin:grospoulet667@192.168.1.144:554/h264Preview_01_main"
OUTPUT_DIR="/home/jc/dev/wp-local/captures"
VPS_PATH="/usr/local/nginx/html/live/captures"
LAT=48.8566
LON=2.3522

export TZ="Europe/Paris"

# Set default permissions for new files and directories
umask 022

# === GET SUNRISE AND SUNSET TIME WITH API sunrise-sunset.org ===
sun_data=$(curl -s "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0")

sunrise_utc=$(echo "$sun_data" | jq -r '.results.sunrise' | sed 's/T/ /')
sunset_utc=$(echo "$sun_data" | jq -r '.results.sunset' | sed 's/T/ /')

# Convert to local timestamp
sunrise_ts=$(date -u --date="$sunrise_utc" +%s)
sunset_ts=$(date -u --date="$sunset_utc" +%s)
now_ts=$(date +%s)

# === IF ACTUAL TIME IS BETWEEN SUNRISE AND SUNSET, THEN SNAP IMAGE ===
if [[ $now_ts -ge $sunrise_ts && $now_ts -le $sunset_ts ]]; then
    today=$(date +%F)
    mkdir -p "$OUTPUT_DIR/$today"
    filename="image_$(date +%F_%H-%M-%S).jpg"
    output="$OUTPUT_DIR/$today/$filename"

    ffmpeg -y -rtsp_transport tcp -i "$RTSP_URL" -frames:v 1 -q:v 20 "$output"
else
    echo "🌙 Night detected, no image."
fi

# === CREATE DIRECTORY ON VPS ===
ssh -i ~/.ssh/id_ed25519_nopass vps "mkdir -p $VPS_PATH/$today && chown jc:jc $VPS_PATH/$today && chmod 755 $VPS_PATH/$today"

# === TRANSFER IMAGE ON VPS ===
scp -i ~/.ssh/id_ed25519_nopass "$output" vps:$VPS_PATH/$today/

echo "✅ Image created and transfered : $filename"