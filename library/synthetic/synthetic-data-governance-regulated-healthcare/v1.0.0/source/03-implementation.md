# Implementation

Follow these steps in order. They realize the **Assess → Design → Generate/Build → Validate →
Expand** model, pilot-first, with explicit pass/fail gates and a defined rollback. Every artifact is
**named** with the `<Purpose> – <Scope> – <Stage>` convention and that exact name is reused in later
steps, testing, troubleshooting, and the scripts.

All governance registers are **JSON-backed, metadata-only** files stored in the
`Governance Register Store – Enterprise – v1` (Requirement R4). They never hold asset payloads and
never real PHI. The five Python tools are referenced by name; each is safe-by-default (dry-run where
it writes) — see `08-deliverables-summary.md` for the full list.

---

## Phase 0 — Confirm prerequisites

1. Verify the six category requirements (`global-requirements-synthetic.md`) and the five
   solution-specific requirements (`02-requirements.md`) are met. In particular confirm you have:
   `Declared Control Set – Enterprise – v1` (R1), `Classification Scheme – Enterprise – v1` (R2),
   `Governance Roles – Enterprise – v1` (R3), `Governance Register Store – Enterprise – v1` (R4),
   and an asset inventory hook (R5).
2. Confirm the **pilot scope**: one named pilot service line (e.g. `a pilot service line`) and the
   set of synthetic/test assets it uses. Everything in Phases 1–4 is scoped to this pilot.

---

## Phase 1 — Assess (establish the readiness baseline)

3. Obtain a **metadata-only inventory** of existing synthetic/test assets (R5) as a JSON or CSV of
   asset id/path, environment, and any known origin. No payloads.
4. Run the **governance readiness assessment** tool (`assess_governance_readiness.py`) against that
   inventory and against the presence/absence of policy, roles, classification scheme, and control
   set. It emits the **Synthetic Data Governance – Enterprise – Readiness** report: counts of assets
   with no lineage, no classification, and no approval, plus which governance foundations exist.
5. Review the readiness report with the data-governance and privacy stakeholders. This baseline is
   the "before" evidence and sets the expansion backlog.

**Gate G1 (Assess):** a readiness baseline exists and has been reviewed. *Pass* = report produced
and the shadow-asset count and foundation gaps are agreed. *Fail* = no inventory or no stakeholder
review — stop and resolve before Design.

---

## Phase 2 — Design (policy, scheme, roles, control mapping)

6. Author the **Synthetic Data Governance Policy – Enterprise – v1**: scope (what counts as a
   governed synthetic/test asset), the roles from `Governance Roles – Enterprise – v1`, the
   classification scheme reference, and the rules for approval, access, retention, and disposal.
7. Finalize the **Classification Scheme – Enterprise – v1** (R2) with a handling rule per value
   (allowed environments, access, retention). Keep it to 3–5 values.
8. Build the **Governance Control Map – Enterprise – v1**: for each control in
   `Declared Control Set – Enterprise – v1` (R1), record which governance control this solution
   operates that maps to it, and the evidence artifact that demonstrates it (e.g. "approval records
   in the approval log"). Where no governance control maps, mark it `not-addressed` — do **not**
   claim alignment you cannot evidence. Interpretation of sufficiency is deferred to compliance.
9. Use the **scope/config helper** tool (`syngov_config.py`) to generate the starter register files
   (empty catalog, empty approval log, and the control-map skeleton seeded from the declared control
   set) into the `Governance Register Store – Enterprise – v1`. Run it in `--dry-run` first to
   preview, then `--commit`.

**Gate G2 (Design):** policy, classification scheme, roles, and control map exist and are reviewed
by privacy/compliance. *Pass* = all four artifacts approved. *Fail* = any missing or unreviewed —
resolve before building.

---

## Phase 3 — Generate/Build (catalog, classify, approve, access)

10. Stand up the **Synthetic Asset Catalog – Enterprise – v1** using the catalog/lineage register
    tool (`asset_catalog_register.py`). For each **pilot** asset, register a record capturing: asset
    id, target model (FHIR/OMOP/native), environment, generator/source, **parent asset** (lineage),
    reference statistics used (if any), and steward. Run `--dry-run` to preview each write, then
    `--commit`.
11. **Classify** each pilot asset against `Classification Scheme – Enterprise – v1` using the
    classification + approval tracker (`classify_approve_tracker.py classify ...`). Classification is
    a **stewarded decision** — the steward supplies the value; the tool records who, when, and why.
12. **Route approvals**: for each pilot asset a consumer needs, record an approval **request**
    (requester, purpose, asset, target environment), then the reviewer's **decision** (approve /
    reject, with reviewer name and date) using `classify_approve_tracker.py request` and
    `... decide`. Requester and approver must differ (R3). Only assets with an `approved` record may
    move to a shared AI/QA environment.
13. **Apply the access model**: from the classification and approval records, produce the access
    matrix (which classification is allowed in which environment for which consumer role) and apply
    it in the environment's existing access-control mechanism. The tools produce the *evidence*; the
    enforcement is your platform's IAM — verify against your platform's documentation.

**Gate G3 (Build):** every pilot asset is cataloged with lineage, classified, and — where consumed —
approved, with access aligned. *Pass* = zero pilot assets missing lineage, classification, or (if
consumed) an approval. *Fail* = any gap — do not proceed to Validate.

---

## Phase 4 — Validate (run the governance gates on the pilot)

14. Run the **coverage/gate report** (`control_compliance_check.py coverage`) over the pilot catalog
    and approval log. It reports, per pilot asset: lineage present, classification present, approval
    present (if consumed), and access aligned — with an overall pass/fail per gate.
15. Run the **policy/control compliance checker** (`control_compliance_check.py controls`) against
    `Governance Control Map – Enterprise – v1` and `Declared Control Set – Enterprise – v1`. It emits
    an evidence view: each declared control marked `in-place`, `partial`, or `not-addressed`, with
    the mapped governance control and evidence artifact. **This is evidence for compliance to
    interpret — it is not a compliance determination.**
16. Review both outputs with privacy/compliance. Record the review as the pilot's validation
    evidence.

**Gate G4 (Validate):** the pilot passes the governance gates (lineage/classification/approval/
access) and the control evidence view has been reviewed. *Pass* = coverage report all-pass on the
pilot and control evidence reviewed. *Fail* = any gate red — **roll back**: pull un-approved or
misclassified assets from shared environments, hold the release, resolve the finding, and re-run
Phase 4.

---

## Phase 5 — Expand (widen coverage, carry the gates)

17. With the pilot passed, extend the **Synthetic Asset Catalog – Enterprise – v1**, classification,
    and approval workflow to the next service line and asset type from the expansion backlog (Step
    5). Reuse the same tools and the same gates (G3, G4) for each new scope.
18. Re-run the readiness assessment (`assess_governance_readiness.py`) periodically against the full
    inventory to show the shadow-asset count trending down — the durable measure that governance is
    winning.
19. Keep the registers current: new asset ⇒ catalog + classify + approve before shared use; retired
    asset ⇒ mark disposed per the policy's retention rule. Governance is continuous, not a one-time
    project.

---

## Rollback (applies at every gate)

If any gate fails, the release is **held**. Un-approved or misclassified assets are removed from
shared AI/QA environments, the finding is recorded against the asset in the catalog, and the phase
is re-run once resolved. No governed asset reaches a shared environment on a failed gate.
