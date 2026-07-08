# 7. Best Practices — Microsoft Purview ISO 27001 Compliance Program

Field-tested practices for running an ISO 27001-aligned Purview program so the controls stay configured,
the evidence stays current, and the audit is defensible. These complement the Implementation and Testing
guides.

## Let the SoA drive the map — never the other way around
- Map **only the in-scope, applicable Annex A controls from the Statement of Applicability**. Do not
  reverse-engineer applicability from what Purview happens to do — applicability is the ISMS/risk
  function's determination, and mapping controls that aren't in scope wastes effort and confuses auditors.
- Be explicit about **what Purview does *not* cover** — organizational, people, and physical controls
  live outside this program. Marking them out-of-Purview is itself good evidence of scope discipline.
- Where Purview provides only **partial** evidence for a control, say "partial" — an auditor trusts a
  program that is honest about its boundaries far more than one that claims everything is met.

## Simulate/test before you enforce — always
- **Never** switch a new or materially changed **DLP, sensitivity-label, or retention** control straight
  to enforce. Run DLP in **simulation**, publish labels **non-mandatory** to a pilot ring, and apply
  retention to a **pilot scope** first — long enough to see real behaviour before expanding.
- Treat **simulation/test/non-mandatory** as your permanent safety switch: any enforced control reverts in
  one setting with no data change — this is your rollback.
- Roll DLP and label enforcement out **audit/tip-first**, then escalate to block/mandatory one
  control/category at a time, re-validating after each.

## Evidence is the product — automate its collection
- ISO auditors want **evidence with an owner, a date, and proof**. Run the delivered
  `ISO27001-ControlEvidence.ps1` on a **recurring cadence** so the register reflects the live technical
  state, not a one-time snapshot.
- Attach the exported evidence to the matching **Compliance Manager improvement action** and set **test
  status/date** — keep the assessment and the technical reality in lockstep.
- **Enable automatic testing** in Compliance Manager for eligible actions so technical controls
  self-update from Microsoft 365 signals — fewer manual re-checks, fresher evidence. Availability is
  plan/action-dependent — verify.
- **Turn on unified audit logging early** (Audit Premium where longer retention is needed). Audit data
  only accrues from the moment it is enabled — a late enablement is a permanent evidence gap for that
  period.

## Segregation of duties (A.5.3) — build it into roles
- Assign **Compliance Manager Administrators / Assessors / Contributors / Readers** least-privilege, and
  **separate** program administrators from action contributors from read-only auditors. The role
  separation is itself an auditable control — snapshot it (`ISO27001 Roles – Separation Evidence`).
- Do the same for the supporting controls: separate label/DLP/retention **authors** from **reviewers**
  where possible, and give oversight/audit **read-only** access.

## Classification, DLP, and retention hygiene
- Keep the **label taxonomy small and meaningful** (e.g. Public / Internal / Confidential / Highly
  Confidential) — a sprawling scheme users can't reason about undermines A.5.12/5.13.
- **Reuse built-in SITs** for DLP where they fit; tune confidence and instance counts so the data-leakage
  control (A.8.12) is low-noise — false positives erode trust in every control.
- Configure retention/disposition to the **records requirements** — but remember the **schedule and file
  plan are records/legal determinations**; use **disposition review** where records must be reviewed
  before deletion (A.5.33 / A.8.10).

## Insider Risk / Communication Compliance — privacy by design
- If you use insider-risk or communication-compliance signals as evidence for monitoring controls
  (A.8.16 / A.6.8), apply **privacy-by-design**: pseudonymize where the capability supports it, restrict
  access with **strict role separation**, and treat case **outcomes** as **HR/legal** determinations — the
  program provides the technical signal, not the verdict.

## Operate as a continual-improvement program (Clause 10)
- ISO 27001 is a **management system**, not a one-time build. Run a **recurring cadence**: re-test and
  re-evidence controls, review overdue improvement actions and owners, refresh the coverage report, and
  re-tune DLP/labels/retention as data and behaviour drift.
- **Watch for standard/template updates** — Annex A and the Compliance Manager ISO template evolve;
  re-map when they change.
- Keep a **change log** of every simulate→enforce transition and every control change, with the ISMS/
  compliance sign-off attached.

## Stay inside the boundary
- **Verify licensing/tenant** before relying on any premium template, endpoint/advanced DLP,
  auto-labeling, or Audit Premium capability — plans and portal paths evolve; don't assume a feature is
  present.
- Purview provides **configured controls and evidence** — **not** the risk assessment, the SoA, the
  management-system clauses, or the **certification**. Those are ISMS / risk / compliance /
  certification-body determinations. Deliver the control and the proof; let them own the decision.
