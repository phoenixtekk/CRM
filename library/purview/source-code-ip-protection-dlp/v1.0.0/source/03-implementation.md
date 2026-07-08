# 3. Implementation Guide — Source-Code & IP Protection DLP (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot (test mode) → Validate →
Expand (enforce)**. Every write is **created in test mode on `Source-Code DLP – Pilot Ring – Stage1`
first**, previewed with `-WhatIf`, and reversible. Named objects are introduced once and reused
everywhere:

| Object | Name |
|---|---|
| DLP policy | `Source-Code & IP DLP – Policy` |
| Detection rule | `Source-Code Detection Rule` |
| Pilot ring | `Source-Code DLP – Pilot Ring – Stage1` |
| Scope/design map | `Source-Code DLP – Map` |
| Coverage report | `Source-Code DLP – Coverage Report` |

> **Test mode first, always.** A DLP policy in **test mode** matches content and shows what it *would*
> block across channels (email, SharePoint/OneDrive, Teams, endpoint) but **enforces nothing**. Only
> **enforce** mode restricts real egress. This solution creates the policy in test mode and moves to
> enforce as a deliberate, approved step. **Verify capability availability (Endpoint DLP, Source Code
> classifier) against your licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (DLP policies + rules)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** the connection succeeds and
`Get-DlpCompliancePolicy` returns without error.

## Step 1 — Assess current state (Assess)
1. Run `DLPCODE-Discover.ps1`. Read-only, it reports every **DLP policy and rule**, which **channels** each
   covers (Exchange/SharePoint/OneDrive/Teams/Endpoint), each policy's **mode** (test/enforce), and a
   sample of available **sensitive information types** (and a reminder to confirm the **Source Code**
   classifier and **Endpoint DLP** onboarding in the portal).
2. Run `DLPCODE-Check-Prereqs.ps1` — module/connection, the DLP/role signals, and existing policies —
   PASS/GAP per signal.
3. Record every GAP and remediate before configuring. **Pass/fail:** the inventory and prereq report
   complete; existing coverage/overlap captured in `Source-Code DLP – Map`.

## Step 2 — Design the DLP policy (Design)
1. With security/IP, choose the **detection** (Source Code classifier + custom IP types/keywords), the
   **channels** (email, SharePoint/OneDrive, Teams, endpoint), the **egress actions** to govern (external
   email, USB/removable-media copy, cloud/browser upload), the **actions** (restrict/block, notify with a
   policy tip, alert admins), and the **exceptions** (approved repos/tools/partners).
2. Define `Source-Code DLP – Pilot Ring – Stage1` (developer users/devices) and the notification/alert
   recipients. Record everything in `Source-Code DLP – Map`.
3. Confirm which capabilities your licensing supports (Endpoint DLP, Source Code classifier); mark any
   unsupported channel/condition **deferred**.
   **Pass/fail:** `Source-Code DLP – Map` is agreed and signed off; what is protected IP and which egress
   to block is owned by stakeholders, not IT.

## Step 3 — Create the policy in test mode (Configure)
Do this **for the pilot ring first**, and **in test mode** — no enforcement yet.

1. **Create the policy + rule (test mode).** Preview then commit:
   ```powershell
   .\DLPCODE-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotUsers "codedlp-pilot@contoso.com" -UseSourceCodeClassifier -WhatIf
   .\DLPCODE-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotUsers "codedlp-pilot@contoso.com" -UseSourceCodeClassifier -Commit
   ```
   This creates `Source-Code & IP DLP – Policy` across the in-scope channels for the pilot users, with
   `Source-Code Detection Rule` matching the **Source Code** classifier (and add your custom IP types), in
   **test-without-notifications** mode by default (change to test-with-tips as designed). Verify with
   `Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`.
2. **Complete detail in the portal.** Purview portal → **Data Loss Prevention → Policies** → the policy →
   confirm the rule conditions (classifier + custom IP types), the **endpoint egress activities**
   (USB/upload), policy-tip text, notifications, alerts, and exceptions match `Source-Code DLP – Map`.
   **Pass/fail:** the policy exists in **test mode**, covers the intended channels for the pilot ring, and
   its rule matches source code / IP — enforcing nothing.

## Step 4 — Pilot in test mode (Pilot)
1. Let the policy run in test mode on the pilot ring. Generate representative activity — email a code file
   externally; attempt a USB copy on an onboarded pilot device; upload code to a personal cloud.
2. Review what the policy **would** match and block (DLP reports / Activity Explorer) across channels and
   where **policy tips** would show. Tune the classifier confidence, custom types, and exceptions (approved
   repos/tools) to remove false positives.
   **Pass/fail:** the policy detects source code / IP across the intended channels in test mode with an
   acceptable false-positive rate; discrepancies are recorded for troubleshooting, not worked around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `DLPCODE-Validate.ps1`. Read-only, it confirms `Source-Code & IP DLP – Policy` exists, covers the
   intended channels, its rule matches the source-code/IP detection, and the policy is in **test mode**
   (not prematurely enforcing) — PASS/FAIL per gate.
2. Confirm policy tips and admin alerts behave as designed on a real test egress across channels.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `Source-Code DLP – Pilot Ring – Stage1`.

## Step 6 — Enforce and expand (Expand)
1. **Move to enforce deliberately** — only after test-mode is validated and stakeholders approve:
   ```powershell
   .\DLPCODE-Set-DlpPolicy.ps1 -Action Enforce -WhatIf
   .\DLPCODE-Set-DlpPolicy.ps1 -Action Enforce -Commit
   ```
   This switches `Source-Code & IP DLP – Policy` to **Enable** (enforce). Communicate the change to
   developers first; enforcement blocks real egress.
2. **Expand the scope** to all intended developer users/devices and channels once validated.
3. Run `DLPCODE-Report.ps1 -CsvPath .\CodeDlpReport.csv` to produce `Source-Code DLP – Coverage Report` —
   each policy/rule, its channels, mode, and match conditions — as the management evidence artifact, and
   re-run it on a schedule.
   **Pass/fail:** the policy is in enforce mode across the intended channels/scope; the report shows
   coverage and mode as designed.

---
### Rollback
- **Return to test mode** with `DLPCODE-Set-DlpPolicy.ps1 -Action Test -Commit` (or
  `Set-DlpCompliancePolicy ... -Mode TestWithoutNotifications`) to stop enforcement immediately while
  keeping the policy for tuning.
- **Disable / delete the policy** (`Set-DlpCompliancePolicy ... -Mode Disable`, or remove it) to stop it
  entirely.
- **Narrow the scope** back to the pilot ring, or add an **exception** to release an approved repo/tool
  that's being blocked. Keep `Source-Code DLP – Map` as the record of the intended state.

### Order of operations
`Assess policies + classifiers + endpoint onboarding → design detection + channels + actions + exceptions →
create policy in test mode on pilot ring → pilot + tune in test mode → validate → enforce deliberately
(approved) → expand scope/channels → report coverage`
