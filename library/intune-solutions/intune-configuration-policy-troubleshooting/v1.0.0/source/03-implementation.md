# 3. Diagnostic Playbook — Intune Device Configuration & Policy Troubleshooting

This is the core of the toolkit: a **symptom-driven decision tree**. Start at **Step 0**, pick the
branch that matches what you see, and follow it. Each branch names the **layer it isolates**, the
**exact checks**, and the **typical fix**. Work **top-down** — confirm assignment before sync, sync
before CSP — because the layers are ordered (see document 1).

All console paths are in the **Microsoft Intune admin center** (`https://intune.microsoft.com`)
unless stated. Use the exact object names from document 2 (`INTCFG-Pilot-Devices`,
`INTCFG-Pilot-Users`, `INTCFG-Filter-Windows-Corporate`).

---

## Step 0 — Read the report first (always start here)
1. Go to **Devices → Configuration** (for settings-catalog/config profiles) → open the affected
   **policy** → **Device status** (and **Per-setting status**).
   *(For endpoint-security policies: **Endpoint security → [the area] →** policy → **Device status**.)*
2. Note the device's line:
   - **Not applicable / device absent** → the policy never targeted it → go to **Branch A (Not assigned)**.
   - **Pending** for a long time, or "last check-in" is old → go to **Branch E (Stuck sync)**.
   - **Error** with a per-setting **code** → go to **Branch F (CSP error code)**.
   - **Conflict** → go to **Branch C (Conflict / precedence)**.
   - **Succeeded** in Intune but the setting is wrong on the device → go to **Branch B (Assigned, not applied)**.
3. For the tenant-wide picture, run **`INTCFG-Discovery.ps1`** (policies + assignments + filters) and
   **`INTCFG-Report.ps1`** (assignment + conflict coverage) — these show in seconds what the console
   shows one policy at a time.

---

## Branch A — "Not assigned" (device never targeted)
**Isolates:** the **Assignment** layer.

**Checks (in order):**
1. **Is the device (or its user) in an Included group?** Policy → **Properties → Assignments**. Note
   each **Included** and **Excluded** group. Run **`INTCFG-Discovery.ps1`** to list assignments per
   policy including group IDs.
2. **Confirm membership.** Entra → **Groups →** the Included group → **Members**. For dynamic groups,
   confirm the device/user actually matches the membership rule (dynamic evaluation can lag).
3. **Context mismatch (very common):** Is this a **device-context** setting assigned to a **user**
   group (or vice-versa)? A device-scoped configuration assigned only to a user group won't apply in
   device context. Check whether the policy/setting is user- or device-scoped.
4. **Excluded wins:** Is the device in **any Excluded** group? **Exclude always beats Include.**

**Typical fix:** Add the device/user to the correct **Included** group (or fix the dynamic rule);
remove an unintended **Exclude**; re-assign to a **device** group for device-context settings. Use
**`INTCFG-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to build/populate `INTCFG-Pilot-Devices`
cleanly, then assign the policy to it. Re-check **Device status** after the next sync.

---

## Branch B — "Assigned but not applied" (targeted, setting still absent)
**Isolates:** narrows to **Scope (filter)**, **Sync**, or **CSP apply** — resolve in that order.

**Checks (in order):**
1. **Filter?** Policy → **Assignments →** the assignment row → is a **filter** attached, and is its
   mode **Include** or **Exclude**? If a filter is present, jump to **Branch D** to evaluate it, then
   return.
2. **Has the device actually synced since assignment?** Intune → **Devices → All devices →** device →
   check **Last check-in**. Or run **`INTCFG-Validation.ps1`** on the device. If it hasn't checked in
   since you assigned the policy, jump to **Branch E**, then return.
3. **Did the setting reach the CSP?** Policy → **Per-setting status** for that device. If the setting
   shows **Error** with a code, go to **Branch F**. If it shows **Succeeded** but the observed value
   on the device is still wrong, suspect a **conflict** — go to **Branch C**.
4. **Applicability:** Confirm the setting/CSP is **supported on that OS edition/build** (e.g. some
   settings are Enterprise/Education only). An unsupported setting reports **Not applicable**, not an
   error.

**Typical fix:** Remove/correct an excluding filter (Branch D); force a check-in (Branch E); resolve
a conflict (Branch C) or decode the error (Branch F); or accept **Not applicable** and target a
supported edition.

---

## Branch C — Conflict / precedence (setting flips or reports "conflict")
**Isolates:** the **CSP apply** layer — two policies set the **same** setting differently.

**Checks:**
1. Policy → **Per-setting status** → the setting shows **Conflict**, or the effective value on the
   device doesn't match any single policy.
2. Run **`INTCFG-Report.ps1`** — it lists settings that appear in **more than one** assigned policy
   (overlap = conflict risk) and which groups each targets.
3. Identify **every** assigned policy that contains that setting. Remember: for configuration
   profiles there is **no reliable priority order** — a conflicting setting becomes
   **undefined/last-writer**, not "the strictest wins."

**Typical fix (conflict-free design):** Make **exactly one** policy own the setting. Remove the
duplicate setting from all other assigned policies (or scope them to non-overlapping groups). Re-run
**`INTCFG-Report.ps1`** until the overlap is gone, then re-check **Per-setting status**.

---

## Branch D — Filter excludes the device
**Isolates:** the **Scope (filter)** layer.

**Checks:**
1. Policy → **Assignments →** the assignment row → open the attached **filter** and note its **rule**
   and **mode** (Include/Exclude).
2. **Evaluate the rule against the device.** Devices → **Filters →** the filter → **Preview devices**
   (Evaluate) — does your affected device appear in the matched set?
   - Filter mode **Include**, device **not** matched → device is filtered *out* (excluded).
   - Filter mode **Exclude**, device **is** matched → device is filtered *out*.
3. Check the rule properties used (e.g. `operatingSystemSKU`, `deviceOwnership`, `model`,
   `enrollmentProfileName`) against the device's actual properties in **Devices → All devices →**
   device → **Hardware**. A common trap: an ownership/OS value that doesn't match what you assumed.
4. Run **`INTCFG-Discovery.ps1`** to list which filter is bound to which assignment and its mode.

**Typical fix:** Correct the filter rule so the intended devices match, or flip the mode, or detach
the filter for the pilot. Standardize on the named filter **`INTCFG-Filter-Windows-Corporate`** so
its rule is known and reused. Re-preview until the affected device is *in* scope, then re-sync.

---

## Branch E — Stuck sync / device not checking in
**Isolates:** the **Sync (MDM check-in)** layer.

**Checks:**
1. Intune → **Devices → All devices →** device → **Last check-in** time. If it's stale (many hours/
   days) the policy simply hasn't arrived yet.
2. Run **`INTCFG-Validation.ps1`** on the device — it reports MDM enrollment health and the last sync.
3. Confirm the device is **online** and can reach Microsoft endpoints (see global requirement G7).
4. Confirm MDM enrollment is healthy (not dual-enrolled/expired): the device shows as **managed by
   Intune / MDM** and not in an error state.

**Typical fix:** Force a check-in — on the device, **Settings → Accounts → Access work or school →
Info → Sync**, or run **`INTCFG-Remediation.ps1`** (default `-WhatIf`; re-run with `-WhatIf:$false`
to trigger the sync). If enrollment is unhealthy, repair enrollment. Re-check **Device status** after
the sync completes.

---

## Branch F — CSP error code on a setting
**Isolates:** the **CSP apply** layer — the setting was delivered but the CSP rejected it.

**Checks:**
1. Policy → **Per-setting status →** the failing setting → note the **error code** (e.g.
   `0x87d1fde8`, `0x87d101f4`).
2. Common meanings:
   - **`0x87d1fde8` (SyncML(500) / conflict or internal)** — frequently a **conflict** with another
     policy → route to **Branch C**.
   - **`0x87d101f4` (SyncML(404) / node not found)** — the CSP node/setting **isn't supported** on
     that OS build/edition → confirm applicability (Branch B, step 4).
   - **`0x82b00006` / generic "Remediation failed"** — the value is invalid for the setting or a
     prerequisite is missing.
3. Get the CSP detail from the **device's local MDM logs** (requirement 2.4): create the MDM report
   (**Access work or school → Info → Create report**) or run **`INTCFG-Validation.ps1`** to surface
   the CSP node + status.

**Typical fix:** For a conflict code, resolve via **Branch C**. For "not supported," target a
supported edition/build or drop the setting for that device set. For an invalid value, correct the
setting value in the owning policy and re-sync.

---

## Where each branch lands
| Branch | Symptom | Layer isolated | Primary script |
|---|---|---|---|
| A | Not assigned / device absent | Assignment | `INTCFG-Discovery.ps1` |
| B | Assigned, not applied | Scope / Sync / CSP | `INTCFG-Validation.ps1` |
| C | Conflict / value flips | CSP apply (conflict) | `INTCFG-Report.ps1` |
| D | Filter excludes device | Scope (filter) | `INTCFG-Discovery.ps1` |
| E | Stuck sync / stale check-in | Sync | `INTCFG-Remediation.ps1` |
| F | Per-setting error code | CSP apply | `INTCFG-Validation.ps1` |

> **The repeatable way:** read the report → pick the branch → isolate the layer → apply that layer's
> typical fix → re-check the report. Repeat until **Device status = Succeeded** with no conflict.
> Overall model: **Assess → Configure → Pilot → Validate → Expand.**
