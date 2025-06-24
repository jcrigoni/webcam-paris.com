/**
 * Modern Paris Webcam Application
 * Single-page application with mobile-optimized streaming
 */

class ParisWebcamApp {
    constructor() {
        this.currentPage = 'live';
        this.videoPlayer = null;
        this.hls = null;
        this.streamRetryCount = 0;
        this.maxRetries = 3;
        this.retryDelay = 5000;
        this.weatherUpdateInterval = null;
        this.statusUpdateInterval = null;
        
        // Initialize the app when DOM is ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.init());
        } else {
            this.init();
        }
    }

    /**
     * Initialize the application
     */
    init() {
        console.log('Initializing Paris Webcam App...');
        
        this.setupEventListeners();
        this.initializeRouter();
        this.initializeVideoPlayer();
        this.initializeWeather();
        this.initializeLazyLoading();
        this.initializeImageGallery();
        this.setupPerformanceOptimizations();
        
        console.log('App initialized successfully');
    }

    /**
     * Device detection for optimal streaming strategy
     */
    detectDevice() {
        const userAgent = navigator.userAgent.toLowerCase();
        const isMobile = /iphone|ipad|ipod|android|blackberry|mini|windows\sce|palm/i.test(userAgent);
        const isIOS = /iphone|ipad|ipod/i.test(userAgent);
        const isSafari = /safari/i.test(userAgent) && !/chrome/i.test(userAgent);
        const isAndroid = /android/i.test(userAgent);
        
        return {
            isMobile,
            isIOS,
            isSafari,
            isAndroid,
            supportsHLS: this.checkHLSSupport(),
            connectionType: this.getConnectionType()
        };
    }

    /**
     * Check if browser supports native HLS
     */
    checkHLSSupport() {
        const video = document.createElement('video');
        return video.canPlayType('application/vnd.apple.mpegurl') !== '';
    }

    /**
     * Get connection type for optimization
     */
    getConnectionType() {
        if ('connection' in navigator) {
            return navigator.connection.effectiveType || 'unknown';
        }
        return 'unknown';
    }

    /**
     * Initialize video player with device-specific optimization
     */
    initializeVideoPlayer() {
        const video = document.getElementById('liveVideo');
        const videoOverlay = document.getElementById('videoOverlay');
        const statusDot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');
        
        if (!video) {
            console.error('Video element not found');
            return;
        }

        this.videoPlayer = video;
        this.showVideoOverlay('Initializing stream...');
        
        const device = this.detectDevice();
        console.log('Device detection:', device);
        
        // Configure video for mobile optimization
        if (device.isMobile) {
            video.setAttribute('webkit-playsinline', 'true');
            video.setAttribute('playsinline', 'true');
            video.muted = true; // Required for autoplay on mobile
        }

        this.initializeStreaming(device);
    }

    /**
     * Initialize streaming based on device capabilities
     */
    initializeStreaming(device) {
        const video = this.videoPlayer;
        const streamUrl = 'https://webcam-paris.com/hls/stream.m3u8';
        
        // Strategy 1: iOS Safari - Use native HLS support
        if (device.isIOS && device.isSafari) {
            console.log('Using native iOS HLS support');
            this.setupNativeHLS(video, streamUrl);
        }
        // Strategy 2: Android or other mobile browsers
        else if (device.isMobile) {
            console.log('Using mobile-optimized HLS.js');
            this.setupMobileHLS(video, streamUrl);
        }
        // Strategy 3: Desktop browsers
        else {
            console.log('Using desktop HLS.js configuration');
            this.setupDesktopHLS(video, streamUrl);
        }
    }

    /**
     * Setup native HLS for iOS Safari
     */
    setupNativeHLS(video, streamUrl) {
        video.src = streamUrl;
        
        video.addEventListener('loadstart', () => {
            this.showVideoOverlay('Loading stream...');
        });
        
        video.addEventListener('loadeddata', () => {
            this.hideVideoOverlay();
            this.updateStreamStatus('online', 'Live Stream Active');
            this.resetRetryCount();
            this.updateLastUpdate();
        });
        
        video.addEventListener('canplay', () => {
            this.hideVideoOverlay();
            if (video.paused) {
                video.play().catch(e => {
                    console.log('Autoplay prevented:', e);
                    this.showVideoOverlay('Tap to play');
                });
            }
        });
        
        video.addEventListener('error', (e) => {
            console.error('Native video error:', e);
            this.handleStreamError('Stream connection failed');
        });

        video.addEventListener('stalled', () => {
            this.showVideoOverlay('Buffering...');
        });

        video.addEventListener('waiting', () => {
            this.showVideoOverlay('Buffering...');
        });

        video.addEventListener('playing', () => {
            this.hideVideoOverlay();
        });
    }

    /**
     * Setup HLS.js for mobile with reduced buffer
     */
    setupMobileHLS(video, streamUrl) {
        if (!window.Hls) {
            this.handleStreamError('HLS.js not available');
            return;
        }

        if (!Hls.isSupported()) {
            console.log('HLS.js not supported, trying native');
            this.setupNativeHLS(video, streamUrl);
            return;
        }

        const hls = new Hls({
            // Mobile-optimized configuration
            enableWorker: true,
            lowLatencyMode: true,
            backBufferLength: 30, // Reduced from 90 for mobile
            maxBufferLength: 60,  // Reduced buffer
            maxMaxBufferLength: 120,
            liveSyncDurationCount: 2,
            liveMaxLatencyDurationCount: 5,
            
            // Mobile network optimization
            manifestLoadingTimeOut: 10000,
            manifestLoadingMaxRetry: 3,
            segmentLoadingTimeOut: 8000,
            segmentLoadingMaxRetry: 2,
            
            // Reduce startup delay
            startLevel: -1, // Auto quality
            testBandwidth: false
        });

        this.hls = hls;
        this.setupHLSEventHandlers(hls, video);
        
        hls.loadSource(streamUrl);
        hls.attachMedia(video);
    }

    /**
     * Setup HLS.js for desktop
     */
    setupDesktopHLS(video, streamUrl) {
        if (!window.Hls) {
            this.handleStreamError('HLS.js not available');
            return;
        }

        if (!Hls.isSupported()) {
            this.setupNativeHLS(video, streamUrl);
            return;
        }

        const hls = new Hls({
            // Desktop configuration
            enableWorker: true,
            lowLatencyMode: true,
            backBufferLength: 90,
            maxBufferLength: 180,
            liveSyncDurationCount: 3,
            liveMaxLatencyDurationCount: 10
        });

        this.hls = hls;
        this.setupHLSEventHandlers(hls, video);
        
        hls.loadSource(streamUrl);
        hls.attachMedia(video);
    }

    /**
     * Setup HLS.js event handlers
     */
    setupHLSEventHandlers(hls, video) {
        hls.on(Hls.Events.MANIFEST_PARSED, () => {
            console.log('HLS manifest parsed');
            this.hideVideoOverlay();
            this.updateStreamStatus('online', 'Live Stream Active');
            this.resetRetryCount();
            this.updateLastUpdate();
            
            // Attempt autoplay
            video.play().catch(e => {
                console.log('Autoplay prevented:', e);
                this.showVideoOverlay('Tap to play');
            });
        });

        hls.on(Hls.Events.LEVEL_LOADED, () => {
            this.hideVideoOverlay();
        });

        hls.on(Hls.Events.ERROR, (event, data) => {
            console.error('HLS error:', data);
            
            if (data.fatal) {
                this.handleStreamError(`Stream error: ${data.type}`);
            } else {
                // Non-fatal errors
                if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
                    this.showVideoOverlay('Network issue, retrying...');
                }
            }
        });

        // Buffer management for mobile
        hls.on(Hls.Events.BUFFER_APPENDED, () => {
            const device = this.detectDevice();
            if (device.isMobile && video.buffered.length > 0) {
                const bufferEnd = video.buffered.end(video.buffered.length - 1);
                const currentTime = video.currentTime;
                
                // Keep buffer small on mobile
                if (bufferEnd - currentTime > 30) {
                    try {
                        hls.trigger(Hls.Events.BUFFER_FLUSHING, {
                            startOffset: 0,
                            endOffset: currentTime - 5
                        });
                    } catch (e) {
                        console.log('Buffer flush failed:', e);
                    }
                }
            }
        });
    }

    /**
     * Handle stream errors with retry logic
     */
    handleStreamError(message) {
        console.error('Stream error:', message);
        this.updateStreamStatus('offline', message);
        
        if (this.streamRetryCount < this.maxRetries) {
            this.streamRetryCount++;
            const retryIn = this.retryDelay / 1000;
            this.showVideoOverlay(`Retrying in ${retryIn}s... (${this.streamRetryCount}/${this.maxRetries})`);
            
            setTimeout(() => {
                console.log(`Retry attempt ${this.streamRetryCount}`);
                this.retryStream();
            }, this.retryDelay);
        } else {
            this.showVideoOverlay('Stream temporarily unavailable. Please refresh the page.');
            this.updateStreamStatus('offline', 'Stream Offline');
        }
    }

    /**
     * Retry stream connection
     */
    retryStream() {
        if (this.hls) {
            this.hls.destroy();
            this.hls = null;
        }
        
        // Reset video
        if (this.videoPlayer) {
            this.videoPlayer.src = '';
            this.videoPlayer.load();
        }
        
        // Reinitialize streaming
        setTimeout(() => {
            this.initializeVideoPlayer();
        }, 1000);
    }

    /**
     * Reset retry counter
     */
    resetRetryCount() {
        this.streamRetryCount = 0;
    }

    /**
     * Show video overlay with message
     */
    showVideoOverlay(message) {
        const overlay = document.getElementById('videoOverlay');
        const messageEl = document.getElementById('videoMessage');
        
        if (overlay && messageEl) {
            messageEl.textContent = message;
            overlay.classList.add('video-overlay--show');
        }
    }

    /**
     * Hide video overlay
     */
    hideVideoOverlay() {
        const overlay = document.getElementById('videoOverlay');
        if (overlay) {
            overlay.classList.remove('video-overlay--show');
        }
    }

    /**
     * Update stream status indicator
     */
    updateStreamStatus(status, text) {
        const statusDot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');
        
        if (statusDot) {
            statusDot.className = `status-dot ${status === 'online' ? 'status-dot--online' : ''}`;
        }
        
        if (statusText) {
            statusText.textContent = text;
        }
    }

    /**
     * Update last update timestamp
     */
    updateLastUpdate() {
        const lastUpdate = document.getElementById('lastUpdate');
        if (lastUpdate) {
            const now = new Date();
            lastUpdate.textContent = `Last updated: ${now.toLocaleTimeString()}`;
        }
    }

    /**
     * Initialize SPA routing system
     */
    initializeRouter() {
        // Handle initial page load
        const hash = window.location.hash.slice(1) || 'live';
        this.navigateToPage(hash);
        
        // Handle browser back/forward
        window.addEventListener('popstate', () => {
            const page = window.location.hash.slice(1) || 'live';
            this.navigateToPage(page, false);
        });
    }

    /**
     * Navigate to a specific page
     */
    navigateToPage(page, updateHistory = true) {
        // Valid pages
        const validPages = ['live', 'timelapses', 'gallery', 'privacy', 'terms'];
        
        if (!validPages.includes(page)) {
            page = 'live';
        }
        
        // Update URL if needed
        if (updateHistory && window.location.hash.slice(1) !== page) {
            window.history.pushState({}, '', `#${page}`);
        }
        
        // Update page visibility
        this.showPage(page);
        
        // Update navigation
        this.updateNavigation(page);
        
        // Update page title
        this.updatePageTitle(page);
        
        // Lazy load content for new page
        this.loadPageContent(page);
        
        this.currentPage = page;
    }

    /**
     * Show specific page and hide others
     */
    showPage(pageId) {
        const pages = document.querySelectorAll('.page');
        pages.forEach(page => {
            if (page.getAttribute('data-page') === pageId) {
                page.classList.remove('page--hidden');
            } else {
                page.classList.add('page--hidden');
            }
        });
    }

    /**
     * Update navigation active state
     */
    updateNavigation(activePage) {
        const navLinks = document.querySelectorAll('.nav__link');
        navLinks.forEach(link => {
            const linkPage = link.getAttribute('data-page');
            if (linkPage === activePage) {
                link.classList.add('nav__link--active');
            } else {
                link.classList.remove('nav__link--active');
            }
        });
    }

    /**
     * Update page title based on current page
     */
    updatePageTitle(page) {
        const titles = {
            live: 'Webcam Paris - Live Eiffel Tower Stream',
            timelapses: 'Timelapses | Webcam Paris',
            gallery: 'Gallery | Webcam Paris',
            privacy: 'Privacy Policy | Webcam Paris',
            terms: 'Terms of Service | Webcam Paris'
        };
        
        document.title = titles[page] || titles.live;
    }

    /**
     * Load content for specific page (lazy loading)
     */
    loadPageContent(page) {
        if (page === 'timelapses' || page === 'gallery') {
            this.loadLazyMedia();
        }
        
        if (page === 'gallery') {
            this.loadTodaysImages();
        }
    }

    /**
     * Initialize lazy loading for media content
     */
    initializeLazyLoading() {
        if ('IntersectionObserver' in window) {
            this.setupIntersectionObserver();
        } else {
            // Fallback for older browsers
            this.loadAllMedia();
        }
    }

    /**
     * Setup intersection observer for lazy loading
     */
    setupIntersectionObserver() {
        const mediaObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.loadMediaElement(entry.target);
                    mediaObserver.unobserve(entry.target);
                }
            });
        }, {
            rootMargin: '50px 0px',
            threshold: 0.01
        });

        // Observe all lazy media elements
        const lazyMedia = document.querySelectorAll('[data-src]');
        lazyMedia.forEach(media => mediaObserver.observe(media));
    }

    /**
     * Load specific media element
     */
    loadMediaElement(element) {
        const src = element.getAttribute('data-src');
        if (!src) return;

        if (element.tagName === 'VIDEO') {
            const source = element.querySelector('source[data-src]');
            if (source) {
                source.src = src;
                source.removeAttribute('data-src');
            }
            element.load();
        } else if (element.tagName === 'IMG') {
            element.src = src;
        }
        
        element.removeAttribute('data-src');
    }

    /**
     * Load lazy media for current page
     */
    loadLazyMedia() {
        const currentPageMedia = document.querySelectorAll(`#${this.currentPage}Page [data-src]`);
        currentPageMedia.forEach(media => this.loadMediaElement(media));
    }

    /**
     * Load all media (fallback)
     */
    loadAllMedia() {
        const allLazyMedia = document.querySelectorAll('[data-src]');
        allLazyMedia.forEach(media => this.loadMediaElement(media));
    }

    /**
     * Initialize weather widget
     */
    initializeWeather() {
        this.fetchWeather();
        
        // Update weather every 30 minutes
        this.weatherUpdateInterval = setInterval(() => {
            this.fetchWeather();
        }, 30 * 60 * 1000);
        
        // Update status every 5 minutes
        this.statusUpdateInterval = setInterval(() => {
            this.updateLastUpdate();
        }, 5 * 60 * 1000);
    }

    /**
     * Fetch weather data from API
     */
    async fetchWeather() {
        try {
            const response = await fetch(
                'https://api.openweathermap.org/data/2.5/weather?q=Paris&appid=9393ff701ada56eb0e753b9d76684cb2&units=metric',
                { timeout: 10000 }
            );
            
            if (!response.ok) {
                throw new Error(`Weather API error: ${response.status}`);
            }
            
            const data = await response.json();
            this.displayWeather(data);
        } catch (error) {
            console.warn('Weather fetch failed:', error);
            this.displayFallbackWeather();
        }
    }

    /**
     * Display weather data
     */
    displayWeather(data) {
        const weatherContent = document.getElementById('weatherContent');
        if (!weatherContent) return;

        const iconMap = {
            '01d': '☀️', '01n': '🌙', '02d': '⛅', '02n': '☁️',
            '03d': '☁️', '03n': '☁️', '04d': '☁️', '04n': '☁️',
            '09d': '🌧️', '09n': '🌧️', '10d': '🌦️', '10n': '🌧️',
            '11d': '⛈️', '11n': '⛈️', '13d': '❄️', '13n': '❄️',
            '50d': '🌫️', '50n': '🌫️'
        };
        
        const icon = iconMap[data.weather[0].icon] || '🌤️';
        
        weatherContent.innerHTML = `
            <div class="weather-icon">${icon}</div>
            <div class="weather-details">
                <h4>${Math.round(data.main.temp)}°C</h4>
                <p>${data.weather[0].description}</p>
                <p>Feels like ${Math.round(data.main.feels_like)}°C</p>
                <p>Humidity: ${data.main.humidity}%</p>
            </div>
        `;
    }

    /**
     * Display fallback weather when API fails
     */
    displayFallbackWeather() {
        const weatherContent = document.getElementById('weatherContent');
        if (!weatherContent) return;

        weatherContent.innerHTML = `
            <div class="weather-icon">🌤️</div>
            <div class="weather-details">
                <h4>--°C</h4>
                <p>Weather data unavailable</p>
                <p>Please check back later</p>
            </div>
        `;
    }

    /**
     * Setup performance optimizations
     */
    setupPerformanceOptimizations() {
        // Page visibility API for performance
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                // Pause video when tab is not visible
                if (this.videoPlayer && !this.videoPlayer.paused) {
                    this.videoPlayer.pause();
                }
            } else {
                // Resume when tab becomes visible
                if (this.videoPlayer && this.videoPlayer.paused && this.currentPage === 'live') {
                    this.videoPlayer.play().catch(e => {
                        console.log('Auto-resume failed:', e);
                    });
                }
            }
        });

        // Connection change handling
        if ('connection' in navigator) {
            navigator.connection.addEventListener('change', () => {
                const connection = navigator.connection;
                console.log('Connection changed:', connection.effectiveType);
                
                // Restart stream with new connection settings if needed
                if (this.currentPage === 'live' && connection.effectiveType === '2g') {
                    console.log('Slow connection detected, optimizing stream');
                    // Could implement lower quality stream here
                }
            });
        }
    }

    /**
     * Setup event listeners
     */
    setupEventListeners() {
        // Navigation clicks
        document.addEventListener('click', (e) => {
            const navLink = e.target.closest('[data-page]');
            if (navLink) {
                e.preventDefault();
                const page = navLink.getAttribute('data-page');
                this.navigateToPage(page);
            }
        });

        // Mobile menu toggle
        const mobileMenuToggle = document.getElementById('mobileMenuToggle');
        const navLinks = document.getElementById('navLinks');
        
        if (mobileMenuToggle && navLinks) {
            mobileMenuToggle.addEventListener('click', () => {
                navLinks.classList.toggle('nav__links--active');
            });
        }

        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            const nav = document.querySelector('.nav');
            if (nav && !nav.contains(e.target)) {
                const navLinks = document.getElementById('navLinks');
                if (navLinks) {
                    navLinks.classList.remove('nav__links--active');
                }
            }
        });

        // Video click overlay handling
        document.addEventListener('click', (e) => {
            const videoOverlay = e.target.closest('.video-overlay');
            if (videoOverlay && this.videoPlayer) {
                this.videoPlayer.play().catch(e => {
                    console.log('Play failed:', e);
                });
            }
        });
    }

    /**
     * Initialize image gallery for today's captures
     */
    initializeImageGallery() {
        this.galleryUpdateInterval = null;
        this.currentImages = [];
        
        // Load gallery when gallery page is accessed
        if (this.currentPage === 'gallery') {
            this.loadTodaysImages();
        }
        
        // Set up auto-refresh every 10 minutes
        this.galleryUpdateInterval = setInterval(() => {
            if (this.currentPage === 'gallery') {
                this.loadTodaysImages();
            }
        }, 10 * 60 * 1000);
    }

    /**
     * Load today's captured images
     */
    async loadTodaysImages() {
        const galleryStatus = document.getElementById('galleryStatus');
        const imageGallery = document.getElementById('imageGallery');
        
        if (!galleryStatus || !imageGallery) return;

        try {
            const today = new Date().toISOString().split('T')[0];
            const capturesPath = `/live/captures/${today}/`;
            
            console.log(`Loading images for today: ${today}`);
            console.log(`Captures path: ${capturesPath}`);
            
            // Update status
            galleryStatus.querySelector('.status-text').textContent = 'Loading today\'s images...';
            
            // First try to fetch a directory listing file if it exists
            let images = await this.fetchFromDirectoryListing(capturesPath);
            
            // If no directory listing, fall back to checking individual images
            if (images.length === 0) {
                console.log('No directory listing found, checking individual images...');
                images = await this.fetchTodaysImageList(capturesPath);
            }
            
            console.log(`Found ${images.length} images:`, images);
            
            if (images.length === 0) {
                this.displayNoImagesMessage();
                return;
            }
            
            // Sort images by time (newest first)
            images.sort((a, b) => b.localeCompare(a));
            
            // Update gallery if images have changed
            if (JSON.stringify(images) !== JSON.stringify(this.currentImages)) {
                this.currentImages = images;
                this.displayImages(images, capturesPath);
            }
            
            // Update status
            galleryStatus.querySelector('.status-text').textContent = `${images.length} images captured today`;
            document.getElementById('lastUpdate').textContent = `Last updated: ${new Date().toLocaleTimeString()}`;
            
        } catch (error) {
            console.error('Failed to load today\'s images:', error);
            this.displayErrorMessage();
        }
    }

    /**
     * Try to fetch images from a directory listing file
     */
    async fetchFromDirectoryListing(capturesPath) {
        try {
            // Try to fetch a simple directory listing file
            const response = await fetch(`${capturesPath}index.txt`, {
                headers: { 'Cache-Control': 'no-cache' }
            });
            
            if (response.ok) {
                const text = await response.text();
                const images = text.split('\n')
                    .filter(line => line.trim().length > 0)
                    .filter(line => line.endsWith('.jpg'))
                    .map(line => line.trim());
                
                console.log('Found directory listing with images:', images);
                return images;
            }
        } catch (e) {
            console.log('No directory listing file found');
        }
        return [];
    }

    /**
     * Fetch list of today's images
     */
    async fetchTodaysImageList(capturesPath) {
        const images = [];
        const today = new Date().toISOString().split('T')[0];
        const now = new Date();
        
        // Generate possible image names for today (every 10 minutes from 6 AM to 8 PM)
        const startHour = 6;
        const endHour = 20;
        
        // Create array of all possible image times for today
        const possibleImages = [];
        for (let hour = startHour; hour <= endHour; hour++) {
            for (let minute = 0; minute < 60; minute += 10) {
                const imageTime = new Date();
                imageTime.setHours(hour, minute, 0, 0);
                
                // Only check for images from times that have already passed
                if (imageTime <= now) {
                    const timeStr = `${hour.toString().padStart(2, '0')}-${minute.toString().padStart(2, '0')}-00`;
                    const filename = `image_${today}_${timeStr}.jpg`;
                    possibleImages.push(filename);
                }
            }
        }
        
        // Check each possible image in parallel with timeout
        const imageChecks = possibleImages.map(async (filename) => {
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 2000); // 2 second timeout
                
                const response = await fetch(`${capturesPath}${filename}`, { 
                    method: 'HEAD',
                    signal: controller.signal
                });
                
                clearTimeout(timeoutId);
                
                if (response.ok) {
                    return filename;
                }
            } catch (e) {
                // Image doesn't exist or network error, return null
            }
            return null;
        });
        
        // Wait for all checks to complete
        const results = await Promise.all(imageChecks);
        
        // Filter out null results
        const existingImages = results.filter(filename => filename !== null);
        
        console.log(`Found ${existingImages.length} images for today:`, existingImages);
        
        return existingImages;
    }

    /**
     * Display images in the gallery
     */
    displayImages(images, basePath) {
        const imageGallery = document.getElementById('imageGallery');
        if (!imageGallery) return;
        
        imageGallery.innerHTML = '';
        
        images.forEach((filename, index) => {
            const imageItem = document.createElement('div');
            imageItem.className = 'gallery-item';
            
            // Extract time from filename for display
            const timeMatch = filename.match(/image_\d{4}-\d{2}-\d{2}_(\d{2})-(\d{2})-(\d{2})\.jpg/);
            const timeDisplay = timeMatch ? `${timeMatch[1]}:${timeMatch[2]}` : 'Unknown time';
            
            imageItem.innerHTML = `
                <div class="gallery-item__image-container">
                    <img 
                        class="gallery-item__image" 
                        data-src="${basePath}${filename}"
                        alt="Paris webcam capture at ${timeDisplay}"
                        loading="lazy"
                    >
                    <div class="gallery-item__overlay">
                        <button class="gallery-item__fullscreen" onclick="openImageFullscreen('${basePath}${filename}')">
                            📱 View Full Size
                        </button>
                    </div>
                </div>
                <div class="gallery-item__info">
                    <span class="gallery-item__time">${timeDisplay}</span>
                    <span class="gallery-item__index">${index + 1}/${images.length}</span>
                </div>
            `;
            
            imageGallery.appendChild(imageItem);
        });
        
        // Initialize lazy loading for new images
        this.initializeLazyLoadingForGallery();
    }

    /**
     * Display message when no images are available
     */
    displayNoImagesMessage() {
        const imageGallery = document.getElementById('imageGallery');
        const galleryStatus = document.getElementById('galleryStatus');
        
        if (imageGallery) {
            imageGallery.innerHTML = `
                <div class="gallery-message">
                    <h3>No captures available yet today</h3>
                    <p>Images are captured every 10 minutes during daylight hours (6 AM - 8 PM).</p>
                    <p>Check back during daylight hours to see today's captures!</p>
                </div>
            `;
        }
        
        if (galleryStatus) {
            galleryStatus.querySelector('.status-text').textContent = 'No images captured today yet';
        }
    }

    /**
     * Display error message
     */
    displayErrorMessage() {
        const imageGallery = document.getElementById('imageGallery');
        const galleryStatus = document.getElementById('galleryStatus');
        
        if (imageGallery) {
            imageGallery.innerHTML = `
                <div class="gallery-message gallery-message--error">
                    <h3>Unable to load images</h3>
                    <p>There was an issue loading today's captures. Please try refreshing the page.</p>
                </div>
            `;
        }
        
        if (galleryStatus) {
            galleryStatus.querySelector('.status-text').textContent = 'Error loading images';
        }
    }

    /**
     * Initialize lazy loading specifically for gallery images
     */
    initializeLazyLoadingForGallery() {
        if ('IntersectionObserver' in window) {
            const galleryObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        this.loadMediaElement(entry.target);
                        galleryObserver.unobserve(entry.target);
                    }
                });
            }, {
                rootMargin: '100px 0px',
                threshold: 0.01
            });

            const galleryImages = document.querySelectorAll('.gallery-item__image[data-src]');
            galleryImages.forEach(img => galleryObserver.observe(img));
        }
    }

    /**
     * Cleanup resources
     */
    destroy() {
        if (this.hls) {
            this.hls.destroy();
        }
        
        if (this.weatherUpdateInterval) {
            clearInterval(this.weatherUpdateInterval);
        }
        
        if (this.statusUpdateInterval) {
            clearInterval(this.statusUpdateInterval);
        }
        
        if (this.galleryUpdateInterval) {
            clearInterval(this.galleryUpdateInterval);
        }
    }
}

/**
 * Global utility functions
 */

/**
 * Share stream functionality
 */
function shareStream() {
    const url = window.location.href.split('#')[0] + '#live';
    const title = 'Webcam Paris - Live Eiffel Tower Stream';
    
    if (navigator.share) {
        navigator.share({
            title: title,
            url: url
        }).catch(err => console.log('Share failed:', err));
    } else if (navigator.clipboard) {
        navigator.clipboard.writeText(url).then(() => {
            alert('Stream URL copied to clipboard!');
        }).catch(() => {
            // Fallback to prompt
            prompt('Copy this URL:', url);
        });
    } else {
        // Fallback to prompt
        prompt('Copy this URL:', url);
    }
}

/**
 * Open image in fullscreen
 */
function openImageFullscreen(imageSrc) {
    const fullscreenOverlay = document.createElement('div');
    fullscreenOverlay.className = 'fullscreen-overlay';
    fullscreenOverlay.innerHTML = `
        <div class="fullscreen-content">
            <button class="fullscreen-close" onclick="closeImageFullscreen()">&times;</button>
            <img class="fullscreen-image" src="${imageSrc}" alt="Full size capture">
        </div>
    `;
    
    document.body.appendChild(fullscreenOverlay);
    document.body.style.overflow = 'hidden';
    
    // Close on background click
    fullscreenOverlay.addEventListener('click', (e) => {
        if (e.target === fullscreenOverlay) {
            closeImageFullscreen();
        }
    });
    
    // Close on escape key
    document.addEventListener('keydown', function escapeHandler(e) {
        if (e.key === 'Escape') {
            closeImageFullscreen();
            document.removeEventListener('keydown', escapeHandler);
        }
    });
}

/**
 * Close fullscreen image
 */
function closeImageFullscreen() {
    const fullscreenOverlay = document.querySelector('.fullscreen-overlay');
    if (fullscreenOverlay) {
        fullscreenOverlay.remove();
        document.body.style.overflow = '';
    }
}

/**
 * Analytics tracking (placeholder)
 */
function trackEvent(action, category = 'Webcam') {
    // Google Analytics 4 example:
    // gtag('event', action, { event_category: category });
    console.log(`Analytics: ${category} - ${action}`);
}

// Initialize the application
const webcamApp = new ParisWebcamApp();

// Export for debugging
window.webcamApp = webcamApp;