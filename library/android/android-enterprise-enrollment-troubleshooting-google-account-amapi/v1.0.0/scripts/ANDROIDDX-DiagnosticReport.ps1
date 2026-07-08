<#
.SYNOPSIS
    ANDROIDDX-DiagnosticReport.ps1 — read-only enrollment/account-add diagnostic report mapping symptom to likely cause.
.DESCRIPTION
    PURPOSE
        Gathers the tenant-side evidence for an Android enrollment / "can't add a Google account"
        investigation — binding health, Android enrollment restriction, enrollment profiles, recent
        Android enrollments and their management agent — and maps the observed state to the most
        likely root-cause node in the Diagnostic Playbook. Produces the
        'Diagnostic Report - Android - <symptom>' artifact and (with -JsonPath) a config snapshot you
        can diff dev-vs-prod. Read-only — it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDDX-DiagnosticReport.ps1 -Symptom CantAddAccount -JsonPath C:\Temp\prod-config.json
        -Symptom accepts: CantAddAccount | DevWorksProdFails | AfterAmapiMigration | BindingError | General
        Requires the Microsoft Graph PowerShell SDK and read scopes DeviceManagementServiceConfig.Read.All,
        DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A ranked list of likely causes for the chosen symptom, each pointing to a Playbook node and its
        fix. Device-side signals (endpoint reachability, on-device account-add error) are gathered by
        ANDROIDDX-EndpointReachability.ps1 and the device logs — this report covers the tenant side.
.NOTES
    Android. Read-only against Microsoft Graph (beta resources).
    Symptom->cause mapping is heuristic guidance, not an assertion — AMAPI/enrollment behavior is
    evolving; confirm each candidate against current Microsoft guidance and your tenant before acting.
#>
[CmdletBinding()] param(
    [ValidateSet('CantAddAccount','DevWorksProdFails','AfterAmapiMigration','BindingError','General')]
    [string]$Symptom = 'General',
    [string]$JsonPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host ("=== Diagnostic report — symptom: {0} ===" -f $Symptom) -ForegroundColor Cyan
$snap = [ordered]@{}

# Evidence: binding
try { $b = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"; $snap.binding = $b } catch { $snap.binding = $null }
# Evidence: enrollment restrictions
try { $snap.enrollmentConfigurations = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations?`$top=100").value } catch { $snap.enrollmentConfigurations = @() }
# Evidence: device-owner enrollment profiles
try { $snap.deviceOwnerProfiles = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles?`$top=100").value } catch { $snap.deviceOwnerProfiles = @() }
# Evidence: recent Android enrollments + agent mix
try { $snap.recentAndroid = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=deviceName,enrolledDateTime,managementAgent,ownerType,complianceState&`$top=200").value } catch { $snap.recentAndroid = @() }

$bindOk = ($snap.binding -and $snap.binding.bindStatus -eq 'bound')
$syncOk = ($snap.binding -and $snap.binding.lastAppSyncStatus -eq 'success')
Write-Host ("Binding: {0}   App sync: {1}   Enrollment profiles: {2}   Android devices seen: {3}" -f `
    $(if($bindOk){'bound'}else{'NOT bound'}), $(if($syncOk){'success'}else{'not success/unknown'}), @($snap.deviceOwnerProfiles).Count, @($snap.recentAndroid).Count) -ForegroundColor Gray

# Symptom -> ranked likely causes (each = a Playbook node)
$causes = New-Object System.Collections.Generic.List[string]
switch ($Symptom) {
    'CantAddAccount' {
        if (-not $bindOk) { $causes.Add("Binding not 'bound' — the managed Google Play account can't be provisioned on-device. Repair the connector (Playbook A).") }
        $causes.Add("Network/proxy or TLS inspection blocking Google endpoints (accounts.google.com / *.googleapis.com / play.google.com) — run ANDROIDDX-EndpointReachability.ps1 from the device network (Playbook D).")
        $causes.Add("Account model mismatch — on a work profile the Google account is a MANAGED account added by the profile, NOT a consumer Gmail add; adding a personal Google account in the work profile is expected to fail (Playbook F).")
        $causes.Add("Device date/time wrong or Google Play services outdated/absent (non-GMS or China-market device) — TLS/token failures (Playbook D/F).")
    }
    'DevWorksProdFails' {
        $causes.Add("Config drift dev-vs-prod — export both with -JsonPath and diff with ANDROIDDX-EndpointReachability.ps1 -CompareConfig (Playbook B).")
        $causes.Add("Prod network egress/proxy differs from dev — endpoints allowed in dev are blocked in prod (Playbook B/D).")
        $causes.Add("Different enrollment-restriction or Conditional Access in prod blocking the sign-in/enrollment (Playbook B).")
        $causes.Add("Different managed Google Play binding model or a not-fully-consented binding in prod (Playbook A/B).")
    }
    'AfterAmapiMigration' {
        $causes.Add("Whether the AMAPI change required device RE-ENROLLMENT — VERIFY against current Microsoft guidance; migrated devices may need re-enrollment for the new management path (Playbook E).")
        $causes.Add("Enrollment profile / token regenerated by the migration — old QR/token no longer valid (Playbook E).")
        $causes.Add("App-approval/config re-sync needed post-migration — force a managed Google Play sync and re-check binding (Playbook A/E).")
        if (-not $syncOk) { $causes.Add("App sync not 'success' after migration — connector needs a sync/repair (Playbook A).") }
    }
    'BindingError' {
        if (-not $bindOk) { $causes.Add("bindStatus='$($snap.binding.bindStatus)' — re-establish the managed Google Play connection (Global Admin consent) (Playbook A).") }
        if ($snap.binding -and -not $snap.binding.ownerUserPrincipalName) { $causes.Add("No binding owner account — the enterprise managed account is missing; re-consent required (Playbook A).") }
        $causes.Add("Managed Google Play sync stalled/failed — apps won't deliver; force sync and inspect lastAppSyncStatus (Playbook A).")
    }
    default {
        $causes.Add("Start at binding health (Playbook A), then enrollment method path (Playbook C), then endpoints (Playbook D).")
    }
}
Write-Host "`nLikely causes (ranked):" -ForegroundColor Cyan
$rank=1; foreach ($c in $causes) { Write-Host ("  {0}. {1}" -f $rank++, $c) -ForegroundColor Yellow }

if ($JsonPath) { $snap | ConvertTo-Json -Depth 6 | Set-Content -Path $JsonPath; Write-Host ("`nSaved snapshot {0} (record as 'Diagnostic Report - Android - {1}'; reuse as dev/prod config for -CompareConfig)." -f $JsonPath,$Symptom) -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
