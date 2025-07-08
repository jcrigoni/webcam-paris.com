#!/bin/bash

# Update Historical Galleries Script for Paris Webcam
# Generates gallery pages for recent dates with images
# This script should be run every 10 minutes alongside the existing cron jobs

# Configuration
CAPTURES_DIR="${CAPTURES_DIR:-/usr/local/nginx/html/live/captures}"
GALLERIES_DIR="${GALLERIES_DIR:-/usr/local/nginx/html/live/html-galleries}"
SCRIPT_DIR="${SCRIPT_DIR:-/usr/local/nginx/html/live}"
HISTORICAL_GENERATOR="${SCRIPT_DIR}/historical-gallery-generator.sh"

# Create directories if they don't exist
mkdir -p "${GALLERIES_DIR}"

# Check if the historical generator script exists
if [ ! -f "${HISTORICAL_GENERATOR}" ]; then
    echo "Error: Historical gallery generator script not found at ${HISTORICAL_GENERATOR}"
    exit 1
fi

# Function to convert date to hierarchical path (YYYY-MM-DD -> YYYY/MM/DD)
date_to_path() {
    local date="$1"
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2)
    local day=$(echo "$date" | cut -d'-' -f3)
    echo "$year/$month/$day"
}

# Function to get list of dates with captures in the last 7 days
get_recent_dates_with_captures() {
    local today=$(date +%Y-%m-%d)
    local dates_with_captures=()
    
    # Check last 7 days
    for i in {0..6}; do
        local check_date=$(date -d "$today - $i days" +%Y-%m-%d)
        local date_path=$(date_to_path "$check_date")
        local captures_dir="${CAPTURES_DIR}/${date_path}"
        
        if [ -d "$captures_dir" ]; then
            # Check if directory has JPG files
            if [ "$(find "$captures_dir" -name "*.jpg" -type f | wc -l)" -gt 0 ]; then
                dates_with_captures+=("$check_date")
            fi
        fi
    done
    
    echo "${dates_with_captures[@]}"
}

# Function to check if gallery file needs updating
needs_update() {
    local date="$1"
    local date_path=$(date_to_path "$date")
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2)
    local gallery_file="${GALLERIES_DIR}/${year}/${month}/gallery-${date}.html"
    local captures_dir="${CAPTURES_DIR}/${date_path}"
    
    # If gallery file doesn't exist, we need to create it
    if [ ! -f "$gallery_file" ]; then
        return 0
    fi
    
    # Check if any image files are newer than the gallery file
    if [ -d "$captures_dir" ]; then
        # Find the newest image file
        local newest_image=$(find "$captures_dir" -name "*.jpg" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ -n "$newest_image" ] && [ "$newest_image" -nt "$gallery_file" ]; then
            return 0
        fi
        
        # Also check if index.txt is newer
        local index_file="${captures_dir}/index.txt"
        if [ -f "$index_file" ] && [ "$index_file" -nt "$gallery_file" ]; then
            return 0
        fi
    fi
    
    return 1
}

# Main execution
echo "$(date): Starting historical gallery update..."

# Get dates with captures
recent_dates=($(get_recent_dates_with_captures))

if [ ${#recent_dates[@]} -eq 0 ]; then
    echo "$(date): No recent dates with captures found"
    exit 0
fi

echo "$(date): Found ${#recent_dates[@]} recent dates with captures: ${recent_dates[*]}"

# Update galleries for dates that need it
updated_count=0
for date in "${recent_dates[@]}"; do
    if needs_update "$date"; then
        echo "$(date): Updating gallery for $date..."
        
        # Export environment variables for the historical generator
        export CAPTURES_DIR GALLERIES_DIR
        
        # Run the historical generator for this specific date
        if "$HISTORICAL_GENERATOR" "$date"; then
            echo "$(date): Successfully updated gallery for $date"
            updated_count=$((updated_count + 1))
        else
            echo "$(date): Failed to update gallery for $date"
        fi
    else
        echo "$(date): Gallery for $date is up to date"
    fi
done

echo "$(date): Historical gallery update complete. Updated $updated_count galleries."

# Optional: Clean up old gallery files (keep last 30 days)
echo "$(date): Cleaning up old gallery files..."
find "${GALLERIES_DIR}" -name "gallery-*.html" -mtime +30 -delete 2>/dev/null || true

echo "$(date): Historical gallery update finished successfully"