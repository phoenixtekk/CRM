# 3. Implementation Guide — Microsoft Purview Automation Framework

Follow these steps **in order**. All work uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — every
`*-DlpCompliancePolicy`, `*-Label`, `*-RetentionCompliancePolicy` cmdlet), and **Microsoft Graph**
(licensing/reporting reads). Every write is gated: scripts run **read-only or `-WhatIf` by default** and
change state only with `-Commit`; nothing **enforces/publishes** without a separate, explicit
`-Enforce -Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview
and are reused verbatim.

> **Model:** Assess current state and the config, design the config and pilot, configure by deploying into
> **test/simulation/unpublished mode**, **pilot** on a bounded scope, validate against desired state, then
> expand by enforcing under change control. Pattern: **Assess → Design → Configure → Pilot (simulate) →
> Validate → Expand (enforce).**

## Step 1 — Confirm the toolchain, roles, and licensing (Assess)
1. Run `OPSAUTO-Health.ps1` (read-only). It reports: `ExchangeOnlineManagement`/`Microsoft.Graph` module versions, `Connect-IPPSSession`/`Connect-MgGraph` reachability, which policy-object types you can read (a permissions probe per type — Requirement 2.2), and whether an E5/E5-Compliance-bearing plan is present (Requirement 2.1).
2. Resolve any red item — missing module, failed connect, missing role, missing license — before proceeding.
3. **Pass gate:** health check is green for the policy types your config targets; you can read DLP/label/retention objects and Graph licensing.

## Step 2 — Inventory the current tenant state (Assess)
1. Run `OPSAUTO-Discovery.ps1` (read-only). It enumerates existing **DLP policies + their mode**, **sensitivity labels + label policies**, and **retention policies + rules**, and writes the snapshot `Automation Snapshot – Tenant State – Current` (JSON).
2. Review the snapshot: what already exists, in what mode, and where it overlaps the intended config. This is the baseline you reconcile against.
3. **Pass gate:** a current-state snapshot exists and has been reviewed with the policy owners.

## Step 3 — Author and validate the desired-state config (Design)
1. Author `Automation Config – Purview Ops – Baseline` (JSON) with the policy owners (Requirement 2.4/2.6): for each DLP/label/retention policy, its **name**, **locations/scope**, target **mode**, and the identifying managed settings. **Content decisions (info types, durations, taxonomy) come from compliance/records/legal** — the config records them.
2. Structurally validate it: `OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -ValidateConfigOnly` (parses the config, checks required fields, flags entries that need E5 — no tenant calls).
3. Define the **pilot scope** `Automation Pilot – Ops Scope – Stage1` — a bounded subset of locations/users and a few policies to prove the flow (Requirement 2.7).
4. **Pass gate:** the config validates structurally, every policy has a named content-owner, and the pilot scope is documented and approved.

## Step 4 — Deploy the pilot into safe-first mode (Configure → Pilot)
1. Dry-run the reconcile for the pilot subset:
   `OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -WhatIf`
   It prints the exact `New-/Set-*` cmdlets it *would* run — creates, updates, and mode settings — with **no changes**.
2. Review every planned action. Confirm names match the config, locations are the **pilot** scope (not tenant-wide), and DLP policies are targeted at **test/simulation mode**, labels **unpublished**, retention **unenforced/pilot-scoped**.
3. Apply the safe-first deploy: re-run with `-Commit` (still **no enforcement**). Result: DLP policies exist in **test/simulation mode**, sensitivity labels exist **but are not published**, retention policies exist **scoped to the pilot / unpublished**. Label the effort `Automation Deploy – Purview Policies – Simulation`.
4. **Pass gate:** `OPSAUTO-Discovery.ps1` shows the pilot policies present in the intended safe-first mode. **Rollback:** `OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -Remove -Commit` removes the objects the framework created (it only touches config-managed objects; it does not delete pre-existing unmanaged policies).

## Step 5 — Validate deployed state against desired state (Pilot → Validate)
1. Run `OPSAUTO-Validate.ps1 -ConfigPath .\baseline.json -Scope Pilot` (read-only). It compares each config entry to the deployed object and reports **drift**: missing, extra, **mode-mismatched**, or altered policies, producing `Automation Validate – Desired State – Drift`.
2. For DLP policies in **test/simulation mode**, review the simulation/test results in the Purview DLP portal (what *would* have matched) with the policy owners — this is where a mis-scoped or over-broad rule is caught before it ever enforces. **Verify the simulation view/behavior in your tenant** (2.1).
3. **Pass gate:** validation reports **no unexpected drift** for the pilot, and the DLP test/simulation results are reviewed and accepted by the owners.

## Step 6 — Report the pilot posture (Validate)
1. Run `OPSAUTO-Report.ps1 -ConfigPath .\baseline.json -Scope Pilot` (read-only) to produce `Automation Report – Policy Inventory – Tenant` and `Automation Report – Coverage Scorecard – Tenant`: what exists, in what mode, versus what the config expects.
2. Complete the **Testing Guide** gates for the pilot before enforcing anything.
3. **Pass gate:** the scorecard is green for the pilot scope and the inventory matches the config.

## Step 7 — Enforce/publish the pilot deliberately (Expand — gated)
1. Only after Steps 5–6 pass, and with change approval, promote the pilot objects to their enforced state:
   `OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -Enforce -WhatIf` → review → `-Enforce -Commit`.
   This moves DLP policies to **Enable** (enforce), **publishes** the label policy, and **publishes/scopes-up** retention — the one and only step that turns on real user/data impact, and it is separate from the safe-first deploy by design.
2. Monitor for user/end-state impact on the pilot scope before widening. **Rollback:** re-run without `-Enforce` (`-Commit`) to return DLP to test mode / unpublish labels / unpublish retention; or `-Remove -Commit` to delete the managed objects.
3. **Pass gate:** the pilot enforces cleanly with no unexpected user impact, validation stays drift-free, and the scorecard remains green.

## Step 8 — Expand to full scope (Expand)
1. Widen the config's scope from `Pilot` to the full agreed locations/users, and repeat Steps 4–7 for the full set: deploy safe-first (`-Commit`), validate, report, then enforce (`-Enforce -Commit`) under change control. Never jump straight to enforce at full scope without the safe-first + validate pass.
2. Confirm licensing (2.1) covers every location/user the expanded policies touch.
3. **Pass gate:** full-scope validation is drift-free and the scorecard is green with enforced policies matching the config.

## Step 9 — Operationalize the cadence (Expand)
1. Schedule the **read-only chain** `OPSAUTO-Discovery.ps1` → `OPSAUTO-Validate.ps1` → `OPSAUTO-Report.ps1` on a cadence (e.g. daily/weekly) so **drift** — a policy edited in the portal, disabled, un-published, or removed from a label policy — is caught and reported early.
2. Treat every config change as a change-controlled pull-request-style flow: edit config → `-ValidateConfigOnly` → `-WhatIf` → `-Commit` (safe-first) → validate → `-Enforce -Commit`.
3. Hand the scorecard and drift report to compliance/security as the standing evidence and monitoring artifact. **Pass gate:** the cadence is scheduled, and config changes flow only through the gated deploy path.
