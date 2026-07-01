# 6. Troubleshooting Guide — Endpoint Health & Digital Experience Monitoring

Use `EHEM-Validation.ps1` / `EHEM-Discovery.ps1` for device state, `EHEM-Report.ps1` for fleet
scores, and `EHEM-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. No data / scores not appearing
| Symptom | Cause | Remediation |
|---|---|---|
| Overview shows "get started", no score | Endpoint analytics not enabled | Reports → Endpoint analytics → Start (Implementation Step 1) |
| Devices missing from analytics | Not enrolled, not synced, or data collection blocked | Run `EHEM-Validation.ps1`; confirm enrollment; run `EHEM-Remediation.ps1` to force a sync |
| Scores look empty after enabling | Baseline period not elapsed | Wait the data warm-up; watch device counts climb day over day |

## B. Device not reporting telemetry
- Confirm the device is enrolled and checking in (Intune → device → **last check-in**).
- Confirm diagnostic data is not forced below the required level by another policy; run
  `EHEM-Validation.ps1`.
- Confirm the device can reach the Microsoft telemetry/Intune endpoints through the proxy/firewall
  (Requirement 2.6).

## C. Startup / resource scores look wrong or volatile
- Low device counts produce volatile averages — wait for more data and judge the **trend**.
- A single bad model can skew the fleet score; use the **model** breakdown to isolate it rather than
  reacting to the overall number.

## D. Proactive remediation not running or not fixing
| Symptom | Cause | Remediation |
|---|---|---|
| Package shows no run history | Not assigned, or device not synced | Confirm assignment to the scope group; run `EHEM-Remediation.ps1` (sync); check schedule |
| Detection runs, remediation skipped | Detection script exit code not signalling "issue found" | Detection must exit non-zero (or per package contract) to trigger remediation; re-test the script |
| Remediation blocked | Signature check on, script unsigned | Sign the script or adjust the package's signature-check setting per policy |

## E. Optional DEX platform issues
- Endpoint analytics is the supported core here. For a dedicated DEX platform (Nexthink, Tanium,
  etc.), collector/console problems are **vendor-specific** — use the vendor's documentation and
  support. Confirm only that the platform is licensed and its collector reaches its own service.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion
Get-CimInstance Win32_OperatingSystem | Select-Object LastBootUpTime   # restart age
dsregcmd /status                                                       # Entra join / MDM state
```
Force a management sync from the device, then re-check after a policy cycle:
```powershell
Start-Process "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
```

## G. When to escalate
If the device is enrolled, syncing, diagnostic data is permitted, the network reaches the service,
and the device still does not appear in Endpoint analytics after the baseline period, collect
`dsregcmd /status` output and the device's last check-in time and open a Microsoft support case. For
dedicated DEX platform problems, escalate to that vendor.
