# 6. Troubleshooting Guide — Application Control (WDAC)

Use **`WDAC-Validation.ps1`** / **`WDAC-Discovery.ps1`** for policy state and
**`WDAC-AuditReport.ps1`** for events, **`WDAC-Remediation.ps1`** for recovery.

## A. Legitimate app blocked (enforced)
| Symptom | Cause | Remediation |
|---|---|---|
| A required app won't run after Enforce | It isn't trusted (not Intune-deployed, not ISG-reputable, unsigned) | Identify via `WDAC-AuditReport.ps1`; deploy it via Intune (managed installer), or add a supplemental/custom rule; if urgent, unassign the policy to recover |
| Whole app category blocked | Trust model too narrow | Enable **ISG** and **managed installer** trust; re-audit before re-enforcing |

## B. Recovery from an over-strict policy
1. **Unassign** the App Control policy from the device group in Intune.
2. Run **`WDAC-Remediation.ps1`** to clear/refresh the local policy and force a sync.
3. The device returns to its prior state; return the policy to **Audit**, fix trust, then re-enforce.
> WDAC policies persist until replaced/removed and may require a reboot to fully clear.

## C. Policy not applying
| Symptom | Cause | Remediation |
|---|---|---|
| No policy active on device | Not synced / not enrolled / unsupported OS | `WDAC-Remediation.ps1` (sync); confirm Windows 1903+/11 and group membership |
| Audit shows nothing | Users didn't run untrusted code, or wrong log | Run a benign unsigned test EXE; check the Code Integrity Operational log |

## D. Too many audit events
- Expected initially — every not-yet-trusted app logs. Triage by publisher/path with `WDAC-AuditReport.ps1`; move the common legitimate ones to managed-installer deployment first.

## E. Diagnostics quick reference
```powershell
# active policies (Windows 11):
citool.exe --list-policies
# Device Guard / code integrity status:
Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard | Select CodeIntegrityPolicyEnforcementStatus
# Code Integrity events: 3076 (audit block), 3077 (enforced block), 3099 (policy loaded)
Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' | Where-Object Id -in 3076,3077,3099
```

## F. When to escalate
If a signed, Intune-deployed app is still blocked under Enforce with managed-installer trust enabled,
capture the 3077 event detail (file path, signing info) and open a Microsoft support case.
