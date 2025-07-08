# Paris Webcam - Deployment Instructions

## Overview
This deployment guide provides complete instructions for setting up the static gallery solution for the Paris webcam website.

## Files to Deploy

### 1. Scripts for VPS
Copy these scripts to your VPS:
- `gallery-generator.sh` → `/usr/local/nginx/html/live/gallery-generator.sh`
- `monthly-zip.sh` → `/usr/local/nginx/html/live/monthly-zip.sh`

### 2. Website Files (via rsync)
Update your local files and sync to VPS:
- `index.html` (updated gallery section)
- `app.js` (mobile HLS fixes, removed gallery JS)
- `styles.css` (gallery redirect styles)

## VPS Setup Instructions

### Step 1: Deploy Scripts to VPS

```bash
# SSH to your VPS
ssh your-vps

# Navigate to website directory
cd /usr/local/nginx/html/live

# Copy the scripts (upload via your preferred method)
# Make them executable
chmod +x gallery-generator.sh
chmod +x monthly-zip.sh

# Test the scripts
./gallery-generator.sh
./monthly-zip.sh
```

### Step 2: Set Up Crontab

Add these entries to root crontab on your VPS:

```bash
# Edit crontab
sudo crontab -e

# Add these lines:

# Generate gallery every 10 minutes
*/10 * * * * /usr/local/nginx/html/live/gallery-generator.sh >> /usr/local/nginx/html/live/logs/gallery-generator.log 2>&1

# Create monthly ZIP at midnight on the 1st of each month
0 0 1 * * /usr/local/nginx/html/live/monthly-zip.sh >> /usr/local/nginx/html/live/logs/monthly-zip.log 2>&1

# Keep existing capture generation (if you have it)
*/10 6-20 * * * /usr/local/nginx/html/live/generate_index.sh >> /usr/local/nginx/html/live/logs/generate_index.log 2>&1
```

### Step 3: Deploy Website Files

From your local machine:

```bash
# Navigate to your local project
cd /path/to/webcam-paris.com

# Sync updated files to VPS
rsync -avz --progress index.html your-vps:/usr/local/nginx/html/live/
rsync -avz --progress app.js your-vps:/usr/local/nginx/html/live/
rsync -avz --progress styles.css your-vps:/usr/local/nginx/html/live/
```

### Step 4: Create Required Directories

```bash
# SSH to VPS and create directories
ssh your-vps
mkdir -p /usr/local/nginx/html/live/downloads
mkdir -p /usr/local/nginx/html/live/logs
chmod 755 /usr/local/nginx/html/live/downloads
```

## Testing the Setup

### Test 1: Gallery Generation

```bash
# SSH to VPS
ssh your-vps

# Run gallery generator manually
cd /usr/local/nginx/html/live
./gallery-generator.sh

# Check if gallery-today.html was created
ls -la gallery-today.html

# Test in browser
curl -I https://webcam-paris.com/gallery-today.html
```

### Test 2: Monthly Archive

```bash
# Test monthly ZIP creation (creates for last month)
./monthly-zip.sh

# Check downloads directory
ls -la downloads/

# Test downloads page
curl -I https://webcam-paris.com/downloads/
```

### Test 3: Main Website

```bash
# Test main site
curl -I https://webcam-paris.com/

# Check gallery redirect
# Visit https://webcam-paris.com/#gallery in browser
# Click "Open Today's Gallery" button
```

## File Structure After Deployment

```
/usr/local/nginx/html/live/
├── index.html              # Main website (updated)
├── app.js                  # Main JS (updated)
├── styles.css              # Main CSS (updated)
├── gallery-generator.sh    # New: Gallery generator script
├── monthly-zip.sh          # New: Monthly archive script
├── gallery-today.html      # Generated: Today's gallery
├── captures/               # Existing: Image captures
│   ├── 2025-06-24/        # Daily directories
│   │   ├── image_*.jpg    # Captured images
│   │   └── index.txt      # Generated file list
│   └── ...
├── downloads/              # New: Monthly archives
│   ├── index.html         # Generated download page
│   ├── captures-2025-06.zip
│   └── ...
└── logs/                   # Log files
    ├── gallery-generator.log
    ├── monthly-zip.log
    └── ...
```

## Monitoring and Maintenance

### Check Logs

```bash
# Gallery generation logs
tail -f /usr/local/nginx/html/live/logs/gallery-generator.log

# Monthly archive logs
tail -f /usr/local/nginx/html/live/logs/monthly-zip.log
```

### Monitor Disk Space

```bash
# Check capture directory size
du -sh /usr/local/nginx/html/live/captures/

# Check downloads directory size
du -sh /usr/local/nginx/html/live/downloads/
```

### Manual Operations

```bash
# Force regenerate today's gallery
/usr/local/nginx/html/live/gallery-generator.sh

# Force create monthly archive for specific month
# Edit monthly-zip.sh to set specific month if needed

# Clean up old captures (be careful!)
find /usr/local/nginx/html/live/captures/ -type d -mtime +30 -delete
```

## Troubleshooting

### Gallery Not Updating
1. Check crontab is running: `sudo crontab -l`
2. Check script permissions: `ls -la gallery-generator.sh`
3. Check logs: `tail logs/gallery-generator.log`
4. Run manually: `./gallery-generator.sh`

### Mobile Streaming Issues
1. Check browser console for errors
2. Test on actual iOS device (not simulator)
3. Monitor network performance
4. Check HLS stream health: `curl -I https://webcam-paris.com/hls/stream.m3u8`

### Download Links Not Working
1. Check downloads directory permissions: `ls -la downloads/`
2. Check nginx configuration for downloads directory
3. Test ZIP file creation: `./monthly-zip.sh`

### High Server Load
1. Reduce gallery generation frequency (change from */10 to */15 or */20)
2. Optimize image sizes if needed
3. Monitor disk I/O during archive creation

## Performance Optimization

### Gallery Generator
- Runs every 10 minutes (144 times/day)
- Minimal CPU usage (mostly file operations)
- Memory usage: <10MB

### Monthly Archive
- Runs once per month
- High I/O during ZIP creation
- Recommend running during low-traffic hours

### Image Storage
- Each day: ~144 images (10 minutes × 14 hours)
- Each month: ~4,320 images
- Storage: ~50-100MB per month (depending on image size)

## Security Considerations

1. **File Permissions**: Scripts should be executable only by root
2. **Directory Access**: Downloads directory should be web-accessible but not writable
3. **Archive Access**: Consider adding basic authentication for downloads if needed
4. **Log Rotation**: Set up log rotation to prevent disk space issues

## Success Indicators

✅ **Gallery Working**: Visit `https://webcam-paris.com/#gallery`, click "Open Today's Gallery"
✅ **Downloads Working**: Visit `https://webcam-paris.com/downloads/` 
✅ **Mobile Streaming**: Test on iPhone Safari, should not buffer endlessly
✅ **Automatic Updates**: Gallery updates every 10 minutes during daylight hours
✅ **Monthly Archives**: New ZIP files appear monthly in downloads

## Support

For issues or questions:
1. Check this deployment guide
2. Review the CLAUDE.md file for technical details
3. Check VPS logs for errors
4. Test individual components manually