# Executive Summary — Automatic Sensitivity Labeling at Scale (Microsoft Purview)

## The problem
Manual sensitivity labeling never scales and never stays consistent. Users forget, guess, or pick the
easiest label, and the millions of files already sitting in SharePoint and OneDrive were never labeled
at all. Because **DLP, encryption, and retention all key off the label being present and correct**,
unlabeled and mislabeled content is a direct compliance gap and data-risk exposure. Yet turning on
automatic labeling carelessly is its own hazard: aggressive rules mislabel content and — where labels
encrypt — apply **surprise encryption** at scale, generating a ticket flood and eroding trust in days.

## The solution
This solution configures Microsoft Purview's two automatic-labeling engines and rolls them out the safe
way. **Client-side** auto-labeling recommends the right label inside the Office apps as users create
content; **service-side** auto-labeling reaches **existing data at rest** (SharePoint, OneDrive) and
**mail in transit** (Exchange). Critically, every service-side policy is **created in simulation** — it
scans and reports exactly what *would* be labeled, with **zero** impact — so precision is measured and
tuned with the data owner **before** anything is enforced. Enforcement then expands by **location**: a
pilot subset first, validated against the accepted simulation, then tenant-wide **at scale**.

The engagement follows the standard, defensible model — **Assess → Design → Configure → Pilot
(simulate) → Validate → Expand (enforce at scale)** — with explicit pass/fail gates and a documented
rollback at every step.

## What's included
- **Full documentation set** — Solution Overview, Requirements Guide, Implementation Guide, Testing
  Guide (ten pass/fail tests with the precision **enforcement gate**), Troubleshooting, and Best
  Practices.
- **Five PowerShell tools** — Discovery, the simulation-first configuration/remediation helper,
  Simulation Report, labeling-coverage Reporting, and a Scope/Health check — all safe-by-default
  (read-only or `-WhatIf`/simulation unless `-Commit`), using only documented Security & Compliance
  PowerShell cmdlets, with **no** stored credentials.

## Scope boundary and deferrals
This build automates the **application** of sensitivity labels that **already exist and are published**
in your tenant; designing and publishing the label taxonomy is a prerequisite. **Which** content is
sensitive and **which** label it carries is a classification/records determination owned by your
compliance, records, privacy, and data-owner functions — this solution provides the technical method
and the evidence, not the determination.

## Licensing note
Automatic sensitivity labeling (client- and service-side) is a **premium** capability that typically
requires **Microsoft 365 E5** or the **E5 Compliance** add-on, and the Purview portal is evolving.
Availability and portal paths are flagged **"verify your licensing/tenant"** rather than assumed.

## The bottom line
Data labeled **automatically, consistently, and without the user** — proven in simulation, enforced by
stages, and validated — so classification is finally reliable enough for DLP, encryption, and retention
to depend on.
