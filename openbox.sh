#!/bin/bash
set -e

apt update || true
DEBIAN_FRONTEND=noninteractive apt install -y \
    openbox xterm tigervnc-standalone-server \
    websockify novnc \
    --no-install-recommends

# Настройка VNC
export DISPLAY=:1
mkdir -p /root/.vnc
echo "password" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Старт VNC с Openbox
vncserver :1 -geometry 1280x720 -depth 16 -xstartup openbox-session

# noVNC на порту 8080 (для Railway web)
websockify --web=/usr/share/novnc/ 0.0.0.0:8080 localhost:5901
