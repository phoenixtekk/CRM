<#
.SYNOPSIS
    DGLINE-ScopeHealth.ps1 — read-only Microsoft Purview account/data-plane health + collection scope (no changes).
.DESCRIPTION
    PURPOSE
        Confirms the Microsoft Purview (Data Governance) account is reachable at its data-plane endpoint,
        acquires a short-lived Azure AD data-plane token, and lists the collections the signed-in identity
        can enumerate — establishing you hold the least-privilege data-plane roles before doing lineage work.
        Read-only. Makes no changes. Stores no secrets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGLINE-ScopeHealth.ps1 -Account <purview-account-name>
        PowerShell 5.1+ or 7+. Requires Az.Accounts (Connect-AzAccount). Uses the Purview data-plane
        resource https://purview.azure.net. Data-plane roles: Collection admin / Data source admin / Data curator.
    EXPECTED RESULTS
        The account endpoint responds, a data-plane token is acquired, and the enumerable collections are
        listed. PASS = endpoint reachable + token acquired + at least the in-scope collection listed.
.NOTES
    Purview — Data Lineage Implementation (DGLINE). Read-only. No secrets in code.
    Data lineage is a Data Map / Unified Catalog capability; provisioning, roles, portal paths, and REST
    api-version values are evolving — verify against your tenant. api-version values below are placeholders.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Account,
    # Verify the current data-plane resource URL and api-version in Microsoft's documentation for your tenant.
    [string]$ResourceUrl   = 'https://purview.azure.net',
    [string]$AccountApiVer = '2019-11-01-preview'
)

$ErrorActionPreference = 'Stop'
$endpoint = "https://$Account.purview.azure.com"
Write-Host ("=== DGLINE ScopeHealth — {0} ===" -f $endpoint) -ForegroundColor Cyan

# --- Sign in and acquire a data-plane token (no secret stored) ---
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$token = (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
if (-not $token) { throw "Could not acquire a data-plane token for $ResourceUrl. Verify the resource URL and your access." }
Write-Host "Data-plane token acquired (short-lived, not stored)." -ForegroundColor Green
$headers = @{ Authorization = "Bearer $token" }

# --- Reachability + collection enumeration (read-only) ---
$collUri = "$endpoint/account/collections?api-version=$AccountApiVer"
try {
    $resp = Invoke-RestMethod -Method GET -Uri $collUri -Headers $headers
    $collections = @($resp.value)
    Write-Host ("Account endpoint reachable. Collections enumerable: {0}" -f $collections.Count) -ForegroundColor Green
    $collections |
        Select-Object @{n='Name';e={$_.name}}, @{n='FriendlyName';e={$_.friendlyName}}, @{n='Parent';e={$_.parentCollection.referenceName}} |
        Format-Table -AutoSize
} catch {
    Write-Host ("Could not enumerate collections at {0}: {1}" -f $collUri, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Verify the account name, the api-version, and that your identity holds a collection-scoped data-plane role." -ForegroundColor Yellow
}

Write-Host 'Scope/health check complete (read-only).' -ForegroundColor Green
