# 1. Solution Overview — Intune Device Configuration & Policy Troubleshooting

## The problem this solves
A configuration profile or settings-catalog policy shows **Assigned** in Intune, yet the setting
never reaches the device — and the admin is left re-pushing blindly, hoping something changes. This
toolkit replaces guessing with a **structured root-cause method**: you follow the policy along the
same path it actually travels, isolate the one layer where it breaks, and apply the typical fix for
that layer.

## How a policy travels: assignment → scope → sync → CSP apply → report
Every Intune device-configuration or settings-catalog policy must pass through **five layers** to
take effect. If any layer fails, the setting never lands — so diagnosis means walking the layers in
order and finding the first one that fails.

1. **Assignment (targeting).** The policy is assigned to one or more **Entra security groups**
   (Included / Excluded). If the device (or its user) isn't in an *Included* group — or is in an
   *Excluded* group — the policy is never sent. **Device-context** policies target **device** groups;
   **user-context** policies target **user** groups. Mixing these up is a top cause of "assigned but
   nothing happens."
2. **Scope (groups + filters).** Even when a group matches, an **assignment filter** can *include*
   or *exclude* the device based on device properties (OS, model, ownership, enrollment). A filter
   in **Exclude** mode that unexpectedly matches the device silently removes it from scope.
3. **Sync (MDM check-in).** The device must **check in** with the Intune service to receive the
   policy. Devices sync on a schedule (roughly every 8 hours, sooner after enrollment) or on demand.
   A device that hasn't synced — or is offline, or whose MDM enrollment is unhealthy — won't have
   the policy yet, no matter how correct the assignment is.
4. **CSP apply.** Intune delivers each setting to the Windows **Configuration Service Provider (CSP)**
   over the MDM channel. The CSP writes the setting and returns a **status / error code**. If a value
   is unsupported on that OS build, conflicts with another policy, or the CSP rejects it, the setting
   fails here even though it was delivered — visible as a per-setting **error code** (e.g. `0x87d1fde8`).
5. **Report.** The device reports success/error back to Intune, surfaced under the policy's
   **Device status** / **Per-setting status**. This is the mirror of layers 1–4: reading it tells you
   *which* layer failed, so you rarely need to guess.

## The layered model behind the root-cause tree
The **Diagnostic Playbook** (document 3) is built directly on those five layers. Each symptom an
admin sees maps to the layer that produces it:

| Symptom the admin sees | Failing layer | What to check |
|---|---|---|
| Policy shows no assigned devices / device not listed | **Assignment** | Group membership, Include vs Exclude, device vs user context |
| Assigned, device listed, but setting absent | **Scope (filter)** or **Sync** | Filter evaluation; last check-in time |
| Two policies fight; setting flips or shows "conflict" | **CSP apply (conflict/precedence)** | Duplicate settings across policies |
| "Error" on one setting with a code | **CSP apply** | Per-setting status + error code meaning |
| Device never checks in / stale status | **Sync** | MDM enrollment health, network, sync trigger |

Because the layers are **ordered**, you always diagnose from the top down: confirm assignment
before blaming sync, confirm sync before blaming the CSP. That ordering is what turns a vague "it
isn't working" into a single isolated cause.

## What "conflict and precedence" means
When **two or more** assigned policies set the **same** setting to **different** values, Intune
reports a **conflict** and the setting's effective value is **undefined/last-writer** rather than
what you intended. There is no simple "priority number" for configuration profiles — the reliable
fix is **conflict-free design**: each setting is owned by exactly one policy. The toolkit's report
script surfaces overlapping settings so you can eliminate the conflict at the source.

## What you get
- A plain-language model of the five layers (this document).
- A **Requirements Guide** for what you need to diagnose (roles, Graph read access, device log access).
- A **Diagnostic Playbook** — the symptom-driven decision tree with exact checks per branch.
- **Five PowerShell scripts**: discovery, per-device validation, assignment + conflict coverage
  report, safe re-sync/remediation, and a pilot target-group builder.
- **Testing** and **Troubleshooting** guides plus **Best Practices** for naming, filters, and
  conflict-free policy design.

## The repeatable method
> **Trace the policy along its five layers → isolate the first failing layer → apply that layer's
> typical fix → re-check the report.** The repeatable pattern behind every branch:
> **Assess → Configure → Pilot → Validate → Expand.**
