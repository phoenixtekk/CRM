# 3. Implementation Guide — Vendor Technical Governance & Anti-Lock-In Playbook

Follow these steps in order. The method is run by the enterprise architect; the scripts support the
inventory, validation, and reporting steps. Console references are to the Microsoft Entra admin
center (`https://entra.microsoft.com`) and the Google Admin console (`https://admin.google.com`)
where the source-environment recon touches them.

> Model: establish the register and the gate, adopt the anti-lock-in criteria and RACI, pilot the
> review method on one vendor design, validate that designs are dispositioned and conform, then
> expand the gate across every partner and workstream. Every design proceeds only by disposition.

## Step 1 — Stand up the vendor design register
1. Create a structured register (CSV or JSON) of every vendor deliverable and design in flight. Per
   entry record: `DesignId`, `Title`, `Owner` (which partner — keep it generic, e.g.
   "Integrator A" / "Platform vendor"), `Type` (integration pattern / migration approach /
   configuration design), `Status` (proposed / in-review / approved / rejected), and the four
   anti-lock-in fields the review will fill (`Portability`, `DataOwnership`, `StandardsConformance`,
   `ExitCriteria`).
2. Seed it from the current in-flight deliverables.
3. Run `GWVEND-Discovery.ps1` to enumerate the register and cross-check it against any
   vendor-created objects readable in the source Microsoft 365 / Entra environment. Save the output
   — it is your governance baseline.

## Step 2 — Establish the design-authority gate
1. Insert a mandatory gate into the delivery process: no vendor design proceeds to build until the
   enterprise architect has dispositioned it (Approved / Approved-with-conditions / Rejected).
2. Define the disposition record (the **Design Review Record**): design reviewed, criteria results,
   disposition, conditions, reviewer, date.
3. Communicate to every partner that the gate is a precondition for build, not an optional review.

## Step 3 — Adopt the Anti-Lock-In Criteria and RACI
1. Adopt the four-part **Anti-Lock-In Criteria** (below) as enterprise policy.
2. Adopt and sign the **Governance RACI** (below) with each partner at engagement start.
3. Publish both alongside the Target Architecture Baseline so partners design *to* the bar.

### The Anti-Lock-In Criteria (the fixed bar every design must pass)
| # | Criterion | What the design must demonstrate |
|---|---|---|
| 1 | **Portability** | Workloads, configuration, and integrations can be moved or rebuilt on an alternative without a proprietary rewrite; sanctioned/standard patterns are used over vendor-only shortcuts; no hard dependency on a single-vendor-only feature without a documented, accepted reason. |
| 2 | **Data ownership** | The enterprise owns the data and the schema; data is stored in open or documented formats; the enterprise can extract a complete, usable copy on demand — not just a vendor-gated export. |
| 3 | **Standards conformance** | Identity, integration, and data-exchange use open standards (e.g. SAML/OIDC/SCIM, documented APIs, standard file/data formats) rather than proprietary equivalents where a standard exists. |
| 4 | **Exit criteria** | A credible exit exists and is documented: how the workload would be migrated off, what the switching cost is, what data comes with it, and what contractual/technical dependencies would have to be unwound. A design with no articulable exit fails. |

A design that fails any criterion is **Rejected** or **Approved-with-conditions** (with the failing
criterion as the condition). "We'll deal with exit later" is a fail, not a pass.

### The Governance RACI (execution vs architectural authority)
| Decision / activity | Enterprise Architect | Program / Enterprise Owner | Vendor / Integrator |
|---|---|---|---|
| Define the Target Architecture Baseline | **A/R** | C | I |
| Set the Anti-Lock-In Criteria | **A/R** | C | I |
| Produce a vendor design | C | I | **A/R** |
| Validate assumptions behind a design | **A/R** | C | R |
| Disposition a design (gate sign-off) | **A/R** | C | I |
| Build/deliver an approved design | I | A | **R** |
| Grant a time-boxed exception | C | **A** | R |
| Escalate a rejected/blocked design | R | **A** | R |

Read the split plainly: **the enterprise architect is Accountable for architectural disposition;
the vendor is Responsible for execution.** Authority never sits in the "produce a design" or
"build" rows.

## Step 4 — The vendor-design review method (per design)
Run this for each design as it arrives:
1. **Log assumptions.** Extract the assumptions the design depends on into the **Vendor Assumption
   Log**; mark each validated / unvalidated / rejected. Do not let an unvalidated assumption pass
   into review as fact.
2. **Review against the baseline.** Compare the design to the Target Architecture Baseline —
   identity, integration pattern, data ownership, standards.
3. **Apply the Anti-Lock-In Criteria.** Score the design on all four criteria. Use
   `GWVEND-Validation.ps1` to score the register entry consistently and flag any missing/failing
   criterion.
4. **Challenge.** Where the design uses a proprietary shortcut, require the sanctioned/standard
   pattern or a documented, accepted reason. Where it assumes a default, require the assumption be
   validated.
5. **Disposition.** Record Approved / Approved-with-conditions / Rejected in the Design Review
   Record, with conditions. Only an Approved (or conditions-met) design proceeds to build.
6. **Report.** Run `GWVEND-Report.ps1` to produce the review/finding report for the design or the
   whole register.

## Step 5 — Pilot on a first design
1. Run the full Step 4 method on the pilot design.
2. Confirm the design is dispositioned, the criteria results are recorded, and any conditions are
   tracked to closure.
3. Confirm `GWVEND-Validation.ps1` and `GWVEND-Report.ps1` reflect the disposition. Complete the
   Testing Guide.

## Step 6 — Handle non-conformant designs (escalation)
1. A **Rejected** or blocked design goes to the escalation ladder (see §6 for the detailed
   handling):
   - Architect and vendor attempt resolution against the specific failing criterion.
   - If unresolved, the Program/Enterprise Owner arbitrates (RACI: Accountable for escalation).
   - A time-boxed **exception** may be granted (owner-accountable) — recorded, dated, and with a
     remediation commitment; it is not a silent waiver.
2. Track every exception to closure; an unclosed exception is standing lock-in debt.

## Step 7 — Validate governance is holding
1. Run `GWVEND-Validation.ps1` -> confirms every register entry has a disposition, no
   build-status design is missing a passed criterion, and no exception is past its close date.
2. Confirm the source-environment recon shows no vendor-created object that has no corresponding
   approved design. Complete the Testing Guide gates.

## Step 8 — Expand across all partners and workstreams
1. With the method proven on the pilot, make the gate mandatory for every partner and every
   workstream.
2. Put governance on a cadence: re-run `GWVEND-Discovery.ps1` and `GWVEND-Report.ps1` regularly so
   new designs and vendor-created objects are caught as they appear.
3. Run the **Vendor-Governance Runbook** (see §8) for each incoming design so the method is executed
   the same way regardless of which partner or architect is involved.

---
### Order of operations
`Register + gate -> criteria + RACI -> review method -> pilot -> escalation for non-conformance ->
validate -> expand`

### Rollback / reversibility
- The gate and criteria are process controls — they add a review step and change nothing in a live
  system, so "rollback" is simply relaxing a condition or granting a tracked exception, never a
  technical revert.
- The only script that writes is the scope helper (`GWVEND-Set-ScopeTargeting.ps1`), which creates
  reviewer/pilot groups and defaults to preview (`-WhatIf`); it creates empty groups only, which are
  trivially removed if not needed.
