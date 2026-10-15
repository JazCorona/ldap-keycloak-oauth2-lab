# =====================================================================
# Escaneo Nuclei de los 3 repos (lab LDAP/Keycloak, backend, frontend)
# Uso (PowerShell, con Docker Desktop abierto), desde esta carpeta:
#   powershell -ExecutionPolicy Bypass -File .\run-nuclei.ps1
#
# Levanta todo en la misma red Docker del lab y corre el contenedor
# de Nuclei conectado a esa red (bridge), para que alcance cada
# servicio por nombre de contenedor sin problemas de puertos.
# Resultados -> <repo>\nuclei-results\
# =====================================================================
$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
$lab  = Join-Path $root "ldap-keycloak-oauth2-lab"
$be   = Join-Path $root "dashboard-musica-backend"
$fe   = Join-Path $root "dashboard-musica-frontend"
$NUCLEI = "projectdiscovery/nuclei:latest"
$VOLS = @("-v", "nuclei-templates:/root/nuclei-templates", "-v", "nuclei-config:/root/.config/nuclei")

function Step($m) { Write-Host "`n==== $m ====" -ForegroundColor Cyan }

docker info *> $null
if ($LASTEXITCODE -ne 0) { Write-Host "Docker no responde. Abre Docker Desktop y vuelve a correr." -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------- 1. Lab
Step "1/6 Levantando lab LDAP + Keycloak + API"
Push-Location $lab
docker compose up -d --build
Pop-Location

Write-Host "Esperando a Keycloak (puede tardar 1-2 min)..."
for ($i = 0; $i -lt 90; $i++) {
  $logs = docker logs keycloak 2>&1 | Out-String
  if ($logs -match "started in") { break }
  Start-Sleep 3
}
$net = (docker inspect keycloak -f "{{range `$k,`$v := .NetworkSettings.Networks}}{{`$k}}{{end}}").Trim()
Write-Host "Red Docker del lab: $net"

Write-Host "Cargando usuarios LDAP..."
for ($i = 0; $i -lt 30; $i++) {
  docker exec openldap ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w adminpassword -b "dc=example,dc=com" -s base *> $null
  if ($LASTEXITCODE -eq 0) { break }
  Start-Sleep 2
}
docker cp (Join-Path $lab "ldap\users.ldif") openldap:/tmp/users.ldif
docker exec openldap ldapadd -c -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w adminpassword -f /tmp/users.ldif *> $null

# ---------------------------------------------------------------- 2. Backend
Step "2/6 Backend (FastAPI :8001) en la red del lab"
docker rm -f dashboard-backend *> $null
docker build -t dashboard-backend $be
docker run -d --name dashboard-backend --network $net -p 8001:8001 `
  -e KEYCLOAK_INTERNAL=http://keycloak:8080 -e KEYCLOAK_PUBLIC=http://localhost:8081 `
  -e KEYCLOAK_REALM=cybersecurity -e KEYCLOAK_CLIENT_ID=fastapi-api dashboard-backend

# ---------------------------------------------------------------- 3. Frontend
Step "3/6 Frontend (Next.js :3000) en la red del lab"
$feDockerfile = @"
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npx","next","start","-H","0.0.0.0","-p","3000"]
"@
$tmpDf = Join-Path $env:TEMP "Dockerfile.dashboard-frontend"
Set-Content -Path $tmpDf -Value $feDockerfile -Encoding ascii
docker rm -f dashboard-frontend *> $null
docker build -t dashboard-frontend -f $tmpDf $fe
docker run -d --name dashboard-frontend --network $net -p 3000:3000 `
  -e KEYCLOAK_URL=http://keycloak:8080 -e KEYCLOAK_REALM=cybersecurity `
  -e KEYCLOAK_CLIENT_ID=fastapi-api -e BACKEND_URL=http://dashboard-backend:8001 dashboard-frontend
Start-Sleep 10

# ---------------------------------------------------------------- 4. Nuclei templates
Step "4/6 Descargando/actualizando templates de Nuclei"
docker pull $NUCLEI
docker run --rm @VOLS $NUCLEI -ut

# ---------------------------------------------------------------- 5. Scans
function Run-Scan($repoDir, $targets) {
  $out = Join-Path $repoDir "nuclei-results"
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  Remove-Item -Recurse -Force (Join-Path $out "*") -ErrorAction SilentlyContinue
  $targets | Out-File -Encoding ascii (Join-Path $out "targets.txt")

  # Prueba de conectividad desde la red del lab (evidencia de que el puerto responde)
  $conn = @("Conectividad desde un contenedor en la red '$net' - $(Get-Date -Format s)")
  foreach ($t in $targets) {
    if ($t -like "http*") {
      $code = docker run --rm --network $net curlimages/curl -s -o /dev/null -w "%{http_code}" --max-time 10 $t 2>&1
      $conn += "$t -> HTTP $code"
    } else {
      $h, $p = $t.Split(":")
      $r = docker run --rm --network $net busybox sh -c "nc -z -w 5 $h $p && echo open || echo closed" 2>&1
      $conn += "$t -> TCP $r"
    }
  }
  $conn | Out-File -Encoding utf8 (Join-Path $out "connectivity.txt")
  $conn | ForEach-Object { Write-Host $_ }

  # Escaneo de red/HTTP con el contenedor de Nuclei conectado a la misma red
  docker run --rm --network $net @VOLS -v "${out}:/output" $NUCLEI `
    -l /output/targets.txt -nmhe -nc -duc `
    -o /output/nuclei-report.txt -jle /output/nuclei-report.jsonl -me /output/markdown 2>&1 |
    ForEach-Object { $s = "$_"; Write-Host $s; $s } |
    Out-File -Encoding utf8 (Join-Path $out "nuclei-scan.log")

  # Escaneo del codigo fuente con templates "file" (secretos, llaves, etc.)
  docker run --rm @VOLS -v "${repoDir}:/src:ro" -v "${out}:/output" $NUCLEI `
    -u /src -file -t file/ -nc -duc `
    -o /output/nuclei-file-report.txt -jle /output/nuclei-file-report.jsonl 2>&1 |
    ForEach-Object { $s = "$_"; Write-Host $s; $s } |
    Out-File -Encoding utf8 (Join-Path $out "nuclei-file-scan.log")
}

Step "5/6 Nuclei -> ldap-keycloak-oauth2-lab"
Run-Scan $lab @("http://phpldapadmin:80", "http://keycloak:8080", "http://ldap-oauth-api:8000", "openldap:389", "openldap:636", "keycloak-db:5432")

Step "5/6 Nuclei -> dashboard-musica-backend"
Run-Scan $be @("http://dashboard-backend:8001")

Step "5/6 Nuclei -> dashboard-musica-frontend"
Run-Scan $fe @("http://dashboard-frontend:3000")

# ---------------------------------------------------------------- 6. Fin
Step "6/6 Listo"
foreach ($r in @($lab, $be, $fe)) {
  $f = Join-Path $r "nuclei-results\nuclei-report.txt"
  $n = if (Test-Path $f) { (Get-Content $f | Measure-Object -Line).Lines } else { 0 }
  Write-Host ("{0,-28} {1} hallazgos -> {2}" -f (Split-Path $r -Leaf), $n, (Split-Path $f))
}
Write-Host "`nAvisale a Claude que termino." -ForegroundColor Green
