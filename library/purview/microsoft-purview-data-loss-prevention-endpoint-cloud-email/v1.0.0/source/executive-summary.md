# Executive Summary — Microsoft Purview Data Loss Prevention (DLP): Endpoint, Cloud & Email

## The problem
Sensitive data leaves the organization through the channels people use every day — email attachments,
"anyone with the link" cloud shares, content pasted into Teams, and files copied to USB or printed from a
laptop. Without a working data-loss control, those leaks are invisible until they become an incident. The
common failed attempt — switching data-loss controls straight to "block" — floods the help desk with false
positives and gets turned off within a week.

## The solution
Implement **Microsoft Purview Data Loss Prevention (DLP)** across all five locations — **Exchange email,
SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only the Microsoft Purview portal,
Security & Compliance PowerShell, and Microsoft Graph. Detection is driven by **sensitive information
types** (built-in, custom, **Exact Data Match**, and **trainable classifiers**), and the defining
discipline is that **every policy is built and proven in SIMULATION first** — Microsoft's built-in test
mode that shows what *would* be blocked, with zero user impact — then tuned for a **low false-positive
rate**, then enforced to a **pilot ring**, then expanded. The result: leaks are blocked without blocking
the business.

## What it delivers
- A mapped **classification layer** — the right detector for each in-scope data category, reusing built-in
  types and adding custom/EDM/trainable only for real gaps.
- **DLP policies across email, cloud, Teams, and endpoint**, each proven in simulation, tuned, and enforced
  through policy tips, user justification/override, or block.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  people trust and one they ignore.
- An **incident/alert triage workflow** so every match is actually acted on, with an evidence trail in
  Activity Explorer and optional SIEM forwarding.
- **Five PowerShell tools** (posture assessment, policy config helper, endpoint-readiness checker,
  match/false-positive report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **Leaks blocked** across the channels data actually walks out through — email, cloud sharing, and
  USB/print on endpoints.
- **Minimal disruption** — simulation-first plus tuning means the control catches leaks without a wave of
  false positives, and any policy reverts to simulation instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence retained.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP and advanced classifiers require E5 / E5 Compliance and
onboarded devices** (verify your tenant). This solution provides the **technical configuration and the
evidence**; *which* data categories are in scope, *which* classifiers legally apply, the **enforced action
per category**, and the **acceptable false-positive threshold** are **compliance, privacy, and legal
determinations**, captured alongside the delivered evidence.
