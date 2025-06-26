#!/bin/bash

# One-time script to fix permissions for all existing captures
# Run this on the VPS to fix permissions for all existing images

CAPTURES_DIR="/usr/local/nginx/html/live/captures"
TARGET_USER="jc"
TARGET_GROUP="jc"

echo "Fixing permissions and ownershipfor all existing captures..."

# Make sure the target user owns the entire captures directory
chown -R "$TARGET_USER:$TARGET_GROUP" "$CAPTURES_DIR"

# Find all JPG files in captures directory and fix permissions
find "$CAPTURES_DIR" -name "*.jpg" -type f -exec chmod 644 {} \;

# Find all index.txt files and fix permissions
find "$CAPTURES_DIR" -name "index.txt" -type f -exec chmod 644 {} \;

# Make sure directories are accessible
find "$CAPTURES_DIR" -type d -exec chmod 755 {} \;

echo "Permissions and ownership fixed for all existing files!"

# Show summary
echo "Summary:"
echo "Directories: $(find "$CAPTURES_DIR" -type d | wc -l)"
echo "JPG files: $(find "$CAPTURES_DIR" -name "*.jpg" -type f | wc -l)"
echo "Index files: $(find "$CAPTURES_DIR" -name "index.txt" -type f | wc -l)"

# Verify ownership
echo ""
echo "Directory ownership:"
ls -ld "$CAPTURES_DIR"