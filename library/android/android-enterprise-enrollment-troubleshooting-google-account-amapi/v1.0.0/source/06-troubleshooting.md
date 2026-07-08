# 6. Troubleshooting Guide — the tools and the tree itself

The Diagnostic Playbook (Section 3) troubleshoots your **tenant's** enrollment failures. This guide
troubleshoots **running the solution** — the PowerShell tools, the Graph connection, and the reproduction
workflow — so the diagnostic session itself doesn't stall.

## Connecting and permissions
| Symptom | Likely cause | Fix |
|---|---|---|
| `Connect-MgGraph` fails or prompts endlessly | SDK not installed, or admin consent missing for the scopes | Install the Microsoft Graph PowerShell SDK; have an admin consent the read scopes (`DeviceManagementServiceConfig.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`) |
| `403 / Authorization_RequestDenied` on a read | Missing one of the read scopes | Reconnect with all three read scopes; confirm the signing-in account holds the Intune-read role |
| Scope helper can't write group membership | Missing `Group.ReadWrite.All` / `User.Read.All` | Connect the scope helper with those scopes; run `-WhatIf` first to preview |

## Binding-health tool (`ANDROIDDX-BindingHealth.ps1`)
| Symptom | Likely cause | Fix |
|---|---|---|
| `404` reading the binding settings | The managed Google Play connection has **never** been created | This solution troubleshoots an existing binding — stand it up with the connection solution first, then return |
| Properties show as blank/null | Beta resource shape differs in your tenant, or binding partially consented | **Verify property names against current Microsoft Graph documentation**; re-check the connection consent in Intune |
| `bindStatus` empty but Intune shows connected | Transient read, or model mismatch | Re-run; confirm the binding model (account-enterprise vs Workspace) in Intune > Devices > Android > Android enterprise |

## Readiness / diagnostic-report tools
| Symptom | Likely cause | Fix |
|---|---|---|
| WARN on "Android enrollment restriction" but Android does enroll | The tool reads the presence of a platform-restriction policy, not its per-platform detail | Confirm in Intune > Devices > Enrollment > Enrollment restrictions that Android Enterprise is not `Blocked`; treat WARN as "go verify," not "broken" |
| "Recent Android enrollments = 0" but devices exist | No enrollments **in the window**, or older than `-Days` | Increase `-Days`; zero recent enrollments when you expect them is itself a symptom, not a tool error |
| `androidDeviceOwnerEnrollmentProfiles` empty | Tenant uses only BYOD work profile (no device-owner path) | Expected — device-owner profiles are only needed for fully managed / dedicated / corp-owned work profile |
| Diagnostic report lists causes that don't apply | Mapping is **heuristic guidance**, not an assertion | Use it to prioritize the tree; confirm each candidate against your tenant and current Microsoft guidance |

## Endpoint-reachability / config-diff tool
| Symptom | Likely cause | Fix |
|---|---|---|
| Endpoint shows `Blocked` from an admin PC but device enrolls fine | You tested from the wrong network segment | Run the tool **from the device's own network/Wi-Fi** — egress rules differ by VLAN |
| Everything `Reachable` but account add still fails | TLS/SSL **interception** on Google hosts (host is reachable, TLS is broken) | Exempt `accounts.google.com` / `*.googleapis.com` / `play.google.com` from TLS inspection |
| Reachable list looks incomplete for my region | The shipped list is a documented **core** set, not exhaustive | Cross-check and extend against the **current** Microsoft (Intune network endpoints) and Google (Android Enterprise network requirements) published lists |
| `-CompareConfig` shows "no differences" but prod still fails | The failure is outside captured config (endpoints, account model, device state, CA) | Move to Playbook D (endpoints), F (account model), or check Conditional Access |

## Reproduction workflow
| Symptom | Likely cause | Fix |
|---|---|---|
| Fix "works" then fails on the next device | You changed more than one variable, or the device wasn't fully reset | Reset the test device fully; change **one** variable; re-run the reproduction each time |
| Device-owner enrollment won't start | Device not factory-reset, or expired QR/token | Factory-reset the device; regenerate the QR/token (Playbook C) |
| Can't add a "personal" Google account in the work profile | **Expected** — the work-profile account is a **managed** account added by the profile | Use the managed account flow; document this for the service desk (Playbook F) |
| Post-AMAPI device won't enroll | Change may require re-enrollment; old token stale | **Verify the re-enrollment requirement against current Microsoft guidance / your tenant**; re-enroll on the test device; redistribute fresh tokens (Playbook E) |

## When to escalate
- **Binding cannot be re-established / re-consented** even by a Global Admin, or `bindStatus` stays in error
  after a documented repair → open a Microsoft support case; capture `Binding Health – Android – Baseline`.
- **Post-AMAPI behavior contradicts the current documentation** for your tenant → escalate to Microsoft
  support with your `Diagnostic Report – Android – AfterAmapiMigration` and the change record.
- **An endpoint block is a security-policy decision** (TLS inspection required) → escalate to the network/
  security owner with `Endpoint Allowlist – Android – Verified` to agree an exemption.
- **Non-GMS / OEM-specific device behavior** (China-market hardware, rugged/kiosk quirks) → defer to the OEM's
  documentation; this solution covers those at the pattern level only.

> Keep every finding as its named artifact so an escalation arrives with evidence, not a description — and so
> the next engineer inherits the trail.
