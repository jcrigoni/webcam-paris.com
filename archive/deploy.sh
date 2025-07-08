#!/bin/bash

# Paris Webcam - Local Deployment Script
# Run this from your local machine to deploy changes to VPS

# Configuration - UPDATE THESE VALUES
VPS_HOST="your-vps-hostname-or-ip"
VPS_USER="your-username"
VPS_PATH="/usr/local/nginx/html/live"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "index.html" ] || [ ! -f "app.js" ] || [ ! -f "styles.css" ]; then
    print_error "Please run this script from the webcam-paris.com project directory"
    exit 1
fi

print_status "Starting deployment to ${VPS_HOST}..."

# Check if VPS configuration is set
if [ "$VPS_HOST" = "your-vps-hostname-or-ip" ]; then
    print_error "Please update VPS_HOST in this script with your actual VPS hostname or IP"
    exit 1
fi

# Sync website files
print_status "Syncing website files..."
rsync -avz --progress \
    --exclude="*.md" \
    --exclude="deploy.sh" \
    --exclude="crontab-entries.txt" \
    --exclude=".git" \
    index.html app.js styles.css \
    "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/"

if [ $? -eq 0 ]; then
    print_status "Website files synced successfully"
else
    print_error "Failed to sync website files"
    exit 1
fi

# Sync shell scripts
print_status "Syncing shell scripts..."
rsync -avz --progress \
    gallery-generator.sh monthly-zip.sh \
    "${VPS_USER}@${VPS_HOST}:${VPS_PATH}/"

if [ $? -eq 0 ]; then
    print_status "Shell scripts synced successfully"
else
    print_error "Failed to sync shell scripts"
    exit 1
fi

# Make scripts executable on VPS
print_status "Making scripts executable on VPS..."
ssh "${VPS_USER}@${VPS_HOST}" "chmod +x ${VPS_PATH}/gallery-generator.sh ${VPS_PATH}/monthly-zip.sh"

if [ $? -eq 0 ]; then
    print_status "Scripts made executable"
else
    print_warning "Failed to make scripts executable - you may need to do this manually"
fi

# Create required directories
print_status "Creating required directories on VPS..."
ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ${VPS_PATH}/downloads ${VPS_PATH}/logs && chmod 755 ${VPS_PATH}/downloads"

if [ $? -eq 0 ]; then
    print_status "Directories created"
else
    print_warning "Failed to create directories - you may need to do this manually"
fi

# Test gallery generation
print_status "Testing gallery generation..."
ssh "${VPS_USER}@${VPS_HOST}" "cd ${VPS_PATH} && ./gallery-generator.sh"

if [ $? -eq 0 ]; then
    print_status "Gallery generation test successful"
    
    # Check if gallery file exists
    ssh "${VPS_USER}@${VPS_HOST}" "ls -la ${VPS_PATH}/gallery-today.html" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_status "gallery-today.html created successfully"
    else
        print_warning "gallery-today.html not found after generation"
    fi
else
    print_warning "Gallery generation test failed - check logs on VPS"
fi

print_status "Deployment completed!"
print_status ""
print_status "Next steps:"
print_status "1. Add crontab entries on VPS (see crontab-entries.txt)"
print_status "2. Test the website: https://your-domain.com"
print_status "3. Test gallery: https://your-domain.com/#gallery"
print_status "4. Monitor logs: tail -f ${VPS_PATH}/logs/*.log"
print_status ""
print_warning "Remember to update crontab entries on VPS!"
print_status "Run: sudo crontab -e"
print_status "Add entries from: crontab-entries.txt"