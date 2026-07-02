<#
.SYNOPSIS
    ESB-Discovery.ps1 — snapshot of the device's current security posture.
.DESCRIPTION
    PURPOSE
        Reports a representative sample of settings a Windows security baseline hardens, so you can
        see the device's pre-baseline state and compare after applying.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\ESB-Discovery.ps1
    EXPECTED RESULTS
        A table of current values for sampled hardening settings.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== Security Posture Snapshot ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$rows = New-Object System.Collections.Generic.List[object]
function Row($n,$v){ $rows.Add([pscustomobject]@{ Setting=$n; Value=$v }) }
try { $mp = Get-MpPreference } catch { $mp = $null }
Row 'OS version' (Get-CimInstance Win32_OperatingSystem).Version
Row 'Firewall profiles enabled' (((Get-NetFirewallProfile).Enabled -join ','))
Row 'Defender PUA protection' ($(if($mp){$mp.PUAProtection}else{'?'}))
Row 'Network protection' ($(if($mp){$mp.EnableNetworkProtection}else{'?'}))
Row 'Controlled folder access' ($(if($mp){$mp.EnableControlledFolderAccess}else{'?'}))
Row 'SMBv1 installed' ((Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -EA SilentlyContinue).State)
Row 'LSA blank-password limit' ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name LimitBlankPasswordUse -EA SilentlyContinue).LimitBlankPasswordUse)
Row 'UAC (EnableLUA)' ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -EA SilentlyContinue).EnableLUA)
$rows | Format-Table -AutoSize
Write-Host "Compare these values after the baseline applies (see ESB-Validation.ps1)." -ForegroundColor Gray
