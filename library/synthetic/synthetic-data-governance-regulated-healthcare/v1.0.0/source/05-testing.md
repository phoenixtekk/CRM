# Testing & Validation

These procedures validate that synthetic data governance is actually operating — not just
documented. They map to the gates in `03-implementation.md` and use the five delivered Python tools.
Each test states its **expected pass/fail** signal. Run them on the named pilot before Expand, and
re-run the relevant ones whenever the registers change.

> **Boundary reminder.** These tests validate the **governance method and its evidence** —
> completeness of lineage, classification, approval, access, and control mapping. They do **not**
> determine HIPAA/HITRUST compliance, de-identification adequacy, or disclosure-risk acceptability;
> those remain with your privacy, compliance, and legal functions.

---

## T1 — Readiness baseline is produced (Gate G1)

- **Procedure:** Run `assess_governance_readiness.py` against the metadata-only asset inventory and
  the governance-foundation flags (policy/roles/scheme/control-set present or not). Confirm it emits
  the **Synthetic Data Governance – Enterprise – Readiness** report.
- **Expected pass:** A report is produced showing counts of assets with no lineage, no
  classification, and no approval, plus which foundations exist. Stakeholders have reviewed it.
- **Fail:** No inventory available, tool errors, or no review. Resolve before Design.

## T2 — Design artifacts exist and are reviewed (Gate G2)

- **Procedure:** Confirm `Synthetic Data Governance Policy – Enterprise – v1`,
  `Classification Scheme – Enterprise – v1`, `Governance Roles – Enterprise – v1`, and
  `Governance Control Map – Enterprise – v1` all exist and carry a privacy/compliance review note.
  Confirm `syngov_config.py --commit` created the starter registers in the store.
- **Expected pass:** All four artifacts present and reviewed; the empty catalog, empty approval log,
  and control-map skeleton exist in `Governance Register Store – Enterprise – v1`.
- **Fail:** Any artifact missing or unreviewed, or the starter registers absent.

## T3 — Every pilot asset has lineage (catalog completeness)

- **Procedure:** Run `control_compliance_check.py coverage` over `Synthetic Asset Catalog – Enterprise – v1`
  restricted to the pilot. Inspect the `lineage` column: each pilot asset must record a
  generator/source and, where derived, a `parent asset`.
- **Expected pass:** 100% of pilot assets have a recorded origin; derived assets record a parent.
  The report's lineage gate = **PASS**.
- **Fail:** Any pilot asset with no recorded origin. Fix in the catalog, re-run.

## T4 — Every pilot asset is classified (classification completeness)

- **Procedure:** In the same coverage report, inspect `classification`. Each value must be one of
  `Classification Scheme – Enterprise – v1` and carry a stewarded record (who/when/why) in the
  classification log.
- **Expected pass:** 100% of pilot assets classified with a valid scheme value and a stewarded
  record. Classification gate = **PASS**.
- **Fail:** Any asset unclassified or carrying a value outside the scheme.

## T5 — Approval is enforced before shared use (approval integrity)

- **Procedure:** For each pilot asset that a consumer uses in a shared AI/QA environment, confirm the
  approval log has an `approved` decision with a **requester ≠ approver**, a purpose, the target
  environment, a named reviewer, and a date. Attempt (in dry-run) to mark an asset consumable that
  has no approval and confirm the coverage report flags it.
- **Expected pass:** Every consumed pilot asset has a valid `approved` record; any consumed asset
  lacking one is flagged red. Approval gate = **PASS**. Requester and approver are never the same
  person.
- **Fail:** A consumed asset with no approval, a self-approval, or an approval missing required
  fields.

## T6 — Access is aligned to classification (access model)

- **Procedure:** Compare the access matrix produced from classification+approval against the actual
  environment access configuration. Confirm no asset of a higher classification is reachable in a
  lower-controlled environment than its handling rule allows.
- **Expected pass:** Every asset's effective access matches its classification's handling rule; no
  higher-classification asset in a disallowed environment. Access gate = **PASS**.
- **Fail:** Any misaligned access. Roll back the asset from the environment and correct.

## T7 — Control evidence view is complete and honest (control mapping)

- **Procedure:** Run `control_compliance_check.py` against `Governance Control Map – Enterprise – v1`
  and `Declared Control Set – Enterprise – v1`. Confirm every declared control resolves to
  `in-place`, `partial`, or `not-addressed`, each with a mapped governance control and an evidence
  artifact reference (or an explicit `none`).
- **Expected pass:** No declared control is left unresolved; `in-place` controls each cite an
  evidence artifact that actually exists in the registers; unaddressed controls are honestly marked
  `not-addressed` (not silently claimed). The output is labeled **evidence for compliance to
  interpret**.
- **Fail:** A declared control with no status, an `in-place` claim with no backing evidence, or a
  gap hidden as addressed.

## T8 — Rollback works

- **Procedure:** Simulate a failed gate: mark a pilot asset misclassified (dry-run) and confirm the
  documented rollback pulls it from the shared environment list, records the finding against the
  asset, and holds the release until resolved.
- **Expected pass:** The asset is removed from shared-environment eligibility, the finding is
  recorded, and the coverage report shows the release held.
- **Fail:** The asset remains eligible after a failed gate, or no finding is recorded.

---

## Overall pilot pass criteria

The pilot **passes** and may proceed to Expand only when T1–T8 all pass: readiness baselined, design
artifacts reviewed, and the pilot catalog shows **100% lineage, 100% classification, enforced
approval, aligned access**, with a complete, honest control-evidence view reviewed by
privacy/compliance and a demonstrated rollback.
