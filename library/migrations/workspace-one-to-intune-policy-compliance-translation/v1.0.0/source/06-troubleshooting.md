# 6. Troubleshooting Guide — Workspace ONE to Intune: Policy & Compliance Translation

Use `WS1POL-Discovery.ps1` for the source inventory, `WS1POL-Validation.ps1` for the parity check,
`WS1POL-Report.ps1` for per-device state, and `WS1POL-Remediation.ps1` (defaults to `-WhatIf`) for
conflicting assignments.

## A. Parity gate fails — settings reported missing

| Symptom | Cause | Remediation |
|---|---|---|
| Validation lists a source setting as missing | It was not mapped, or mapped on the wrong platform | Find the gap-register row; map it in the correct `Mapped Config - <Platform> - Pilot`, or record substitute/defer/accept-gap |
| A whole platform shows many missing | The platform's policy was not assigned to the pilot scope | Confirm assignment of `Policy Scope - Pilot - Stage`; re-run `WS1POL-Report.ps1` |
| Source export incomplete | Inventory captured only part of the source | Re-export per VMware/Omnissa documentation; re-run `WS1POL-Discovery.ps1` |

## B. Setting maps by name but posture differs

- A control mapped with a different effective value silently changes posture. Compare the effective
  value, not just the setting name, against the source; correct the value in the mapped policy and
  re-run `WS1POL-Validation.ps1`.

## C. Compliance policy does not gate access

| Symptom | Cause | Remediation |
|---|---|---|
| Noncompliant device still reaches resources | No Conditional Access policy requires a compliant device | Confirm with the identity owner that Conditional Access requires device compliance for these users/devices |
| Device shows compliant but should not | A translated rule is missing or weaker than the source | Compare the rule set in `Mapped Compliance - <Platform> - Pilot` to the source; tighten to match |

## D. Policy conflict on a device

- A setting reported in conflict means two policies set it differently. Run `WS1POL-Remediation.ps1`
  with `-WhatIf` to identify the conflicting assignment, then re-run without `-WhatIf` (with
  confirmation) to resolve it. Conflicts commonly come from a leftover Intune policy or two mapped
  policies overlapping — consolidate.

## E. Device not receiving the mapped policy

- Confirm the device is enrolled and a member of `Policy Scope - Pilot - Stage`; trigger a sync
  (device-side path differs per platform); then re-run `WS1POL-Report.ps1`. Coexistence note: until a
  platform clears parity, Workspace ONE policy may still be authoritative on the device — confirm
  which MDM the device is enrolled in.

## F. Source-side export issues (Workspace ONE)

- Export mechanics (console paths, the UEM REST API, payload format) are vendor-owned and
  version-specific. If the export is incomplete or malformed, consult the current VMware/Omnissa
  Workspace ONE UEM documentation — this solution defers all source-side mechanics there.

## G. When to escalate

If parity validation is clean, the policy is assigned, the device is synced and enrolled in Intune,
and a setting still does not apply or a compliance rule still does not gate, collect the
`WS1POL-Validation.ps1` and `WS1POL-Report.ps1` output and open a Microsoft support case for the
Intune side (or a VMware/Omnissa case for a source-export discrepancy).
