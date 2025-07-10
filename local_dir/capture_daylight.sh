#!/bin/bash

# === CONFIGURATION ===
RTSP_URL="rtsp://{camera_ip}/h264Preview_01_main"
OUTPUT_DIR="/home/user/dev/wp-local/captures"
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
    year=$(date +%Y)
    month=$(date +%m)
    day=$(date +%d)
    
    # Create hierarchical directory structure: YYYY/MM/DD
    local_capture_dir="$OUTPUT_DIR/$year/$month/$day"
    mkdir -p "$local_capture_dir"
    
    # Create temporary filename for initial capture
    temp_filename="temp_image_$(date +%F_%H-%M-%S).jpg"
    temp_output="$local_capture_dir/$temp_filename"
    
    # Capture the image
    ffmpeg -y -rtsp_transport tcp -i "$RTSP_URL" -frames:v 1 -q:v 20 "$temp_output"
    
    # Calculate brightness from the center 75% of the image (excluding borders)  Alternative using histogram
    brightness=$(ffmpeg -i "$temp_output" -vf "crop=in_w*0.75:in_h*0.75,format=gray,scale=1:1" -f rawvideo - 2>/dev/null | od -An -tu1 | awk '{print $1}')
    
    # Create final filename with brightness
    filename="image_$(date +%F_%H-%M-%S)_${brightness}.jpg"
    output="$local_capture_dir/$filename"
    
    # Rename to final filename with brightness
    mv "$temp_output" "$output"
    
    echo "📸 Image captured with brightness: $brightness"
else
    echo "🌙 Night detected, no image."
    exit 0
fi

# === CREATE DIRECTORY ON VPS ===
vps_capture_dir="$VPS_PATH/$year/$month/$day"
ssh -i {which_key} vps "mkdir -p $vps_capture_dir && chmod 755 $vps_capture_dir"

# === TRANSFER IMAGE ON VPS ===
scp -i {which_key} "$output" vps:$vps_capture_dir/

echo "✅ Image created and transfered : $filename"
