# Deliverables Summary

What the buyer gets — a complete, self-guided package to establish synthetic data governance for
regulated healthcare, aligned to HIPAA/HITRUST + enterprise data governance. Regulatory
interpretation is deferred to your privacy, compliance, and legal functions; this package delivers
the governance **method and evidence**.

## Documentation

- **Solution Overview** (`01-solution-overview.md`) — the six-component governance model (policy &
  roles, catalog & lineage, classification, approval workflow, access model, controls & alignment)
  and the Assess → Design → Generate/Build → Validate → Expand deployment model.
- **Requirements Guide** (`02-requirements.md`) — the solution-specific prerequisites (declared
  control set, classification scheme, governance roles, register store, inventory hook), each with
  how to verify and how to implement if missing, on top of the six category-wide requirements.
- **Implementation Guide** (`03-implementation.md`) — exact, ordered steps through all five phases,
  every artifact named, with the four pass/fail gates and a rollback.
- **Testing & Validation** (`05-testing.md`) — eight procedures (T1–T8) mapping to the gates, each
  with an explicit pass/fail signal, and the overall pilot pass criteria.
- **Troubleshooting** (`06-troubleshooting.md`) — common failure modes and resolutions.
- **Best Practices** (`07-best-practices.md`) — durable governance, boundary, register, and scale
  practices.
- **Executive Summary** (`executive-summary.md`) — the outcome, approach, and why it is safe.

## The 5 Python tools

All tools are Python 3.10+ standard-library-first, safe-by-default (dry-run where they write, never
real PHI, no invented network calls), and self-documenting via `--help`. They read and write the
JSON-backed, metadata-only governance registers.

1. **`assess_governance_readiness.py`** — *Governance readiness assessment.* Profiles a metadata-only
   asset inventory plus the governance-foundation flags and emits the **Synthetic Data Governance –
   Enterprise – Readiness** report: how many assets have no lineage, no classification, and no
   approval, and which foundations (policy/roles/scheme/control-set) exist. The "before" baseline and
   the trend metric.
2. **`asset_catalog_register.py`** — *Synthetic-asset catalog & lineage register.* Registers each
   governed synthetic/test asset into the **Synthetic Asset Catalog – Enterprise – v1** (JSON-backed)
   with id, target model, environment, generator/source, **parent asset** (lineage), reference stats
   used, and steward. Dry-run by default; `--commit` to write. Lists and queries the catalog.
3. **`classify_approve_tracker.py`** — *Classification & approval tracker.* Records the stewarded
   classification of each asset (against the scheme) and drives the approval workflow — `request`
   (requester/purpose/target env), `decide` (approve/reject, reviewer, date), enforcing
   requester ≠ approver — into the JSON classification/approval log. Dry-run by default;
   `--commit` to write.
4. **`control_compliance_check.py`** — *Policy/control compliance checker.* Maps the governance
   controls this solution operates against the org's **declared control set**, marking each control
   `in-place`, `partial`, or `not-addressed` with the mapped control and evidence artifact. Emits
   **evidence for compliance to interpret — not a compliance determination.** (Doubles as the
   governance coverage/gate report over catalog + approval log.)
5. **`syngov_config.py`** — *Scope & config helper.* Generates the starter register files (empty
   catalog, empty classification/approval log, control-map skeleton seeded from the declared control
   set), validates the classification scheme and roles config, and scaffolds the
   `Governance Register Store – Enterprise – v1` layout. Dry-run by default; `--commit` to write.

## Register artifacts (you produce these)

- `Synthetic Data Governance Policy – Enterprise – v1`
- `Classification Scheme – Enterprise – v1`
- `Governance Roles – Enterprise – v1`
- `Declared Control Set – Enterprise – v1` (input from compliance)
- `Governance Control Map – Enterprise – v1`
- `Synthetic Asset Catalog – Enterprise – v1`
- `Synthetic Data Governance – Enterprise – Readiness` (the assessment report)
