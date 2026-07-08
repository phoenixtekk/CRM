# 3. Implementation Guide — SharePoint Online DLP (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot (test mode) → Validate →
Expand (enforce)**. Every write is **created in test mode on `SPO DLP – Pilot Sites – Stage1` first**,
previewed with `-WhatIf`, and reversible. Named objects are introduced once and reused everywhere:

| Object | Name |
|---|---|
| DLP policy | `SPO-OneDrive DLP – Policy` |
| Detection rule | `SPO DLP – External Sharing Rule` |
| Pilot scope | `SPO DLP – Pilot Sites – Stage1` |
| Scope/design map | `DLP Scope – Map` |
| Coverage report | `SPO DLP – Coverage Report` |

> **Test mode first, always.** A DLP policy in **test mode** matches content and shows what it *would*
> block (with or without policy tips) but **enforces nothing**. Only **enforce** mode restricts real
> sharing. This solution creates the policy in test mode and moves to enforce as a deliberate, approved
> step. **Verify capability availability (info types, conditions) against your licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (DLP policies + rules)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** the connection succeeds and
`Get-DlpCompliancePolicy` returns without error.

## Step 1 — Assess current state (Assess)
1. Run `DLPSPO-Discover.ps1`. Read-only, it reports every **DLP policy and rule**, whether each covers
   **SharePoint** and/or **OneDrive**, each policy's **mode** (test/enforce), and the available
   **sensitive information types** to match on.
2. Run `DLPSPO-Check-Prereqs.ps1` — module/connection, the DLP/role signals, and existing policies —
   PASS/GAP per signal.
3. Record every GAP and remediate before configuring. **Pass/fail:** the inventory and prereq report
   complete; existing coverage/overlap captured in `DLP Scope – Map`.

## Step 2 — Design the DLP policy (Design)
1. With compliance/security, choose the **sensitive information types / labels / keywords** to detect, the
   **sharing conditions** to govern (shared externally, shared with everyone, accessible by external
   users), the **actions** (restrict access / block external sharing, notify with a policy tip, alert
   admins), and the **exceptions**.
2. Define `SPO DLP – Pilot Sites – Stage1` and the notification/alert recipients. Record everything in
   `DLP Scope – Map`.
3. Confirm which info types/conditions your licensing supports; mark any unsupported condition
   **deferred**.
   **Pass/fail:** `DLP Scope – Map` is agreed and signed off; which content is sensitive and which sharing
   to block is owned by stakeholders, not IT.

## Step 3 — Create the policy in test mode (Configure)
Do this **for the pilot scope first**, and **in test mode** — no enforcement yet.

1. **Create the policy + rule (test mode).** Preview then commit:
   ```powershell
   .\DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -WhatIf
   .\DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -Commit
   ```
   This creates `SPO-OneDrive DLP – Policy` scoped to the pilot sites (and OneDrive where designed) with
   `SPO DLP – External Sharing Rule`, in **test-without-notifications** mode by default (change to
   test-with-tips as designed). Verify with `Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`.
2. **Complete tip/notification/exception detail in the portal.** Purview portal → **Data Loss Prevention →
   Policies** → the policy → confirm the rule conditions, policy-tip text, notifications, alerts, and
   exceptions match `DLP Scope – Map`.
   **Pass/fail:** the policy exists in **test mode**, covers exactly the pilot scope, and its rule matches
   the intended sensitive content + sharing condition — enforcing nothing.

## Step 4 — Pilot in test mode (Pilot)
1. Let the policy run in test mode on the pilot sites. Generate representative activity — upload a
   document containing the sensitive info type; share it externally.
2. Review what the policy **would** match and block (DLP reports / activity explorer) and where **policy
   tips** would show. Tune conditions and exceptions to remove false positives.
   **Pass/fail:** the policy matches the intended content and share conditions in test mode with an
   acceptable false-positive rate; discrepancies are recorded for troubleshooting, not worked around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `DLPSPO-Validate.ps1`. Read-only, it confirms `SPO-OneDrive DLP – Policy` exists, covers the
   intended locations, its rule matches the intended sensitive content/sharing condition, and the policy
   is in **test mode** (not prematurely enforcing) — PASS/FAIL per gate.
2. Confirm policy tips and admin alerts behave as designed on a real test share.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `SPO DLP – Pilot Sites – Stage1`.

## Step 6 — Enforce and expand (Expand)
1. **Move to enforce deliberately** — only after test-mode is validated and stakeholders approve:
   ```powershell
   .\DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -WhatIf
   .\DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -Commit
   ```
   This switches `SPO-OneDrive DLP – Policy` to **Enable** (enforce). Communicate the change to users
   first; enforcement blocks real sharing.
2. **Expand the scope** to all intended SharePoint/OneDrive locations once validated.
3. Run `DLPSPO-Report.ps1 -CsvPath .\SpoDlpReport.csv` to produce `SPO DLP – Coverage Report` — each
   policy/rule, its locations, mode, and match conditions — as the management evidence artifact, and re-run
   it on a schedule.
   **Pass/fail:** the policy is in enforce mode at the intended scope; the report shows coverage and mode
   as designed.

---
### Rollback
- **Return to test mode** with `DLPSPO-Set-DlpPolicy.ps1 -Action Test -Commit` (or
  `Set-DlpCompliancePolicy ... -Mode TestWithoutNotifications`) to stop enforcement immediately while
  keeping the policy for tuning.
- **Disable / delete the policy** (`Set-DlpCompliancePolicy ... -Mode Disable`, or remove it) to stop it
  entirely.
- **Narrow the scope** back to the pilot to reduce blast radius, or add an **exception** to release a
  false-positive site/group. Keep `DLP Scope – Map` as the record of the intended state.

### Order of operations
`Assess policies + info types → design content + sharing + actions + exceptions → create policy in test
mode on pilot → pilot + tune in test mode → validate → enforce deliberately (approved) → expand scope →
report coverage`
