# 6. Troubleshooting Guide — Universal Print Deployment & Print-Server Retirement

Use `UPRT-Validation.ps1` / `UPRT-Discovery.ps1` for device and print-environment state,
`UPRT-Report.ps1` for deployment coverage, and `UPRT-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Printer not appearing on a device
| Symptom | Cause | Remediation |
|---|---|---|
| Deployed printer never shows up | Device not synced, or not in the target group | Sync the device; confirm membership of `UniversalPrint – Printers – Pilot`/`Broad`; run `UPRT-Remediation.ps1` |
| Some devices get it, others don't | Mixed group membership or stale assignment | Run `UPRT-Report.ps1` for coverage; reconcile group membership |
| Printer added manually but not via Intune | Printer shared but no Intune printer deployment | Create the Universal Print printer deployment and assign the group (Implementation Step 6) |

## B. Print jobs fail or hang
| Symptom | Cause | Remediation |
|---|---|---|
| Jobs stuck "Sending" | Connector host offline/unreachable | Check `UniversalPrint – Connector – Site1` status in the portal; ensure the host is on and has outbound HTTPS |
| Works on LAN, fails off network | Connector host not reachable, or endpoint blocked off-site | Confirm the connector host stays reachable; allow Universal Print endpoints on the off-network path |
| Job errors immediately | Printer not Shared, or user lacks access | Confirm the printer is Shared; deploy via Intune group rather than per-user share |

## C. Connector problems
- Connector shows Offline: confirm the Windows service is running on the host, the host signed in with the Printer Administrator account, and outbound HTTPS to the service is open. Re-run `UPRT-Validation.ps1`.
- Printers missing from the connector: re-open the connector app and re-register the printers the host can see; large estates may need a second connector.

## D. Licensing / volume
- Printer registration blocked or jobs rejected: confirm Universal Print licensing is assigned and print-volume allotment is not exhausted (Microsoft 365 admin center → Billing → Licenses).

## E. Old queue and new printer both present (during coexistence)
- This is expected during coexistence. Once the printer's users are validated on Universal Print, remove the old shared queue (disable first) so users stop selecting the legacy path.

## F. Diagnostics quick reference
```powershell
Get-Printer | Select-Object Name, DriverName, PortName, Shared, Published
Get-PrintConfiguration -PrinterName "<name>"          # per-queue settings
Get-Service -Name "PrintWorkflowUserSvc*","Spooler"   # local print services
# Universal Print via Graph (uses Invoke-MgGraphRequest against /print endpoints):
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/printers" | Out-String
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares"   | Out-String
```

## G. When to escalate
If the printer is Registered + Shared, the connector is healthy, the device is synced and in the
correct group, endpoints are reachable on the failing network, and jobs still fail, collect the
connector logs and `UPRT-Validation.ps1` output and open a Microsoft support case for Universal Print.
