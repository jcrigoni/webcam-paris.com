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
