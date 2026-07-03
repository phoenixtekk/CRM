<#
.SYNOPSIS
    UPRTG-Set-ScopeTargeting.ps1 — build a Universal Print targeting group and grant it on a share (GCC High).
.DESCRIPTION
    PURPOSE
        Creates (if missing) a Microsoft Entra security group used to target a Universal Print
        share, adds the specified members, and grants that group access on the named share.
        This is the repeatable way to build pilot and wave targeting on a GCC High tenant.
        SAFE BY DEFAULT: runs as -WhatIf; it prints the plan and changes nothing until you
        re-run with -Execute (or -Confirm:$false).
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\UPRTG-Set-ScopeTargeting.ps1 -GroupName 'UP-Pilot-Users' -ShareName 'UP-Pilot-Printer-01' -MemberUpn 'user1@your-tenant.us','user2@your-tenant.us'
        Apply:
          add -Execute
        (Graph scopes: Group.ReadWrite.All, PrinterShare.ReadWrite.All, User.Read.All; -Environment USGov)
    EXPECTED RESULTS
        In preview you see each action prefixed 'WhatIf:'. With -Execute the group is created/updated,
        members added, and the group granted on the share; the script prints PASS per action.
.NOTES
    White-label — the repeatable way. Changes Microsoft Graph US Gov state only when -Execute is set.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$GroupName,
    [string]$ShareName,
    [string[]]$MemberUpn = @(),
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

# Default to safe preview: unless -Execute is passed, force -WhatIf behavior.
if (-not $Execute) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Warning "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

try {
    Connect-MgGraph -Environment USGov -Scopes "Group.ReadWrite.All","PrinterShare.ReadWrite.All","User.Read.All" -NoWelcome
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

# --- 1. Ensure the targeting group exists ---
$group = $null
try {
    $found = @((Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value)
    $group = $found | Select-Object -First 1
} catch {}

if ($group) {
    Write-Host ("Group '{0}' already exists (id {1})." -f $GroupName, $group.id) -ForegroundColor Green
}
else {
    if ($PSCmdlet.ShouldProcess("Entra security group '$GroupName'", "Create")) {
        $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
        $bodyObj = @{
            displayName     = $GroupName
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        }
        $group = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $bodyObj
        Write-Host ("PASS: created group '{0}' (id {1})." -f $GroupName, $group.id) -ForegroundColor Green
    }
}

# --- 2. Add members ---
foreach ($upn in $MemberUpn) {
    if ($PSCmdlet.ShouldProcess("user '$upn'", "Add to group '$GroupName'")) {
        try {
            $u = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}" -f $upn)
            $ref = @{ "@odata.id" = "https://graph.microsoft.us/v1.0/directoryObjects/$($u.id)" }
            Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $group.id) -Body $ref
            Write-Host ("PASS: added {0} to '{1}'." -f $upn, $GroupName) -ForegroundColor Green
        }
        catch { Write-Warning ("Could not add {0}: {1}" -f $upn, $_.Exception.Message) }
    }
}

# --- 3. Grant the group on the share ---
if ($ShareName) {
    $share = $null
    try {
        $shares = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares").value)
        $share = $shares | Where-Object { $_.displayName -eq $ShareName } | Select-Object -First 1
    } catch {}

    if (-not $share) {
        Write-Warning ("Share '{0}' not found. Share the printer in portal.azure.us first (Implementation Step 6)." -f $ShareName)
    }
    elseif ($group) {
        if ($PSCmdlet.ShouldProcess("share '$ShareName'", "Grant group '$GroupName'")) {
            try {
                $ref = @{ "@odata.id" = "https://graph.microsoft.us/v1.0/directoryObjects/$($group.id)" }
                Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/print/shares/{0}/allowedGroups/`$ref" -f $share.id) -Body $ref
                Write-Host ("PASS: granted '{0}' on share '{1}'." -f $GroupName, $ShareName) -ForegroundColor Green
            }
            catch { Write-Warning ("Could not grant group on share: {0}" -f $_.Exception.Message) }
        }
    }
}

Write-Host ""
if (-not $Execute) { Write-Host "Preview complete. Re-run with -Execute to apply the plan above." -ForegroundColor Yellow }
else               { Write-Host "Targeting applied. Validate with UPRTG-Validation.ps1." -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
