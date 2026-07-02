<#
.SYNOPSIS
    Get-TenantId.ps1 — retrieve the Microsoft Entra Tenant ID needed for Known Folder Move.

.DESCRIPTION
    PURPOSE
        Returns your Microsoft Entra (Azure AD) Tenant ID (directory GUID). This value is
        required by the OneDrive "Silently move Windows known folders to OneDrive" (KFM) policy.

    HOW TO RUN
        Easiest (no sign-in) from a Microsoft Entra–joined device:
            powershell -ExecutionPolicy Bypass -File .\Get-TenantId.ps1
        Or look it up in the cloud (prompts for sign-in) with -FromGraph:
            .\Get-TenantId.ps1 -FromGraph

    EXPECTED RESULTS
        Prints the Tenant ID GUID. Copy it into the KFM policy "Tenant ID" field.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param([switch]$FromGraph)

if ($FromGraph) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome
    $org = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization'
    $tid = $org.value[0].id
    Disconnect-MgGraph | Out-Null
} else {
    # Read from the local device registration (Entra-joined devices)
    $dsreg = (dsregcmd /status) 2>$null
    $tid = ($dsreg | Select-String 'TenantId\s*:\s*([0-9a-fA-F-]{36})').Matches.Groups[1].Value
    if (-not $tid) {
        $tid = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\*' -ErrorAction SilentlyContinue).TenantId
    }
}

if ($tid) {
    Write-Host "Microsoft Entra Tenant ID:" -ForegroundColor Cyan
    Write-Host "  $tid" -ForegroundColor Green
    Write-Host "Paste this into the OneDrive KFM policy 'Tenant ID' field."
} else {
    Write-Host "Could not determine Tenant ID locally. Re-run with -FromGraph, or read it from https://entra.microsoft.com > Overview." -ForegroundColor Yellow
    exit 1
}
