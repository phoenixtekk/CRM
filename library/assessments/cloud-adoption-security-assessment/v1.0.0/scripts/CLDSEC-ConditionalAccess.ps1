<#
.SYNOPSIS
    CLDSEC-ConditionalAccess.ps1 — read-only Conditional Access coverage/gap review.
.DESCRIPTION
    PURPOSE
        Enumerates every Conditional Access policy (enabled and report-only) and tests for the coverage
        gaps that most often leave a tenant exposed even when many policies exist: no phishing-resistant
        MFA for admins or all users, legacy authentication not blocked, no device-compliance grant, and
        break-glass / emergency-access accounts not excluded from enforcement. It REPORTS gaps only — it
        never creates, edits, enables, or disables a policy. Building/enforcing CA policy is a separate,
        pilot-first remediation.
    HOW TO RUN
        Connect-MgGraph -Scopes "Policy.Read.All"
        pwsh -File .\CLDSEC-ConditionalAccess.ps1 -OutputFolder "<secure path>"
        Optionally: -BreakGlassUpns "bg-admin1@contoso.com","bg-admin2@contoso.com"
    EXPECTED RESULTS
        A policy inventory and a gap checklist (PASS/GAP) with the policy names involved. CSV written to the
        output folder. Read-only.
.NOTES
    White-label. Read-only. Makes no changes. contoso.com is a placeholder.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OutputFolder,
    [string[]]$BreakGlassUpns
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Write-Host "CLDSEC Conditional Access coverage (read-only)`n" -ForegroundColor Cyan

try { $policies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop }
catch { Write-Host "Could not read CA policies: $($_.Exception.Message). Confirm Policy.Read.All (R3)." -ForegroundColor Red; return }

$all = @($policies)
$enabled = @($all | Where-Object { $_.State -eq 'enabled' })
Write-Host "Policies: $($all.Count) total, $($enabled.Count) enabled, $((@($all | Where-Object State -eq 'enabledForReportingButNotEnforced')).Count) report-only`n" -ForegroundColor Green

# Inventory
$inv = $all | ForEach-Object {
    [pscustomobject]@{
        Name        = $_.DisplayName
        State       = $_.State
        Users       = ($_.Conditions.Users.IncludeUsers -join ',')
        Apps        = ($_.Conditions.Applications.IncludeApplications -join ',')
        GrantControls = ($_.GrantControls.BuiltInControls -join ',')
        ClientApps  = ($_.Conditions.ClientAppTypes -join ',')
    }
}
$inv | Format-Table -AutoSize
$inv | Export-Csv -Path (Join-Path $OutputFolder "CLDSEC-ca-inventory-$stamp.csv") -NoTypeInformation -Encoding UTF8

# --- Gap checks (against ENABLED policies only) ------------------------------
$checks = New-Object System.Collections.Generic.List[object]
function Add-Gap([string]$Name,[string]$Status,[string]$Detail){ $checks.Add([pscustomobject]@{ Check=$Name; Status=$Status; Detail=$Detail }) }

# 1. MFA for admins / all users
$mfaAll = $enabled | Where-Object {
    ($_.GrantControls.BuiltInControls -contains 'mfa') -and
    ($_.Conditions.Users.IncludeUsers -contains 'All')
}
Add-Gap 'MFA required for all users' (if ($mfaAll){'PASS'}else{'GAP'}) (if ($mfaAll){"via: $(($mfaAll.DisplayName) -join '; ')"}else{'No enabled policy requires MFA for All users'})

$mfaAdmin = $enabled | Where-Object {
    ($_.GrantControls.BuiltInControls -contains 'mfa') -and
    ($_.Conditions.Users.IncludeRoles.Count -gt 0)
}
Add-Gap 'MFA required for admin roles' (if ($mfaAdmin){'PASS'}else{'GAP'}) (if ($mfaAdmin){"via: $(($mfaAdmin.DisplayName) -join '; ')"}else{'No enabled policy targets admin roles with MFA'})

# 2. Legacy auth blocked
$legacyBlock = $enabled | Where-Object {
    ($_.Conditions.ClientAppTypes -contains 'exchangeActiveSync' -or $_.Conditions.ClientAppTypes -contains 'other') -and
    ($_.GrantControls.BuiltInControls -contains 'block')
}
Add-Gap 'Legacy authentication blocked' (if ($legacyBlock){'PASS'}else{'GAP'}) (if ($legacyBlock){"via: $(($legacyBlock.DisplayName) -join '; ')"}else{'No enabled policy blocks legacy/other client apps'})

# 3. Device compliance grant
$compGrant = $enabled | Where-Object { $_.GrantControls.BuiltInControls -contains 'compliantDevice' -or $_.GrantControls.BuiltInControls -contains 'domainJoinedDevice' }
Add-Gap 'Device compliance / hybrid-join grant' (if ($compGrant){'PASS'}else{'GAP'}) (if ($compGrant){"via: $(($compGrant.DisplayName) -join '; ')"}else{'No enabled policy requires a compliant/joined device'})

# 4. Break-glass exclusion
if ($BreakGlassUpns) {
    $anyExcludesBg = $enabled | Where-Object { $_.Conditions.Users.ExcludeUsers.Count -gt 0 }
    Add-Gap 'Break-glass accounts excluded' (if ($anyExcludesBg){'REVIEW'}else{'GAP'}) 'Manually confirm the emergency-access accounts are excluded from enforcement policies (verify UPNs against ExcludeUsers)'
} else {
    Add-Gap 'Break-glass accounts excluded' 'REVIEW' 'Provide -BreakGlassUpns to check; every enforcement policy must exclude the emergency-access accounts'
}

Write-Host "`n--- Coverage gaps ---" -ForegroundColor Cyan
$checks | Format-Table -AutoSize
$checks | Export-Csv -Path (Join-Path $OutputFolder "CLDSEC-ca-gaps-$stamp.csv") -NoTypeInformation -Encoding UTF8

$gapCount = (@($checks | Where-Object Status -eq 'GAP')).Count
Write-Host "`n$gapCount coverage GAP(s). Report only — no policy was created or changed (remediation is pilot-first, separate)." -ForegroundColor Yellow
