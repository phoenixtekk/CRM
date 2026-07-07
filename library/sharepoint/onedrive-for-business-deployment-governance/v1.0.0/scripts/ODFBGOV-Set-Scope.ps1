<#
.SYNOPSIS
    ODFBGOV-Set-Scope.ps1 — scope/config helper: resolve the tenant ID + AD domain GUIDs and emit the exact policy values for silent config, KFM, and sync restriction. Read-only.
.DESCRIPTION
    PURPOSE
        Removes the guesswork from OneDrive client policy by producing the exact values operators must
        paste into Intune / Group Policy and the SharePoint admin center: the Microsoft 365 tenant ID
        (needed for the KFM "Silently move known folders" policy and for tenant sync restriction) and
        the on-prem Active Directory domain GUID(s) (needed for "Allow syncing only on computers joined
        to specific domains"). Optionally emits a ready-to-import .reg reference of the documented
        OneDrive client policy value names. Read-only — resolves and reports, changes nothing.
    HOW TO RUN
        .\ODFBGOV-Set-Scope.ps1 -TenantOnlyLookup                          # tenant ID via Graph
        .\ODFBGOV-Set-Scope.ps1 -ResolveDomainGuids                        # AD domain GUIDs (needs RSAT ActiveDirectory)
        .\ODFBGOV-Set-Scope.ps1 -TenantOnlyLookup -EmitRegReference C:\Temp\ODFBGOV-ClientPolicy.reg
        (PowerShell 5.1+/7+; Microsoft.Graph for tenant ID; ActiveDirectory module for domain GUIDs.)
    EXPECTED RESULTS
        Prints the tenant ID and each domain's Name + ObjectGUID, and (with -EmitRegReference) writes a
        commented .reg TEMPLATE of the documented policy value names (SilentAccountConfig, KFMSilentOptIn,
        KFMBlockOptOut, FilesOnDemandEnabled) with the tenant GUID substituted — a REFERENCE to review,
        not an auto-apply. Verify value names against the current OneDrive.admx for your build.
.NOTES
    SharePoint category — OneDrive for Business Deployment & Governance. Read-only; the .reg output is a template to review, never silently imported.
#>
[CmdletBinding()]
param(
    [switch]$TenantOnlyLookup,
    [switch]$ResolveDomainGuids,
    [string]$EmitRegReference
)

$tenantId = $null
if ($TenantOnlyLookup -or $EmitRegReference) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome
    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value | Select-Object -First 1
    $tenantId = $org.id
    Write-Host ("Tenant ID (use for KFMSilentOptIn / tenant sync restriction): {0}" -f $tenantId) -ForegroundColor Green
    Disconnect-MgGraph | Out-Null
}

if ($ResolveDomainGuids) {
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Import-Module ActiveDirectory -ErrorAction Stop
        Get-ADForest | Select-Object -ExpandProperty Domains | ForEach-Object {
            $d = Get-ADDomain -Identity $_
            [pscustomobject]@{ Domain = $d.DNSRoot; DomainGuid = $d.ObjectGUID }
        } | Format-Table -AutoSize
        Write-Host 'Paste the DomainGuid value(s) into "Allow syncing only on computers joined to specific domains" (or Set-SPOTenantSyncClientRestriction -DomainGuids).' -ForegroundColor Cyan
    } else {
        Write-Warning 'ActiveDirectory module not available. Get the domain GUID from a domain controller: (Get-ADDomain).ObjectGUID'
    }
}

if ($EmitRegReference) {
    if (-not $tenantId) { $tenantId = '<YOUR-TENANT-ID-GUID>' }
    @"
Windows Registry Editor Version 5.00

; ODFBGOV client policy REFERENCE — review before deploying. Prefer Intune/ADMX over hand-edited registry.
; Verify these value names against the OneDrive.admx shipped with your OneDrive build.
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive]
; Silently sign in users with their Windows credentials ("OneDrive Silent Config - AllUsers - Prod")
"SilentAccountConfig"=dword:00000001
; Use OneDrive Files On-Demand
"FilesOnDemandEnabled"=dword:00000001
; Silently move Windows known folders to OneDrive ("KFM Silent Redirect - Broad - Stage2") — value = tenant ID
"KFMSilentOptIn"="$tenantId"
; Prevent users from moving their known folders back to the PC
"KFMBlockOptOut"=dword:00000001
"@ | Out-File -FilePath $EmitRegReference -Encoding ascii
    Write-Host ("Wrote client-policy REFERENCE template to {0} (review, do not blind-import)." -f $EmitRegReference) -ForegroundColor Green
}

if (-not ($TenantOnlyLookup -or $ResolveDomainGuids -or $EmitRegReference)) {
    Write-Host 'Nothing to do. Pass -TenantOnlyLookup, -ResolveDomainGuids, and/or -EmitRegReference.' -ForegroundColor Yellow
}
