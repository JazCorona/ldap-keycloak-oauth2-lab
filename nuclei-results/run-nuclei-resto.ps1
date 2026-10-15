# Continua el escaneo: codigo fuente del lab + backend + frontend.
# No re-escanea los servicios del lab (ya estan en ldap-keycloak-oauth2-lab\nuclei-results).
# Uso: powershell -ExecutionPolicy Bypass -File .\run-nuclei-resto.ps1
# IMPORTANTE: no hagas clic dentro de esta ventana mientras corre (Windows pausa la consola).
$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
$lab  = Join-Path $root "ldap-keycloak-oauth2-lab"
$be   = Join-Path $root "dashboard-musica-backend"
$fe   = Join-Path $root "dashboard-musica-frontend"
$NUCLEI = "projectdiscovery/nuclei:latest"
$VOLS = @("-v", "nuclei-templates:/root/nuclei-templates", "-v", "nuclei-config:/root/.config/nuclei")
function Step($m) { Write-Host "`n==== $m ====  ($(Get-Date -Format HH:mm:ss))" -ForegroundColor Cyan }

$net = (docker inspect keycloak -f "{{range `$k,`$v := .NetworkSettings.Networks}}{{`$k}}{{end}}").Trim()
Write-Host "Red Docker del lab: $net"

# Asegura backend y frontend arriba (frontend en 3001 porque juice-shop usa el 3000)
if (-not (docker ps -q --filter name=^dashboard-backend$)) {
  docker rm -f dashboard-backend *> $null
  docker run -d --name dashboard-backend --network $net -p 8001:8001 `
    -e KEYCLOAK_INTERNAL=http://keycloak:8080 -e KEYCLOAK_PUBLIC=http://localhost:8081 `
    -e KEYCLOAK_REALM=cybersecurity -e KEYCLOAK_CLIENT_ID=fastapi-api dashboard-backend
}
if (-not (docker ps -q --filter name=^dashboard-frontend$)) {
  docker rm -f dashboard-frontend *> $null
  docker run -d --name dashboard-frontend --network $net -p 3001:3000 `
    -e KEYCLOAK_URL=http://keycloak:8080 -e KEYCLOAK_REALM=cybersecurity `
    -e KEYCLOAK_CLIENT_ID=fastapi-api -e BACKEND_URL=http://dashboard-backend:8001 dashboard-frontend
  Start-Sleep 10
}

function File-Scan($repoDir) {
  $out = Join-Path $repoDir "nuclei-results"
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  docker run --rm @VOLS -v "${repoDir}:/src:ro" -v "${out}:/output" $NUCLEI `
    -u /src -file -t file/ -nc -duc -stats -si 30 `
    -o /output/nuclei-file-report.txt -jle /output/nuclei-file-report.jsonl 2>&1 |
    ForEach-Object { $s = "$_"; Write-Host $s; $s } |
    Out-File -Encoding utf8 (Join-Path $out "nuclei-file-scan.log")
}

function Net-Scan($repoDir, $targets) {
  $out = Join-Path $repoDir "nuclei-results"
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  $targets | Out-File -Encoding ascii (Join-Path $out "targets.txt")
  $conn = @("Conectividad desde un contenedor en la red '$net' - $(Get-Date -Format s)")
  foreach ($t in $targets) {
    $code = docker run --rm --network $net curlimages/curl -s -o /dev/null -w "%{http_code}" --max-time 10 $t 2>&1
    $conn += "$t -> HTTP $code"
  }
  $conn | Out-File -Encoding utf8 (Join-Path $out "connectivity.txt")
  $conn | ForEach-Object { Write-Host $_ }
  docker run --rm --network $net @VOLS -v "${out}:/output" $NUCLEI `
    -l /output/targets.txt -nmhe -nc -duc -stats -si 30 `
    -o /output/nuclei-report.txt -jle /output/nuclei-report.jsonl -me /output/markdown 2>&1 |
    ForEach-Object { $s = "$_"; Write-Host $s; $s } |
    Out-File -Encoding utf8 (Join-Path $out "nuclei-scan.log")
}

Step "1/5 Codigo fuente del lab (templates file)"
File-Scan $lab

Step "2/5 Backend (http://dashboard-backend:8001)"
Net-Scan $be @("http://dashboard-backend:8001")

Step "3/5 Codigo fuente del backend"
File-Scan $be

Step "4/5 Frontend (http://dashboard-frontend:3000)"
Net-Scan $fe @("http://dashboard-frontend:3000")

Step "5/5 Codigo fuente del frontend"
File-Scan $fe

Step "Listo"
Write-Host "Avisale a Claude que termino." -ForegroundColor Green
