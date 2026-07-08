# Troubleshooting — Microsoft Purview Health Check

The common failure modes when running a read-only Purview health check, and how to resolve them.
Because this solution **reads and scores** (its only write is the gated audit-log re-enable), almost
every issue is a **read-access**, **cmdlet-availability**, or **scoring-interpretation** problem — not a
change that broke something. The **portal is authoritative**; when a script and the portal disagree,
trust the portal and fix the read. Objects, domains (**P/C/R**), and the register fields are named
verbatim from the Implementation Guide.

## A surface returns access-denied → a false "Gap"
- **Symptom:** `OPSHEALTH-Discovery.ps1` / `OPSHEALTH-ScopeCheck.ps1` can't read DLP, labels, retention,
  audit, or roles, and the domain looks empty.
- **Likely cause:** The account lacks the **read** role for that surface (R1) — an empty read is not the
  same as an empty estate.
- **Resolve:** Record it as a **read-access** finding, **not** a drift Gap; assign the least-privilege
  read role (e.g. Compliance/Global Reader, the relevant View-Only role group) under change control;
  re-run before scoring that domain. Do **not** over-grant write access "to be safe."

## A cmdlet is not available in the tenant
- **Symptom:** `Get-InsiderRiskPolicy`, `Get-Label`, or another cmdlet is missing after a successful
  connect.
- **Likely cause:** The capability is **portal-managed** or **plan-gated** (E5 / E5 Compliance; some
  preview), or the module is old.
- **Resolve:** Update the module (`Install-Module ExchangeOnlineManagement`,
  `Install-Module Microsoft.Graph`); where the cmdlet genuinely doesn't exist, confirm the surface in
  the **portal** (Insider Risk is largely portal-managed — report **presence + privacy posture** only)
  and **verify against your licensing/tenant.** A plan-gated absence is a **licensing** note, not a
  drift Gap.

## The unified audit-log status is ambiguous or unreadable
- **Symptom:** `Get-AdminAuditLogConfig` errors, or the on/off status looks wrong.
- **Likely cause:** Not connected to **Exchange Online** (separate from S&C PowerShell), missing read
  access, or ingestion still propagating after a change.
- **Resolve:** `Connect-ExchangeOnline` and confirm `Get-AdminAuditLogConfig` read access; re-check
  `UnifiedAuditLogIngestionEnabled`. After re-enabling with
  `OPSHEALTH-Remediate.ps1 -EnableUnifiedAuditLog -Commit`, allow propagation — status is not instant;
  **verify in tenant.**

## Coverage is mis-mapped (a policy looks like it covers less/more than it does)
- **Symptom:** `OPSHEALTH-ScopeCheck.ps1` reports a workload blind spot that the portal contradicts, or
  the `Workload` field is blank.
- **Likely cause:** The policy's location/scope is set in a way the cmdlet's `Workload` field doesn't
  fully express, or coverage was scored **without** the R3 in-scope map.
- **Resolve:** Open the policy in the portal and read its **locations** directly (authoritative); score
  Coverage against the **R3 in-scope workload map** — an intended-but-uncovered workload is a Gap, a
  not-intended one is not. "We have DLP" often means "email only" — confirm each workload.

## Role read is incomplete (Global Admin count missing)
- **Symptom:** The role review shows compliance role groups but no Global Administrator count.
- **Likely cause:** The **Microsoft Graph** directory-role read didn't run — module not imported, not
  connected, or missing `RoleManagement.Read.Directory` / `Directory.Read.All`.
- **Resolve:** Import `Microsoft.Graph.Identity.DirectoryManagement`, `Connect-MgGraph` with the
  directory-read scopes, and re-run `OPSHEALTH-ScopeCheck.ps1`. GA sprawl (over the threshold), empty
  critical role groups, and single-member (SPOF) groups are role **Gaps/At Risk** to record with owner
  **Identity / Roles**.

## Licensing gap scored as a drift Gap (confusion)
- **Symptom:** A capability that was never adopted (or isn't licensed) is scored as a **Gap**.
- **Likely cause:** Missing the **R4 intended capability baseline** — a Gap is only a Gap **against
  intent**.
- **Resolve:** Compare against the R4 baseline: **missing-but-intended** = Gap; **not-adopted** =
  Healthy; **unlicensed** = a **licensing decision**, tagged as such and **verify against your
  licensing/tenant** — not a drift Gap. Re-tag and re-run `OPSHEALTH-Report.ps1` to correct the
  scorecard.

## "Stuck in test" flagged on a fresh pilot (false At Risk)
- **Symptom:** A DLP policy in `Test*` mode is flagged **At Risk**, but it's a legitimate current pilot.
- **Likely cause:** The heuristic can't tell a fresh pilot from long-term drift.
- **Resolve:** Confirm the pilot start date; a policy in simulation/test **past its pilot window** is
  At Risk (drift), a **current** pilot is expected. Annotate the register accordingly.

## Insider-risk / sensitive surface — how to stay on the right side of the privacy line
- **Symptom:** Unsure how much to report on Insider Risk / Communication Compliance.
- **Likely cause:** These are **HR/privacy-sensitive** (R5).
- **Resolve:** Report **presence + privacy posture only** (e.g. anonymization on, role separation
  intact) — **never** case contents or any person's identity. If any case detail appears beyond your
  authorized role scope, **stop**: the review breached the boundary. Posture, not content.

## The scorecard diverges from the portal
- **Symptom:** `OPSHEALTH-Report.ps1` rollup doesn't match what the portal shows.
- **Likely cause:** A read gap, stale CSV, or a mis-scored row.
- **Resolve:** The **portal is authoritative** — reconcile the register to it, fix any read-access
  finding, ensure every non-Healthy row has an **owner** and **severity**, and re-issue.

## A determination item was actioned before governance signed off
- **Symptom:** A retention-schedule / records / legal-hold / regulatory item was changed by IT.
- **Likely cause:** A **"determination required"** item was treated as a technical fix.
- **Resolve:** **Halt**; route it to compliance/records/privacy/legal (R8). The health check surfaces
  **technical state**, not the determination — those decisions are theirs.

---
### Key reminders
| Rule | Why |
|---|---|
| Empty read ≠ empty estate | An unreadable surface is a **read-access** finding, not a Gap |
| The portal is authoritative | When a script disagrees, trust the portal and fix the read |
| Score against **intent** (R4) | Missing vs not-adopted vs unlicensed are different verdicts |
| Posture only on IRM/CC | HR/privacy-sensitive — presence + guardrails, never content |
| One direct write only | The gated **audit-log re-enable**; everything else is planned/routed |
| Determinations to governance | Records/retention/legal/regulatory decisions are not IT's |
