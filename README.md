#WEBCAM-PARIS.COM

This website displays a view of Paris with a rooftop webcam

Libraries: ffmpeg,  nginx, rtmp-module
Hardware: 4k 12M pixel camera, Ryzen 3 computer boot on Ubuntu (local server), Hostinger VPS boot on Ubuntu (remote server)
All connected with SSH, controled from a third computer.

Website directory in the VPS: root@93.127.163.199:/usr/local/nginx/html/live#
root@srv855970:/usr/local/nginx/html/live# ls
CLAUDE.md  app.js  index.html  logs  styles.css dir(videos)

Copy in the local server: jc@192.168.1.59:/home/jc/dev/wp-local
➜  wp-local git:(main) ls
app.js  CLAUDE.md  index.html  logs  styles.css  dir(videos)

Automation script in the local server: jc@192.168.1.59:/home/jc/scripts
➜  scripts ls
stream_monitor.sh  stream.sh
stream_monitor.sh main automation script, run at boot as an enabled service, does health checks every 30 sec
stream.sh fall back little stream script, use it only when working on stream_monitor.sh

How to check the stream flow in the local server:
tail -f /home/jc/dev/wp-local/logs/ffmpeg_output.log

How to check the health check flow in the local server:
tail -f /home/jc/dev/wp-local/logs/stream.log

How to check for the log files size in the VPS:
ls -lih /usr/local/nginx/html/live/logs

Where to put timelapse videos in the VPS:
scp video-to-load.mp4 root@93.127.163.199:/usr/local/nginx/html/live/videos/

How to re-encode a timelapse video to H.264 (AVC)  (for linux reading purpose)
go to the directory containing the mp4 file and type:
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output_h264.mp4
input.mp4 = input video name (change according to your file)
output.mp4 = output video name  (change according to your file)

How to access crontab in local server:
ssh jc@192.168.1.59
crontab -e

How to access capture logs:
/home/jc/dev/wp-local/logs/log_capture.txt

How to access daylight captures in the local server:
/home/jc/dev/wp-local/captures/

How to access capture_daylight.sh Shell script:
/home/jc/scripts/capture_daylight.sh

How to download and check a daylight capture :
scp jc@192.168.1.59:/home/jc/dev/wp-local/captures/2025-06-24/image_2025-06-24_10-47-51.jpg .  (replace subfolder and image names)
xdg-open image_2025-06-23_16-05-49.jpg (replace image name)

How to access daylight captures in VPS:
root@srv855970:/usr/local/nginx/html/live/captures

How to SSH as jc user:
ssh jc@93.127.163.199

How to rsync the local directory (t14s) with active directory in VPS:
 rsync -avz --exclude '*/' --prune-empty-dirs /home/jcrigoni/projects/webcam-paris.com/ root@93.127.163.199:/usr/local/nginx/html/live/




---

```markdown
# WEBCAM-PARIS.COM

This project streams a real-time rooftop view of Paris via a 4K webcam.  
It uses a local server to handle video capture and encoding, and a remote VPS to host the live stream and display the website.

---

## 🔧 System Overview

- **Camera**: 4K, 12MP rooftop webcam
- **Local Server**: Ubuntu, Ryzen 3 – runs FFmpeg and health monitoring scripts
- **Remote VPS**: Ubuntu (Hostinger) – runs Nginx with RTMP module to serve the stream
- **Control**: All systems managed via SSH from a third computer

---

## 🧩 Technologies Used

- `ffmpeg` – for video encoding and streaming
- `nginx` + `nginx-rtmp-module` – for handling RTMP and HLS streaming
- `cron` – for timed tasks (e.g., daylight captures)
- `rsync`, `scp` – for file synchronization

---

## 📁 Project Structure

### VPS: `/usr/local/nginx/html/live/`
Contains website and video files:
```

CLAUDE.md  app.js  index.html  logs/  styles.css  videos/

````

### Local: `/home/jc/dev/wp-local/`
Mirror of the VPS directory for local development.

### Scripts (Local): `/home/jc/scripts/`
- `stream_monitor.sh` → Main script, runs at boot, checks stream health every 30s
- `stream.sh` → Backup script used for testing only

---

## 📡 Stream Monitoring

### Check FFmpeg output (local server)
```bash
tail -f /home/jc/dev/wp-local/logs/ffmpeg_output.log
````

### Check stream health logs

```bash
tail -f /home/jc/dev/wp-local/logs/stream.log
```

### Capture log file

```bash
cat /home/jc/dev/wp-local/logs/log_capture.txt
```

---

## 🎞️ Timelapse Videos

### Upload a timelapse video to VPS:

```bash
scp video-to-load.mp4 root@93.127.163.199:/usr/local/nginx/html/live/videos/
```

### Re-encode to H.264 (Linux-friendly format):

```bash
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output_h264.mp4
```

---

## 📸 Daylight Image Captures

### Local capture folder:

```
/home/jc/dev/wp-local/captures/
```

### VPS capture folder:

```
/usr/local/nginx/html/live/captures/
```

### View a capture (download and open):

```bash
scp jc@192.168.1.59:/home/jc/dev/wp-local/captures/2025-06-24/image_2025-06-24_10-47-51.jpg .
xdg-open image_2025-06-24_10-47-51.jpg
```

### Daylight capture script:

```
/home/jc/scripts/capture_daylight.sh
```

---

## 🔁 File Sync

### Rsync from local project to VPS:

```bash
rsync -avz --exclude '*/' --prune-empty-dirs /home/jcrigoni/projects/webcam-paris.com/ root@93.127.163.199:/usr/local/nginx/html/live/
```

---

## 🔐 SSH Access

### Local server (user: jc)

```bash
ssh jc@192.168.1.59
```

### Remote VPS (users: root or jc)

```bash
ssh root@93.127.163.199
ssh jc@93.127.163.199
```

---

## 📆 Crontab (on local server)

Edit scheduled tasks:

```bash
ssh jc@192.168.1.59
crontab -e
```

---

## 📌 Notes

* Always check logs when debugging issues.
* Use `stream.sh` only if `stream_monitor.sh` is disabled or under maintenance.
* Place videos in the `videos/` folder and images in `captures/` for web access.

```

---
