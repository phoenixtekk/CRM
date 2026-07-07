# Solution Overview

## Google Cloud FinOps — Billing, Budgets & Cost Governance

Cloud spend without FinOps becomes a surprise bill that nobody owns. Google Cloud makes it
trivially easy to spin up resources across many projects and teams, and just as easy to lose sight
of what each of them costs, who is accountable for it, and whether any of it is waste. This
solution establishes **FinOps for Google Cloud** — a disciplined operating model that makes every
dollar of spend **visible, attributable, and governed**.

FinOps here is not a one-time cleanup. It is a durable capability built on four load-bearing
mechanisms, each of which this solution stands up and hands to the organization:

1. **Visibility — detailed billing export to BigQuery.** Google Cloud's console cost reports are
   useful but aggregated and short-lived. The authoritative, queryable record of every line item
   is the **detailed usage cost export to BigQuery**. Once enabled, every SKU, project, label, and
   credit lands in a dataset the organization can query, join, and report on indefinitely.

2. **Attribution — cost broken down by the resource hierarchy and labels.** Spend is only
   controllable when someone owns it. This solution attributes cost along the **folder/project
   hierarchy** (org → folder → project) and along **labels** (`cost-center`, `team`, `environment`,
   `app`) so that every charge rolls up to an accountable owner — a team, a cost center, or an
   application.

3. **Control — budgets and alerts.** Cloud Billing **budgets** with **threshold alert rules** turn
   spend from something discovered after the fact into something that pages an owner *before* the
   month closes. Budgets scoped to projects, folders, labels, or services give each owner a guardrail
   on their own spend.

4. **Optimization — committed-use discounts (CUD) and rightsizing.** Google Cloud surfaces
   **rightsizing recommendations** (idle/oversized VMs, unattached disks) and **committed-use
   discount** opportunities through the Recommender API. This solution turns those recommendations
   into a reviewed, owned savings backlog rather than an ignored console tab.

On top of these, the solution establishes a **showback/chargeback** cadence — a recurring report
that shows each team what it spent, so cost becomes a normal part of how the organization plans and
operates. The same model **extends to Google Workspace and Gemini licensing**: once the enterprise
is attributing GCP spend by owner, the same showback discipline covers subscription/licensing cost.

### The reference design

```
        ┌──────────────────────────────────────────────────────────┐
        │  Cloud Billing account  (billing admin owns budgets)      │
        │                                                            │
        │   Detailed usage cost export ─────────►  BigQuery dataset  │
        │                                          FinOps – Billing  │
        └───────────────┬──────────────────────────────┬───────────┘
                        │                                │
             ┌──────────▼──────────┐         ┌───────────▼────────────┐
             │  Budgets + alerts   │         │  Attribution + reports │
             │  (project/folder/   │         │  (BigQuery SQL views:  │
             │   label/service)    │         │   by hierarchy/label,  │
             │  → Pub/Sub / email  │         │   showback tables)     │
             └──────────┬──────────┘         └───────────┬────────────┘
                        │                                │
             ┌──────────▼──────────┐         ┌───────────▼────────────┐
             │ Recommender API     │         │ Showback / chargeback  │
             │ (rightsizing + CUD  │         │ dashboard (Looker      │
             │  savings backlog)   │         │  Studio on BigQuery)   │
             └─────────────────────┘         └────────────────────────┘
```

Everything is anchored on the **billing account** and the **`FinOps – Billing Export – Prod`**
BigQuery dataset. Budgets, attribution views, savings analysis, and dashboards all read from that
single authoritative export.

### How it works, end to end

- **Billing export** is enabled on the billing account, writing the **detailed usage cost** export
  (and, optionally, the **pricing** export) into a dedicated BigQuery dataset. This is the source of
  truth for all downstream reporting.
- **Attribution views** are BigQuery SQL views built on the export table that group cost by
  `project.id`, by folder (via the resource ancestry), and by the label keys the organization
  standardized on. Unlabeled/unattributed spend is itself a first-class metric — it is the backlog
  of things that need an owner.
- **Budgets** are created against the billing account and scoped (all-projects, a folder's projects,
  a label, or specific services) with **alert threshold rules** (e.g. 50/90/100% of a monthly amount,
  plus a forecasted-spend rule) that notify by email and/or a **Pub/Sub topic** for automation.
- **Optimization** reads the **Recommender API** (`google.compute.instance.MachineTypeRecommender`,
  idle-resource recommenders, and commitment/CUD recommenders) to produce a savings backlog with an
  owner and an estimated monthly saving per item.
- **Showback** is a scheduled report (BigQuery query → table/dashboard) delivered to each team on a
  cadence, closing the loop so spend stays owned.

### Deployment model

This solution follows the house model used across every Google Cloud solution:
**Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
gates and a documented rollback for any org-wide change.

- **Assess** current billing configuration, hierarchy, labeling coverage, and existing budgets
  (read-only — the discovery tool does exactly this).
- **Design** the attribution model (which labels, which hierarchy roll-ups), the budget policy
  (who gets which budget at which thresholds), and the showback cadence.
- **Configure** the billing export, attribution views, budgets, and dashboards.
- **Pilot** on a single **pilot scope** (`FinOps – Pilot – v1`: one folder or a small set of
  projects) before touching the whole organization.
- **Validate** against the gates: spend is attributable, budgets alert correctly, savings are
  identified.
- **Expand** to the full organization once the pilot passes, keeping the rollback documented.

### Benefits

- **No more surprise bills** — budgets alert owners before, not after, the month closes.
- **Every dollar has an owner** — cost rolls up to a team/cost-center via hierarchy and labels.
- **Waste becomes a backlog** — rightsizing and CUD opportunities are surfaced, owned, and tracked.
- **Durable, queryable history** — the BigQuery export outlives the console's short retention.
- **Extensible** — the same showback discipline covers Workspace and Gemini licensing spend.

### Limitations and boundaries

- **This solution provides the technical FinOps method and evidence; it does not make financial or
  contractual decisions.** Chargeback policy, cost-center mappings, and commitment-purchase
  approvals are business decisions owned by finance and the cloud-governance/FinOps function.
- **CUD purchases move money and are commitments** — the tooling *identifies* opportunities
  (read-only); the actual purchase is an explicit, approved, human action, never automated here.
- **Billing export is not retroactive.** Enabling the export begins capturing data from that point
  forward; historical detail before enablement is limited to what the console retained.
- **Preview/version-dependent surfaces are flagged.** Where a Recommender, budget field, or export
  schema element is version- or preview-dependent, verify it against the current Google Cloud
  documentation for your organization rather than assuming the behavior described here.
- **Labeling is a prerequisite discipline, not a magic switch.** Attribution quality is bounded by
  labeling coverage; the solution measures and drives that coverage but cannot invent an owner for
  a resource nobody labeled.
