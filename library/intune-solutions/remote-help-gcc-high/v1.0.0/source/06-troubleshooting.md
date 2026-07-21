# 6. Troubleshooting Guide — Remote Help — Government (GCC High) Edition

Use `RHELPG-Discovery.ps1` for tenant/feature/RBAC state, `RHELPG-Test-Endpoints.ps1` for the cloud
plane, `RHELPG-Validate.ps1` for PASS/FAIL, `RHELPG-Report.ps1` for an export, and
`RHELPG-Set-RoleScope.ps1` (default `-WhatIf`) to assign RBAC. All sovereign specifics are **verify
against current Microsoft documentation**.

## A. Feature unavailable in the sovereign cloud (GCC High / DoD — check first)
| Symptom | Cause | Remediation |
|---|---|---|
| No Remote Help blade in the `*.us` Intune portal | Remote Help is **not offered on GCC High / DoD** (planned, no ETA) | **Expected.** Do not try to force it. Use the compliant alternative (`gcc-high-parity-notes.md` §4). Re-verify availability against current Microsoft documentation and monitor the roadmap |
| `RHELPG-Discovery.ps1` reports Remote Help "not present" on GCC High/DoD | Same — feature absent on the tier | This is the correct discovery result, not a fault. Follow Path B |
| `RHELPG-Set-RoleScope.ps1` can't find a Remote Help role | Remote Help RBAC permissions not present in the sovereign tenant | Expected on GCC High/DoD; use the alternative. On GCC, confirm you're on the commercial plane |
| A stakeholder expects "Remote Help for GCC High" | Assumed commercial parity | Show them the availability finding (`gcc-high-parity-notes.md` §0); it is planned, not available. Adopt when it ships |

## B. Wrong / commercial endpoints (plane mismatch)
| Symptom | Cause | Remediation |
|---|---|---|
| GCC High/DoD account not recognized; portal shows `.com` | Signed in to a Commercial portal | Use the sovereign portals: `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, `portal.office365.us`, `security.microsoft.us` |
| Script auth fails / targets the wrong tenant | `Connect-MgGraph` defaulted to Commercial Graph | Pass **`-Environment USGov`** (GCC High) or **`USGovDoD`** (DoD); confirm with `RHELPG-Test-Endpoints.ps1` |
| You're on `*.us` but the GCC tenant isn't found | **GCC is the commercial Intune instance** | For a GCC tenant use the **commercial** portals and `-Environment Global` — GCC does **not** use `*.us` |
| A blade/menu is missing | Commercial-only or not-yet-in-sovereign feature | Check `gcc-high-parity-notes.md`; verify against current Microsoft documentation |

## C. Licensing mismatch (where Remote Help is available)
| Symptom | Cause | Remediation |
|---|---|---|
| "Enable" greyed out / helper can't start | No Remote Help license, or only one party licensed | Assign the **Remote Help add-on** (or Intune Suite) to **both** helpers **and** sharers; confirm the **government SKU** is offered for your tier (verify against current Microsoft documentation) |
| License present but feature off | Tenant not refreshed | Wait/refresh; re-open **Tenant administration → Remote Help** |

## D. Consent / RBAC differences
| Symptom | Cause | Remediation |
|---|---|---|
| Helper can't **Give help** | Missing Remote Help permissions | Assign **Help Desk Operator** (or a custom role with *Offer remote assistance* + *Remote Assistance Connector — Read* + a Remote Help permission); `RHELPG-Set-RoleScope.ps1` |
| Helper can't see the sharer's device | Sharer not in the helper's **scope**; used *All Devices* scope | Scope to a **user** group — *All Devices* excludes unenrolled devices |
| Helper can view but not control | View-only role, or full control disabled tenant-wide | Grant full control by role, and enable it in **Tenant administration → Remote Help** |
| No on-screen consent indicator expected | Unattended (Android dedicated) or a misconfiguration | Attended sessions require consent + show an indicator; unattended is Android-dedicated only, used sparingly |
| Conditional Access for helpers not applying | CA for Remote Help is **Windows/macOS only** | Verify against current Microsoft documentation; scope the helper CA policy to those platforms |

## E. Session won't connect (where available)
| Symptom | Cause | Remediation |
|---|---|---|
| Connection fails | Network/endpoints blocked, or SSL inspection | Allow the Remote Help service URLs (port 443, TLS 1.2) and **exclude them from SSL inspection**; confirm the endpoint list for your tier (verify against current Microsoft documentation) |
| Cross-tenant help fails | All participants must be in the **same tenant** | Provide in-tenant devices (or Windows 365/AVD joined to the tenant) to outsourced helpdesk |
| AVD session unsupported | Remote Help is **not** supported in AVD (GCC) | Exclude AVD hosts; use it on supported Windows/Windows 365/macOS/Android-dedicated only |

## F. Scripts
```powershell
# Confirm the cloud plane for your tier
.\RHELPG-Test-Endpoints.ps1 -Environment USGov      # GCC High  (USGovDoD = DoD; Global = GCC/Commercial)
# Read-only posture: cloud context, Remote Help presence, RBAC
.\RHELPG-Discovery.ps1 -Environment USGov
# PASS/FAIL readiness (NOT-AVAILABLE is the expected Remote Help result on GCC High/DoD)
.\RHELPG-Validate.ps1 -Environment USGov
# Export status to CSV
.\RHELPG-Report.ps1 -Environment USGov -CsvPath C:\Temp\rhelpg-status.csv
# Assign RBAC role/scope (state change — defaults to -WhatIf; add -WhatIf:$false to apply)
.\RHELPG-Set-RoleScope.ps1 -MembersGroupName "RemoteHelp - GCCH - Pilot" -ScopeGroupName "RemoteHelp - GCCH - Pilot"
```
> All five scripts default to the sovereign plane (`-Environment USGov`; use `USGovDoD` for DoD, or
> `Global` for a GCC/commercial-instance tenant). None require you to edit angle-bracket placeholders.

## G. When to escalate
On a tier where Remote Help **is** available: if licensing is assigned to both parties, Remote Help is
enabled, the app is installed, RBAC and scope are correct, and sessions still fail, capture the app
version and a session error and open a Microsoft Intune support case — **note the government tenant tier
(GCC / GCC High / DoD)** so it routes to the correct support queue. On GCC High / DoD where the feature
is **absent**, there is nothing to escalate as a bug — track the roadmap and use the compliant
alternative. **Re-verify availability against current Microsoft documentation.**
