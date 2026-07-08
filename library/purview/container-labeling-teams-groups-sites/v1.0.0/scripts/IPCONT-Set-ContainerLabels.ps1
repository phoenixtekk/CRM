<#
.SYNOPSIS
    IPCONT-Set-ContainerLabels.ps1 — enable container labeling and/or apply container labels to Teams/Groups/Sites (SAFE: -WhatIf by default; -Commit to apply).
.DESCRIPTION
    PURPOSE
        Configuration/remediation helper with two jobs, both SAFE BY DEFAULT (preview with -WhatIf,
        change nothing until -Commit):
          (1) -EnablePrerequisites : the one-time TENANT enablement of container labeling — sets the
              Entra 'Group.Unified' directory setting EnableMIPLabels = True and runs Execute-AzureAdLabelSync
              (AIPService) so sensitivity labels are usable on Groups/Teams/Sites.
          (2) -TargetsPath <csv>   : applies a named container label to each target — Groups/Teams via
              Microsoft Graph (group 'assignedLabels'), SharePoint sites via Set-SPOSite -SensitivityLabel.
              Prints the exact REVERSE command for every change. Apply to the pilot ring first.
    HOW TO RUN
        # One-time enablement (dry-run then commit):
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -WhatIf
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -Commit
        # Apply labels (dry-run then commit):
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Set-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -WhatIf
        powershell -ExecutionPolicy Bypass -File .\IPCONT-Set-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -Commit -SPOAdminUrl https://contoso-admin.sharepoint.com
        Targets CSV columns: ContainerName, Identity (group id OR site URL), Label (display name)
        Requires: Microsoft.Graph, AIPService (enablement), Microsoft.Online.SharePoint.PowerShell (sites).
    EXPECTED RESULTS
        Dry-run prints each intended change + its reverse command and makes nothing. With -Commit, groups
        report the assigned label and sites report -SensitivityLabel set. PASS = pilot targets carry the
        intended label; enablement reports EnableMIPLabels = True.
.NOTES
    Purview — Container Labeling (Teams, Groups & Sites). HIGH-IMPACT (guest/sharing/device) — pilot first.
    Verify the current EnableMIPLabels method against Microsoft guidance for your tenant (surface evolving).
    No secrets in code; interactive modern-auth only. Tier determinations are the stakeholders' to make.
#>
[CmdletBinding(DefaultParameterSetName='WhatIf')]
param(
    [switch]$EnablePrerequisites,
    [string]$TargetsPath,
    [string]$SPOAdminUrl,
    [switch]$Commit,
    [switch]$WhatIf = $true
)

if ($Commit) { $WhatIf = $false }
if (-not $EnablePrerequisites -and -not $TargetsPath) {
    throw "Specify -EnablePrerequisites and/or -TargetsPath. Nothing to do."
}
$mode = if ($WhatIf) { 'DRY-RUN (-WhatIf): no changes will be made' } else { 'COMMIT: changes WILL be applied' }
Write-Host ("=== IPCONT-Set-ContainerLabels  [{0}] ===" -f $mode) -ForegroundColor Cyan

function Connect-GraphWrite([string[]]$scopes) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $scopes | Out-Null
}

# ---------------- (1) One-time tenant enablement ----------------
if ($EnablePrerequisites) {
    Write-Host "`n-- Enable container labeling (Group.Unified EnableMIPLabels + label sync) --" -ForegroundColor Cyan
    Connect-GraphWrite @('Directory.ReadWrite.All','Group.Read.All')

    # Read current Group.Unified directory (group) setting
    $setting = $null
    try {
        $all = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/settings'
        $setting = $all.value | Where-Object { $_.templateId -and $_.displayName -eq 'Group.Unified' } | Select-Object -First 1
    } catch { Write-Host ("  [warn] Could not read directory settings: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    $current = if ($setting) { ($setting.values | Where-Object { $_.name -eq 'EnableMIPLabels' }).value } else { $null }
    Write-Host ("  Current EnableMIPLabels: {0}" -f ($(if($current){$current}else{'<not set / no Group.Unified setting>'}))) -ForegroundColor Gray

    if ($current -eq 'True') {
        Write-Host "  [SKIP] EnableMIPLabels already True." -ForegroundColor DarkGray
    } elseif ($WhatIf) {
        Write-Host "  [WOULD SET] Group.Unified EnableMIPLabels = True (creates the setting from the template if absent)." -ForegroundColor Yellow
        Write-Host "             reverse: set EnableMIPLabels = False on the Group.Unified setting." -ForegroundColor DarkGray
        Write-Host "  [WOULD RUN] Execute-AzureAdLabelSync (AIPService) to sync labels to Entra." -ForegroundColor Yellow
    } else {
        try {
            if ($setting) {
                $vals = @($setting.values | ForEach-Object { @{ name = $_.name; value = $_.value } })
                for ($i=0; $i -lt $vals.Count; $i++){ if ($vals[$i].name -eq 'EnableMIPLabels'){ $vals[$i].value = 'True' } }
                if (-not ($vals.name -contains 'EnableMIPLabels')) { $vals += @{ name='EnableMIPLabels'; value='True' } }
                Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/v1.0/settings/{0}" -f $setting.id) -Body (@{ values = $vals } | ConvertTo-Json -Depth 5)
            } else {
                $tmpl = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/directorySettingTemplates').value |
                        Where-Object { $_.displayName -eq 'Group.Unified' } | Select-Object -First 1
                if (-not $tmpl) { throw "Group.Unified directorySettingTemplate not found." }
                $vals = @($tmpl.values | ForEach-Object { @{ name = $_.name; value = $_.defaultValue } })
                for ($i=0; $i -lt $vals.Count; $i++){ if ($vals[$i].name -eq 'EnableMIPLabels'){ $vals[$i].value = 'True' } }
                Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/settings' -Body (@{ templateId = $tmpl.id; values = $vals } | ConvertTo-Json -Depth 5)
            }
            Write-Host "  [SET] EnableMIPLabels = True on Group.Unified." -ForegroundColor Green
        } catch { Write-Host ("  [ERROR] setting EnableMIPLabels: {0}" -f $_.Exception.Message) -ForegroundColor Red }

        try {
            if (-not (Get-Module -ListAvailable -Name AIPService)) { Install-Module AIPService -Scope CurrentUser -Force -AllowClobber }
            Import-Module AIPService -ErrorAction Stop
            Connect-AIPService -ErrorAction Stop
            Execute-AzureAdLabelSync -ErrorAction Stop
            Write-Host "  [SYNC] Execute-AzureAdLabelSync completed." -ForegroundColor Green
        } catch { Write-Host ("  [warn] Label sync step: {0} — verify AIPService availability/guidance for your tenant." -f $_.Exception.Message) -ForegroundColor Yellow }
    }
}

# ---------------- (2) Apply labels to targets ----------------
if ($TargetsPath) {
    if (-not (Test-Path $TargetsPath)) { throw "Targets CSV not found: $TargetsPath" }
    $targets = Import-Csv -Path $TargetsPath
    foreach ($c in 'ContainerName','Identity','Label') {
        if (-not ($targets | Get-Member -Name $c)) { throw "Targets CSV must have columns: ContainerName, Identity, Label" }
    }
    Write-Host "`n-- Apply container labels to targets --" -ForegroundColor Cyan
    Connect-GraphWrite @('Group.ReadWrite.All','Directory.Read.All','InformationProtectionPolicy.Read')

    # Build label display-name -> id map from the published label catalog
    $nameToId = @{}
    try {
        (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/informationProtection/policy/labels').value |
            ForEach-Object { $nameToId[$_.name] = $_.id }
    } catch { Write-Host ("  [warn] Could not read label catalog: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    $spoReady = $false
    if ($SPOAdminUrl) {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
            Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
        try { Connect-SPOService -Url $SPOAdminUrl -ErrorAction Stop; $spoReady = $true }
        catch { Write-Host ("  [warn] SPO connect failed; site targets will be skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    }

    foreach ($row in $targets) {
        $name = $row.ContainerName.Trim(); $id = $row.Identity.Trim(); $label = $row.Label.Trim()
        if (-not $id -or -not $label) { continue }
        $isSite = $id -match '^https?://'

        if ($isSite) {
            if (-not $spoReady) { Write-Host ("  [SKIP] site '{0}' — supply -SPOAdminUrl to apply." -f $name) -ForegroundColor DarkGray; continue }
            $reverse = ("Set-SPOSite -Identity '{0}' -SensitivityLabel '<previous-or-empty>'" -f $id)
            if ($WhatIf) {
                Write-Host ("  [WOULD LABEL SITE] '{0}' <- '{1}'   reverse: {2}" -f $name, $label, $reverse) -ForegroundColor Yellow
            } else {
                try { Set-SPOSite -Identity $id -SensitivityLabel $label -ErrorAction Stop
                      Write-Host ("  [LABELED SITE] '{0}' <- '{1}'   (reverse: {2})" -f $name, $label, $reverse) -ForegroundColor Green }
                catch { Write-Host ("  [ERROR] site '{0}': {1}" -f $name, $_.Exception.Message) -ForegroundColor Red }
            }
        } else {
            $labelId = $nameToId[$label]
            if (-not $labelId) { Write-Host ("  [MISSING LABEL] '{0}' not found in the published label catalog — verify the label is published." -f $label) -ForegroundColor Yellow; continue }
            $reverse = ("Update group {0} assignedLabels to its previous value (or empty)" -f $id)
            if ($WhatIf) {
                Write-Host ("  [WOULD LABEL GROUP] '{0}' <- '{1}' ({2})   reverse: {3}" -f $name, $label, $labelId, $reverse) -ForegroundColor Yellow
            } else {
                try {
                    $body = @{ assignedLabels = @(@{ labelId = $labelId }) } | ConvertTo-Json -Depth 5
                    Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/v1.0/groups/{0}" -f $id) -Body $body -ErrorAction Stop
                    Write-Host ("  [LABELED GROUP] '{0}' <- '{1}'   (reverse: {2})" -f $name, $label, $reverse) -ForegroundColor Green
                } catch { Write-Host ("  [ERROR] group '{0}': {1}" -f $name, $_.Exception.Message) -ForegroundColor Red }
            }
        }
    }
}

if ($WhatIf) { Write-Host "`nDry-run complete. Re-run with -Commit to apply. Apply to the pilot ring first." -ForegroundColor Cyan }
else         { Write-Host "`nCommit complete. Validate with IPCONT-Validate-ContainerLabels.ps1." -ForegroundColor Green }
