<#
  refresh-image.ps1 — replace the base/listing image on an ALREADY-PUBLISHED solution's products.

  Regenerate the hero first (tools\build-hero.py), then run this to push the new image to the
  live store: deploys loader + listing JSON + the new hero PNG, runs the loader's --replace-images
  (deletes old product images + files, attaches the new one), then indexer:index + optimize:clear.

  Usage:  pwsh tools\refresh-image.ps1 -Slug windows-hello-for-business
#>
param([Parameter(Mandatory)][string]$Slug)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$metaFile = Get-ChildItem "$repo\library" -Recurse -Filter 'solution.meta.json' |
    Where-Object { (Get-Content $_.FullName -Raw | ConvertFrom-Json).slug -eq $Slug } | Select-Object -First 1
if (-not $metaFile) { throw "No solution for slug '$Slug'" }
$meta = Get-Content $metaFile.FullName -Raw | ConvertFrom-Json
$src = $metaFile.Directory.FullName; $sol = $meta.sol_code
$png = "$src\deliverables\$sol-hero.png"; $json = "$src\listing\bagisto-products.json"; $loader = "$repo\loader\create-bagisto-products.php"
foreach ($f in @($png,$json,$loader)) { if (-not (Test-Path $f)) { throw "Missing: $f" } }

# refresh the deliverables shelf copy too
$shelf = "$repo\library\_deliverables\$Slug"; New-Item -ItemType Directory -Force $shelf | Out-Null
Copy-Item "$src\deliverables\*" $shelf -Force

Write-Host "[$Slug] refreshing image..." -ForegroundColor Cyan
scp -q $loader linuxg5:/tmp/loader.php
scp -q $json   linuxg5:/tmp/bp.json
scp -q $png    linuxg5:/tmp/d_png
$remote = @"
set -e
APP=/home/workplace/public_html
chmod 644 /tmp/loader.php /tmp/bp.json /tmp/d_png
sudo -u workplace cp /tmp/loader.php "`$APP/create-bagisto-products.php"
sudo -u workplace mkdir -p "`$APP/solutions/$Slug"
sudo -u workplace cp /tmp/bp.json "`$APP/solutions/$Slug/bagisto-products.json"
sudo -u workplace cp /tmp/d_png "`$APP/solutions/$Slug/$sol-hero.png"
rm -f /tmp/loader.php /tmp/bp.json /tmp/d_png
cd "`$APP"
sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/$Slug/bagisto-products.json --replace-images
sudo -u workplace php8.4 artisan indexer:index >/dev/null 2>&1 && echo INDEXED
sudo -u workplace php8.4 artisan optimize:clear >/dev/null 2>&1 && echo CLEARED
"@
$out = ssh linuxg5 $remote 2>&1
$out | ForEach-Object { Write-Host "  $_" }
Write-Host "[$Slug] image refreshed." -ForegroundColor Green
