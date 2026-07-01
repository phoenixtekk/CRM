<#
  publish.ps1 — one-command publish of a generated solution to the live Bagisto store.

  Does: LATEST.txt + deliverables shelf → scp loader + listing JSON + deliverables (PDF/ZIP/hero)
  → load via php8.4 → indexer:index + optimize:clear → mark meta published → rebuild index →
  curl the public pages.

  Usage:  pwsh tools\publish.ps1 -Slug windows-autopilot
  Prereqs: solution generated in the library; DB should be backed up separately for the batch.
#>
param([Parameter(Mandatory)][string]$Slug, [string]$Today = "2026-06-13")
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent

$metaFile = Get-ChildItem "$repo\library" -Recurse -Filter 'solution.meta.json' |
    Where-Object { (Get-Content $_.FullName -Raw | ConvertFrom-Json).slug -eq $Slug } | Select-Object -First 1
if (-not $metaFile) { throw "No solution.meta.json for slug '$Slug'" }
$meta = Get-Content $metaFile.FullName -Raw | ConvertFrom-Json
$src  = $metaFile.Directory.FullName
$ver  = $metaFile.Directory.Name
$sol  = $meta.sol_code
$deliv = Join-Path $src 'deliverables'

# LATEST + shelf
Set-Content -Path (Join-Path $metaFile.Directory.Parent.FullName 'LATEST.txt') -Value $ver -NoNewline -Encoding UTF8
$shelf = "$repo\library\_deliverables\$Slug"; New-Item -ItemType Directory -Force $shelf | Out-Null
Copy-Item "$deliv\*" $shelf -Force

$pdf = "$deliv\$sol-Solution.pdf"; $zip = "$deliv\$sol-Scripts.zip"; $png = "$deliv\$sol-hero.png"
$json = "$src\listing\bagisto-products.json"; $loader = "$repo\loader\create-bagisto-products.php"
foreach ($f in @($pdf,$zip,$png,$json,$loader)) { if (-not (Test-Path $f)) { throw "Missing: $f" } }

Write-Host "[$Slug] deploying..." -ForegroundColor Cyan
scp -q $loader linuxg5:/tmp/loader.php
scp -q $json   linuxg5:/tmp/bp.json
scp -q $pdf    linuxg5:/tmp/d_pdf
scp -q $zip    linuxg5:/tmp/d_zip
scp -q $png    linuxg5:/tmp/d_png

$remote = @"
set -e
APP=/home/workplace/public_html
chmod 644 /tmp/loader.php /tmp/bp.json /tmp/d_pdf /tmp/d_zip /tmp/d_png
sudo -u workplace cp /tmp/loader.php "`$APP/create-bagisto-products.php"
sudo -u workplace mkdir -p "`$APP/solutions/$Slug"
sudo -u workplace cp /tmp/bp.json "`$APP/solutions/$Slug/bagisto-products.json"
sudo -u workplace cp /tmp/d_pdf "`$APP/solutions/$Slug/$sol-Solution.pdf"
sudo -u workplace cp /tmp/d_zip "`$APP/solutions/$Slug/$sol-Scripts.zip"
sudo -u workplace cp /tmp/d_png "`$APP/solutions/$Slug/$sol-hero.png"
rm -f /tmp/loader.php /tmp/bp.json /tmp/d_pdf /tmp/d_zip /tmp/d_png
cd "`$APP"
sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/$Slug/bagisto-products.json --ensure-category
sudo -u workplace php8.4 artisan indexer:index >/dev/null 2>&1 && echo INDEXED
sudo -u workplace php8.4 artisan optimize:clear >/dev/null 2>&1 && echo CLEARED
"@
$out = ssh linuxg5 $remote 2>&1
$out | ForEach-Object { Write-Host "  $_" }

if ($out -match 'FAIL') { throw "[$Slug] loader reported FAIL — not marking published." }

# mark meta published + rebuild index
(Get-Content $metaFile.FullName -Raw) `
    -replace '"status":\s*"generated"', '"status": "published"' `
    -replace '"published_at":\s*null', "`"published_at`": `"$Today`"" |
    Set-Content $metaFile.FullName -Encoding UTF8
pwsh -NoProfile -File "$repo\library\_index\rebuild-index.ps1" | Out-Null

# verify public pages
$comm = ($meta.products | Where-Object audience -eq 'commercial').sku
$npo  = ($meta.products | Where-Object audience -eq 'nonprofit').sku
foreach ($p in $meta.products) {
    $uk = "$Slug-$($p.audience)"
    $code = (curl.exe -sk -o NUL -w "%{http_code}" "https://workplace.phoenixtekk.com/$uk")
    Write-Host ("  page {0,-40} HTTP {1}" -f $uk, $code) -ForegroundColor ($(if($code -eq '200'){'Green'}else{'Yellow'}))
}

# Blog draft (best-effort, non-fatal): create/update a DRAFT post on phoenixtekk.com with the
# hero as featured image. Idempotent by ptk_slug. Draft-for-review by owner decision (2026-07-01).
try {
    python "$repo\tools\publish-blog.py" --slug $Slug --status draft 2>&1 |
        Where-Object { $_ -notmatch 'Plesk Control Panel' -and $_ -match 'BLOG|error|Error' } |
        ForEach-Object { Write-Host "  blog: $_" -ForegroundColor Cyan }
} catch { Write-Host "  blog step skipped (non-fatal): $_" -ForegroundColor Yellow }

Write-Host "[$Slug] PUBLISHED." -ForegroundColor Green
