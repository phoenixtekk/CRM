# 3. Implementation Guide — Architecture & Design Review Board (ARB) Governance Framework

Follow these steps in order. The board is stood up on paper (charter, decision rights, gates,
templates), proven on a **pilot workstream**, then expanded program-wide. Tooling reads and manages
the tracker via Microsoft Graph PowerShell; all live-system reads are read-only.

> Model: Assess to Configure to Pilot to Validate to Expand. You charter the board and open the gates,
> run one full governance cycle on a pilot workstream's designs, prove decisions are made and recorded
> without becoming a bottleneck (Step 7 gate), then expand across every workstream.

Named artifacts you will produce (reuse these names verbatim):
- `ARB Charter - Transformation - Ratified`
- `Decision Rights Matrix - ARB - Program`
- `Submission Template - Design Review - Standard` (one variant per gate)
- `Review Checklist - <Gate Name> - Standard` (one per gate)
- `Architecture Decision Record - <DesignId> - Dated` (an ADR per decision)
- `Decision Register - Transformation ARB - Program-Wide`
- `Standards Baseline - Target Architecture - Approved`
- `Gap Register - Design Drift - Rolling`
- `ARB KPI Set - Governance - Standard`
- ARB membership groups: `ARB - Voting Members - Board` and `ARB - Advisory Reviewers - Panel`

## Step 1 — Assess: confirm the mandate and the baseline
1. Confirm the executive sponsor and quote the written mandate (Requirement 2.1) into the charter.
2. Confirm a ratified target architecture exists (Requirement 2.2). Express its key standards as
   `Standard,ExpectedValue` rows — this becomes the `Standards Baseline - Target Architecture -
   Approved` that `GWARB-Validation.ps1` reads.
3. If no target architecture is ratified, the board's first act is to adopt one; do not open
   conformance gates against an un-ratified standard.

## Step 2 — Configure: write the charter and decision rights
1. Draft the `ARB Charter - Transformation - Ratified`: purpose, scope (the five gates), the
   vendor/enterprise authority boundary (Requirement 2.4), meeting cadence, and the sponsor mandate.
2. Build the `Decision Rights Matrix - ARB - Program` — for each gate, who submits, who reviews, who
   votes, what quorum is, who may approve/reject, and the escalation path for a tie or a blocked
   decision. Distinguish **voting members** (quorum-bearing) from **advisory reviewers** (no vote).
3. Provision the two membership groups with `GWARB-Set-ScopeTargeting.ps1` (defaults to `-WhatIf`;
   review, then re-run with `-Confirm`). Record the returned group IDs in the charter.

## Step 3 — Configure: define the five review gates and their templates
1. Adopt the five standard gates: Migration Wave Plan, Identity & Sync Model, Security Configuration,
   Data-Migration Pattern, Work-Transformation Approach.
2. For each gate, create a `Submission Template - Design Review - Standard` variant capturing: design
   summary, the target-architecture standards it touches, alternatives considered, risks and rollback,
   the requested decision, and the declared attribute values the board will validate.
3. For each gate, create a `Review Checklist - <Gate Name> - Standard` — the specific conformance
   questions reviewers must answer (for example, for Identity & Sync: source of truth, provisioning
   mechanism, SSO model, coexistence handling).

## Step 4 — Configure: stand up the tracker and the register
1. Stand up the submission/decision tracker (Requirement 2.5) with the columns
   `GWARB-Discovery.ps1` reads: DesignId, Title, Gate, State, Workstream, DecisionRecordId,
   Submitted, Owner. A Microsoft List is convenient because the scripts read/write it via Graph.
2. Create the `Decision Register - Transformation ARB - Program-Wide` — one row per ADR, linking
   DesignId to its decision, rationale, conditions/exceptions, and owner.
3. Create the `Gap Register - Design Drift - Rolling` — where discovered-vs-approved drift is tracked
   and adjudicated.

## Step 5 — Pilot: run one governance cycle on a pilot workstream
1. Choose one workstream (for example, the identity workstream) as the pilot scope. Have it submit
   its real designs through the appropriate gates using the submission templates.
2. Convene the board at the cadence. For each submission, run the gate's review checklist, validate
   declared attributes against the `Standards Baseline` with `GWARB-Validation.ps1`, and record a
   decision: Approved, Approved with conditions (log the exception), or Rejected (rework).
3. Write an `Architecture Decision Record - <DesignId> - Dated` for every decision and link it in the
   register. No pilot design proceeds to build without an ADR.

## Step 6 — Run the drift-prevention loop on the pilot
1. `GWARB-Discovery.ps1` — inventory what the pilot workstream has actually submitted/built and its
   gate state, from the tracker.
2. `GWARB-Validation.ps1` — check declared/built attributes against the approved baseline; every
   Non-Conformant row is drift.
3. `GWARB-Report.ps1` — produce the Decision Register roll-up and the `Gap Register`, plus the KPI
   block.
4. `GWARB-Remediation.ps1` (defaults to `-WhatIf`) — open an owned, dated action for each gap; review
   the plan, then re-run with `-Confirm`. Each gap is closed by rework-to-standard or an approved
   exception.

## Step 7 — Validate: the pilot gate (GATE)
1. Confirm every pilot design has a decision and an ADR; the register and tracker reconcile.
2. Confirm the KPI set is populated: decisions logged, approval rate, open drift, time-in-gate,
   exception count.
3. Gate: do not expand the board program-wide until the pilot shows decisions are being **made and
   recorded** and time-in-gate is acceptable (governance is not the bottleneck). If designs pile up
   undecided, fix cadence/decision-rights before expanding.

## Step 8 — Expand: govern every workstream
1. Onboard the remaining workstreams and the delivery partner to the gates and templates; restate the
   authority boundary so vendor designs come through the board.
2. Run the full loop (Steps 5 to 6) every cadence cycle across all gates; keep the `Decision
   Register` and `Gap Register` current.
3. Report the `ARB KPI Set - Governance - Standard` to the sponsor each cycle; a falling open-drift
   trend and a stable time-in-gate prove the board is working.

---
### Order of operations
`Confirm mandate + baseline -> Charter + decision rights + groups -> Gates + submission/checklist
templates -> Tracker + registers -> Pilot governance cycle -> Drift-prevention loop -> Pilot gate ->
Expand program-wide`
