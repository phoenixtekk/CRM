# Executive Summary

Cloud spend without FinOps becomes a surprise bill that nobody owns. As the enterprise adopts Google
Cloud across many teams and projects, cost grows faster than the ability to see it, attribute it, or
control it — and the first symptom is usually an over-budget invoice with no clear owner. This
solution establishes **FinOps for Google Cloud**: a durable operating model that makes every dollar
of spend **visible, attributable, and governed.**

## The outcome

- **Visible.** Detailed billing export lands every line item in a BigQuery dataset — the
  authoritative, queryable, durable record of spend, replacing short-lived console screenshots.
- **Attributable.** Cost rolls up along the folder/project hierarchy and along standardized labels
  (`cost-center`, `team`, `environment`, `app`), so every charge reaches an accountable owner and
  "unattributed spend" becomes a tracked, shrinking backlog.
- **Governed.** Cloud Billing budgets with threshold and forecast alerts warn owners *before* the
  month closes; rightsizing and committed-use-discount opportunities are surfaced as an owned savings
  backlog; and a recurring showback report keeps spend a normal part of how teams plan — extendable to
  Workspace and Gemini licensing.

## The approach — safe and governed by design

The rollout follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
pilot-first, with explicit pass/fail gates and a documented rollback for every org-wide change. It is
proven on a small **pilot scope** before any organization-wide budget or export change is applied.

The package includes five Python/`gcloud` automation tools that are **safe by default**: discovery,
reporting, guardrail validation, and savings analysis are strictly **read-only**, and the only tool
that writes — the budget provisioner — makes **no change unless `--apply` is passed** and prints its
plan first. No service-account keys are created or committed and no secrets live in code;
authentication uses Application Default Credentials with least-privilege roles.

## Why it is safe

Budgets **alert but never cap** spend, and attribution views are derived, non-destructive, and
re-creatable. The one genuinely irreversible FinOps action — purchasing a committed-use discount — is
deliberately **kept out of the automation** and left to an explicit, human-approved decision by
finance/FinOps. Financial, chargeback, and contractual determinations remain with the organization's
finance and cloud-governance functions; this solution provides the technical method and the evidence.

## The result

Google Cloud (and, by extension, Workspace/Gemini) spend made **visible, attributable, and
controlled** — budgets alerting, savings identified, showback in place — delivered self-guided,
tested, and at a fraction of the cost of a consulting engagement. No more surprise bills.
