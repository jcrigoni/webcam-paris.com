# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modern Paris webcam website that provides a live stream of the Eiffel Tower with additional features like timelapses and photo galleries. The project is built as a single-page application (SPA) using vanilla HTML, CSS, and JavaScript with mobile-optimized streaming capabilities.

## Architecture

- **Single-Page Application**: Modern SPA with client-side routing in `index.html`
- **Mobile-First Design**: Responsive design optimized for mobile streaming
- **Intelligent Streaming**: Device detection for optimal HLS streaming strategy
- **Media Content**: Videos and images stored in the `videos/` directory
- **Logging System**: Stream monitoring logs stored in `logs/` directory
- **Performance Optimizations**: Lazy loading, reduced buffers for mobile, connection awareness

## Key Components

### Core Files
- `index.html`: Main SPA structure with all page sections (Live, Timelapses, Gallery, Privacy, Terms)
- `styles.css`: Modern CSS with custom properties, mobile-first responsive design
- `app.js`: Modular JavaScript with streaming optimization, routing, and performance features

### Media Structure
- `videos/output-day.mp4`: Day timelapse video
- `videos/output-night.mp4`: Night timelapse video  
- `videos/output-eiffel.mp4`: Eiffel Tower focused video
- `videos/couche-soleil.jpg`: Sunset photograph

### Logging System
- `logs/stream.log`: Current stream monitoring log
- `logs/stream.log.old`: Rotated stream log
- `logs/ffmpeg_output.log`: FFmpeg processing log

## Development Commands

Since this is a modern static website with no build process, it can be served directly from a web server.

### Local Development
```bash
# Serve locally using Python
python -m http.server 8000

# Or using Node.js
npx http-server .

# Or using PHP (if available)
php -S localhost:8000
```

### Testing Mobile Streaming
When testing mobile streaming functionality:
- Test on actual iOS Safari (not Chrome on iOS)
- Test on Android Chrome
- Use browser dev tools to simulate slow connections
- Check console for device detection logs

### Testing Responsive Layout
When testing layout across screen sizes:
- **Narrow browser window** (< 1400px): Content should be centered, no sidebar
- **Wide browser window** (> 1400px): Content + sidebar side-by-side, both centered
- **Very wide screens** (> 1600px): More spacing, everything still centered
- **Mobile simulation**: Use DevTools responsive mode to test mobile layouts
- **Check for overlaps**: Sidebar should never overlap video or main content

### Stream Monitoring
The logs indicate an automated stream monitoring system that:
- Monitors stream health every 30 seconds
- Automatically restarts failed streams
- Rotates logs when they reach size limits

## Key Technical Details

### Mobile-Optimized HLS Streaming
- **iOS Safari**: Uses native HLS support for best performance
- **Android/Mobile**: Uses HLS.js with reduced buffer settings (30s vs 90s)
- **Desktop**: Uses HLS.js with standard configuration
- **Stream URL**: `https://webcam-paris.com/hls/stream.m3u8`
- **Retry Logic**: Automatic retry with exponential backoff on failures
- **Connection Awareness**: Adapts to network changes and slow connections

### Device Detection Logic
Located in `app.js` - `detectDevice()` method:
- Detects iOS Safari for native HLS
- Identifies mobile devices for buffer optimization
- Checks connection type for quality adaptation
- Handles autoplay restrictions on mobile

### Single-Page Application
- **Client-side routing**: Hash-based routing with URL updates
- **Page sections**: Live, Timelapses, Gallery, Privacy, Terms
- **Navigation**: Mobile-first responsive navigation with hamburger menu
- **SEO friendly**: Proper page titles and meta tags

### Performance Optimizations
- **Lazy Loading**: Videos and images load only when needed
- **Intersection Observer**: Modern lazy loading with fallback
- **Page Visibility API**: Pauses video when tab is not visible
- **Connection API**: Adapts to network changes
- **Mobile Buffer Management**: Keeps buffer small on mobile devices

### Weather Integration
- **API**: OpenWeatherMap with robust error handling
- **Updates**: Every 30 minutes with fallback display
- **Timeout**: 10-second request timeout
- **API Key**: Embedded in `app.js` fetchWeather method

### Responsive Layout System
- **Container Wrapper**: `.container` div provides flexbox layout for large screens
- **Mobile-First**: Content centered on all screen sizes
- **Breakpoints**: 
  - Mobile/Tablet (< 1400px): No sidebar, content fully centered
  - Large Desktop (1400px+): Flexbox layout with content + sidebar
  - Extra Large (1600px+): More spacing between elements
- **Sidebar Positioning**: Uses `position: sticky` to stay with content flow, never overlaps

### Advertisement Integration
Pre-built ad spaces with clear commenting:
- **Top Banner**: 728x90 (desktop) / 320x50 (mobile)
- **Content Banner**: 300x250 medium rectangle
- **Sidebar**: 160x600 skyscraper (shows only on screens 1400px+ wide)

## Code Style Conventions

- **Modern CSS**: CSS custom properties, mobile-first design
- **Semantic HTML**: Proper structure with accessibility features
- **Modular JavaScript**: Class-based architecture with clear separation
- **BEM-style CSS**: Block-Element-Modifier naming convention
- **Progressive Enhancement**: Works without JavaScript for basic content
- **Accessibility**: ARIA labels, reduced motion support, keyboard navigation

## Common Maintenance Tasks

### Content Updates
1. **Adding new videos**: Update `data-src` attributes in timelapses/gallery sections
2. **Updating weather API**: Replace API key in `app.js` fetchWeather method
3. **Stream URL changes**: Update stream URL in `app.js` initializeStreaming methods
4. **Advertisement updates**: Modify ad banner HTML in designated sections

### Performance Monitoring
1. **Stream health**: Monitor logs in `logs/` directory for connection issues
2. **Mobile performance**: Test streaming on actual devices, especially iOS Safari
3. **Loading times**: Check lazy loading performance and image optimization
4. **Buffer optimization**: Adjust buffer settings in HLS configuration if needed

### Code Maintenance
1. **CSS updates**: All styles are in single `styles.css` file
2. **JavaScript updates**: Main logic is in `app.js` ParisWebcamApp class
3. **Mobile compatibility**: Test device detection logic when adding features
4. **SEO updates**: Update meta tags and structured data in `index.html`

### Common Issues
- **iOS streaming fails**: Check if using native HLS vs HLS.js
- **Mobile autoplay blocked**: Ensure muted attribute and proper user interaction
- **Navigation broken**: Verify hash routing and data-page attributes
- **Lazy loading not working**: Check IntersectionObserver support and fallbacks
- **Layout issues on large screens**: 
  - Content should be centered using `.container` flexbox layout
  - Sidebar appears only on 1400px+ screens with `position: sticky`
  - If content appears stuck to one side, check container max-width and centering
- **Sidebar overlapping content**: Ensure using flexbox layout, not fixed positioning

## Gallery Feature Implementation (Today's Captures)

### Overview
Attempted implementation of dynamic gallery showing today's captured images from the VPS capture system. Images are captured every 10 minutes during daylight hours (6 AM - 8 PM) and stored in `/usr/local/nginx/html/live/captures/YYYY-MM-DD/` with naming format `image_YYYY-MM-DD_HH-mm-ss.jpg`.

### Technical Implementation

#### HTML Structure (index.html)
- Replaced static gallery content with dynamic "Today's Captures" section
- Added gallery status display (`#galleryStatus`) and image container (`#imageGallery`)
- Added manual reload button for debugging (`#reloadImagesBtn`)

#### JavaScript Functionality (app.js)
- **initializeImageGallery()**: Sets up gallery initialization and 10-minute auto-refresh
- **loadTodaysImages()**: Main function to fetch and display today's images
- **fetchFromDirectoryListing()**: Attempts to load image list from `index.txt` file
- **fetchTodaysImageList()**: Fallback method using HEAD requests to detect images
- **displayImages()**: Creates responsive grid layout with hover effects and fullscreen capability
- **Error handling**: Shows appropriate messages for no images or network errors

#### CSS Styling (styles.css)
- Responsive grid layout: `grid-template-columns: repeat(auto-fill, minmax(280px, 1fr))`
- Mobile-first approach: 1 column on mobile, multi-column on desktop
- Image cards with hover effects and overlay buttons
- Fullscreen modal with backdrop and close controls
- Status indicators and error state styling

#### Server-Side Scripts

**generate_index.sh**: 
- Generates `index.txt` file listing all JPG files in today's directory
- Fixes file permissions (644 for web accessibility)
- Runs via crontab every 10 minutes: `*/10 * * * * /usr/local/nginx/html/live/generate_index.sh`
- Cleans up old index files (older than 2 days)

**fix_permissions.sh**:
- One-time script to fix permissions for all existing captures
- Sets 644 permissions for all JPG and index.txt files
- Sets 755 permissions for directories

### Path Structure
- **VPS Directory**: `/usr/local/nginx/html/live/captures/YYYY-MM-DD/`
- **Web Path**: `/captures/YYYY-MM-DD/` (relative to document root)
- **Index File**: `/captures/YYYY-MM-DD/index.txt`
- **Images**: `/captures/YYYY-MM-DD/image_YYYY-MM-DD_HH-mm-ss.jpg`

### Verified Working Components
✅ **Server Access**: Images accessible via HTTPS (confirmed with curl)
✅ **Directory Listing**: index.txt generation and web accessibility
✅ **File Permissions**: Fixed with automated scripts
✅ **HTTPS Redirects**: Nginx properly redirects HTTP to HTTPS
✅ **Image Serving**: Individual images serve correctly (HTTP 200 OK)

### Current Issues
❌ **mobile streaming**: very long buffering on iphones and androids

### Debug Information Added
- Console logging for gallery initialization and page detection
- Detailed fetch request logging with response status
- Manual reload button for testing (fixed onclick handler)
- Status indicators showing loading/error states

### Alternative Approaches to Consider
1. **Server-Side Rendering**: Generate HTML gallery server-side instead of client-side JavaScript
2. **Direct Directory Listing**: Use nginx autoindex module for automatic directory listing
3. **API Endpoint**: Create PHP/Node.js endpoint to return JSON list of images
4. **Static File Generation**: Generate static HTML gallery files alongside images
5. **Simplified JavaScript**: Remove SPA complexity and use direct page-based approach

### Files Modified
- `index.html`: Gallery section HTML structure
- `app.js`: Gallery JavaScript functionality and debugging
- `styles.css`: Gallery responsive CSS styling
- `generate_index.sh`: Server-side directory listing script
- `fix_permissions.sh`: Permission fixing script

### Layout Architecture
The layout uses a modern responsive approach:
1. **HTML Structure**: 
   ```
   <div class="container">
     <main class="main">...</main>
     <aside class="ad-sidebar">...</aside>
   </div>
   ```
2. **CSS Strategy**:
   - Small screens: `.container` is normal block, `.ad-sidebar` is `display: none`
   - Large screens (1400px+): `.container` becomes `display: flex` with centered content
   - Sidebar uses `position: sticky` to scroll with content, never overlaps