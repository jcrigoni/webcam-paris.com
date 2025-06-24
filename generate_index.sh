#!/bin/bash

# Script to generate index.txt files for each day's captures
# This should be run on the VPS to create directory listings for the web gallery

CAPTURES_DIR="/usr/local/nginx/html/live/captures"

# Get today's date
TODAY=$(date +%Y-%m-%d)
TODAY_DIR="$CAPTURES_DIR/$TODAY"

# Check if today's directory exists
if [ -d "$TODAY_DIR" ]; then
    echo "Generating index for $TODAY_DIR"
    
    # Generate index.txt with list of JPG files
    ls -1 "$TODAY_DIR"/*.jpg 2>/dev/null | xargs -n1 basename > "$TODAY_DIR/index.txt"
    
    # Count files
    COUNT=$(wc -l < "$TODAY_DIR/index.txt" 2>/dev/null || echo "0")
    echo "Generated index.txt with $COUNT images"
    
    # Set proper permissions
    chmod 644 "$TODAY_DIR/index.txt"
else
    echo "Today's directory $TODAY_DIR does not exist yet"
fi

# Also clean up old index files (older than 2 days)
find "$CAPTURES_DIR" -name "index.txt" -type f -mtime +2 -delete 2>/dev/null
echo "Cleaned up old index files"