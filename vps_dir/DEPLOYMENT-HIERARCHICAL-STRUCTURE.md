# Hierarchical Directory Structure Deployment Guide

## Overview
The webcam capture and gallery system has been updated to use a hierarchical directory structure for better filesystem performance as data grows over time.

## Directory Structure Changes

### Old Structure (YYYY-MM-DD)
```
/usr/local/nginx/html/live/
├── captures/
│   ├── 2025-01-06/
│   ├── 2025-01-07/
│   ├── 2025-01-08/
│   └── ...
└── html-galleries/
    ├── gallery-2025-01-06.html
    ├── gallery-2025-01-07.html
    └── ...
```

### New Structure (YYYY/MM/DD)
```
/usr/local/nginx/html/live/
├── captures/
│   └── 2025/
│       ├── 01/
│       │   ├── 06/
│       │   │   ├── index.txt
│       │   │   └── image_2025-01-06_*.jpg
│       │   └── 07/
│       │       ├── index.txt
│       │       └── image_2025-01-07_*.jpg
│       └── 07/
│           ├── 07/
│           │   ├── index.txt
│           │   └── image_2025-07-07_*.jpg
│           └── 08/
│               ├── index.txt
│               └── image_2025-07-08_*.jpg
└── html-galleries/
    └── 2025/
        ├── 01/
        │   ├── 06/
        │   │   └── gallery-2025-01-06.html
        │   └── 07/
        │       └── gallery-2025-01-07.html
        └── 07/
            ├── 07/
            │   └── gallery-2025-07-07.html
            └── 08/
                └── gallery-2025-07-08.html
```

## Updated Scripts

### 1. capture_daylight.sh (local_dir/)
**Changes:**
- Directory creation: `$OUTPUT_DIR/$year/$month/$day`
- VPS upload: `$VPS_PATH/$year/$month/$day`
- Variables: Added `year=$(date +%Y)`, `month=$(date +%m)`, `day=$(date +%d)`

**Example paths:**
- Local: `/home/jc/dev/wp-local/captures/2025/07/08/`
- VPS: `/usr/local/nginx/html/live/captures/2025/07/08/`

### 2. generate_index.sh (vps_dir/)
**Changes:**
- Directory path: `$CAPTURES_DIR/$YEAR/$MONTH/$DAY`
- Variables: Added `YEAR=$(date +%Y)`, `MONTH=$(date +%m)`, `DAY=$(date +%d)`

### 3. gallery-generator.sh (vps_dir/)
**Changes:**
- Directory path: `$CAPTURES_DIR/$YEAR/$MONTH/$DAY`
- Web paths: `/captures/$YEAR/$MONTH/$DAY/$filename`
- Variables: Added `YEAR=$(date +%Y)`, `MONTH=$(date +%m)`, `DAY=$(date +%d)`

### 4. historical-gallery-generator.sh (vps_dir/)
**Changes:**
- Added `date_to_path()` function to convert YYYY-MM-DD to YYYY/MM/DD
- Added `create_gallery_subdirs()` function for hierarchical gallery directories
- Updated all path references to use hierarchical structure
- Navigation links use relative paths: `../../YYYY/MM/DD/gallery-YYYY-MM-DD.html`
- Web image paths: `/captures/YYYY/MM/DD/filename.jpg`

### 5. update-historical-galleries.sh (vps_dir/)
**Changes:**
- Added `date_to_path()` function
- Updated directory detection to use hierarchical paths
- Gallery file paths: `$GALLERIES_DIR/$date_path/gallery-$date.html`

## URL Structure

### Image URLs
- **Old**: `https://webcam-paris.com/captures/2025-01-06/image_2025-01-06_08-00-00_142.jpg`
- **New**: `https://webcam-paris.com/captures/2025/01/06/image_2025-01-06_08-00-00_142.jpg`

### Gallery URLs
- **Old**: `https://webcam-paris.com/html-galleries/gallery-2025-01-06.html`
- **New**: `https://webcam-paris.com/html-galleries/2025/01/06/gallery-2025-01-06.html`

### Today's Gallery
- **Unchanged**: `https://webcam-paris.com/gallery-today.html`

## Migration Process

### 1. Backup Current Data
```bash
# On VPS
sudo rsync -av /usr/local/nginx/html/live/captures/ /backup/captures-old/
sudo rsync -av /usr/local/nginx/html/live/html-galleries/ /backup/galleries-old/
```

### 2. Deploy Updated Scripts
```bash
# Upload all updated scripts to VPS
scp local_dir/capture_daylight.sh vps:/usr/local/nginx/html/live/
scp vps_dir/generate_index.sh vps:/usr/local/nginx/html/live/
scp vps_dir/gallery-generator.sh vps:/usr/local/nginx/html/live/
scp vps_dir/historical-gallery-generator.sh vps:/usr/local/nginx/html/live/
scp vps_dir/update-historical-galleries.sh vps:/usr/local/nginx/html/live/

# Make scripts executable
ssh vps "chmod +x /usr/local/nginx/html/live/*.sh"
```

### 3. Optional: Migrate Existing Data
```bash
# Create migration script to move old data to new structure
# This can be run gradually or as needed

#!/bin/bash
OLD_CAPTURES="/usr/local/nginx/html/live/captures"
NEW_CAPTURES="/usr/local/nginx/html/live/captures"

# Move old YYYY-MM-DD directories to YYYY/MM/DD
for old_dir in $OLD_CAPTURES/20??-??-??; do
    if [ -d "$old_dir" ]; then
        basename=$(basename "$old_dir")
        year=$(echo "$basename" | cut -d'-' -f1)
        month=$(echo "$basename" | cut -d'-' -f2)
        day=$(echo "$basename" | cut -d'-' -f3)
        
        new_dir="$NEW_CAPTURES/$year/$month/$day"
        mkdir -p "$new_dir"
        mv "$old_dir"/* "$new_dir"/ 2>/dev/null
        rmdir "$old_dir" 2>/dev/null
        echo "Migrated $old_dir to $new_dir"
    fi
done
```

### 4. Update Nginx Configuration (if needed)
```nginx
# Add location blocks for hierarchical paths
location /captures/ {
    alias /usr/local/nginx/html/live/captures/;
    expires 1d;
    add_header Cache-Control "public, immutable";
}

location /html-galleries/ {
    alias /usr/local/nginx/html/live/html-galleries/;
    expires 1h;
    add_header Cache-Control "public";
}
```

## Performance Benefits

### Filesystem Performance
- **Reduced directory scanning**: Hierarchical structure reduces directory size
- **Faster file operations**: Smaller directories improve performance
- **Better scalability**: Structure scales naturally with years of data

### Directory Size Comparison
- **Old structure**: Single directory with thousands of subdirectories
- **New structure**: Maximum ~31 subdirectories per directory level

## Backward Compatibility

### Image Access
- Old URLs will break and need to be updated
- Consider adding nginx redirects for commonly accessed old URLs:

```nginx
# Redirect old image URLs to new structure
location ~ /captures/(\d{4})-(\d{2})-(\d{2})/(.+) {
    return 301 /captures/$1/$2/$3/$4;
}
```

### Gallery Access
- Old gallery URLs will break
- Historical galleries now use hierarchical paths
- Today's gallery remains at same URL

## Testing

### Verify Structure
```bash
# Check directory structure
ls -la /usr/local/nginx/html/live/captures/2025/07/08/
ls -la /usr/local/nginx/html/live/html-galleries/2025/07/08/

# Test image access
curl -I https://webcam-paris.com/captures/2025/07/08/image_2025-07-08_12-00-00_166.jpg

# Test gallery access
curl -I https://webcam-paris.com/html-galleries/2025/07/08/gallery-2025-07-08.html
```

### Script Testing
```bash
# Test capture script (local)
./capture_daylight.sh

# Test generation scripts (VPS)
./generate_index.sh
./gallery-generator.sh
./historical-gallery-generator.sh 2025-07-08
./update-historical-galleries.sh
```

## Monitoring

### Log Files
- Monitor `/var/log/webcam-*.log` for script execution
- Check for any directory creation errors
- Verify image upload success

### Disk Usage
```bash
# Monitor directory sizes
du -sh /usr/local/nginx/html/live/captures/2025/*
du -sh /usr/local/nginx/html/live/html-galleries/2025/*
```

## Troubleshooting

### Common Issues
1. **Permission errors**: Ensure directories have proper 755 permissions
2. **Path issues**: Verify all scripts use hierarchical paths
3. **Navigation broken**: Check relative path calculations in gallery navigation
4. **Image loading**: Verify web paths use correct hierarchical structure

### Recovery
- Restore from backup if needed
- Regenerate galleries using historical-gallery-generator.sh
- Recreate index files using generate_index.sh

## Future Considerations

### Additional Optimization
- Consider adding year-based cleanup policies
- Implement compression for old data
- Add database indexing for large-scale queries

### Analytics Integration
- Hierarchical structure supports better analytics queries
- Enables efficient year/month/day-based reporting
- Supports time-series analysis of brightness data