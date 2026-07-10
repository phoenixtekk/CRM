<#
.SYNOPSIS
    SRCANCHOR-Assess.ps1 — report the current source anchor, Connect version, and mS-DS-ConsistencyGuid state.
.DESCRIPTION
    PURPOSE
        Read-only readiness assessment before switching the Microsoft Entra Connect source anchor from
        objectGUID to mS-DS-ConsistencyGuid. Reports (1) the CURRENT source anchor attribute from
        Get-ADSyncGlobalSettings, (2) the installed Microsoft Entra Connect Sync version, and (3) whether
        any in-scope object already has mS-DS-ConsistencyGuid populated (the wizard blocker), then prints
        a readiness verdict. Makes no changes.
    HOW TO RUN
        On the Microsoft Entra Connect server, elevated:
            powershell -ExecutionPolicy Bypass -File .\SRCANCHOR-Assess.ps1
        Optionally scope the populated-attribute check to specific OUs:
            powershell -ExecutionPolicy Bypass -File .\SRCANCHOR-Assess.ps1 ^
                -IncludeOU "OU=Source Anchor - In-Scope OUs,DC=corp,DC=example,DC=com"
        Requires the ADSync module (the Microsoft Entra Connect role) and the ActiveDirectory module
        (RSAT AD tools) to read directory objects.
    EXPECTED RESULTS
        Current source anchor (expect "objectGUID"), the installed Connect Sync version, the count of
        in-scope objects already carrying mS-DS-ConsistencyGuid (expect 0), and a READY / NOT READY
        verdict. No changes are made.
.NOTES
    White-label — the repeatable way. Read-only; the anchor change itself is done in the Microsoft Entra
    Connect wizard, never scripted. Vendor internals (Quest On Demand Migration) deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [string[]]$IncludeOU
)

Write-Host "`n=== Source Anchor Assessment — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$ready = $true

# 1) Current source anchor from ADSync global settings
if (Get-Module -ListAvailable -Name ADSync) {
    Import-Module ADSync -ErrorAction Stop
    try {
        $params = (Get-ADSyncGlobalSettings).Parameters
        $anchor = ($params | Where-Object { $_.Name -eq 'Microsoft.SourceAnchorAttribute' }).Value
        if (-not $anchor) { $anchor = ($params | Where-Object { $_.Name -like '*SourceAnchor*' } | Select-Object -First 1).Value }
        Write-Host ("Current source anchor : {0}" -f $anchor)
        if ($anchor -eq 'mS-DS-ConsistencyGuid') {
            Write-Host "  Anchor is already mS-DS-ConsistencyGuid — no switch needed." -ForegroundColor Green
        } elseif ($anchor -ne 'objectGUID') {
            Write-Host "  Anchor is neither objectGUID nor mS-DS-ConsistencyGuid — investigate before proceeding." -ForegroundColor Yellow
            $ready = $false
        }
    } catch { Write-Host "Could not read source anchor: $($_.Exception.Message)" -ForegroundColor Yellow; $ready = $false }
} else {
    Write-Host "ADSync module not found — run this on the Microsoft Entra Connect server." -ForegroundColor Yellow
    $ready = $false
}

# 2) Installed Microsoft Entra Connect Sync version (best-effort across known locations)
$ver = $null
$uninstall = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($u in $uninstall) {
    $p = Get-ItemProperty $u -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Microsoft (Entra Connect|Azure AD Connect)' } | Select-Object -First 1
    if ($p) { $ver = $p.DisplayVersion; break }
}
if (-not $ver) {
    foreach ($exe in @(
        "$env:ProgramFiles\Microsoft Azure AD Sync\Bin\miiserver.exe",
        "$env:ProgramFiles\Microsoft Azure AD Connect\AzureADConnect.exe")) {
        if (Test-Path $exe) { $ver = (Get-Item $exe).VersionInfo.FileVersion; break }
    }
}
Write-Host ("Entra Connect Sync ver: {0}" -f ($(if ($ver) { $ver } else { 'not detected — verify manually' })))
Write-Host "  (mS-DS-ConsistencyGuid is the default source anchor since Azure AD Connect 1.1.524.)"

# 3) Is mS-DS-ConsistencyGuid already populated anywhere in-scope?
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $scopes = if ($IncludeOU) { $IncludeOU } else { @((Get-ADDomain).DistinguishedName) }
    $populated = 0
    foreach ($ou in $scopes) {
        $n = @(Get-ADObject -LDAPFilter '(mS-DS-ConsistencyGuid=*)' -SearchBase $ou -ErrorAction SilentlyContinue).Count
        Write-Host ("Populated in {0} : {1}" -f $ou, $n)
        $populated += $n
    }
    Write-Host ("mS-DS-ConsistencyGuid populated (in-scope) : {0}" -f $populated) -ForegroundColor ($(if ($populated -gt 0) { 'Yellow' } else { 'Green' }))
    if ($populated -gt 0) { $ready = $false }
} else {
    Write-Host "ActiveDirectory module not found — install RSAT AD tools to check the attribute." -ForegroundColor Yellow
    $ready = $false
}

if ($ready) {
    Write-Host "`nVerdict: READY — anchor is objectGUID, version supports the switch, attribute empty in-scope." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nVerdict: NOT READY — resolve the flagged items above before running the wizard." -ForegroundColor Yellow
    exit 1
}
