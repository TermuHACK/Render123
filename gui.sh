#!/bin/bash
# minimal no-password VNC + jwm + noVNC (Alpine)
# всё в /tmp/vnc, подходит для контейнера
set -eu

TMPDIR=/tmp/vnc
NOVNC_PORT=8000
VNC_PORT=5901
DISPLAY_NUM=1
GEOMETRY=1280x720

# очистим старое
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# ---- Установка (если пакетов нет) ----
# apk add --no-cache tigervnc jwm xterm font-terminus git python3 py3-pip curl
# (см. блок "Желательно" ниже для обновлений)

# убить старые инстансы (если есть)
vncserver -kill :$DISPLAY_NUM >/dev/null 2>&1 || true
pkill -f "Xvnc.*:$DISPLAY_NUM" >/dev/null 2>&1 || true
pkill -f novnc >/dev/null 2>&1 || true

# клонируем noVNC (в /tmp)
git clone --depth 1 https://github.com/novnc/noVNC.git novnc
git clone --depth 1 https://github.com/novnc/websockify.git novnc/utils/websockify

# создаём минимальную сессию jwm в tmp (используется HOME=/tmp/vnc)
export HOME="$TMPDIR"
mkdir -p "$HOME/.vnc"

cat > "$HOME/.jwmrc" <<'EOF'
<?xml version="1.0"?>
<JWM>
  <StartupCommand>exec xterm</StartupCommand>
</JWM>
EOF

cat > "$HOME/.Xresources" <<'EOF'
xterm*faceName: Terminus
EOF

cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xrdb $HOME/.Xresources 2>/dev/null || true
exec jwm
EOF
chmod +x "$HOME/.vnc/xstartup"

# Запустим Xvnc напрямую без пароля (SecurityTypes None)
# Используем -localhost no чтобы слушал на всех интерфейсах внутри контейнера
# (при необходимости можно оставить localhost-only)
XVNCPIDFILE="$TMPDIR/Xvnc.pid"
rm -f "$XVNCPIDFILE"
nohup Xvnc ":$DISPLAY_NUM" -geometry "$GEOMETRY" -depth 24 -rfbport "$VNC_PORT" -SecurityTypes None -localhost no >/dev/null 2>&1 &
sleep 0.5

# убедимся, что Xvnc поднялся
sleep 1
if ! netstat -tlnp 2>/dev/null | grep -q ":$VNC_PORT"; then
  echo "Ошибка: VNC не запущен на порту $VNC_PORT"
  exit 1
fi

# Запускаем jwm в этом DISPLAY
export DISPLAY=":$DISPLAY_NUM"
# Немного задержки перед запуском WM
(sleep 0.5 && DISPLAY="$DISPLAY" jwm) >/dev/null 2>&1 &

# Запускаем noVNC (launch.sh использует websockify)
cd "$TMPDIR/novnc"
# --listen может требовать права, так что слушаем на 0.0.0.0:$NOVNC_PORT
./utils/launch.sh --vnc localhost:"$VNC_PORT" --listen "$NOVNC_PORT" >/dev/null 2>&1 &

echo "============================================"
echo "Запущено (без пароля):"
echo " - VNC (RFB):  tcp://0.0.0.0:$VNC_PORT    (дисплей :$DISPLAY_NUM)"
echo " - noVNC (web): http://0.0.0.0:$NOVNC_PORT"
echo "WM: jwm"
echo "Все файлы в: $TMPDIR"
echo "============================================"
