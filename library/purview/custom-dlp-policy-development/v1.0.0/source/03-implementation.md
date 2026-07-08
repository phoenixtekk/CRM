# 3. Implementation Guide — Custom DLP Policy Development (Microsoft Purview)

Follow these steps **in order**. Authoring is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Data loss prevention**) and **Security & Compliance PowerShell**
(`Connect-IPPSSession`). Policy creation/changes are previewed with `-WhatIf`, applied with `-Commit`, and
the policy is **created in simulation / test mode first** — it only moves to enforcement after the match
evidence passes the gate. Artifact names follow the `Custom DLP – <Purpose> – <Stage>` convention from the
Overview and are reused verbatim; the placeholder data type `Sensitive Data` stands in for your real class.

> **Model:** Assess the environment, design conditions/actions/exceptions, configure the policy in
> simulation, pilot (simulate — no user impact), validate & tune against the matches, then expand to
> enforcement under change control. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**
>
> **Portal paths are cited as of authoring and the Purview portal is evolving — verify each path in your
> own tenant.** Capability availability is licensing-dependent — verify against your plan (Requirement
> 2.1). **Never** create a custom DLP policy directly in `Enable` mode: always simulate first.

## Step 1 — Assess the DLP environment (Assess)
1. Open the Purview portal → **Data loss prevention → Policies** and review what already exists — which
   templates are on, in which mode, over which locations.
2. Run `DLPCUSTOM-Assess-DlpEnvironment.ps1 -CsvPath .\DlpDiscovery.csv`. Read-only, it captures: existing
   DLP policies + rules and their **mode** (`Enable` / `TestWithNotifications` / `TestWithoutNotifications`
   / `Disable`) and locations via `Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`; the available
   **sensitive information types** via `Get-DlpSensitiveInformationType`; and the DLP-relevant licensing.
   It writes `Custom DLP – Discovery – Assess`.
3. Note any **over-firing** existing policy and confirm the **SITs your design needs are present**
   (Requirement 2.5). **Pass/fail:** you have an inventory of current DLP, the available SITs, and the
   licensed workloads — and you know which SITs/labels your new policy can reference.

## Step 2 — Design conditions, actions, and exceptions (Design)
1. From the stakeholders' data-protection intent (Requirement 2.6), build the design matrix
   `Custom DLP – Sensitive Data – Design`. For each rule, specify:
   - **Conditions** — which **SIT(s)** at which **confidence** (low/medium/high), **instance count**
     (min/max), any **sensitivity label**, and content/recipient conditions (e.g. *sent outside the
     organisation*).
   - **Actions** — staged: **audit only → notify (policy tip) → restrict/block → encrypt** — and whether to
     **generate an incident report**.
   - **Exceptions (`ExceptIf…`)** — the approved flows that must **not** trigger (approved partner domains,
     service mailboxes, specific sites/groups).
2. Choose the **workloads** (Exchange, SharePoint, OneDrive, Teams, endpoints) and the **pilot scope**
   (a pilot user group / site set, not all users).
3. **Pass/fail:** every rule maps to a documented intent; each condition references a SIT/label that
   exists (Step 1); the sensitive-action rows have named approvers. Determinations about *what is
   sensitive / which regulation applies* are the stakeholders' — recorded, not decided here.

## Step 3 — Configure the policy in SIMULATION / test mode (Configure, simulate-first)
1. Dry-run first: `DLPCUSTOM-New-DlpPolicy.ps1 -PolicyName 'Custom DLP – Sensitive Data – Pilot' -DesignPath .\DlpDesign.json -WhatIf`.
   With `-WhatIf` (the default) it makes **no changes** — it prints exactly the `New-DlpCompliancePolicy` /
   `New-DlpComplianceRule` it *would* run, the mode, the locations, the conditions, and the exceptions, and
   flags any referenced SIT/label that is missing in the tenant.
2. Read every line against `Custom DLP – Sensitive Data – Design`. Confirm the mode is a **test mode**
   (`TestWithoutNotifications` by default — evaluates content and records matches **without blocking or
   notifying**), the scope is the **pilot** scope, and the exceptions are present.
3. Apply in simulation: run with `-Commit`. The script creates the policy with
   `New-DlpCompliancePolicy -Mode TestWithoutNotifications` scoped to the pilot locations, then adds the
   rule with `New-DlpComplianceRule` (conditions via `-ContentContainsSensitiveInformation`, exceptions via
   the `-ExceptIf…` parameters, actions per the design but with **no block** while in test).
4. **Pass/fail + rollback:** `Get-DlpCompliancePolicy -Identity 'Custom DLP – Sensitive Data – Pilot'`
   shows the policy in a **test** mode over the pilot scope. Rollback is
   `Remove-DlpCompliancePolicy -Identity 'Custom DLP – Sensitive Data – Pilot'` (the script prints the exact
   reverse command). **Nothing is blocked or shown to users at this stage.**

## Step 4 — Pilot: let the policy simulate (Pilot)
1. Leave the policy in test mode over the pilot scope so it evaluates real content and **records matches
   with zero user impact**. Allow time for content to be processed (new/edited items evaluate as they
   change; existing content is evaluated as the service scans it — allow up to ~24–48 hours for meaningful
   volume, and longer for large SharePoint/OneDrive estates).
2. Do **not** move to enforcement yet. This simulation period is the mandatory high-impact-change gate for
   the Purview category. **Pass/fail:** the policy is generating simulation matches over the pilot scope.

## Step 5 — Validate and tune against the match evidence (Validate)
1. Run `DLPCUSTOM-Test-DlpPolicy.ps1 -PolicyName 'Custom DLP – Sensitive Data – Pilot'` — read-only, it
   confirms the policy/rule mode, locations, conditions, and exceptions are exactly as designed, and writes
   `Custom DLP – Simulation – Validate`.
2. Run `DLPCUSTOM-Report-DlpMatches.ps1 -PolicyName 'Custom DLP – Sensitive Data – Pilot' -CsvPath .\DlpMatches.csv`
   (read-only) to pull the simulation matches (from Activity Explorer / DLP reporting — verify the reporting
   surface in your tenant) into `Custom DLP – Matches – Report`.
3. **Tune** with `DLPCUSTOM-New-DlpPolicy.ps1 … -Update` (dry-run `-WhatIf`, then `-Commit`):
   - **Too many false positives** → raise the **confidence** requirement, raise the **instance-count**
     minimum, add an **exception** for the approved flow, or narrow the **SIT**.
   - **False negatives (missed data)** → add/broaden a **SIT**, lower an over-strict threshold, or add a
     content/recipient condition.
4. Re-simulate and re-report after each change. **Pass/fail:** match quality meets the agreed gate (e.g.
   false-positive rate under the target, no known-sensitive sample missed) recorded in the Testing Guide.

## Step 6 — Expand to enforcement, staged, under change control (Expand)
1. With the tuned policy passing the gate, move it toward enforcement **in stages** — dry-run `-WhatIf`
   then `-Commit` each time:
   - First to **`TestWithNotifications`** (simulation **plus** policy tips) so users start seeing guidance
     while nothing is yet blocked; or straight to **`Enable`** with only the **notify/policy-tip** action.
   - Then, once notifications are validated, enable the **restrictive action** (restrict access / block /
     encrypt) per the design.
   The script sets mode via `Set-DlpCompliancePolicy -Mode Enable` and the action via
   `Set-DlpComplianceRule`.
2. Broaden **scope** from the pilot group to the full in-scope population only after the enforced policy is
   confirmed healthy on the pilot.
3. **Pass/fail + rollback:** the policy reports `Enable` with the intended action over the intended scope,
   and legitimate business flows still succeed (exceptions hold). Rollback at any stage is
   `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to no-impact simulation) or
   `-Mode Disable` — both printed by the script; keep the change window open until validated.

---
### Order of operations
`Assess environment + SIT inventory → design conditions/actions/exceptions → dry-run (-WhatIf) policy →
create in TestWithoutNotifications on pilot scope → simulate (no impact) → validate + report matches →
tune (re-simulate) → stage to TestWithNotifications / Enable with tips → enable restrictive action →
broaden scope — each move -WhatIf first, under change control, rollback ready.`
