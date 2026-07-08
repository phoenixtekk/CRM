<#
.SYNOPSIS
    DGSNOW-Check-Prereqs.ps1 — Prerequisite/health helper for Snowflake onboarding to Purview (read-only; PASS/GAP).
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to register/scan Snowflake: the Az.Accounts module and Azure
        sign-in, whether a Purview endpoint token can be acquired and the Data Map is readable, and prints
        the manual checks (Key Vault-backed credential, SHIR, least-privilege roles). Read-only; stores no
        secret.
    HOW TO RUN
        .\DGSNOW-Check-Prereqs.ps1 -PurviewAccount "<your-purview-account>"
        PowerShell 5.1+/7+. Connect first with Connect-AzAccount. No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/GAP line per signal plus a manual checklist. GAPs are recorded against the Requirements
        checklist and remediated before configuring. Makes no change.
.NOTES
    Purview — Snowflake Data Governance. Read-only. Verify your licensing/tenant: Data Governance has its
    own consumption model; the Snowflake connector + API surface are evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PurviewAccount,
    [string]$ApiVersion = '2022-07-01-preview'
)

function Signal([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("GAP   {0} — {1}" -f $Name, $Detail) -ForegroundColor Yellow }
}

Write-Host "`n=== Snowflake Data Governance — prerequisite/health check (read-only) ===" -ForegroundColor Cyan

$haveAz = [bool](Get-Module -ListAvailable -Name Az.Accounts)
Signal 'Module: Az.Accounts' $haveAz $(if($haveAz){'installed'}else{'install: Install-Module Az.Accounts -Scope CurrentUser'})

$ctx = $null
try { $ctx = Get-AzContext -ErrorAction Stop } catch {}
Signal 'Azure signed in' ([bool]$ctx) $(if($ctx){("account: {0}" -f $ctx.Account)}else{'run Connect-AzAccount'})

$token = $null
if ($ctx) {
    try { $token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net' -ErrorAction Stop).Token } catch {}
}
Signal 'Purview endpoint token' ([bool]$token) $(if($token){'token acquired'}else{'could not acquire — check permissions/sign-in'})

if ($token) {
    try {
        $r = Invoke-RestMethod -Method GET -Uri ("https://{0}.purview.azure.com/scan/datasources?api-version={1}" -f $PurviewAccount, $ApiVersion) -Headers @{ Authorization = "Bearer $token" } -ErrorAction Stop
        Signal 'Data Map readable' $true ("data sources endpoint responded ({0} source(s))" -f @($r.value).Count)
    } catch {
        Signal 'Data Map readable' $false ("could not read data sources: {0}" -f $_.Exception.Message)
    }
}

Write-Host "`nVerify manually (not readable here):" -ForegroundColor Cyan
Write-Host "  [ ] Purview account has Data Governance (Data Map/Catalog); consumption model confirmed with owner" -ForegroundColor DarkGray
Write-Host "  [ ] Least-privilege collection roles: Collection admin / Data source admin / Data curator" -ForegroundColor DarkGray
Write-Host "  [ ] Snowflake login (least-privilege read); secret stored in Azure Key Vault LINKED to Purview" -ForegroundColor DarkGray
Write-Host "  [ ] Network path to Snowflake; self-hosted integration runtime installed where required" -ForegroundColor DarkGray
Write-Host "  [ ] In-scope databases + pilot scope (one db/schema) agreed; classification scheme approved" -ForegroundColor DarkGray
Write-Host "`nNo Snowflake secret belongs in any script — it lives only in Key Vault. Record GAPs before configuring." -ForegroundColor DarkGray
