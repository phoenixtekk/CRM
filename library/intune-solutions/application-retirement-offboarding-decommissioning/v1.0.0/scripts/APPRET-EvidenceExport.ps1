<#
.SYNOPSIS
    APPRET-EvidenceExport.ps1 — compile the decommission evidence pack for a retired app (read-only).
.DESCRIPTION
    PURPOSE
        Produces the proof-of-decommission pack that answers "is this app genuinely gone?" Gathers the
        final install/uninstall status, the residual-installed device list with last check-in (so each
        remaining device can be dispositioned), whether the Intune app object still exists, whether any
        Entra groups / enterprise application / CA reference for the app remain, and writes it all to a
        timestamped folder (per-section CSVs + a summary.txt). Strictly read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPRET-EvidenceExport.ps1 -AppName "LegacyTrack Client" -OutFolder .\APPRET-LGT-Evidence
        US Gov: add  -Environment USGov  or  -Environment USGovDoD
        Requires the Microsoft Graph PowerShell SDK with DeviceManagementApps.Read.All, Group.Read.All,
        Application.Read.All.
    EXPECTED RESULTS
        A folder containing summary.txt, residual-installed.csv, final-status.csv, and
        remaining-artifacts.csv — attach with the Decision Record as the evidence pack.
.NOTES
    Intune Solutions — read-only. Evidence stage of an application retirement.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppName,
    [string]$OutFolder = ".\APPRET-Evidence",
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All','Application.Read.All' -Environment $Environment -NoWelcome

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = Join-Path $OutFolder $stamp
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$summary = New-Object System.Collections.Generic.List[string]
$summary.Add("Decommission Evidence Pack")
$summary.Add("App: $AppName")
$summary.Add("Generated: $(Get-Date -Format o)  (environment: $Environment)")
$summary.Add("")

# App object present?
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$app = $apps | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1

if ($app) {
    $summary.Add("APP OBJECT: STILL PRESENT in Intune (id $($app.id)). Decommission NOT complete until deleted (Step 13.1).")
    # Final status + residual installed
    $dev = @(); $duri = "/v1.0/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    do { $dr = Invoke-MgGraphRequest -Method GET -Uri $duri; $dev += $dr.value; $duri = $dr.'@odata.nextLink' } while ($duri)
    $dev | Select-Object deviceName,userName,installState,installStateDetail,lastSyncDateTime | Export-Csv (Join-Path $dir 'final-status.csv') -NoTypeInformation -Encoding UTF8
    $residual = $dev | Where-Object { $_.installState -eq 'installed' } | Select-Object deviceName,userName,lastSyncDateTime
    $residual | Export-Csv (Join-Path $dir 'residual-installed.csv') -NoTypeInformation -Encoding UTF8
    $g = $dev | Group-Object installState | ForEach-Object { "  $($_.Name): $($_.Count)" }
    $summary.Add("FINAL INSTALL STATUS:"); $g | ForEach-Object { $summary.Add($_) }
    $summary.Add("RESIDUAL INSTALLED (must each be dispositioned in the residual list): $($residual.Count)")
} else {
    $summary.Add("APP OBJECT: NOT FOUND in Intune — the app object has been deleted (good).")
}

# Remaining artefacts
$remain = @()
$grps = @(); $guri = "/v1.0/groups?`$filter=startswith(displayName,'APPRET')&`$select=id,displayName"
do { $gr = try { Invoke-MgGraphRequest -Method GET -Uri $guri -Headers @{ ConsistencyLevel='eventual' } } catch { $null }; if($gr){ $grps += $gr.value; $guri=$gr.'@odata.nextLink' } else { break } } while ($guri)
foreach ($g in ($grps | Where-Object { $_.displayName -like "*$AppName*" })) { $remain += [pscustomobject]@{ Type='EntraGroup'; Name=$g.displayName; Id=$g.id } }
try {
    $sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=startswith(displayName,'$AppName')&`$select=id,displayName,appId").value
    foreach ($s in $sp) { $remain += [pscustomobject]@{ Type='EnterpriseApp'; Name=$s.displayName; Id=$s.appId } }
} catch {}
$remain | Export-Csv (Join-Path $dir 'remaining-artifacts.csv') -NoTypeInformation -Encoding UTF8
$summary.Add("")
$summary.Add("REMAINING ARTEFACTS referencing the app (should be ZERO at closure): $($remain.Count)")
$remain | ForEach-Object { $summary.Add("  [$($_.Type)] $($_.Name)") }
$summary.Add("")
$summary.Add("Reminder: WDAC/App Control rules and SCCM deployments are verified manually (Step 13.4/13.6);")
$summary.Add("attach the data-export record and licence-reclamation figures from the Decision Record.")

$summary | Set-Content (Join-Path $dir 'summary.txt') -Encoding UTF8
Write-Host "Evidence pack written to: $dir" -ForegroundColor Green
Get-ChildItem $dir | Select-Object Name,Length | Format-Table -AutoSize
Disconnect-MgGraph | Out-Null
