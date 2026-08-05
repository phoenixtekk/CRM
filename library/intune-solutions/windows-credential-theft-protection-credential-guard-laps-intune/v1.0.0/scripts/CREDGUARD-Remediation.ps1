<#
.SYNOPSIS
    CREDGUARD-Remediation.ps1 — safely create/assign the Windows Credential Guard profile (and preview the rest).
.DESCRIPTION
    PURPOSE
        Remediates the most common gap in the credential-theft defense: no Windows Defender Credential
        Guard profile deployed. It creates a Windows endpoint-protection profile that enables
        virtualization-based security and Credential Guard (UEFI lock by default) and assigns it to a
        target group, then PREVIEWS the remaining controls (LSASS RunAsPPL, WDigest UseLogonCredential=0,
        Remote Credential Guard / restricted delegation, and WinRM DisableRunAs) with the exact values to
        set per the Implementation Guide — because those surface differently across tenants (Settings
        Catalog vs Custom) and should be verified before creation. Defaults to -WhatIf, so it previews
        every change and modifies nothing until re-run to apply. Remediates the endpoint credential-theft
        controls only — never RDP host hardening or domain settings.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -Name "Credential Guard - Pilot"  -WithoutLock  (use enableWithoutUEFILock for pilots)
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be created/assigned, plus the
        values for the remaining hardening controls. When applied: a Credential Guard endpoint-protection
        profile exists and is assigned to the group. Re-run CREDGUARD-Discovery.ps1 to confirm.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'Credential Guard - Pilot',
    [switch]$WithoutLock
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$cgMode = if ($WithoutLock) { 'enableWithoutUEFILock' } else { 'enableWithUEFILock' }

# Does a Credential Guard endpoint-protection profile already exist?
$existing = $null
try {
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windows10EndpointProtectionConfiguration')"
    foreach ($p in @($tpl.value)) {
        if ($p.displayName -eq $Name -or ("$($p | ConvertTo-Json -Depth 20)") -match 'CredentialGuardSettings.*enable') { $existing = $p; break }
    }
} catch {}

if ($existing) {
    Write-Host "Credential Guard profile already present: '$($existing.displayName)' (id $($existing.id))." -ForegroundColor Green
    $profileId = $existing.id
} else {
    # Windows endpoint-protection template: VBS + Credential Guard. Documented enum values:
    #   deviceGuardLocalSystemAuthorityCredentialGuardSettings = enableWithUEFILock | enableWithoutUEFILock | disable
    $profile = @{
        '@odata.type' = '#microsoft.graph.windows10EndpointProtectionConfiguration'
        displayName   = $Name
        description   = 'VBS + Windows Defender Credential Guard for credential-theft protection. Created by CREDGUARD-Remediation.ps1.'
        deviceGuardEnableVirtualizationBasedSecurity           = $true
        deviceGuardEnableSecureBootWithDMA                     = $true
        deviceGuardLocalSystemAuthorityCredentialGuardSettings = $cgMode
    }
    if ($PSCmdlet.ShouldProcess($Name, "Create Credential Guard profile ($cgMode)")) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations' -Body ($profile | ConvertTo-Json -Depth 20) -ContentType 'application/json'
        Write-Host "Created profile '$($created.displayName)' (id $($created.id), $cgMode)." -ForegroundColor Green
        $profileId = $created.id
    } else {
        Write-Host "WhatIf: would create Windows Credential Guard endpoint-protection profile '$Name' with VBS enabled, Secure Boot + DMA, and Credential Guard = $cgMode." -ForegroundColor Yellow
    }
}

# Assign to the target group
if ($profileId -and $PSCmdlet.ShouldProcess("profile $profileId", "Assign to group $GroupId")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$profileId/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned profile to group $GroupId." -ForegroundColor Green
} elseif (-not $profileId) {
    Write-Host "WhatIf: would then assign the new profile to group $GroupId." -ForegroundColor Yellow
}

# Preview the remaining controls — authored per the Implementation Guide (verify surfacing in your tenant).
Write-Host ''
Write-Host 'Remaining credential-theft controls to author (Implementation Guide Steps 6-12):' -ForegroundColor Cyan
Write-Host "  * LSASS Protection (RunAsPPL) - Pilot   -> HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL = 1 (audit-first)"
Write-Host "  * WDigest Disabled - Baseline           -> HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest\UseLogonCredential = 0"
Write-Host "  * Remote Credential Guard - Pilot       -> Restrict delegation of credentials to remote servers = Require Remote Credential Guard"
Write-Host "  * WinRM No RunAs Credentials - Baseline -> HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\DisableRunAs = 1"
Write-Host "  * Windows LAPS - Baseline               -> Endpoint security > Account protection > Local admin password solution (Entra backup)"
Write-Host "  (These surface as Settings Catalog / Account protection differently by tenant — verify names, then create per the guide.)" -ForegroundColor DarkGray

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run CREDGUARD-Discovery.ps1 to confirm.' -ForegroundColor Green }
