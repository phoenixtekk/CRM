# Testing & Validation — Microsoft Purview Health Check

Run these gates in order. Each has an explicit **pass/fail** signal. Because this is a **read-only
assessment**, the gates confirm that the health check **read the estate completely and scored it
correctly** — and, after remediation, that each fixed item now reads **Healthy**. The **portal is
authoritative**; where a script cannot read a surface, that is a finding about **access**, not a
verdict about the estate.

Use the scripts where noted; they are read-only or `-WhatIf` and change nothing you don't explicitly
`-Commit`.

---

## Gate 1 — Read access and toolchain are in place

**Why:** The check can only score what it can read; missing read access produces false Gaps.
**How:** Confirm `Connect-IPPSSession`, `Connect-ExchangeOnline`, and `Connect-MgGraph` all succeed with
an MFA-capable admin. Run `OPSHEALTH-Discovery.ps1` and confirm it reaches DLP, labels, retention,
audit, and role surfaces.
**Pass:** All three connections succeed; the inventory reads every in-scope surface without an
access error.
**Fail:** A surface returns access-denied → this is a **read-access** finding; fix access (R1) and
re-run before scoring that domain.

## Gate 2 — The inventory is complete (Discovery)

**Why:** A partial inventory under-reports drift.
**How:** Run `OPSHEALTH-Discovery.ps1`. Confirm it returns DLP policies (with **Mode**), sensitivity
labels + label policies, retention/lifecycle policies + labels, unified-audit-log status, insider-risk
**presence/posture**, and role-group membership.
**Pass:** Every in-scope surface is inventoried; counts reconcile with a spot-check in the portal.
**Fail:** A surface is empty when the portal shows objects → confirm read role and cmdlet availability
(**verify in tenant**) before trusting the score.

## Gate 3 — Policy health (P) is scored against intent

**Why:** A policy can exist but be **disabled** or **stuck in test** — both are drift.
**How:** For each intended policy (R4 baseline), confirm its **Mode**/enabled/health state.
`OPSHEALTH-ScopeCheck.ps1` / `OPSHEALTH-Validate.ps1` report mode and health.
**Pass:** Each intended DLP/retention/label policy is **enabled and healthy** → **Healthy**; anything
**stuck in simulation/test** past pilot or showing a health warning is **At Risk**; anything **missing
or disabled**, or the **audit log off**, is a **Gap** — and every non-Healthy item is in the register.
**Fail:** A disabled/stuck/missing policy is not reflected in the score/register → re-score.

## Gate 4 — The unified audit log status is correctly determined

**Why:** The audit log is the defensibility evidence base; off = High-severity Gap.
**How:** `OPSHEALTH-Discovery.ps1` / `OPSHEALTH-Validate.ps1` report unified-audit-log status via
Exchange Online.
**Pass:** Status is read correctly (**on** = Healthy; **off** = a **High**-severity Gap in the register).
**Fail:** Status cannot be read, or is misreported → confirm Exchange Online connectivity and the
`Get-AdminAuditLogConfig`/organization-config read; **verify in tenant**.

## Gate 5 — Coverage (C) is scored against the in-scope map

**Why:** "We have DLP" often means "on email only" — the blind spots are the risk.
**How:** `OPSHEALTH-ScopeCheck.ps1` maps each policy's **workloads** (Exchange / SharePoint / OneDrive /
Teams / endpoints) against the R3 in-scope map.
**Pass:** Each in-scope workload's intended coverage is present → **Healthy**; partial coverage (e.g.
labels to a subset, endpoint intended but **no devices onboarded**) → **At Risk**; an in-scope workload
with **no** coverage of an intended capability → **Gap** — all recorded.
**Fail:** A workload blind spot is not surfaced → re-check the policy's location/scope settings and the
in-scope map.

## Gate 6 — Roles (R) least-privilege review is clean or flagged

**Why:** Role drift (GA sprawl, SPOF, stale/empty groups) is a real, auditable risk.
**How:** `OPSHEALTH-ScopeCheck.ps1` reports compliance role-group membership, Global Admin count,
single-member and empty role groups.
**Pass:** Least privilege confirmed → **Healthy**; a single-member (SPOF) group, mild over-membership, or
a stale member → **At Risk**; **Global Admin sprawl**, an empty **critical** role group, or broad
over-privilege → **Gap** — all recorded with owner **Identity / Roles**.
**Fail:** An obvious over-privilege (e.g. many Global Admins) is not flagged → re-run and confirm the
directory-role read (Graph) succeeded.

## Gate 7 — Insider-risk / sensitive surfaces reported as POSTURE only

**Why:** Insider Risk and Communication Compliance are HR/privacy-sensitive.
**How:** Review the Discovery output for those surfaces.
**Pass:** The check reports **presence + privacy posture** (e.g. anonymization on, role separation
intact) **only** — no case contents, no person's identity, no judgement.
**Fail:** Any case detail or identity beyond authorized role scope appears → **stop**; the review
breached the privacy boundary (R5). Report posture only.

## Gate 8 — The scorecard and register are complete and owned

**Why:** Findings without severity and an owner do not get fixed.
**How:** Run `OPSHEALTH-Report.ps1`; inspect the scorecard + Remediation Register CSV.
**Pass:** Every non-Healthy check is a register row with **Domain**, **Rating**, **Severity**, **Owner**,
**Owning capability**, and **Recommended action**; the overall **health rating** reconciles with the
per-domain counts and the portal.
**Fail:** A finding lacks an owner/severity, or the rollup diverges from the portal → the portal is
authoritative; reconcile and re-issue.

## Gate 9 — Remediation planned `-WhatIf`; only the audit-log fix committed

**Why:** The health check must not enable/enforce high-impact capabilities.
**How:** Run `OPSHEALTH-Remediate.ps1 -WhatIf`; if committing the audit-log fix, run with
`-EnableUnifiedAuditLog -Commit` under R7 change control.
**Pass:** `-WhatIf` prints the plan and changes nothing; the only committed change is the **unified
audit-log re-enable**; all DLP/label/retention/insider-risk items are routed to their owning capability
(piloted in simulation/test there), not enabled here.
**Fail:** Any attempt to enable/enforce DLP/labels/retention/insider risk **from this solution** → stop;
that belongs to the owning solution, piloted first.

## Gate 10 — Re-score confirms improvement (post-remediation)

**Why:** Closing the loop proves the remediation worked and the estate is healthier.
**How:** After remediation, re-run `OPSHEALTH-Validate.ps1` and `OPSHEALTH-Report.ps1`.
**Pass:** Each remediated item now reads **Healthy**; the overall **health rating** improved; closed
items are gone from the register; determination items remain pending their governance owner (expected).
**Fail:** A remediated item still reads non-Healthy → confirm the fix landed in the owning capability and
propagated (**verify in tenant**), then re-score.

---

### Exit criteria (all must be true to call the health check complete)

- [ ] Read access + toolchain verified (Gate 1)
- [ ] Inventory complete and reconciled with the portal (Gate 2)
- [ ] Policy health scored against intent (Gate 3)
- [ ] Unified audit-log status correctly determined (Gate 4)
- [ ] Coverage scored against the in-scope map (Gate 5)
- [ ] Role least-privilege review clean or flagged (Gate 6)
- [ ] Insider-risk / sensitive surfaces reported as posture only (Gate 7)
- [ ] Scorecard + Remediation Register complete and owned (Gate 8)
- [ ] Remediation planned `-WhatIf`; only the audit-log fix committed (Gate 9)
- [ ] Re-score confirms improvement; determinations routed to governance (Gate 10)
