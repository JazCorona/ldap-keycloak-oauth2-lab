#!/bin/sh
# -----------------------------------------------------------------------------
# Protección EXTRA a nivel de PUERTO para el servicio LDAP sobre TLS (LDAPS 636).
#
# Este contenedor comparte el network namespace de OpenLDAP
# (network_mode: "service:openldap"), por lo que las reglas iptables que crea
# aquí aplican directamente al tráfico que entra a OpenLDAP.
#
# Objetivo: que un flood contra el puerto TLS 636 no tumbe el servicio. Se
# limita el número de conexiones NUEVAS por IP de origen; el exceso se descarta.
# El 389 (texto plano, interno para Keycloak) NO se toca: la política por
# defecto sigue en ACCEPT y solo agregamos reglas específicas al 636.
# -----------------------------------------------------------------------------
set -e
apk add --no-cache iptables >/dev/null 2>&1 || true

LDAPS_PORT=636

# Idempotencia: limpia reglas previas de corridas anteriores.
iptables -D INPUT -p tcp --dport "$LDAPS_PORT" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p tcp --dport "$LDAPS_PORT" -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name ldaps_guard --hashlimit-mode srcip \
  --hashlimit-above 30/minute --hashlimit-burst 15 -j DROP 2>/dev/null || true
iptables -D INPUT -p tcp --dport "$LDAPS_PORT" -m connlimit --connlimit-above 20 -j DROP 2>/dev/null || true

# 1) Permitir siempre las conexiones TLS ya establecidas.
iptables -A INPUT -p tcp --dport "$LDAPS_PORT" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 2) Límite de TASA de conexiones nuevas por IP: máx. ~30/min (ráfaga 15).
#    Un atacante que abra conexiones TLS en masa al 636 es frenado aquí.
iptables -A INPUT -p tcp --dport "$LDAPS_PORT" -m conntrack --ctstate NEW -m hashlimit \
  --hashlimit-name ldaps_guard --hashlimit-mode srcip \
  --hashlimit-above 30/minute --hashlimit-burst 15 -j DROP

# 3) Límite de conexiones CONCURRENTES por IP: máx. 20 simultáneas.
iptables -A INPUT -p tcp --dport "$LDAPS_PORT" -m connlimit --connlimit-above 20 -j DROP

echo "[ldap-fw] Reglas de protección de puerto aplicadas sobre LDAPS/$LDAPS_PORT:"
iptables -L INPUT -n --line-numbers | grep -E "dpt:$LDAPS_PORT|$LDAPS_PORT" || true

# Mantener el contenedor vivo (las reglas persisten mientras exista el netns).
exec tail -f /dev/null
