# Best Practices

Durable practices for operating synthetic data governance in a regulated healthcare enterprise.

## Governance discipline

- **Lineage is the spine — an asset with no origin is a finding.** Never let a synthetic/test asset
  enter a shared environment without a catalog record naming its generator/source and, if derived,
  its parent asset. "We're not sure where this came from" is exactly the shadow risk this solution
  exists to kill.
- **Classify before you share, not after.** Classification drives access and the controls that
  apply. An unclassified asset is ungoverned by definition; block it from shared use until a steward
  records a classification value from `Classification Scheme – Enterprise – v1`.
- **Approval is a recorded human decision, never a default.** Every release to a shared AI/QA
  environment carries an approval record with a distinct requester and approver, a purpose, and a
  date. Self-approval is not approval.
- **Keep the classification scheme small.** 3–5 values with clear handling rules beat a sprawling
  taxonomy nobody applies consistently. Complexity in the scheme becomes inconsistency in practice.

## Keep the boundary bright

- **Deliver method and evidence — defer the determination.** Produce the catalog, classification,
  approval, and control-evidence artifacts; let privacy/compliance/legal decide HIPAA/HITRUST
  de-identification adequacy, disclosure-risk acceptance, and control sufficiency. Never let a tool's
  green output be read as a compliance sign-off.
- **The declared control set is authoritative — do not edit it to look better.** Map honestly. Mark
  unaddressed controls `not-addressed`; a truthful gap is more valuable than a hidden one, and an
  overstated `in-place` will fail an audit.
- **Never real PHI into a shared harness/twin/AI test environment.** Governance records are
  metadata-only. Where real data must inform fidelity, it is read-only, minimized, and under the
  privacy controls — and the asset that touched it carries the `contains-minimized-real` (or your
  scheme's equivalent) classification with the stricter handling rule.

## Registers & evidence

- **Metadata-only, version-controlled, access-controlled.** The registers hold no payloads and no
  PHI. Store them where changes are tracked and approval records cannot be silently altered — the
  audit trail *is* the value.
- **One source of truth per register.** Catalog, classification/approval log, and control map are
  the authoritative copies. Integrate with an enterprise data catalog if one exists rather than
  forking a second truth.
- **Dry-run first, commit second.** Every tool that writes defaults to dry-run. Preview the change,
  confirm it, then `--commit`. This is habit, not ceremony — it prevents a fat-fingered approval.

## Process & scale

- **Pilot-first, always.** Prove the full gate set (lineage → classification → approval → access →
  control evidence) on one service line before expanding. A pattern that passes a pilot scales; one
  that skips the pilot multiplies unproven risk.
- **Watch the shadow-asset count trend.** Re-run the readiness assessment periodically against the
  full inventory. A falling count of assets-with-no-lineage/classification/approval is the durable
  proof governance is working; a rising one is an early warning.
- **Requester ≠ approver, enforced.** Bake separation of duties into the approval tool and the
  reviewers' expectations, not just the policy PDF.
- **Retire assets on purpose.** Apply the policy's retention/disposal rule; mark disposed assets in
  the catalog. An accumulating pile of stale "test" datasets is future shadow risk.
- **Review roles when the org changes.** Owner/steward/reviewer/consumer assignments drift with
  reorgs. Re-confirm `Governance Roles – Enterprise – v1` on a set cadence so approvals never route
  to someone who has moved on.
