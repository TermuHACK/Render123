#!/bin/bash
set -e

# Устанавливаем всё нужное
apt-get update
apt-get install -y openbox xterm \
    tigervnc-standalone-server novnc websockify \
    && rm -rf /var/lib/apt/lists/*

# Настройка VNC
export DISPLAY=:1
mkdir -p /root/.vnc
echo "password" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Старт VNC с Openbox
vncserver :1 -geometry 1280x720 -depth 16 -xstartup openbox-session

# noVNC на порту 8080 (для Railway web)
websockify --web=/usr/share/novnc/ 0.0.0.0:8080 localhost:5901
