# Análisis Nuclei — ldap-keycloak-oauth2-lab

- **Fecha:** 2026-10-14
- **Herramienta:** Nuclei v3.11.1, templates v10.5.0 (11,144 templates), contenedor `projectdiscovery/nuclei:latest`
- **Método:** Nuclei se ejecutó en un contenedor conectado a la red Docker del lab (`ldap-keycloak-oauth2-lab_auth-network`). Así alcanzó cada servicio por su nombre de contenedor, sin problemas de acceso por puerto. Antes del escaneo se verificó la conectividad de cada objetivo (`connectivity.txt`); todos respondieron.
- **Scripts usados:** `run-nuclei.ps1` (escaneo completo) y `run-nuclei-resto.ps1` (continuación del escaneo de código).

## Objetivos

| Servicio | Objetivo | Conectividad |
|---|---|---|
| phpLDAPadmin | `http://phpldapadmin:80` | HTTP 200 |
| Keycloak | `http://keycloak:8080` | HTTP 302 |
| API FastAPI | `http://ldap-oauth-api:8000` | HTTP 404 en `/` (normal) |
| OpenLDAP | `openldap:389`, `openldap:636` | TCP abierto |
| PostgreSQL | `keycloak-db:5432` | TCP abierto |
| Código fuente | repo montado en `/src` (templates `file/`) | — |

## Resultados del escaneo de servicios (34 hallazgos)

| # | Severidad | Template | Objetivo | Comentario |
|---|---|---|---|---|
| 1 | **MEDIUM** | `ldap-anonymous-login-detect` | openldap:389 | OpenLDAP acepta bind anónimo. Cualquiera en la red puede consultar el directorio sin credenciales. |
| 2 | info | `ldap-metadata` | openldap:389 / 636 | El RootDSE se lee de forma anónima (deriva del #1). |
| 3 | info | `cookies-without-httponly` | phpldapadmin | Cookie de sesión PHP sin `HttpOnly`. |
| 4 | info | `cookies-without-secure` | phpldapadmin | Cookie sin `Secure` (servido por HTTP; `PHPLDAPADMIN_HTTPS=false`). |
| 5 | info | `missing-cookie-samesite-strict` | phpldapadmin | Cookie sin `SameSite`. |
| 6 | info | `phpldapadmin-panel` | phpldapadmin | Panel de administración expuesto y versión revelada (1.2.5). |
| 7 | info | `apache-detect`, `waf-detect:apachegeneric` | phpldapadmin | Se revela el servidor Apache. |
| 8 | info | `xss-deprecated-header` | phpldapadmin | Usa `X-XSS-Protection: 1; mode=block`, un header obsoleto. |
| 9 | info | `http-missing-security-headers` ×10 | phpldapadmin | Faltan CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, COOP, COEP, CORP y X-Permitted-Cross-Domain-Policies. |
| 10 | info | `swagger-api`, `openapi`, `redoc-api-docs` | ldap-oauth-api | `/docs`, `/redoc` y `/openapi.json` públicos. |
| 11 | info | `http-missing-security-headers` ×10 | ldap-oauth-api | Los mismos 10 headers faltantes. |
| 12 | info | `tech-detect:uvicorn` | ldap-oauth-api | Se revela el servidor (header `server: uvicorn`). |
| 13 | info | `options-method` | keycloak | `OPTIONS` habilitado. |
| 14 | info | `pgsql-detect` | keycloak-db:5432 | Postgres alcanzable desde la red interna (no está publicado al host). |

Detalle por hallazgo (request y response) en `markdown/` y en `nuclei-report.jsonl`.

## Resultados del escaneo de código (`-file`, 25 coincidencias)

| Archivo | Template | ¿Real? |
|---|---|---|
| `docker-compose.yml` | `credentials-disclosure-file` | **Sí.** Contraseñas en texto plano: `LDAP_ADMIN_PASSWORD`, `POSTGRES_PASSWORD`, `KC_DB_PASSWORD`, `KC_BOOTSTRAP_ADMIN_PASSWORD`. |
| `ldap/users.ldif` | `credentials-disclosure-file` | **Sí.** `userPassword` en texto plano (`alice123`, `bob123`). |
| `README.md` | `credentials-disclosure-file` | **Sí.** Documenta credenciales de admin y de usuarios. |
| `fastapi/app/main.py` | `credentials-disclosure-file` | Falso positivo: nombres de variables (`token`, `key`). |
| `.git/hooks/fsmonitor-watchman.sample` | `credentials-disclosure-file` | Falso positivo: archivo de ejemplo de Git. |
| `nuclei-results/*` | `credentials-disclosure-file` | Ruido: Nuclei escaneó sus propios reportes. |

## Nota sobre el log

`nuclei-scan.log` solo tiene el encabezado. La consola de PowerShell se pausó al terminar el escaneo y el log no alcanzó a escribirse completo. El escaneo sí terminó: `nuclei-report.txt`, `nuclei-report.jsonl` y `markdown/` tienen todos los resultados.
