<#
.SYNOPSIS
    UPRTG-Remediation.ps1 — safely fix common Universal Print configuration drift on GCC High.
.DESCRIPTION
    PURPOSE
        Detects and, on approval, fixes common Universal Print configuration drift on a GCC High
        tenant: a targeting group that exists but is not granted on its share, and empty
        targeting groups. SAFE BY DEFAULT: runs as -WhatIf; it reports findings and the fix plan
        and changes nothing until you re-run with -Execute (or -Confirm:$false). It never
        deletes printers, shares, or groups.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\UPRTG-Remediation.ps1 -ShareName 'UP-Pilot-Printer-01' -GroupName 'UP-Pilot-Users'
        Apply the reviewed fixes:
          add -Execute
        (Graph scopes: PrinterShare.ReadWrite.All, Group.Read.All; -Environment USGov)
    EXPECTED RESULTS
        Sign-in opens login.microsoftonline.us. Findings print as OK / DRIFT. In preview, fixes
        show as 'WhatIf:'. With -Execute, applied fixes print PASS. Re-run UPRTG-Validation.ps1 after.
.NOTES
    White-label — the repeatable way. Changes Microsoft Graph US Gov state only when -Execute is set.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$ShareName,
    [Parameter(Mandatory)] [string]$GroupName,
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
if (-not $Execute) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

try {
    Connect-MgGraph -Environment USGov -Scopes "PrinterShare.ReadWrite.All","Group.Read.All" -NoWelcome
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov' (GCC High)." }
    Write-Host "Connected as $($ctx.Account) ($($ctx.Environment))" -ForegroundColor Green
}
catch {
    Write-Warning "Graph sign-in failed: $($_.Exception.Message)"
    return
}

if (-not $Execute) {
    Write-Host "PREVIEW MODE (-WhatIf): no changes will be made. Re-run with -Execute to apply." -ForegroundColor Yellow
}

# --- Resolve group and share ---
$group = $null
try {
    $g = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value)
    $group = $g | Select-Object -First 1
} catch {}
if (-not $group) {
    Write-Warning ("Group '{0}' not found. Create it with UPRTG-Set-ScopeTargeting.ps1 first." -f $GroupName)
    Disconnect-MgGraph | Out-Null; return
}

$share = $null
try {
    $shares = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares").value)
    $share = $shares | Where-Object { $_.displayName -eq $ShareName } | Select-Object -First 1
} catch {}
if (-not $share) {
    Write-Warning ("Share '{0}' not found. Share the printer in portal.azure.us first (Implementation Step 6)." -f $ShareName)
    Disconnect-MgGraph | Out-Null; return
}

Write-Host "==== Findings ====" -ForegroundColor Cyan

# --- Finding 1: group empty? (report only — do not auto-add unknown members) ---
$memberCount = 0
try { $memberCount = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members" -f $group.id)).value).Count } catch {}
if ($memberCount -gt 0) { Write-Host ("  OK    Group '{0}' has {1} member(s)." -f $GroupName, $memberCount) -ForegroundColor Green }
else { Write-Host ("  DRIFT Group '{0}' has no members. Add users with UPRTG-Set-ScopeTargeting.ps1 (not auto-fixed here)." -f $GroupName) -ForegroundColor Yellow }

# --- Finding 2: group not granted on share? (auto-fixable) ---
$granted = $false
try {
    $allowed = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/print/shares/{0}/allowedGroups" -f $share.id)).value)
    $granted = [bool]($allowed | Where-Object { $_.id -eq $group.id })
} catch {}

if ($granted) {
    Write-Host ("  OK    Group '{0}' is granted on share '{1}'." -f $GroupName, $ShareName) -ForegroundColor Green
}
else {
    Write-Host ("  DRIFT Group '{0}' is NOT granted on share '{1}'." -f $GroupName, $ShareName) -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("share '$ShareName'", "Grant group '$GroupName'")) {
        try {
            $ref = @{ "@odata.id" = "https://graph.microsoft.us/v1.0/directoryObjects/$($group.id)" }
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/print/shares/{0}/allowedGroups/`$ref" -f $share.id) -Body $ref
            Write-Host ("  PASS  Granted '{0}' on share '{1}'." -f $GroupName, $ShareName) -ForegroundColor Green
        }
        catch { Write-Warning ("Could not grant group on share: {0}" -f $_.Exception.Message) }
    }
}

Write-Host ""
if (-not $Execute) { Write-Host "Preview complete. Re-run with -Execute to apply the fixes above." -ForegroundColor Yellow }
else               { Write-Host "Remediation applied. Re-run UPRTG-Validation.ps1 to confirm." -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
