# 0) Переменные (можно поменять, если нужно)
NOVNC_DIR=/opt/novnc
PORT=8000

# 1) Проверим доступность пакетов в репозиториях (быстрое пассивное подтверждение)
for p in xvfb x11vnc jwm websockify python3 py3-pip supervisor git ttf-freefont bash; do
  echo "== Проверка пакета: $p =="
  apk search -v "^${p}$" || echo "!!! Пакет не найден в репозитории: $p"
done

# 2) Установим пакеты (без --no-cache, чтобы кеш остался)
apk add bash xvfb x11vnc jwm openbox git python3 py3-pip supervisor websockify ttf-freefont

# 3) Клонируем noVNC (статические файлы)
mkdir -p ${NOVNC_DIR}
if [ -d "${NOVNC_DIR}/.git" ]; then
  echo "noVNC уже клонирован в ${NOVNC_DIR}"
else
  git clone --depth=1 https://github.com/novnc/noVNC.git ${NOVNC_DIR}
fi

# 4) Простая конфигурация JWM (редактируй по вкусу)
mkdir -p /root/.jwm
cat > /root/.jwmrc <<'EOF'
<JWM>
  <WindowStyle>
    <Font>fixed</Font>
  </WindowStyle>
  <Tray>
    <TaskList/>
  </Tray>
  <Menu label="Menu">
    <Program label="xterm" command="xterm"/>
    <Program label="Exit" command="killall Xvfb; sleep 1; exit"/>
  </Menu>
</JWM>
EOF

# 5) Создаём supervisord-конфиг с портом 8000
cat > /etc/supervisord.conf <<EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
logfile_maxbytes=0

[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1024x768x24 -nolisten tcp
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr

[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -nopw -listen 127.0.0.1 -forever -shared -rfbport 5900
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr

[program:jwm]
command=/usr/bin/jwm
environment=DISPLAY=":0"
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr

[program:websockify]
command=/usr/bin/websockify --web=${NOVNC_DIR} ${PORT} 127.0.0.1:5900
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

# 6) Удобный запуск-скрипт
cat > /usr/local/bin/start_gui.sh <<'EOF'
#!/bin/sh
exec /usr/bin/supervisord -c /etc/supervisord.conf
EOF
chmod +x /usr/local/bin/start_gui.sh

# 7) Запускаем (в фоне)
# Если хочешь в foreground — запусти без &.
/usr/local/bin/start_gui.sh &

# 8) Небольшая пауза и проверка статуса процессов/портов
sleep 1
ps aux | grep -E "Xvfb|x11vnc|jwm|websockify" | grep -v grep || true
ss -ltnp | grep -E ":${PORT}\\s|:5900\\s" || true
tail -n 200 /var/log/supervisord.log || true

# 9) Как подключиться:
# - Открой в браузере: http://<HOST>:${PORT}/vnc.html
# - Если HOST недоступен извне, пробрось порт через SSH:
#   ssh -L ${PORT}:localhost:${PORT} user@host
EOF
