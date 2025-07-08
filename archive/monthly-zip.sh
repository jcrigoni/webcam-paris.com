#!/bin/bash

# Monthly ZIP Generator Script for Paris Webcam
# Creates monthly ZIP files of captured images for data scientists
# To be deployed to VPS at /usr/local/nginx/html/live/monthly-zip.sh

# Configuration
CAPTURES_DIR="/usr/local/nginx/html/live/captures"
DOWNLOADS_DIR="/usr/local/nginx/html/live/downloads"
LOG_FILE="/usr/local/nginx/html/live/logs/monthly-zip.log"

# Create directories if they don't exist
mkdir -p "${DOWNLOADS_DIR}"
mkdir -p "$(dirname "${LOG_FILE}")"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

# Function to get previous month in YYYY-MM format
get_previous_month() {
    date -d "last month" '+%Y-%m'
}

# Function to get month name for better naming
get_month_name() {
    local month_code="$1"
    date -d "${month_code}-01" '+%B-%Y'
}

# Function to create ZIP file for a specific month
create_monthly_zip() {
    local month="$1"
    local month_name=$(get_month_name "${month}")
    local zip_filename="captures-${month}.zip"
    local zip_path="${DOWNLOADS_DIR}/${zip_filename}"
    local temp_dir="/tmp/webcam-${month}-$$"
    
    log_message "Starting ZIP creation for ${month} (${month_name})"
    
    # Check if ZIP already exists
    if [ -f "${zip_path}" ]; then
        log_message "ZIP file already exists: ${zip_filename}"
        return 0
    fi
    
    # Find all directories for this month
    local month_dirs=($(find "${CAPTURES_DIR}" -type d -name "${month}-*" | sort))
    
    if [ ${#month_dirs[@]} -eq 0 ]; then
        log_message "No data found for month ${month}"
        return 1
    fi
    
    # Create temporary directory structure
    mkdir -p "${temp_dir}/captures"
    
    local total_images=0
    local total_size=0
    
    # Copy all month directories to temp location
    for dir in "${month_dirs[@]}"; do
        local day_name=$(basename "${dir}")
        local dest_dir="${temp_dir}/captures/${day_name}"
        
        if [ -d "${dir}" ]; then
            mkdir -p "${dest_dir}"
            
            # Copy all JPG files
            local jpg_files=($(find "${dir}" -name "*.jpg" -type f))
            if [ ${#jpg_files[@]} -gt 0 ]; then
                cp "${jpg_files[@]}" "${dest_dir}/" 2>/dev/null || true
                
                # Count images and calculate size
                local day_count=${#jpg_files[@]}
                local day_size=$(du -sb "${dest_dir}" | cut -f1)
                total_images=$((total_images + day_count))
                total_size=$((total_size + day_size))
                
                log_message "  Copied ${day_count} images from ${day_name}"
            fi
        fi
    done
    
    if [ $total_images -eq 0 ]; then
        log_message "No images found for month ${month}"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Create README file
    cat > "${temp_dir}/README.txt" << EOF
Paris Webcam Dataset - ${month_name}
==========================================

This archive contains webcam captures from Paris, France, featuring a view of the Eiffel Tower.

Dataset Information:
- Month: ${month_name}
- Total Images: ${total_images}
- Archive Size: $(numfmt --to=iec ${total_size})
- Capture Frequency: Every 10 minutes during daylight hours (6 AM - 8 PM)
- Image Format: JPEG
- Resolution: Varies (typically 1920x1080 or similar)
- Timezone: Europe/Paris (CET/CEST)

File Structure:
captures/
├── ${month}-01/        # Day 1 of the month
│   ├── image_${month}-01_06-00-00.jpg
│   ├── image_${month}-01_06-10-00.jpg
│   └── ...
├── ${month}-02/        # Day 2 of the month
│   └── ...
└── ...

Filename Format:
image_YYYY-MM-DD_HH-mm-SS.jpg

Where:
- YYYY-MM-DD: Date in ISO format
- HH-mm-SS: Time in 24-hour format (local time)

Usage Notes:
- Images are captured during daylight hours only (approximately 6 AM to 8 PM)
- Weather conditions may affect image quality
- Some days may have fewer images due to technical maintenance
- All images are from the same fixed camera position

Data Source:
- Website: https://webcam-paris.com
- Camera Location: South West Paris, 30 meters above street level
- View Direction: Northwest facing (direct Eiffel Tower perspective)

Terms of Use:
- This dataset is provided for research and educational purposes
- Please credit "webcam-paris.com" when using this data
- Commercial use requires permission
- No warranty is provided for data accuracy or completeness

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Archive Created: $(date '+%Y-%m-%d')
EOF

    # Create the ZIP file
    log_message "Creating ZIP archive with ${total_images} images ($(numfmt --to=iec ${total_size}))"
    
    cd "${temp_dir}"
    if zip -r "${zip_path}" . -q; then
        cd /
        
        # Set proper permissions
        chmod 644 "${zip_path}"
        
        # Get final ZIP size
        local zip_size=$(stat -f%z "${zip_path}" 2>/dev/null || stat -c%s "${zip_path}")
        local compression_ratio=$((100 - (zip_size * 100 / total_size)))
        
        log_message "ZIP created successfully: ${zip_filename}"
        log_message "  Images: ${total_images}"
        log_message "  Original size: $(numfmt --to=iec ${total_size})"
        log_message "  ZIP size: $(numfmt --to=iec ${zip_size})"
        log_message "  Compression: ${compression_ratio}%"
        
        # Create download index HTML
        create_download_index
        
    else
        log_message "ERROR: Failed to create ZIP file"
        rm -f "${zip_path}"
        cd /
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Clean up temp directory
    rm -rf "${temp_dir}"
    
    return 0
}

# Function to create download index HTML
create_download_index() {
    local index_file="${DOWNLOADS_DIR}/index.html"
    
    cat > "${index_file}" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paris Webcam Dataset Downloads</title>
    <style>
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            line-height: 1.6;
            color: #2c3e50;
            background: #f8f9fa;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #1c45d9;
            text-align: center;
            margin-bottom: 30px;
        }
        .description {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .downloads {
            margin-bottom: 30px;
        }
        .download-item {
            background: #fff;
            border: 1px solid #e1e8ed;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .download-info h3 {
            margin: 0 0 5px 0;
            color: #2c3e50;
        }
        .download-meta {
            font-size: 0.9em;
            color: #666;
        }
        .download-link {
            background: #1c45d9;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 500;
        }
        .download-link:hover {
            background: #3498db;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #1c45d9;
            text-decoration: none;
        }
        .footer {
            text-align: center;
            padding-top: 20px;
            border-top: 1px solid #e1e8ed;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-link">← Back to Webcam</a>
        
        <h1>🗼 Paris Webcam Dataset Downloads</h1>
        
        <div class="description">
            <h2>About the Dataset</h2>
            <p>High-quality webcam captures from Paris featuring the Eiffel Tower, captured every 10 minutes during daylight hours. Perfect for computer vision research, time-lapse analysis, weather studies, and urban photography projects.</p>
            
            <h3>Dataset Features:</h3>
            <ul>
                <li><strong>Consistent viewpoint:</strong> Fixed camera position with direct Eiffel Tower view</li>
                <li><strong>Regular intervals:</strong> Images captured every 10 minutes</li>
                <li><strong>Daylight hours:</strong> 6 AM to 8 PM (Europe/Paris timezone)</li>
                <li><strong>High resolution:</strong> Typically 1920x1080 or similar</li>
                <li><strong>Weather variety:</strong> Clear skies, clouds, rain, snow, fog</li>
                <li><strong>Seasonal changes:</strong> Different lighting and atmospheric conditions</li>
            </ul>
        </div>
        
        <div class="downloads">
            <h2>Available Downloads</h2>
EOF

    # Add download items for each ZIP file
    for zip_file in "${DOWNLOADS_DIR}"/captures-*.zip; do
        if [ -f "${zip_file}" ]; then
            local filename=$(basename "${zip_file}")
            local month=$(echo "${filename}" | sed 's/captures-\(.*\)\.zip/\1/')
            local month_name=$(get_month_name "${month}")
            local file_size=$(stat -f%z "${zip_file}" 2>/dev/null || stat -c%s "${zip_file}")
            local file_size_human=$(numfmt --to=iec ${file_size})
            local file_date=$(stat -f%Sm -t%Y-%m-%d "${zip_file}" 2>/dev/null || stat -c%y "${zip_file}" | cut -d' ' -f1)
            
            # Count images in ZIP (approximate)
            local image_count=$(unzip -l "${zip_file}" | grep -c '\.jpg$' || echo "Unknown")
            
            cat >> "${index_file}" << EOF
            <div class="download-item">
                <div class="download-info">
                    <h3>${month_name}</h3>
                    <div class="download-meta">
                        ${image_count} images • ${file_size_human} • Created ${file_date}
                    </div>
                </div>
                <a href="${filename}" class="download-link">Download</a>
            </div>
EOF
        fi
    done

    cat >> "${index_file}" << 'EOF'
        </div>
        
        <div class="footer">
            <p><strong>Terms of Use:</strong> This dataset is provided for research and educational purposes. Please credit "webcam-paris.com" when using this data.</p>
            <p>For commercial use or questions, contact: info@webcam-paris.com</p>
        </div>
    </div>
</body>
</html>
EOF

    chmod 644 "${index_file}"
    log_message "Updated download index: ${index_file}"
}

# Function to clean up old ZIPs (keep last 12 months)
cleanup_old_zips() {
    log_message "Cleaning up old ZIP files..."
    
    # Find ZIP files older than 12 months
    find "${DOWNLOADS_DIR}" -name "captures-*.zip" -mtime +365 -type f | while read -r old_zip; do
        local filename=$(basename "${old_zip}")
        log_message "Removing old ZIP: ${filename}"
        rm -f "${old_zip}"
    done
}

# Main execution
main() {
    log_message "=== Monthly ZIP Generator Started ==="
    
    # Get previous month (only create ZIPs for complete months)
    local prev_month=$(get_previous_month)
    local current_date=$(date '+%Y-%m-%d')
    
    log_message "Processing month: ${prev_month}"
    log_message "Current date: ${current_date}"
    
    # Create ZIP for previous month
    if create_monthly_zip "${prev_month}"; then
        log_message "Successfully created ZIP for ${prev_month}"
    else
        log_message "Failed to create ZIP for ${prev_month}"
    fi
    
    # Cleanup old files
    cleanup_old_zips
    
    # Create/update download index
    create_download_index
    
    log_message "=== Monthly ZIP Generator Completed ==="
    
    # Show summary
    local zip_count=$(find "${DOWNLOADS_DIR}" -name "captures-*.zip" -type f | wc -l)
    local total_size=$(du -sh "${DOWNLOADS_DIR}" | cut -f1)
    log_message "Summary: ${zip_count} ZIP files available, total size: ${total_size}"
}

# Run main function
main "$@"