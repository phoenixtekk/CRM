# Executive Summary — OneDrive for Business DLP (Microsoft Purview)

## The problem
OneDrive for Business is personal cloud storage that fills up with corporate data — customer
spreadsheets, contracts, and exports individuals save to work on. Two risks follow: **sensitive content
sitting in personal storage**, and **that content being over-shared**, most often as an "anyone with the
link" or a direct external share. Left unaddressed, this is a compliance gap and a data-risk exposure
that stays invisible until it becomes an incident. The common failed attempt — switching data-loss
controls straight to "block" — strips sharing on legitimate collaboration, floods the help desk, and
gets turned off within a week.

## The solution
Implement **Microsoft Purview Data Loss Prevention (DLP)** for the **OneDrive for Business** location
using only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph — no
third-party tooling. Detection is driven by **sensitive information types** (built-in, custom, **Exact
Data Match**, and **trainable classifiers**), and the policy acts on both **sensitive content at rest**
and the higher-severity case of **sensitive content shared externally**. The defining discipline is that
**every policy is built and proven in SIMULATION first** — Microsoft's built-in test mode that shows what
*would* be restricted, with zero user impact — then tuned for a **low false-positive rate**, then
enforced to a **pilot ring**, then expanded. The result: risky exposure is controlled without blocking
legitimate collaboration.

## What it delivers
- A mapped **classification layer** — the right detector for each in-scope data category, reusing
  built-in types and adding custom/EDM/trainable only for real gaps.
- **OneDrive DLP policies** — an *at-rest* policy for sensitive content stored in OneDrive and an
  *external-share* policy that targets the over-share specifically, each proven in simulation, tuned, and
  enforced through policy tips, user justification/override, or restricting external access.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  people trust and one they ignore.
- An **incident/alert triage workflow** so every match is actually acted on, with an evidence trail in
  Activity Explorer and optional SIEM forwarding.
- **Five PowerShell tools** (posture assessment, policy config/remediation helper, validation reporter,
  match/false-positive report, scope/health helper) — read-only or `-WhatIf` by default, no credentials
  in code.

## Business outcomes
- **Over-shares controlled** — sensitive files shared "anyone with the link" or externally are
  restricted, while internal collaboration is left untouched.
- **Minimal disruption** — simulation-first plus tuning means the control catches exposure without a wave
  of false positives, and any policy reverts to simulation instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence
  retained.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented
  and tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **custom/advanced classifiers require E5 / E5 Compliance** (verify
your tenant); DLP for OneDrive and built-in SITs are broadly available. This solution provides the
**technical configuration and the evidence**; *which* data categories are in scope, *which* classifiers
legally apply, the **enforced action per category** (e.g. block external sharing vs. warn-and-override),
and the **acceptable false-positive threshold** are **compliance, privacy, and legal determinations**,
captured alongside the delivered evidence.
