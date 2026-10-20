#!/bin/bash
set -e
mkdir -p /var/log/nginx /var/run/fail2ban /run
touch /var/log/nginx/access.log /var/log/nginx/error.log /var/log/fail2ban.log
rm -f /var/run/fail2ban/fail2ban.sock /var/run/fail2ban/fail2ban.pid

# 1) API (uvicorn) SOLO en loopback.
uvicorn app.main:app --host 127.0.0.1 --port 9000 &

# 2) Nginx al frente en el puerto público 8000.
nginx -g 'daemon off;' &

# 3) Fail2Ban vigilando el access.log de nginx.
sleep 1
fail2ban-client -x start

echo "[api-protected] uvicorn(127.0.0.1:9000) + nginx(:8000) + fail2ban ACTIVOS"
exec tail -F /var/log/fail2ban.log
