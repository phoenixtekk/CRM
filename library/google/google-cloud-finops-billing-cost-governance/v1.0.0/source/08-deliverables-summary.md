# Deliverables Summary

This solution delivers a complete, self-guided FinOps package for Google Cloud: the documentation
to stand the model up and run it, plus five Python/`gcloud` tools that automate discovery,
provisioning, reporting, guardrail validation, and savings analysis — all safe-by-default
(read-only or `--dry-run` unless `--apply` is passed), with no credentials or keys in code.

## Documentation

- **Solution Overview** — the FinOps model (billing export, attribution by hierarchy/label,
  budgets/alerts, CUD/rightsizing optimization, showback/chargeback), the reference design, benefits,
  limitations, and the Assess → Design → Configure → Pilot → Validate → Expand deployment model.
- **Requirements Guide** — the FinOps-specific prerequisites (billing-admin access, a dedicated
  export project + BigQuery dataset, a labeling convention with measurable coverage, the Recommender
  API, a budget notification channel, a pilot scope and FinOps owner), each with how to verify and
  implement, building on the shared GCP global requirements.
- **Implementation Guide** — exact, ordered steps to enable billing export to BigQuery, build
  attribution views, provision budgets/alerts (pilot-first), stand up the showback dashboard,
  identify savings, and expand org-wide — with named artifacts, pass/fail gates, and a rollback.
- **Testing & Validation** — nine procedures (T1–T9), each with an explicit PASS/FAIL signal.
- **Troubleshooting** — common failure modes (export not appearing, view/total mismatches, alerts not
  firing, recommender permission errors) and their resolutions.
- **Best Practices** — durable practices for keeping attribution accurate, budgets useful, tooling
  safe, optimization governed, and FinOps running as an operating rhythm.
- **Executive Summary** — the outcome, approach, and why it is safe and governed.

## Python tools (5)

All tools require Python 3.10+ and authenticate via `gcloud` / Application Default Credentials
(`gcloud auth application-default login`). No service-account keys are created, downloaded, or
committed. Where a Cloud Client Library is used, the file notes the `pip install` package.

1. **`finops-discovery.py`** — *Assessment / discovery (read-only).* Inventories the billing account,
   its linked projects, whether detailed billing export is configured, existing budgets and their
   thresholds, the resource hierarchy (org → folders → projects), and the labeling keys present.
   Produces the Assess baseline. Never changes anything.

2. **`finops-budget-provisioner.py`** — *Configuration / provisioning helper (dry-run by default).*
   Creates (or deletes) Cloud Billing budgets with alert threshold rules and a Pub/Sub/email
   notification target, scoped to projects, a folder, a label, or all projects. Prints the plan and
   changes nothing unless `--apply` is passed; `--delete` removes only the named budget.

3. **`finops-report.py`** — *Validation / report generator.* Emits and (with `--apply`) creates the
   BigQuery attribution views (`FinOps – Attribution Views – v1`) — cost by project, label, and
   service — and reports the **unattributed-spend %** with the top unattributed projects/services for
   showback and remediation.

4. **`finops-guardrail-check.py`** — *Policy / guardrail check (read-only).* Validates the FinOps
   posture against the gates: export flowing (recent rows), budgets present with expected thresholds
   and a live notification target, attribution views resolving, and unattributed spend below target.
   Exits non-zero if any check fails, for use in CI or a scheduled compliance run.

5. **`finops-scope-helper.py`** — *Scope / config helper.* Resolves and validates the FinOps scope —
   the billing account, the export project/dataset, the pilot vs. org project sets from the resource
   hierarchy, and the required label keys — and writes a normalized `finops-scope.json` the other
   tools can consume, so the scope is defined once and reused consistently. Read-only.
