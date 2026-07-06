# Troubleshooting

Common failure modes when standing up and operating synthetic data governance, with resolutions.
Symptoms are grouped by phase. All tools are safe-by-default (dry-run where they write); when in
doubt, re-run without `--commit` to preview.

> **Boundary reminder.** These resolutions fix the governance **method and evidence**. They never
> substitute for a privacy/compliance/legal determination on HIPAA/HITRUST de-identification,
> disclosure risk, or control sufficiency.

---

## Assess

**Symptom: `assess_governance_readiness.py` reports 0 assets.**
- *Cause:* the inventory JSON is empty, or the assets are under a key the tool does not read.
- *Resolution:* the tool accepts a bare list or `{"assets": [...]}`. Confirm the inventory has an
  `assets` array (or is a top-level list) with one object per asset. It is metadata-only — no
  payloads needed.

**Symptom: everything shows as "no lineage" even for assets you know the origin of.**
- *Cause:* lineage is read from an asset's `generator` or `source` field; the inventory export uses a
  different field name.
- *Resolution:* map the export to include `generator` (or `source`) per asset before assessing. The
  assessment's whole point is to surface the shadow assets that genuinely lack a recorded origin —
  don't mask real gaps, but do fix field-name mismatches.

## Design

**Symptom: `syngov_config.py validate` fails "scheme has N values (keep it to 3-5)".**
- *Cause:* the classification scheme is too large or too small.
- *Resolution:* collapse the scheme to 3–5 values with clear handling rules. A sprawling taxonomy
  becomes inconsistent in practice (see Best Practices). If you genuinely need more, that is a policy
  decision — but validate the tradeoff first.

**Symptom: `syngov_config.py validate` fails a classification "has no handling_rule".**
- *Cause:* a scheme value lacks a `handling_rule` (allowed environments/access/retention).
- *Resolution:* add a handling rule to every value. Classification without a handling rule cannot
  drive access, which defeats its purpose.

**Symptom: `syngov_config.py scaffold` says `[skip]` for a file you wanted created.**
- *Cause:* the register already exists — scaffold never overwrites, by design (it must not clobber a
  live catalog or approval log).
- *Resolution:* this is expected and safe. To re-seed a register, move the existing file aside first,
  then re-run scaffold.

**Symptom: the control map is seeded but every control is `not-addressed`.**
- *Cause:* that is the honest default — scaffold seeds from the declared control set with no mappings
  claimed.
- *Resolution:* the steward fills in `governance_control` and `evidence` and sets `status` to
  `in-place`/`partial` only where a real governance control and evidence artifact exist. Never mass-
  set to `in-place` to "look done"; the compliance checker will flag `in-place` with no evidence.

## Build

**Symptom: `asset_catalog_register.py` errors "an asset needs an origin".**
- *Cause:* neither `--generator` nor `--source` was supplied — the asset would have no lineage.
- *Resolution:* supply the generating tool/pattern (`--generator`) or the source system
  (`--source`). An asset with no origin is a finding, so the tool refuses to register one.

**Symptom: registering a derived asset warns "parent … is not in the catalog".**
- *Cause:* the `--parent` id has not been registered yet — lineage would be broken.
- *Resolution:* register the parent asset first, then the child. Lineage is the spine; a dangling
  parent reference is exactly what governance exists to prevent.

**Symptom: `classify_approve_tracker.py classify` rejects the value.**
- *Cause:* the value is not in `Classification Scheme – Enterprise – v1`.
- *Resolution:* use an agreed scheme value. If the asset genuinely needs a new category, that is a
  scheme change (a stewarded/policy decision), not a per-asset override.

**Symptom: `decide` errors "requester and approver must differ".**
- *Cause:* the reviewer is the same person who requested the asset — a self-approval.
- *Resolution:* route the decision to a different reviewer (separation of duties, R3). This guard is
  intentional and should not be worked around.

**Symptom: `decide` errors "no open approval request".**
- *Cause:* no `request` was recorded for that asset (or the last one is already decided).
- *Resolution:* run `classify_approve_tracker.py request …` first, then `decide`.

## Validate

**Symptom: `control_compliance_check.py coverage` shows an asset FAIL on approval though it looks
approved.**
- *Cause:* the asset is marked `consumed_in_shared` but has no `approved` decision, or the approval's
  `target_env` does not match the asset's environment.
- *Resolution:* record (or complete) the approval for the correct target environment. Approval is
  required only for assets consumed in a shared environment — if it is not actually consumed there,
  unset `--consumed-in-shared` on the catalog record.

**Symptom: coverage shows an access FAIL.**
- *Cause:* a consumed asset has no approval matching its environment — access is not evidenced as
  aligned.
- *Resolution:* approve the asset for that environment, or (rollback) pull it from the shared
  environment until approved. Then re-run coverage.

**Symptom: `controls` reports "in-place w/o evidence".**
- *Cause:* a mapping claims `status: in-place` but has no `evidence` artifact.
- *Resolution:* add the evidence artifact reference (e.g. "approval records in the approval log") or
  downgrade the status to `partial`/`not-addressed`. An unbacked `in-place` claim will not survive an
  audit — honesty here is the whole value.

**Symptom: `controls` reports "UNRESOLVED" for a declared control.**
- *Cause:* the declared control has no entry in the control map (id mismatch, or missing mapping).
- *Resolution:* add a mapping for that control id (even if `not-addressed`). Every declared control
  must resolve to a status; a missing one is a hole in the evidence view.

## Operate / Expand

**Symptom: the shadow-asset count is not falling across readiness runs.**
- *Cause:* new assets are entering shared environments without being cataloged/classified/approved —
  the governance gate is being bypassed.
- *Resolution:* enforce "catalog + classify + approve before shared use" at the platform level
  (access model), not just in policy. Investigate how ungoverned assets are reaching shared
  environments and close that path.

**Symptom: approvals route to someone who has left the team.**
- *Cause:* `Governance Roles – Enterprise – v1` is stale after a reorg.
- *Resolution:* re-confirm role holders on a set cadence and update the roles config. Validate again
  with `syngov_config.py validate`.
