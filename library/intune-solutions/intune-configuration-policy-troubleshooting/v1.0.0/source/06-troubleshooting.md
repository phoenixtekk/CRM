# 6. Troubleshooting Guide — Intune Device Configuration & Policy Troubleshooting

The **Diagnostic Playbook** (document 3) handles the common branches. This guide covers **deeper
edge cases** the tree doesn't fully resolve, plus when and how to **escalate**. Use
**`INTCFG-Discovery.ps1`** / **`INTCFG-Report.ps1`** for the tenant view, **`INTCFG-Validation.ps1`**
on the device, and **`INTCFG-Remediation.ps1`** to force a sync.

## A. Dynamic group membership lag
| Symptom | Cause | Remediation |
|---|---|---|
| Device is in a dynamic group by rule, but the policy still doesn't target it | Dynamic membership **evaluation lag** (can take minutes to hours after a property changes) | Confirm the device matches the rule in Entra → Groups → membership; wait for processing, or temporarily add it to `INTCFG-Pilot-Devices` (static) to unblock; verify with `INTCFG-Discovery.ps1` |
| Device dropped out of scope unexpectedly | A device property changed and no longer matches the dynamic rule | Compare device Hardware properties to the rule; fix the rule or the property source |

## B. User-context vs device-context mismatch
| Symptom | Cause | Remediation |
|---|---|---|
| Setting applies for some signed-in users but not at the device level (or vice-versa) | A user-scoped setting assigned to a **device** group, or a device-scoped setting assigned to a **user** group | Match assignment context to the setting: device settings → `INTCFG-Pilot-Devices`; user settings → `INTCFG-Pilot-Users`. Shared/multi-user devices amplify this — prefer device context there |

## C. "Succeeded" in Intune but wrong value on the device
- The report can show **Succeeded** while the effective value is wrong when a **conflict** exists
  (last-writer wins) or a **local GPO / third-party agent** overwrites the same setting after MDM
  applies it. Run **`INTCFG-Report.ps1`** to rule out a policy conflict first; if clean, check for an
  on-device GPO or agent touching the same registry/CSP node.

## D. Filter evaluates differently than expected
- Assignment filters evaluate against **device properties at check-in time**. A filter referencing a
  property that is blank or not yet populated (e.g. `enrollmentProfileName` on a freshly enrolled
  device) can silently exclude the device. Use the filter's **Preview/Evaluate** and compare to the
  device's actual **Hardware** properties; avoid volatile properties in filter rules.

## E. Settings-catalog vs template/ADMX behaviour
- The same outcome can be configured via a **settings-catalog** policy, a **template** profile, and
  an **ADMX-ingested** policy — and these can target the **same CSP node** from different surfaces,
  producing a conflict that `INTCFG-Report.ps1` may only partially surface (it compares
  settings-catalog policies). If a value fights and no catalog overlap shows, check for a template or
  administrative-templates policy setting the same thing.

## F. Sync succeeds but setting never appears
| Symptom | Cause | Remediation |
|---|---|---|
| Last check-in is recent, no error, setting still absent | Setting is **Not applicable** to that OS **edition/build** (e.g. Enterprise-only on Pro) | Confirm applicability; target a supported edition. Not applicable is expected, not a failure |
| Recent sync, setting absent, no report line at all | Policy not actually assigned to this device (only appeared to be) | Re-confirm with `INTCFG-Discovery.ps1`; fix the assignment (Branch A) |

## G. Diagnostics quick reference
```powershell
# On the device — confirm enrollment + last sync + CSP errors:
powershell -ExecutionPolicy Bypass -File .\INTCFG-Validation.ps1

# Force a check-in (default -WhatIf; add -WhatIf:$false to apply):
powershell -ExecutionPolicy Bypass -File .\INTCFG-Remediation.ps1 -WhatIf:$false

# MDM/CSP result events (error codes appear here):
Get-WinEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin' -MaxEvents 50 |
    Where-Object { $_.LevelDisplayName -in 'Error','Warning' }

# Common per-setting error codes:
#   0x87d1fde8  SyncML(500)  — conflict / internal (see Branch C)
#   0x87d101f4  SyncML(404)  — node not found / not supported on this OS build
#   0x82b00006  remediation failed — invalid value / missing prerequisite
```

## H. When to escalate
Open a Microsoft support case when: a setting reports **Succeeded** yet is verifiably wrong on the
device with **no** policy conflict and **no** on-device GPO/agent override; or a per-setting
**error code** persists after the device is correctly targeted, in scope, freshly synced, and the
setting is confirmed supported on that OS edition/build. Attach the device **MDM diagnostic report**
(**Access work or school → Info → Create report**), the failing **error code**, the policy/setting
name, and the outputs of **`INTCFG-Discovery.ps1`** and **`INTCFG-Report.ps1`** so the failing layer
is already documented.
