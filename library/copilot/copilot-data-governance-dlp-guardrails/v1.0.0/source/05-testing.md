# 5. Testing & Validation — Microsoft 365 Copilot Data Governance & DLP Guardrails

Validate the build against explicit **pass/fail gates** before enforcing anything. Discovery, validation,
audit search, and reporting are automated and read-only; the enforcing controls are created in
simulation/test and evaluated for false positives first. Record each result against the named object.

> **Principle:** the pilot gate is a **simulation/test review with an acceptable false-positive rate**,
> plus **confirmed audit capture** of Copilot interactions — with **no legitimate Copilot use
> over-blocked**. Nothing moves to enforce until every gate below passes.

## Test 1 — Scope, licensing & connections (Step 0)
- **Procedure:** Run `CPLTGOV-Discovery.ps1 -ScopeOnly`.
- **Pass:** `Connect-IPPSSession` / `Connect-MgGraph` succeed; labels/label-policies/DLP/auto-labeling
  levers enumerated; the **Copilot DLP location** availability is reported; auditing is on; pilot ring and
  simulation window agreed.
- **Fail:** A sign-in fails, or the Copilot DLP location is absent → resolve (Requirements 2.1–2.5); if
  DLP-for-Copilot is unavailable, plan the label-encryption interim and note it pending.

## Test 2 — Label coverage discovered (Step 1)
- **Procedure:** Run `CPLTGOV-Discovery.ps1`; open `Copilot Label Coverage – Estate – Assess`.
- **Pass:** The export lists published labels, sensitive info types, and the coverage picture; the top
  unlabeled-sensitive locations Copilot can reach are named.
- **Fail:** Empty/partial → confirm `Connect-IPPSSession` and read scopes; re-run.

## Test 3 — Control design recorded (Step 2)
- **Procedure:** Review the design baseline.
- **Pass:** The default label, the "keep out of Copilot" labels, the auto-labeling conditions, and the
  prompt/response guardrails are recorded, with stakeholder ownership of the classification
  determinations noted.
- **Fail:** Any determination is an admin guess rather than a stakeholder decision → engage compliance
  (Requirement 2.7) before configuring.

## Test 4 — Labeling piloted safely (Step 3)
- **Procedure:** Confirm `Default Labeling – Users – Pilot` is published to the ring; run
  `CPLTGOV-Guardrails.ps1 -Action AutoLabel -Name "Auto-Label Sensitive – Pilot – Simulation" -WhatIf`
  then, after review, `-Commit`.
- **Pass:** The label policy applies to the pilot ring only; the auto-labeling policy exists in
  **simulation** and has labelled **nothing** yet.
- **Fail:** Auto-labeling created outside simulation → delete and recreate in simulation; never label
  content before the simulation review.

## Test 5 — DLP for Copilot in test only (Step 4)
- **Procedure:** Confirm `DLP for Copilot – Pilot – Test` exists via the portal / `CPLTGOV-Validate.ps1`.
- **Pass:** The policy is scoped to the **Microsoft 365 Copilot** location, conditioned on the agreed
  labels, and is in **test/disabled** — it blocks **nothing** yet.
- **Fail:** The policy is enabled/enforcing, or scoped to the wrong location → set to test/disabled and
  re-scope; verify the Copilot location name in your tenant.

## Test 6 — Audit & eDiscovery capture Copilot interactions (Step 5) — decisive
- **Procedure:** Generate a few Copilot prompts/responses in the pilot ring, then run
  `CPLTGOV-AuditSearch.ps1` and check `Copilot Interaction Audit – Tenant – Validate`; confirm the events
  are discoverable in **eDiscovery**.
- **Pass:** Copilot interaction events appear in the audit search and are eDiscoverable — the evidence
  trail works.
- **Fail:** No events → confirm auditing is on (Requirement 2.5), allow for backfill latency, and re-run.

## Test 7 — Simulation/test false-positive review (Step 6) — decisive
- **Procedure:** After the simulation window, review the auto-labeling **simulation results** and the
  DLP-for-Copilot **test** matches with stakeholders.
- **Pass:** The matches are accurate (sensitive content correctly identified); the false-positive rate is
  acceptable to stakeholders; no legitimate Copilot use would be over-blocked.
- **Fail:** Too many false positives / legitimate use blocked → tune the conditions and re-pilot; do not
  enforce.

## Test 8 — Enforce, evidence & recurring review (Step 7)
- **Procedure:** After the gate passes, move auto-labeling to **on** and DLP-for-Copilot to **enforce**
  (`CPLTGOV-Guardrails.ps1 -Action Enforce -Commit`); run `CPLTGOV-Report.ps1`; confirm the
  `Copilot Governance Review – Tenant – Recurring` chain is scheduled.
- **Pass:** Policies enforced at the agreed scope; `Copilot Governance Report – Tenant – Expand` shows the
  before/after coverage, controls and their state, audit capture, and residual risk; the read-only review
  chain is scheduled.
- **Fail:** Enforcement causes an issue → return the affected policy to simulation/test and re-tune.

## Evidence to retain
- `Copilot Label Coverage – Estate – Assess` (baseline) and the post-enforcement re-measure.
- The simulation/test review notes (false-positive assessment, stakeholder sign-off).
- `Copilot Interaction Audit – Tenant – Validate` (audit-capture confirmation).
- `Copilot Governance Report – Tenant – Expand` (the governance sign-off record).
- The recorded classification/acceptable-use determinations from Step 2 (the stakeholders' decisions).
