# 6. Troubleshooting Guide — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

This is the formal troubleshooting section for the **toolkit and its tooling** — what to do when the
diagnostic process itself misbehaves (Graph sign-in fails, a device isn't found, an on-Mac command is
denied, escrow reads empty). For diagnosing the *Mac failure* itself, follow the Diagnostic Playbook
(§3) and its five branches.

## A. Microsoft Graph sign-in / scope errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or module missing | `Microsoft.Graph.Authentication` not installed | `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`, then retry |
| `Authorization_RequestDenied` on a read | The consented scopes don't include the one the check needs | Reconnect with the read scopes in §2.2; an admin may need to consent |
| Remediation/Targeting write is refused | Missing write scope | Reconnect adding `DeviceManagementManagedDevices.PrivilegedOperations.All` (Sync) or `Group.ReadWrite.All`/`GroupMember.ReadWrite.All` (targeting) |
| Wrong tenant | Cached context points elsewhere | `Disconnect-MgGraph`, then reconnect with `-TenantId your-tenant-id` |

## B. Device not found by the scripts
- The scripts match macOS managed devices by **device name or serial** (substring). If nothing
  matches, confirm the device is enrolled (Intune → **Devices → macOS**) and try the **serial** — a
  freshly enrolled Mac may not have its friendly name yet.
- If `MACDX-Discovery.ps1` lists the device but `-DeviceName` in another script misses it, use a more
  specific substring (the full serial) so it isn't ambiguous.

## C. On-Mac commands are denied or "command not found"
| Symptom | Cause | Remediation |
|---|---|---|
| `sysadminctl`/`fdesetup` "not permitted" | Not running as an admin, or SecureToken-holder needed | Run in Terminal as a local admin; SecureToken grants need a SecureToken-holding admin's credentials |
| `app-sso platform -s` returns nothing | Platform SSO not configured / older macOS | Confirm the SSO method is Platform SSO and macOS supports it (§2.8); for Extensible SSO check **System Settings → Profiles** instead |
| `profiles status -type bootstraptoken` "not escrowed" | Bootstrap Token was never escrowed | `sudo profiles install -type bootstraptoken` or re-enroll (Playbook Branch C) |

## D. Profile shows Error/Conflict in Intune but you can't tell why
- Two profiles setting the **same** payload differently produce a **Conflict** — find the second
  profile targeting the device and reconcile them; the Mac's group membership tells you which
  profiles apply (`MACDX-Set-ScopeTargeting.ps1` preview shows current membership).
- For an **Error**, read the Mac's MDM log: `log show --predicate 'subsystem == "com.apple.ManagedClient"' --last 1h`
  or Console.app for the `mdmclient`/`profiles` entry that names the failing payload.

## E. Recovery keys / escrow reads empty
- Intune → device → **Recovery keys** blank while `fdesetup status` shows FileVault On → the
  **personal recovery key** wasn't escrowed. Rotate/re-escrow via the FileVault (Disk encryption)
  policy; the key appears after the next check-in.
- `MACDX-Report.ps1` escrow coverage shows 0 → confirm the FileVault policy is assigned and the
  reading account has `DeviceManagementConfiguration.Read.All` / `DeviceManagementManagedDevices.Read.All`.

## F. "Compliant but denied" doesn't resolve
- If Intune shows Compliant but Entra keeps denying, the block is a **Conditional Access** decision,
  not an Intune one — read the CA tab in the **Sign-in log**, not the compliance blade. The named
  policy + grant control is the actual cause (Playbook Branch D).
- A browser that doesn't use the SSO extension can present as a different/unknown device to CA even
  though the OS is compliant — confirm the SSO extension is delivering device state (Branch B).

## G. Remediation / targeting "made no change"
- Both `MACDX-Remediation.ps1` and `MACDX-Set-ScopeTargeting.ps1` default to **`-WhatIf`** — that is
  by design. They only act when you re-run with **`-WhatIf:$false`**. The `[PREVIEW MODE]` banner tells
  you no change was made.
- A Sync issued but nothing changed on the Mac → allow a few minutes for the device to check in, then
  re-run `MACDX-Validation.ps1` for that layer.

## H. Diagnostics quick reference
```powershell
# Confirm the Graph context and scopes the scripts will use
Get-MgContext | Select-Object Account, TenantId, Scopes

# List macOS managed devices (read-only), newest check-in first
Invoke-MgGraphRequest -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'" |
  Select-Object -ExpandProperty value |
  Select-Object deviceName, serialNumber, complianceState, osVersion, lastSyncDateTime |
  Sort-Object lastSyncDateTime -Descending | Select-Object -First 20
```
```bash
# On the affected Mac (Terminal, as admin) — the four layer signals
sudo profiles status -type enrollment          # ADE / enrollment (Branch A)
app-sso platform -s                            # Platform SSO registration (Branch B)
sysadminctl -secureTokenStatus theusername     # SecureToken holder (Branch C)
sudo profiles status -type bootstraptoken      # Bootstrap Token escrow (Branch C)
fdesetup status                                # FileVault On/Off (Branch C)
```

## I. When to escalate
If the layer signal is read correctly, the branch fix is applied, and the symptom persists, collect:
the Company Portal **diagnostic report**, the Mac's MDM log
(`log collect --last 2h` / Console.app), the Intune device page, and the Entra **Sign-in log** for
the failed CA case. Open a Microsoft support case with the symptom class, the failing layer, and the
exact signal you captured — and, for an Apple-side ADE assignment issue, engage Apple/ABM support with
the serial and the assigned MDM server.
