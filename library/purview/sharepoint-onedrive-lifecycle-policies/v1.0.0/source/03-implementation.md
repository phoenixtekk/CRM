# 3. Implementation Guide — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot → Validate → Expand**.
Every write is **piloted on `SPO Lifecycle – Pilot Scope – Stage1` first**, previewed with `-WhatIf`, and
**starts retain-only** — deletion is enabled deliberately only after validation. Named objects are
introduced once and reused everywhere:

| Object | Name |
|---|---|
| Retention policy | `SPO-OneDrive Retention – Policy` |
| Retain-only rule | `SPO-OneDrive – Retain-Only Rule` |
| Retain-then-delete rule | `SPO-OneDrive – Retain-Then-Delete Rule` (enabled after validation) |
| Pilot scope | `SPO Lifecycle – Pilot Scope – Stage1` |
| Schedule/design map | `Lifecycle Schedule – Map` |
| Coverage report | `Lifecycle – Coverage Report` |

> **The policy never deletes on its own until you enable it.** A retain-only rule keeps content and
> deletes nothing. Only a **retain-then-delete** or **delete-only** rule removes content — and only after
> its period elapses. This solution keeps the delete action **off through the pilot** and enables it as a
> deliberate, approved step. **Verify capability availability (e.g. adaptive scopes) against your
> licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (retention policies + rules)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** the connection succeeds and
`Get-RetentionCompliancePolicy` returns without error.

## Step 1 — Assess current state (Assess)
1. Run `DLCSPO-Discover.ps1`. Read-only, it reports every **retention policy and rule**, whether each
   covers **SharePoint** and/or **OneDrive**, the period/action of each rule, and any **adaptive scopes**.
2. Run `DLCSPO-Check-Prereqs.ps1` — module/connection, the retention/role signals, whether adaptive
   scopes are available, and existing policies — PASS/GAP per signal.
3. Record every GAP and remediate before configuring. **Pass/fail:** the inventory and prereq report
   complete; existing coverage and any overlap is captured in `Lifecycle Schedule – Map`.

## Step 2 — Design the lifecycle (Design)
1. With records/compliance, translate the **retention schedule** into concrete rules: period(s), and for
   each whether it is **retain-only**, **retain-then-delete**, or **delete-only** (the last two enabled
   after validation). Record every determination and its approver in `Lifecycle Schedule – Map`.
2. Choose the **scope** per rule — all locations, a **static scope** (named sites/accounts), or an
   **adaptive scope** (rule over properties). Define `SPO Lifecycle – Pilot Scope – Stage1`.
3. Confirm which capabilities your licensing supports (adaptive scopes E5); mark any unsupported approach
   **deferred** and fall back to static scoping.
   **Pass/fail:** `Lifecycle Schedule – Map` is agreed and signed off; the keep/delete determinations are
   owned by records/compliance, not IT.

## Step 3 — Create the policy in retain-only mode (Configure)
Do this **for the pilot scope first**, and **retain-only** — no deletion yet.

1. **Create the policy + retain-only rule.** Preview then commit:
   ```powershell
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -WhatIf
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -Commit
   ```
   This creates `SPO-OneDrive Retention – Policy` scoped to the pilot sites (and OneDrive where designed)
   with the **retain-only** rule — content is **retained**, nothing is deleted. Verify with
   `Get-RetentionCompliancePolicy` / `Get-RetentionComplianceRule`.
2. **Confirm scope in the portal.** Purview portal → **Data Lifecycle Management → Retention policies** →
   the policy → confirm the locations equal the pilot scope and the rule is retain-only.
   **Pass/fail:** the policy exists, covers exactly the pilot scope, retains for the intended period, and
   deletes nothing (no retain-then-delete/delete rule is enabled yet).

## Step 4 — Pilot on the limited scope (Pilot)
1. Let the policy apply to the pilot scope. Confirm that content in a pilot site **cannot be permanently
   removed** before its period — deleting a file routes a copy to the **Preservation Hold Library**.
2. Do **not** enable deletion yet. Observe retention behavior only.
   **Pass/fail:** retained content is held; a delete attempt on a pilot document is preserved (hold
   library) as expected; discrepancies are recorded for troubleshooting, not worked around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `DLCSPO-Validate.ps1`. Read-only, it confirms `SPO-OneDrive Retention – Policy` exists, covers the
   intended locations, the rule period matches design, and **no unintended delete action** is enabled —
   PASS/FAIL per gate.
2. Confirm the Preservation Hold Library behavior on a pilot site end-to-end.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `SPO Lifecycle – Pilot Scope – Stage1`.

## Step 6 — Enable cleanup and expand (Expand)
1. **Enable deletion deliberately** — only after retain-only is validated and stakeholders approve. Add
   the retain-then-delete behavior:
   ```powershell
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -WhatIf
   .\DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -Commit
   ```
   This sets the rule to **retain-then-delete** (keep for the period, then delete). Communicate the change
   first; deletion after the window is irreversible.
2. **Expand the scope** to all intended locations (or switch a static scope to the full set / an adaptive
   scope) once validated.
3. Run `DLCSPO-Report.ps1 -CsvPath .\LifecycleReport.csv` to produce `Lifecycle – Coverage Report` — each
   policy/rule, its locations, period, and action — as the management evidence artifact, and re-run it on
   a schedule.
   **Pass/fail:** the policy covers all intended locations; the intended action (retain / retain-then-
   delete) is enabled per approval; the report shows coverage as designed.

---
### Rollback
- **Disable / delete the policy** (`Set-RetentionCompliancePolicy ... -Enabled $false` or remove it) to
  stop enforcement — retention stops applying going forward. Content already in the Preservation Hold
  Library follows the documented release behavior.
- **Revert deletion** by returning the rule to **retain-only** before the delete window elapses; once
  content is deleted after the window, it is **not recoverable** — which is why deletion is enabled only
  after validation and approval.
- **Narrow the scope** back to the pilot to reduce blast radius. Keep `Lifecycle Schedule – Map` as the
  record of the intended state.

### Order of operations
`Assess policies + coverage → design schedule → rules + scope (map) → create policy retain-only on pilot →
pilot + observe hold library → validate → enable delete deliberately (approved) → expand scope → report
coverage`
