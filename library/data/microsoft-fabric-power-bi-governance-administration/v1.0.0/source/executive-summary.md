# Executive Summary — Microsoft Fabric & Power BI Governance & Administration

Self-service analytics sprawls fast. Anyone can spin up a workspace, publish a report, share it with
the whole company, and pin it to a capacity nobody is watching — so you end up with uncontrolled
workspaces, over-shared and over-exported reports, mystery capacity spend, and no path from a draft to
a trusted production report. This solution establishes governance at the **platform** level: a tenant-
settings baseline, a capacity management and monitoring model, a workspace architecture with a role and
access model, deployment pipelines for a controlled dev to test to prod lifecycle, and the admin and
scanner APIs that let you see and prove what is happening.

This is a complete, do-it-the-repeatable-way package for governing Microsoft Fabric and Power BI as a
platform, written for a competent Fabric/Power BI administrator with no prior tenant-governance
experience. It is deliberately scoped to platform **administration and governance** — tenant settings,
capacities, workspaces, pipelines, and monitoring.

## What you get
- A plain-language Solution Overview of the platform-governance model, how the admin surface works, and the standard deployment model.
- A Requirements Guide with Verify and Implement-if-missing for every solution-specific prerequisite (category-wide prerequisites live in the separate global-requirements file).
- An Implementation Guide of precise, ordered, click-by-click steps — every object you create is named with one convention and reused through testing, troubleshooting, and the scripts.
- Five PowerShell scripts: platform discovery, a governance-baseline validator, a capacity-and-activity report, a tenant-settings desired-state helper, and a workspace/pipeline provisioner — read-only or preview-first by default.
- Testing and Troubleshooting guides so you can prove the governance actually holds before you expand.

## What this delivers
A named tenant baseline — `Tenant Governance Baseline – Fabric/Power BI – v1` — applied to defined
security groups, a workspace model (`Sales BI – Content – Dev/Test/Prod`) fed by a deployment pipeline
(`Deployment Pipeline – Sales BI – DevTestProd`), capacities that are monitored for utilization and
spend, and admin-API-based monitoring — all piloted on a governance ring before it touches the whole
tenant.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand — tenant-setting changes are piloted on a ring and
approved before they go tenant-wide, because they affect every user.

## Boundary
This solution governs the **platform**. Data classification of analytics content — sensitivity labeling
and DLP for Power BI/Fabric, and Purview-side reporting — is delivered by the Microsoft Purview
information-protection solutions and is cross-referenced here, not duplicated. Regulatory, records, and
data-classification determinations remain the customer's compliance function's decision; this guide
provides the technical controls.

## Effort
Plan roughly two to four days for a first rollout: about half a day to assess and inventory, a day to
configure the baseline, workspaces, and a pilot pipeline, a day to pilot and validate on the governance
ring, and the remainder to expand tenant-wide under change control. Reusable on every subsequent
workload and rollout.
