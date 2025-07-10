#!/bin/bash

# Configuration
PIDFILE="/tmp/stream.pid"
# Changed log location to user's home directory
LOGFILE="/home/user/dev/wp-local/logs/stream.log"
FFMPEG_LOGFILE="/home/user/dev/wp-local/logs/ffmpeg_output.log"
STATSFILE="/tmp/stream_stats.txt"
RTSP_SOURCE="rtsp://{camera_ip}/h264Preview_01_main"
RTMP_DESTINATION="rtmp://{vps_ip}/live/stream"
RTMP_HOST="{vps_ip}"
RTMP_PORT="1935"

# Health check interval (seconds)
CHECK_INTERVAL=30

# Maximum unhealthy checks before restart
MAX_FAILURES=3
FAILURE_COUNT=0

# Log rotation settings
MAX_LOG_SIZE=10485760 # 10MB in bytes
MAX_FFMPEG_LOG_SIZE=52428800 # 50MB in bytes

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOGFILE")"

log_message() {
    echo "$(date): $1" | tee -a $LOGFILE
    # Check if main log file is getting too large and rotate it
    if [ -f "$LOGFILE" ] && [ $(stat -f%z "$LOGFILE" 2>/dev/null || stat -c%s "$LOGFILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
        mv "$LOGFILE" "${LOGFILE}.old"
        echo "$(date): Log rotated due to size limit" > "$LOGFILE"
    fi
}

rotate_ffmpeg_log() {
    # Rotate FFmpeg log if it gets too large
    if [ -f "$FFMPEG_LOGFILE" ] && [ $(stat -f%z "$FFMPEG_LOGFILE" 2>/dev/null || stat -c%s "$FFMPEG_LOGFILE" 2>/dev/null || echo 0) -gt $MAX_FFMPEG_LOG_SIZE ]; then
        mv "$FFMPEG_LOGFILE" "${FFMPEG_LOGFILE}.old"
        log_message "FFmpeg log rotated due to size limit"
    fi
}

start_stream() {
    log_message "Starting stream..."
    
    # Kill any existing stream first
    stop_stream
    
    # Rotate FFmpeg log before starting new stream
    rotate_ffmpeg_log
    
    # Start new stream with progress monitoring
    # Redirect detailed FFmpeg output to a separate file that we can rotate
    ffmpeg -rtsp_transport tcp -i "$RTSP_SOURCE" \
    -c:v libx264 -preset veryfast -maxrate 2M -bufsize 4M -g 50 -an -f flv \
    -progress "$STATSFILE" \
    "$RTMP_DESTINATION" > "$FFMPEG_LOGFILE" 2>&1 &
    
    local PID=$!
    echo $PID > $PIDFILE
    log_message "Stream started with PID $PID"
    
    # Reset failure counter
    FAILURE_COUNT=0
}

stop_stream() {
    if [ -f $PIDFILE ]; then
        local PID=$(cat $PIDFILE)
        if kill -0 $PID 2>/dev/null; then
            log_message "Stopping stream with PID $PID"
            kill $PID
            sleep 3
            if kill -0 $PID 2>/dev/null; then
                kill -9 $PID
            fi
        fi
        rm -f $PIDFILE
    fi
    
    # Cleanup orphaned processes
    pkill -f "$RTSP_SOURCE"
    rm -f $STATSFILE
}

check_process_health() {
    local PID=$(cat $PIDFILE 2>/dev/null)
    
    if [ -z "$PID" ] || ! kill -0 $PID 2>/dev/null; then
        echo "Process not running"
        return 1
    fi
    
    return 0
}

check_statistics_health() {
    if [ ! -f "$STATSFILE" ]; then
        echo "No statistics file"
        return 1
    fi
    
    # Check if stats file was updated recently
    local LAST_UPDATE=$(stat -c %Y "$STATSFILE" 2>/dev/null || echo 0)
    local NOW=$(date +%s)
    local AGE=$((NOW - LAST_UPDATE))
    
    if [ $AGE -gt 60 ]; then
        echo "Statistics too old (${AGE}s)"
        return 1
    fi
    
    # Check bitrate from ffmpeg progress
    local BITRATE=$(grep "bitrate=" "$STATSFILE" | tail -1 | cut -d'=' -f2 | cut -d'k' -f1)
    if [ -n "$BITRATE" ] && [ "${BITRATE%.*}" -lt 100 ]; then
        echo "Low bitrate: ${BITRATE}kbps"
        return 1
    fi
    
    return 0
}

check_rtmp_health() {
    # Check if RTMP server is reachable
    if ! timeout 5 nc -z "$RTMP_HOST" "$RTMP_PORT" 2>/dev/null; then
        echo "RTMP server unreachable"
        return 1
    fi
    
    return 0
}

check_rtsp_health() {
    # Quick RTSP source check
    if ! timeout 15 ffprobe -v quiet -show_entries format=duration \
         -rtsp_transport tcp "$RTSP_SOURCE" 2>/dev/null; then
        echo "RTSP source unreachable"
        return 1
    fi
    
    return 0
}

perform_health_check() {
    local STATUS="HEALTHY"
    local REASON=""
    
    # Check process
    if ! check_process_health; then
        STATUS="UNHEALTHY"
        REASON="Process not running"
    # Check statistics
    elif ! STATS_CHECK=$(check_statistics_health); then
        STATUS="UNHEALTHY" 
        REASON="Statistics issue: $STATS_CHECK"
    # Check RTMP connection
    elif ! RTMP_CHECK=$(check_rtmp_health); then
        STATUS="UNHEALTHY"
        REASON="RTMP issue: $RTMP_CHECK"
    # Periodically check RTSP source (every 5th check to avoid overload)
    elif [ $(($(date +%s) % 150)) -eq 0 ] && ! RTSP_CHECK=$(check_rtsp_health); then
        STATUS="UNHEALTHY"
        REASON="RTSP issue: $RTSP_CHECK"
    fi
    
    if [ "$STATUS" = "UNHEALTHY" ]; then
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        log_message "Health check failed ($FAILURE_COUNT/$MAX_FAILURES): $REASON"
        
        if [ $FAILURE_COUNT -ge $MAX_FAILURES ]; then
            log_message "Maximum failures reached, restarting stream"
            start_stream
        fi
    else
        if [ $FAILURE_COUNT -gt 0 ]; then
            log_message "Stream recovered, resetting failure count"
        fi
        FAILURE_COUNT=0
        log_message "Health check passed"
    fi
}

# Main monitoring loop
main() {
    log_message "Starting stream monitor"
    
    # Start initial stream
    start_stream
    
    # Monitor loop
    while true; do
        sleep $CHECK_INTERVAL
        perform_health_check
    done
}

# Signal handlers for clean shutdown
trap 'log_message "Received signal, shutting down"; stop_stream; exit 0' INT TERM

# Start monitoring
main
