# 8. Deliverables Summary — Google Cloud IAM & Least-Privilege Governance

Everything included in this solution, on one page.

## Documentation
- **01 — Solution Overview.** The Cloud IAM governance model: principals (groups + service accounts),
  predefined vs custom roles, binding at the right hierarchy level, Workload Identity Federation,
  IAM-restricting org policies, and the review cadence — plus the reference design and deployment model.
- **02 — Requirements.** Solution-specific prerequisites (org-admin IAM roles, Google Groups as source
  of truth, workload/federation inventory, pilot scope, required APIs, ADC), each with verify /
  implement-if-missing — building on the shared `global-requirements-gcp.md`.
- **03 — Implementation.** Exact ordered steps: Assess → Design → Configure → Pilot → Validate → Expand,
  every artifact named (`IAM Governance – Pilot`, `IAM Guardrails – Org – v1`, `WIF Pool – Pilot – v1`),
  with pass/fail gates and a documented rollback.
- **05 — Testing.** Eight validation tests with expected pass/fail (no primitive grants, group-based
  access, keys un-creatable, exported keys gone, workload on WIF, Domain-Restricted Sharing, reference
  assertion, access-review report).
- **06 — Troubleshooting.** Common failure modes and resolutions (locked-out access, guardrail not
  enforcing, WIF token exchange, Recommender empty, custom-role permission errors, key still creatable).
- **07 — Best Practices.** Durable practices for roles, principals, killing exported keys, guardrails,
  the review cadence, and tooling discipline.
- **Executive Summary.** The outcome, approach, and why it is safe and governed, for decision-makers.

## The 5 Python tools (`gcloud` / Cloud Client Libraries; read-only or `--dry-run` by default)
1. **`GCPIAM-Assess.py`** — *IAM-posture assessment (read-only).* Inventories primitive-role grants,
   user-managed (exportable) service-account keys, external principals, and role sprawl across the
   Organization/folder/project; writes the baseline used for rollback and validation.
2. **`GCPIAM-RoleDesigner.py`** — *Custom-role designer/applier (dry-run default).* Validates a proposed
   custom role's permissions and prints the plan; creates/updates the Organization-level custom role only
   with `--apply`.
3. **`GCPIAM-WIFSetup.py`** — *Workload Identity Federation setup helper (dry-run default).* Plans and
   (with `--apply`) creates a WIF pool + OIDC/AWS provider and the SA impersonation binding, then prints
   the workload-side config — so exported keys can be retired.
4. **`GCPIAM-Review.py`** — *Access-review report generator (read-only).* Pulls IAM Recommender
   (unused / over-granted roles) and Policy Analyzer, and emits a per-binding CSV for owner attestation.
5. **`GCPIAM-PolicyCheck.py`** — *Org-policy guardrail check & reference-design assertion (dry-run
   default).* Reads/sets IAM-restricting org-policy constraints (dry-run → enforce) and asserts the
   reference-design invariants hold on a scope.

**Safety:** every tool authenticates via **Application Default Credentials** (no key files), is
**read-only or `--dry-run` unless `--apply`** is passed, and contains **no hardcoded credentials, keys,
or secrets**.
