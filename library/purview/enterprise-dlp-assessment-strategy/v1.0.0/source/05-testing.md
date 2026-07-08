# 5. Testing & Validation — Enterprise DLP Assessment & Strategy (Microsoft Purview)

Validate the assessment against explicit **pass/fail gates**. Because this solution **enforces nothing**,
the gates are about *completeness and correctness of the evidence and the roadmap*, not about blocking
leaks. The four headline gates are: **(A) posture is baselined**, **(B) sensitive data is discovered
(rest + motion)**, **(C) exposure is ranked and the roadmap is sound**, and **(D) nothing is enforced and
everything is reversible**. Where any test touches sample content, use **non-real, clearly-fake data** (e.g.
the Microsoft-documented test credit-card number `4111 1111 1111 1111`) — never real customer/employee data.

> All tests assume the posture baseline (Phase 0), the Content Explorer data map (Phase 1), the monitor-only
> simulation policy (Phase 2), and the movement measurement (Phase 3) from the Implementation Guide.

---

## Test A — Posture baseline (Assess)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Policy inventory captured | Run `DLPASSESS-Discovery.ps1 -CsvPath ...`. | Every existing DLP policy is listed with its **mode** (enforce / simulation / disabled) and locations; the CSV is produced. |
| A2 | SIT/label coverage mapped | Review the Discovery output. | Built-in vs custom SIT counts and the sensitivity/retention labels in play are recorded. |
| A3 | Unexpected enforcement flagged | Review the "enforcing policies" callout. | Any policy in **Enable** (enforce) mode is flagged for review; if none is expected, the list is empty. |

**Gate A (pass):** a written posture baseline exists — policies + modes + SIT/label coverage — and any
pre-existing enforcement is identified.

---

## Test B — Sensitive-data discovery (rest + motion)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Readiness confirmed | Run `DLPASSESS-Validation.ps1`. | Audit logging **On**, Content Explorer viewer roles held (or gap documented), discovery surfaces available. |
| B2 | Data-at-rest map produced | Run `DLPASSESS-DataScan.ps1 -Tags <shortlist> -CsvPath ...`. | Per-SIT/label **item counts and locations** are exported for the candidate categories (or a category is explicitly a detector gap). |
| B3 | Simulation baseline live | Run `DLPASSESS-Discovery.ps1` after creating the baseline. | Exactly one broad policy reports a **Test\*** mode (`TestWithoutNotifications`) over the intended locations/SITs. |
| B4 | Movement measured | After dwell time, run `DLPASSESS-Report.ps1 -Days <n> -CsvPath ...`. | Simulated matches are aggregated by **SIT, workload, volume, and external exposure**; the CSV is produced. |
| B5 | Rest↔motion reconciled | Compare B2 and B4. | Categories with data at rest but zero movement (or vice-versa) are explained as genuine or as a coverage gap. |

**Gate B (pass):** you can state, with evidence, **where each candidate category rests and how it moves**,
with any coverage gaps documented.

---

## Test C — Ranking & roadmap quality (Design)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Exposure ranked | Review `Sensitive Data Map – Prioritized – Assessment`. | Categories are ranked by prevalence, external-sharing exposure, and movement volume — with the weighting recorded. |
| C2 | Roadmap is simulation-first | Review each roadmap step. | Every proposed rollout step starts in **simulation**, has a **pass/fail gate** and a **rollback**, and names a detector, location, action, ring, and order. |
| C3 | Detector gaps captured | Check categories with no built-in SIT. | Each is listed as a **detector-to-build** backlog item (custom SIT / EDM / trainable), not silently dropped. |
| C4 | Determinations flagged | Scan the roadmap for scope/action decisions. | Every compliance/privacy/legal decision is marked **[to be ratified]** — none is asserted by the assessment. |

**Gate C (pass):** a defensible ranking and a simulation-first, gated, reversible roadmap exist, with
detector gaps and governance determinations explicitly flagged.

---

## Test D — Non-enforcement & reversibility (safety)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| D1 | Nothing enforced | Run `DLPASSESS-Discovery.ps1`. | The only policy this solution created is in **simulation**; no user is blocked or tipped by it. |
| D2 | Zero user impact | Confirm with a pilot user that normal email/sharing is unaffected. | Users experience **no** policy tips or blocks from the assessment baseline. |
| D3 | Instant rollback | Run `DLPASSESS-Baseline.ps1 -Remove -Commit` (or delete in portal). | The simulation policy is removed cleanly with no data change and no user impact. |
| D4 | Scripts safe-by-default | Run `DLPASSESS-Baseline.ps1` **without** `-Commit`. | It makes no change (`-WhatIf` output only); Discovery / DataScan / Validation / Report are read-only. |

**Gate D (pass):** the assessment enforced nothing, imposed zero user impact, and every created object is
instantly and cleanly removable.

---

## Evidence to capture (for the deliverable record)
- The posture baseline CSV (Phase 0) and the SIT/label coverage summary (Gate A).
- The Content Explorer data-at-rest map and the movement report, plus the rest↔motion reconciliation
  (Gate B).
- The ranked exposure view and the prioritized, simulation-first roadmap with detector gaps and
  **[to be ratified]** flags (Gate C).
- Confirmation that the only created policy was in **simulation**, caused no user impact, and was removable
  (Gate D).
- The stakeholder ratification record (who reviewed, what was ratified/revised).

> **Determination boundary.** These tests prove the **assessment and the roadmap are complete and
> non-enforcing**. Whether a given category is *in scope*, which classifier *legally applies*, and the
> *enforced action per category* are compliance/privacy/legal sign-offs, captured alongside the evidence
> above.
