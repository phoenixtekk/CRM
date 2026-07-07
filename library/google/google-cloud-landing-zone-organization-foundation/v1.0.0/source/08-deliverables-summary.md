# Deliverables Summary

This solution delivers a complete, run-to-implement package for standing up an enterprise Google
Cloud landing zone — the governed foundation every later workload lands on.

## Documentation

- **Solution Overview** — what the landing zone is, the reference design (resource hierarchy, org
  policies, IAM baseline, centralized logging, billing export, Shared VPC, naming/labeling), benefits,
  limitations, and the Assess → Design → Configure → Pilot → Validate → Expand deployment model.
- **Requirements Guide** — the six shared GCP prerequisites plus six solution-specific ones (seed
  project & CI identity, org/billing/domain IDs, the approved hierarchy/naming design, Cloud Identity
  groups, required APIs, and a named pilot scope with a rollback owner) — each with how to verify and
  how to implement.
- **Implementation Guide** — exact ordered steps to build the folder/project hierarchy, apply
  `Org Policy Baseline – Org – v1` (pilot-first), set the group-based IAM baseline, wire the
  aggregated audit-log sink and BigQuery billing export, and stand up the Shared VPC — with named
  artifacts, pass/fail gates, and a documented rollback.
- **Testing & Validation** — eight procedures (hierarchy, guardrails enforced, group-only IAM, logs
  flowing, Shared VPC usable, billing export populated, naming conformance, full report) each with
  its expected pass/fail signal.
- **Best Practices** — durable practices for hierarchy, guardrails, IAM, logging/cost, networking,
  and change management as workloads onboard.
- **Troubleshooting** — common failure modes and resolutions.
- **Executive Summary** — the outcome, approach, and why it is safe and governed.

## The 5 Python tools (`scripts/`)

All are **safe-by-default** — read-only, or dry-run unless `--apply` is passed — use Application
Default Credentials / the environment (no hardcoded credentials, no exported keys, no secrets in
code), and expose `--help`.

1. **`gcp_org_assessment.py`** — *Assessment / discovery (read-only).* Enumerates the Organization's
   folders, projects, existing org policies, billing linkage, and top-level IAM, and writes a
   baseline inventory report. The starting point for Stage 1 — Assess.

2. **`gcp_hierarchy_provisioner.py`** — *Hierarchy & project provisioner (dry-run default).* Reads a
   hierarchy plan and creates the named folders and foundation projects (`Logging – Common – Prod`,
   `Billing-Export – Common – Prod`, `Networking-Host – Shared-VPC – Prod`, `Bootstrap – Seed –
   Prod`), links billing, and records a change log for rollback. Prints the plan and changes nothing
   unless `--apply` is passed.

3. **`gcp_org_policy_guardrails.py`** — *Org-policy guardrail applier (dry-run default).* Applies the
   `Org Policy Baseline – Org – v1` constraint set to a given scope (pilot folder first, then the
   Organization), diffing current vs desired and enforcing only on `--apply`. Constraint names are
   flagged to verify against the current reference for your organization.

4. **`gcp_landing_zone_validate.py`** — *Validation / report generator (read-only).* Checks all the
   gates — hierarchy present, guardrails enforced, IAM baseline group-only, org audit sink writing,
   billing export populated, Shared VPC attachable — and emits an HTML report with a per-check
   PASS/FAIL. This is the Stage 5 gate to Expand.

5. **`gcp_naming_label_helper.py`** — *Naming/label config helper (read-only).* Emits the
   `<Purpose> – <Scope> – <Stage>` name grammar and the `env`/`owner`/`cost-center`/`data-class`
   label standard, and validates candidate names/labels (or scans the Organization) against it — so
   non-conforming resources are caught in Design and in CI.
