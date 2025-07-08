#!/bin/bash

# Gallery Generator Script for Paris Webcam
# Generates static HTML file for today's captured images
# To be deployed to VPS at /usr/local/nginx/html/live/gallery-generator.sh

# Configuration
CAPTURES_DIR="/usr/local/nginx/html/live/captures"
OUTPUT_FILE="/usr/local/nginx/html/live/gallery-today.html"
WEBSITE_BASE="https://webcam-paris.com"
TODAY=$(date +%Y-%m-%d)
TODAY_DIR="${CAPTURES_DIR}/${TODAY}"

# Create captures directory if it doesn't exist
mkdir -p "${TODAY_DIR}"

# Function to generate the HTML header
generate_header() {
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Today's Captures - Webcam Paris</title>
    <meta name="description" content="Live captures from Paris webcam today, updated every 10 minutes during daylight hours.">
    
    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://webcam-paris.com/gallery-today.html">
    <meta property="og:title" content="Today's Captures - Webcam Paris">
    <meta property="og:description" content="Live captures from Paris webcam today">
    
    <style>
        /* CSS Custom Properties */
        :root {
            --primary-blue: #1c45d9;
            --text-primary: #2c3e50;
            --text-secondary: #666;
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

        .gallery-info {
            background: var(--bg-primary);
            border-radius: var(--radius-lg);
            padding: var(--spacing-lg);
            box-shadow: var(--shadow-md);
            text-align: center;
            margin-bottom: var(--spacing-xl);
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
            <h1>🗼 Today's Paris Captures</h1>
            <p>Live captures from today, updated every 10 minutes during daylight hours (6 AM - 8 PM)</p>
        </div>

        <div class="gallery-info">
EOF
}

# Function to generate the HTML footer
generate_footer() {
    cat << 'EOF'
        </div>

        <div class="footer">
            <p>Generated automatically every 10 minutes | <a href="https://webcam-paris.com">webcam-paris.com</a></p>
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

extract_brightness() {
    local filename="$1"
    if [[ $filename =~ image_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}_([0-9]{1,3})\.jpg ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "Unknown"
    fi
}

# Main execution
echo "Starting gallery generation for ${TODAY}..."

# Start generating the HTML file
generate_header > "${OUTPUT_FILE}"

# Check if today's directory exists and has images
if [ -d "${TODAY_DIR}" ]; then
    # Find all JPG files in today's directory
    images=($(find "${TODAY_DIR}" -name "*.jpg" -type f | sort -r))
    
    if [ ${#images[@]} -gt 0 ]; then
        # Calculate average brightness
        total_brightness=0
        valid_images=0
        
        for image_path in "${images[@]}"; do
            filename=$(basename "${image_path}")
            brightness=$(extract_brightness "${filename}")
            
            # Only add to calculation if brightness is not "Unknown"
            if [ "${brightness}" != "Unknown" ]; then
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
        cat >> "${OUTPUT_FILE}" << EOF
            <p><strong>${#images[@]} captures</strong> from ${TODAY}</p>
            <p>Average brightness: ${average_brightness}</p>
            <p>Last updated: $(date '+%H:%M:%S')</p>
        </div>

        <div class="gallery-grid">
EOF

        # Generate gallery items for each image
        for image_path in "${images[@]}"; do
            filename=$(basename "${image_path}")
            # Convert absolute path to relative web path
            web_path="/captures/${TODAY}/${filename}"
            time_display=$(extract_time "${filename}")
            brightness_display=$(extract_brightness "${filename}")
            
            cat >> "${OUTPUT_FILE}" << EOF
            <div class="gallery-item">
                <img src="${web_path}" 
                     alt="Paris webcam capture at ${time_display}" 
                     loading="lazy">
                <div class="gallery-item-info">
                    <div class="gallery-item-time">${time_display}</div>
                    <div class="gallery-item-brightness">Brightness: ${brightness_display}</div>
                    <a href="${web_path}" class="gallery-item-link" target="_blank">View Full Size</a>
                </div>
            </div>
EOF
        done

        echo "        </div>" >> "${OUTPUT_FILE}"
        
        echo "Generated gallery with ${#images[@]} images"
    else
        # No images found
        cat >> "${OUTPUT_FILE}" << EOF
            <p>No captures available yet</p>
            <p>Last checked: $(date '+%H:%M:%S')</p>
        </div>

        <div class="no-images">
            <h2>No captures available yet today</h2>
            <p>Images are captured every 10 minutes during daylight hours (6 AM - 8 PM).</p>
            <p>Check back during daylight hours to see today's captures!</p>
        </div>
EOF
        echo "No images found for today"
    fi
else
    # Directory doesn't exist
    cat >> "${OUTPUT_FILE}" << EOF
        <p>No captures directory found</p>
        <p>Last checked: $(date '+%H:%M:%S')</p>
    </div>

    <div class="no-images">
        <h2>Captures directory not found</h2>
        <p>The capture system may not be running yet today.</p>
        <p>Check back later for today's captures!</p>
    </div>
EOF
    echo "Captures directory not found: ${TODAY_DIR}"
fi

# Add footer
generate_footer >> "${OUTPUT_FILE}"

# Set proper permissions
chmod 644 "${OUTPUT_FILE}"

echo "Gallery generation complete: ${OUTPUT_FILE}"
echo "File size: $(du -h "${OUTPUT_FILE}" | cut -f1)"

# Optional: Clean up old gallery files (keep last 7 days)
find "/usr/local/nginx/html/live" -name "gallery-*.html" -mtime +7 -delete 2>/dev/null || true

echo "Gallery generator finished successfully"