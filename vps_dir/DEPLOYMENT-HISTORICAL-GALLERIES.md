# Historical Gallery Deployment Guide

## Overview
This system generates static HTML gallery pages for historical webcam captures, organized by date. Each gallery page contains images with brightness metadata and navigation between dates.

## Architecture
- **Historical Gallery Generator**: Main script that creates individual gallery pages
- **Update Script**: Incremental updater that runs every 10 minutes
- **Static HTML Pages**: Generated gallery pages with scientific metadata
- **Navigation**: Automatic previous/next navigation between available dates

## Files to Deploy

### 1. Scripts
Copy these files to `/usr/local/nginx/html/live/` on the VPS:
- `historical-gallery-generator.sh` → Main gallery generator
- `update-historical-galleries.sh` → Incremental updater

### 2. Directory Structure
Create the following directory on the VPS:
```
/usr/local/nginx/html/live/html-galleries/
```

### 3. Permissions
Make scripts executable:
```bash
chmod +x /usr/local/nginx/html/live/historical-gallery-generator.sh
chmod +x /usr/local/nginx/html/live/update-historical-galleries.sh
```

## Generated Files
- **Gallery Pages**: `/usr/local/nginx/html/live/html-galleries/gallery-YYYY-MM-DD.html`
- **Index Page**: `/usr/local/nginx/html/live/html-galleries/index.html`
- **Web URLs**: `https://webcam-paris.com/html-galleries/gallery-YYYY-MM-DD.html`

## Cron Jobs
Add these entries to the VPS crontab:

```bash
# Update historical galleries every 10 minutes
*/10 * * * * /usr/local/nginx/html/live/update-historical-galleries.sh >> /var/log/webcam-historical-galleries.log 2>&1

# Generate all galleries for the last 30 days (run once daily at 2 AM)
0 2 * * * /usr/local/nginx/html/live/historical-gallery-generator.sh >> /var/log/webcam-historical-galleries.log 2>&1
```

## Gallery Features

### 1. Scientific Metadata
- **Brightness Values**: Extracted from filename format `image_YYYY-MM-DD_HH-MM-SS_BBB.jpg`
- **Average Calculations**: Daily brightness averages displayed in gallery info
- **Timestamp Parsing**: Automatic extraction of capture times

### 2. Navigation
- **Previous/Next**: Automatic navigation between available dates
- **Date Detection**: Only shows navigation to dates with actual captures
- **Responsive Design**: Mobile-optimized layout

### 3. Performance
- **Lazy Loading**: Images load only when scrolled into view
- **Index.txt Integration**: Uses existing index files for better performance
- **Incremental Updates**: Only regenerates galleries when captures change

## Usage

### Manual Generation
Generate a single date:
```bash
/usr/local/nginx/html/live/historical-gallery-generator.sh 2025-01-07
```

Generate a date range:
```bash
/usr/local/nginx/html/live/historical-gallery-generator.sh 2025-01-06 2025-01-07
```

Generate all recent dates:
```bash
/usr/local/nginx/html/live/historical-gallery-generator.sh
```

### Incremental Updates
The update script checks for changes and only regenerates galleries when needed:
```bash
/usr/local/nginx/html/live/update-historical-galleries.sh
```

## Integration with Main Site

### Current Gallery Link
The main site's gallery navigation points to:
```html
<a href="https://webcam-paris.com/gallery-today.html">Gallery</a>
```

### Historical Gallery Access
Users can access historical galleries via:
- Direct URLs: `https://webcam-paris.com/html-galleries/gallery-YYYY-MM-DD.html`
- Index page: `https://webcam-paris.com/html-galleries/index.html`
- Navigation within gallery pages (previous/next buttons)

## Scientific Features

### Brightness Analysis
- **Automatic Extraction**: Brightness values from filename metadata
- **Daily Averages**: Calculated and displayed for each gallery
- **Research Support**: Data formatted for scientific analysis

### Metadata Display
Each gallery shows:
- Total number of captures
- Average brightness for the day
- Individual image brightness values
- Capture timestamps

## Maintenance

### Log Files
Monitor gallery generation:
```bash
tail -f /var/log/webcam-historical-galleries.log
```

### Cleanup
- Old gallery files are automatically cleaned up (older than 30 days)
- Configurable in the scripts

### Directory Structure
```
/usr/local/nginx/html/live/
├── captures/
│   ├── 2025-01-06/
│   │   ├── index.txt
│   │   └── image_2025-01-06_*.jpg
│   └── 2025-01-07/
│       ├── index.txt
│       └── image_2025-01-07_*.jpg
├── html-galleries/
│   ├── gallery-2025-01-06.html
│   ├── gallery-2025-01-07.html
│   └── index.html
├── historical-gallery-generator.sh
└── update-historical-galleries.sh
```

## Testing

### Local Testing
Use environment variables for local testing:
```bash
CAPTURES_DIR="/path/to/captures" GALLERIES_DIR="/path/to/galleries" ./historical-gallery-generator.sh 2025-01-07
```

### Verification
1. Check that gallery files are generated
2. Verify navigation links work between dates
3. Confirm brightness values are extracted correctly
4. Test responsive design on mobile devices

## Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure scripts are executable and directories are writable
2. **Missing Images**: Check that capture directories exist and contain JPG files
3. **Navigation Broken**: Verify date parsing and availability detection
4. **Performance Issues**: Consider adjusting update frequency for large datasets

### Debug Mode
Add debug output to scripts:
```bash
set -x  # Enable debug mode
```

## Future Enhancements

### Potential Features
1. **Search Functionality**: Search galleries by date or brightness range
2. **Brightness Charts**: Visual representation of brightness trends
3. **Weather Integration**: Correlate brightness with weather data
4. **ML Analysis**: Automated sky condition classification

### Performance Optimizations
1. **Thumbnail Generation**: Pre-generate thumbnails for faster loading
2. **Caching**: Implement caching for frequently accessed galleries
3. **Database Integration**: Store metadata in database for complex queries