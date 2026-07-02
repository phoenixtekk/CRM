<#
.SYNOPSIS
    Enable-EntraKerberos.ps1 — (Hybrid only) enable Microsoft Entra Kerberos for Cloud Kerberos Trust.

.DESCRIPTION
    PURPOSE
        Creates the Microsoft Entra Kerberos server object for an on-premises Active Directory
        domain. This is the one-time step that lets Windows Hello for Business users on hybrid
        devices obtain Kerberos tickets for on-premises resources (file shares, printers) without
        a password and without per-user certificates (Cloud Kerberos Trust).

        CLOUD-ONLY ORGANIZATIONS DO NOT NEED THIS SCRIPT.

    HOW TO RUN
        On a domain-joined admin workstation that can reach a domain controller, signed in with:
          * an on-premises Domain Administrator, and
          * a Microsoft Entra Global Administrator (or Cloud Device Administrator).
        Run once per domain:
            powershell -ExecutionPolicy Bypass -File .\Enable-EntraKerberos.ps1 -Domain corp.contoso.com -DomainController dc01.corp.contoso.com

    EXPECTED RESULTS
        The script installs the AzureADHybridAuthenticationManagement module if needed, creates
        (or confirms) the Azure AD Kerberos server object for the domain, and prints its state.

.NOTES
    White-label — Intune Solutions.
    Wraps Microsoft's Set-/Get-AzureADKerberosServer cmdlets with safe checks and clear output.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Domain,

    [string]$CloudGlobalAdminUPN
)

Write-Host "=== Enable Microsoft Entra Kerberos (Cloud Kerberos Trust) for $Domain ===" -ForegroundColor Cyan

# 1) Module
if (-not (Get-Module -ListAvailable -Name AzureADHybridAuthenticationManagement)) {
    Write-Host "Installing AzureADHybridAuthenticationManagement (current user)..." -ForegroundColor Yellow
    Install-Module AzureADHybridAuthenticationManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module AzureADHybridAuthenticationManagement -ErrorAction Stop

# 2) Credentials
if (-not $CloudGlobalAdminUPN) { $CloudGlobalAdminUPN = Read-Host "Microsoft Entra Global Admin UPN" }
Write-Host "On-prem Domain Admin credential prompt follows..." -ForegroundColor Gray
$domainCred = Get-Credential -Message "On-premises Domain Administrator for $Domain"

# 3) Check existing state
Write-Host "`nChecking for an existing Azure AD Kerberos server object..."
try {
    $existing = Get-AzureADKerberosServer -Domain $Domain `
        -UserPrincipalName $CloudGlobalAdminUPN -DomainCredential $domainCred -ErrorAction Stop
    if ($existing -and $existing.Id) {
        Write-Host "Azure AD Kerberos server already exists for $Domain (Id: $($existing.Id))." -ForegroundColor Green
        $existing | Format-List
        return
    }
} catch {
    Write-Host "No existing object (or read failed): $($_.Exception.Message)" -ForegroundColor Gray
}

# 4) Create
if ($PSCmdlet.ShouldProcess($Domain, "Create Azure AD Kerberos server object")) {
    try {
        Set-AzureADKerberosServer -Domain $Domain `
            -UserPrincipalName $CloudGlobalAdminUPN -DomainCredential $domainCred -ErrorAction Stop
        Write-Host "Created Azure AD Kerberos server object for $Domain." -ForegroundColor Green
        Get-AzureADKerberosServer -Domain $Domain `
            -UserPrincipalName $CloudGlobalAdminUPN -DomainCredential $domainCred | Format-List
    } catch {
        Write-Host "Creation failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}