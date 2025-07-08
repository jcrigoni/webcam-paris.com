#!/bin/bash

# Historical Gallery Generator Script for Paris Webcam
# Generates static HTML files for all historical captured images
# To be deployed to VPS at /usr/local/nginx/html/live/historical-gallery-generator.sh

# Configuration
CAPTURES_DIR="${CAPTURES_DIR:-/usr/local/nginx/html/live/captures}"
GALLERIES_DIR="${GALLERIES_DIR:-/usr/local/nginx/html/live/html-galleries}"
WEBSITE_BASE="https://webcam-paris.com"

# Function to convert date to hierarchical path (YYYY-MM-DD -> YYYY/MM/DD)
date_to_path() {
    local date="$1"
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2)
    local day=$(echo "$date" | cut -d'-' -f3)
    echo "$year/$month/$day"
}

# Function to convert hierarchical path back to date (YYYY/MM/DD -> YYYY-MM-DD)
path_to_date() {
    local path="$1"
    echo "$path" | tr '/' '-'
}

# Create galleries directory with hierarchical structure if it doesn't exist
mkdir -p "${GALLERIES_DIR}"

# Create year/month subdirectories for galleries (YYYY/MM/)
create_gallery_subdirs() {
    local date="$1"
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2)
    mkdir -p "${GALLERIES_DIR}/${year}/${month}"
}

# Function to generate the HTML header for a specific date
generate_header() {
    local date="$1"
    local date_display="$2"
    
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paris Captures - ${date_display} | Webcam Paris</title>
    <meta name="description" content="Historical captures from Paris webcam on ${date_display}, updated every 10 minutes during daylight hours.">
    
    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://webcam-paris.com/html-galleries/$(echo "$date" | cut -d'-' -f1)/$(echo "$date" | cut -d'-' -f2)/gallery-${date}.html">
    <meta property="og:title" content="Paris Captures - ${date_display}">
    <meta property="og:description" content="Historical captures from Paris webcam on ${date_display}">
    
    <style>
        /* CSS Custom Properties */
        :root {
            --primary-blue: #1c45d9;
            --secondary-blue: #3498db;
            --text-primary: #2c3e50;
            --text-secondary: #666;
            --text-light: #999;
            --bg-primary: #ffffff;
            --bg-secondary: #f8f9fa;
            --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
            --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.15);
            --radius-md: 0.5rem;
            --radius-lg: 1rem;
            --spacing-sm: 1rem;
            --spacing-md: 1.5rem;
            --spacing-lg: 2rem;
            --spacing-xl: 3rem;
            --font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Roboto', sans-serif;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: var(--font-family);
            line-height: 1.6;
            color: var(--text-primary);
            background-color: var(--bg-secondary);
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: var(--spacing-md);
        }

        .header {
            text-align: center;
            margin-bottom: var(--spacing-xl);
            padding: var(--spacing-lg) 0;
        }

        .header h1 {
            color: var(--primary-blue);
            font-size: 2.5rem;
            margin-bottom: var(--spacing-md);
        }

        .header p {
            color: var(--text-secondary);
            font-size: 1.125rem;
            max-width: 600px;
            margin: 0 auto;
        }

        .back-link {
            display: inline-block;
            margin-bottom: var(--spacing-lg);
            color: var(--primary-blue);
            text-decoration: none;
            font-weight: 500;
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--bg-primary);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-md);
            transition: all 0.3s ease;
        }

        .back-link:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }

        .navigation {
            display: flex;
            justify-content: center;
            gap: var(--spacing-md);
            margin-bottom: var(--spacing-lg);
            flex-wrap: wrap;
        }

        .nav-btn {
            color: var(--primary-blue);
            text-decoration: none;
            font-weight: 500;
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--bg-primary);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-md);
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }

        .nav-btn:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
            background: var(--primary-blue);
            color: white;
        }

        .nav-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }

        .nav-btn:disabled:hover {
            background: var(--bg-primary);
            color: var(--primary-blue);
            transform: none;
        }

        .current-date {
            font-weight: 600;
            color: var(--text-primary);
            background: var(--bg-primary);
            padding: var(--spacing-sm) var(--spacing-md);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-md);
        }

        .gallery-info {
            background: var(--bg-primary);
            border-radius: var(--radius-lg);
            padding: var(--spacing-lg);
            box-shadow: var(--shadow-md);
            text-align: center;
            margin-bottom: var(--spacing-xl);
        }

        .scientific-info {
            background: var(--bg-primary);
            border-radius: var(--radius-lg);
            padding: var(--spacing-lg);
            box-shadow: var(--shadow-md);
            margin-bottom: var(--spacing-xl);
        }

        .scientific-info h3 {
            color: var(--primary-blue);
            margin-bottom: var(--spacing-md);
            font-size: 1.5rem;
        }

        .scientific-info p {
            color: var(--text-secondary);
            margin-bottom: var(--spacing-sm);
        }

        .gallery-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: var(--spacing-lg);
            margin-bottom: var(--spacing-xl);
        }

        .gallery-item {
            background: var(--bg-primary);
            border-radius: var(--radius-lg);
            overflow: hidden;
            box-shadow: var(--shadow-md);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .gallery-item:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-lg);
        }

        .gallery-item img {
            width: 100%;
            height: 225px;
            object-fit: cover;
            display: block;
        }

        .gallery-item-info {
            padding: var(--spacing-md);
            text-align: center;
        }

        .gallery-item-time {
            font-weight: 600;
            color: var(--text-primary);
            font-size: 1.125rem;
            margin-bottom: 0.5rem;
        }

        .gallery-item-brightness {
            color: var(--text-secondary);
            font-size: 0.875rem;
            margin-bottom: var(--spacing-sm);
        }

        .gallery-item-link {
            color: var(--primary-blue);
            text-decoration: none;
            font-size: 0.875rem;
        }

        .gallery-item-link:hover {
            text-decoration: underline;
        }

        .no-images {
            text-align: center;
            padding: var(--spacing-xl);
            background: var(--bg-primary);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-md);
        }

        .no-images h2 {
            color: var(--text-primary);
            margin-bottom: var(--spacing-md);
        }

        .no-images p {
            color: var(--text-secondary);
            margin-bottom: var(--spacing-sm);
        }

        .footer {
            text-align: center;
            padding: var(--spacing-lg);
            color: var(--text-secondary);
            font-size: 0.875rem;
        }

        /* Mobile responsive */
        @media (max-width: 768px) {
            .gallery-grid {
                grid-template-columns: 1fr;
                gap: var(--spacing-md);
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .container {
                padding: var(--spacing-sm);
            }

            .navigation {
                flex-direction: column;
                align-items: center;
            }

            .nav-btn,
            .current-date {
                min-width: 200px;
                text-align: center;
            }
        }

        /* Lazy loading support */
        img[loading="lazy"] {
            opacity: 0;
            transition: opacity 0.3s;
        }

        img[loading="lazy"].loaded {
            opacity: 1;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/#live" class="back-link">← Back to Main Site</a>
        
        <div class="header">
            <h1>🗼 Paris Captures - ${date_display}</h1>
            <p>Historical captures from ${date_display}, updated every 10 minutes during daylight hours (6 AM - 8 PM)</p>
        </div>

        <div class="scientific-info">
            <h3>🔬 Scientific Data Collection</h3>
            <p>Each image filename contains brightness metadata: <strong>image_YYYY-MM-DD_HH-MM-SS_BBB.jpg</strong></p>
            <p>The final 3-digit number (BBB) represents the average pixel brightness (0-255) calculated automatically during capture.</p>
            <p>This data supports weather pattern analysis, urban atmospheric studies, and machine learning research.</p>
        </div>

        <div class="gallery-info">
EOF
}

# Function to generate the HTML footer
generate_footer() {
    cat << 'EOF'
        </div>

        <div class="footer">
            <p>Generated automatically from historical data | <a href="https://webcam-paris.com">webcam-paris.com</a></p>
        </div>
    </div>

    <script>
        // Simple lazy loading for better performance
        document.addEventListener('DOMContentLoaded', function() {
            const images = document.querySelectorAll('img[loading="lazy"]');
            
            if ('IntersectionObserver' in window) {
                const imageObserver = new IntersectionObserver((entries, observer) => {
                    entries.forEach(entry => {
                        if (entry.isIntersecting) {
                            const img = entry.target;
                            img.classList.add('loaded');
                            observer.unobserve(img);
                        }
                    });
                });

                images.forEach(img => {
                    imageObserver.observe(img);
                    img.addEventListener('load', () => img.classList.add('loaded'));
                });
            } else {
                // Fallback for older browsers
                images.forEach(img => {
                    img.classList.add('loaded');
                });
            }
        });
    </script>
</body>
</html>
EOF
}

# Function to extract time from filename
extract_time() {
    local filename="$1"
    if [[ $filename =~ image_[0-9]{4}-[0-9]{2}-[0-9]{2}_([0-9]{2})-([0-9]{2})-([0-9]{2})_[0-9]{1,3}\.jpg ]]; then
        echo "${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
    else
        echo "Unknown"
    fi
}

# Function to extract brightness from filename
extract_brightness() {
    local filename="$1"
    if [[ $filename =~ image_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}_([0-9]{1,3})\.jpg ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "Unknown"
    fi
}

# Function to format date for display
format_date_display() {
    local date="$1"
    date -d "$date" "+%A, %B %d, %Y" 2>/dev/null || echo "$date"
}

# Function to get previous date
get_previous_date() {
    local date="$1"
    date -d "$date - 1 day" "+%Y-%m-%d" 2>/dev/null
}

# Function to get next date
get_next_date() {
    local date="$1"
    date -d "$date + 1 day" "+%Y-%m-%d" 2>/dev/null
}

# Function to check if date directory exists
date_has_images() {
    local date="$1"
    local date_path=$(date_to_path "$date")
    local date_dir="${CAPTURES_DIR}/${date_path}"
    
    if [ -d "$date_dir" ]; then
        # Check if directory has any JPG files
        if [ "$(find "$date_dir" -name "*.jpg" -type f | wc -l)" -gt 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Function to generate navigation for a date
generate_navigation() {
    local current_date="$1"
    local prev_date next_date
    
    # Find previous date with images
    prev_date="$current_date"
    for i in {1..30}; do
        prev_date=$(get_previous_date "$prev_date")
        if date_has_images "$prev_date"; then
            break
        fi
        if [ $i -eq 30 ]; then
            prev_date=""
        fi
    done
    
    # Find next date with images
    next_date="$current_date"
    today=$(date +%Y-%m-%d)
    for i in {1..30}; do
        next_date=$(get_next_date "$next_date")
        if [ "$next_date" \> "$today" ]; then
            next_date=""
            break
        fi
        if date_has_images "$next_date"; then
            break
        fi
        if [ $i -eq 30 ]; then
            next_date=""
        fi
    done
    
    echo '<div class="navigation">'
    
    if [ -n "$prev_date" ]; then
        local prev_year=$(echo "$prev_date" | cut -d'-' -f1)
        local prev_month=$(echo "$prev_date" | cut -d'-' -f2)
        local curr_year=$(echo "$current_date" | cut -d'-' -f1)
        local curr_month=$(echo "$current_date" | cut -d'-' -f2)
        
        # Calculate relative path between gallery directories
        if [ "$prev_year" = "$curr_year" ] && [ "$prev_month" = "$curr_month" ]; then
            # Same month - direct link
            echo "    <a href=\"gallery-${prev_date}.html\" class=\"nav-btn\">← $(format_date_display "$prev_date")</a>"
        else
            # Different month - relative path
            echo "    <a href=\"../${prev_year}/${prev_month}/gallery-${prev_date}.html\" class=\"nav-btn\">← $(format_date_display "$prev_date")</a>"
        fi
    else
        echo "    <button class=\"nav-btn\" disabled>← No Earlier Date</button>"
    fi
    
    echo "    <span class=\"current-date\">$(format_date_display "$current_date")</span>"
    
    if [ -n "$next_date" ]; then
        local next_year=$(echo "$next_date" | cut -d'-' -f1)
        local next_month=$(echo "$next_date" | cut -d'-' -f2)
        local curr_year=$(echo "$current_date" | cut -d'-' -f1)
        local curr_month=$(echo "$current_date" | cut -d'-' -f2)
        
        # Calculate relative path between gallery directories
        if [ "$next_year" = "$curr_year" ] && [ "$next_month" = "$curr_month" ]; then
            # Same month - direct link
            echo "    <a href=\"gallery-${next_date}.html\" class=\"nav-btn\">$(format_date_display "$next_date") →</a>"
        else
            # Different month - relative path
            echo "    <a href=\"../${next_year}/${next_month}/gallery-${next_date}.html\" class=\"nav-btn\">$(format_date_display "$next_date") →</a>"
        fi
    else
        echo "    <button class=\"nav-btn\" disabled>No Later Date →</button>"
    fi
    
    echo '</div>'
}

# Function to generate gallery for a specific date
generate_gallery_for_date() {
    local date="$1"
    local date_path=$(date_to_path "$date")
    local date_dir="${CAPTURES_DIR}/${date_path}"
    
    # Create gallery subdirectories and set output file path
    create_gallery_subdirs "$date"
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2)
    local output_file="${GALLERIES_DIR}/${year}/${month}/gallery-${date}.html"
    local date_display
    
    date_display=$(format_date_display "$date")
    
    echo "Generating gallery for ${date} (${date_display})..."
    
    # Start generating the HTML file
    generate_header "$date" "$date_display" > "$output_file"
    
    # Add navigation
    generate_navigation "$date" >> "$output_file"
    
    # Check if date directory exists and has images
    if [ -d "$date_dir" ]; then
        # Read from index.txt if it exists, otherwise scan directory
        if [ -f "${date_dir}/index.txt" ]; then
            # Use index.txt file for better performance
            mapfile -t images < "${date_dir}/index.txt"
            # Filter out empty lines and ensure JPG files only
            filtered_images=()
            for img in "${images[@]}"; do
                if [[ "$img" =~ \.jpg$ ]] && [ -f "${date_dir}/${img}" ]; then
                    filtered_images+=("${date_dir}/${img}")
                fi
            done
            images=("${filtered_images[@]}")
        else
            # Fallback to directory scan
            images=($(find "$date_dir" -name "*.jpg" -type f | sort -r))
        fi
        
        if [ ${#images[@]} -gt 0 ]; then
            # Calculate average brightness
            total_brightness=0
            valid_images=0
            
            for image_path in "${images[@]}"; do
                filename=$(basename "$image_path")
                brightness=$(extract_brightness "$filename")
                
                # Only add to calculation if brightness is not "Unknown"
                if [ "$brightness" != "Unknown" ]; then
                    total_brightness=$((total_brightness + brightness))
                    valid_images=$((valid_images + 1))
                fi
            done
            
            # Calculate average (using integer division)
            if [ ${valid_images} -gt 0 ]; then
                average_brightness=$((total_brightness / valid_images))
            else
                average_brightness="Unknown"
            fi
            
            # Add gallery info with count and average brightness
            cat >> "$output_file" << EOF
            <p><strong>${#images[@]} captures</strong> from ${date_display}</p>
            <p>Average brightness: ${average_brightness}</p>
            <p>Generated: $(date '+%H:%M:%S on %Y-%m-%d')</p>
        </div>

        <div class="gallery-grid">
EOF

            # Generate gallery items for each image
            for image_path in "${images[@]}"; do
                filename=$(basename "$image_path")
                # Convert absolute path to relative web path using hierarchical structure
                web_path="/captures/${date_path}/${filename}"
                time_display=$(extract_time "$filename")
                brightness_display=$(extract_brightness "$filename")
                
                cat >> "$output_file" << EOF
            <div class="gallery-item">
                <img src="${web_path}" 
                     alt="Paris webcam capture at ${time_display} on ${date_display}" 
                     loading="lazy">
                <div class="gallery-item-info">
                    <div class="gallery-item-time">${time_display}</div>
                    <div class="gallery-item-brightness">Brightness: ${brightness_display}</div>
                    <a href="${web_path}" class="gallery-item-link" target="_blank">View Full Size</a>
                </div>
            </div>
EOF
            done

            echo "        </div>" >> "$output_file"
            
            echo "Generated gallery with ${#images[@]} images for ${date}"
        else
            # No images found
            cat >> "$output_file" << EOF
            <p>No captures available for ${date_display}</p>
            <p>Generated: $(date '+%H:%M:%S on %Y-%m-%d')</p>
        </div>

        <div class="no-images">
            <h2>No captures available for ${date_display}</h2>
            <p>Images are captured every 10 minutes during daylight hours (6 AM - 8 PM).</p>
            <p>This date may not have had any captures due to technical issues or the capture system not being active.</p>
        </div>
EOF
            echo "No images found for ${date}"
        fi
    else
        # Directory doesn't exist
        cat >> "$output_file" << EOF
        <p>No captures directory found for ${date_display}</p>
        <p>Generated: $(date '+%H:%M:%S on %Y-%m-%d')</p>
    </div>

    <div class="no-images">
        <h2>Captures directory not found for ${date_display}</h2>
        <p>The capture system may not have been running on this date.</p>
        <p>Try browsing other dates to see available captures.</p>
    </div>
EOF
        echo "Captures directory not found: ${date_dir}"
    fi
    
    # Add footer
    generate_footer >> "$output_file"
    
    # Set proper permissions
    chmod 644 "$output_file"
    
    echo "Gallery generation complete for ${date}: ${output_file}"
}

# Main execution
echo "Starting historical gallery generation..."

# Generate galleries for a specific date range or all available dates
if [ $# -eq 1 ]; then
    # Single date provided
    generate_gallery_for_date "$1"
elif [ $# -eq 2 ]; then
    # Date range provided
    start_date="$1"
    end_date="$2"
    
    current_date="$start_date"
    while [ "$current_date" != "$end_date" ]; do
        if date_has_images "$current_date"; then
            generate_gallery_for_date "$current_date"
        fi
        current_date=$(get_next_date "$current_date")
    done
    
    # Generate for end date
    if date_has_images "$end_date"; then
        generate_gallery_for_date "$end_date"
    fi
else
    # No arguments - generate for all available dates in the last 30 days
    echo "Generating galleries for all available dates in the last 30 days..."
    
    today=$(date +%Y-%m-%d)
    start_date=$(date -d "$today - 30 days" +%Y-%m-%d)
    
    current_date="$start_date"
    generated_count=0
    
    while [ "$current_date" != "$today" ]; do
        if date_has_images "$current_date"; then
            generate_gallery_for_date "$current_date"
            generated_count=$((generated_count + 1))
        fi
        current_date=$(get_next_date "$current_date")
    done
    
    # Generate for today
    if date_has_images "$today"; then
        generate_gallery_for_date "$today"
        generated_count=$((generated_count + 1))
    fi
    
    echo "Generated ${generated_count} gallery pages"
fi

# Optional: Clean up old gallery files (keep last 60 days)
echo "Cleaning up old gallery files..."
find "${GALLERIES_DIR}" -name "gallery-*.html" -mtime +60 -delete 2>/dev/null || true

echo "Historical gallery generator finished successfully"