# 6. Troubleshooting Guide — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

Use `MACMDE-Discovery.ps1` for tenant/device readiness, `MACMDE-Validation.ps1` for a single device,
`MACMDE-Report.ps1` for fleet posture and drift, `MACMDE-Remediation.ps1` for safe reapply (default
`-WhatIf`), and `MACMDE-Set-ScopeTargeting.ps1` when widening scope during Expand. On the Mac itself,
the `mdatp` CLI is the definitive source of agent health.

## A. Onboarded in the portal but not actually protecting (the classic macOS failure)
| Symptom | Cause | Remediation |
|---|---|---|
| Portal shows the Mac onboarded, but `mdatp health` shows `real_time_protection_enabled : false` or `healthy : false` | The capability profiles were not applied **before** onboarding (extensions never approved) | Confirm all five profiles Succeeded (`MDE macOS – System Extensions`, `– Full Disk Access`, `– Network Filter`, `– Background Services`, `– Notifications`); fix whichever is not applying, sync, then re-check `mdatp health` |
| `systemextensionsctl list` shows the Defender extensions not enabled / pending approval | System Extensions profile missing, wrong team identifier, or Mac not supervised | Correct the team identifier / bundle identifiers in `MDE macOS – System Extensions` (Requirement 2.6); on unsupervised Macs the user may need to approve once — prefer ADE/supervised |

## B. Full Disk Access not granted
| Symptom | Cause | Remediation |
|---|---|---|
| Defender shows a Full Disk Access warning, scans incomplete | PPPC profile missing, wrong bundle identifier, or wrong code requirement string | Correct `MDE macOS – Full Disk Access` (SystemPolicyAllFiles = Allow, correct bundle id + code requirement, Requirement 2.6); confirm **System Settings → Privacy & Security → Full Disk Access** shows Defender granted |

## C. Network protection / web filtering inert
| Symptom | Cause | Remediation |
|---|---|---|
| Network protection not working; content filter absent under Network/Device Management | Network filter profile missing or names the wrong network-extension identifier | Correct `MDE macOS – Network Filter` with the Microsoft Defender network extension identifier; confirm the content filter is attached on the Mac |

## D. Agent installed but never onboards / stays inactive in the portal
| Symptom | Cause | Remediation |
|---|---|---|
| App installed, `mdatp health` shows onboarded false | `MDE macOS – Onboarding` not assigned/applied, or wrong onboarding package (different tenant) | Confirm the onboarding profile Succeeded and uses the package downloaded from **this** tenant's Defender portal (Requirement 2.5); re-download if unsure |
| Onboarded but stays **Inactive** in the portal | Blocked network egress to MDE service endpoints | Run `mdatp connectivity test`; allow the Microsoft Defender service URLs through the proxy/firewall (Requirement 2.8) |

## E. User prompts appearing (should have been silent)
- Prompts for extension approval, Full Disk Access, or network filter mean the corresponding profile did not apply before the app. Confirm the profile Succeeded and, on unsupervised Macs, expect one-time approval; re-enroll via ADE for fully silent approval.

## F. App will not install
| Symptom | Cause | Remediation |
|---|---|---|
| `MDE macOS – Defender App` shows failed install | Not enrolled/synced, or packaging/type issue | Confirm enrollment (`MACMDE-Discovery.ps1`) and group membership; force a sync; if using a packaged PKG/DMG, confirm the app type and signing |

## G. Ordering mistake (onboarding pushed first)
- If Macs were onboarded before the capability profiles, they are likely degraded. **Roll back onboarding** (unassign `MDE macOS – Onboarding`), ensure the five capability profiles Succeed, then reassign onboarding. Do not try to "fix forward" a degraded agent by re-onboarding on top of missing approvals.

## H. Graph scripts fail to connect
- The scripts need Microsoft Graph PowerShell and read scopes such as `DeviceManagementConfiguration.Read.All`, `DeviceManagementApps.Read.All`, `DeviceManagementManagedDevices.Read.All`; consent them on first `Connect-MgGraph`.
- If module load fails, run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## I. Diagnostics quick reference
```powershell
Get-MgContext   # confirm Graph scopes
```
On the Mac (Terminal — the definitive agent state):
```bash
mdatp health                 # healthy, real_time_protection_enabled, licensed, onboarded
systemextensionsctl list     # Defender endpoint-security + network extensions enabled?
mdatp connectivity test      # reach the MDE cloud?
profiles list                # installed configuration profiles (the five + onboarding)
```
Intune-side: device → **Device configuration** shows each profile's apply status; **Apps** shows app
install state; the onboarding **custom profile** shows Succeeded/Error.

## J. When to escalate
If all five capability profiles show Succeeded, the app is Installed, `MDE macOS – Onboarding` is
Succeeded, `mdatp connectivity test` passes, and the agent still reports unhealthy, capture
`mdatp health`, `systemextensionsctl list`, `profiles list`, and the Intune device-status pages and
open a Microsoft support case.
