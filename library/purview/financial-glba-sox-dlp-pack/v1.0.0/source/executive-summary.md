# Executive Summary — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

## The problem
Financial institutions and public companies hold data that regulation says must not leak: **customer
nonpublic personal information (NPI)** protected under the **Gramm-Leach-Bliley Act (GLBA)** — account and
card numbers, bank routing/account numbers, Social Security / taxpayer numbers — and **financial-reporting
data and material non-public information** whose integrity underpins **Sarbanes-Oxley (SOX)** controls.
Both walk out through everyday channels: an emailed account export, a general-ledger extract shared
"anyone with the link," card numbers pasted into Teams, or a draft statement copied to a USB stick.
Without a working data-loss control those leaks are invisible until they become an incident — and the
common failed attempt, switching controls straight to "block," floods the help desk with false positives
(GL codes, invoice IDs) and gets turned off within a week.

## The solution
Stand up **Microsoft Purview Data Loss Prevention (DLP)** tuned for financial and customer data across all
five locations — **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using
only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Detection is
driven by **financial sensitive information types** (built-in card/routing/account/SSN/ITIN types, the
**GLBA / U.S. Financial Data** templates, plus **Exact Data Match**, **document fingerprinting** of
statement templates, and **trainable classifiers**), and the defining discipline is that **every policy is
built and proven in SIMULATION first** — Microsoft's built-in test mode that shows what *would* be blocked
with zero user impact — then tuned for a **low false-positive rate**, then enforced to a **finance pilot
ring**, then expanded. The result: financial and NPI leaks are blocked without blocking month-end close.

## What it delivers
- A mapped **financial classification layer** — the right detector for each in-scope NPI/financial
  category, reusing built-in types and GLBA templates and adding custom SITs / EDM / fingerprints only for
  real gaps (internal account numbers, GL codes, statement templates).
- **DLP policies across email, cloud, Teams, endpoint, and a dedicated SOX financial-records policy**, each
  proven in simulation, tuned, and enforced through policy tips, justification/override, or block/encrypt.
- A **measured false-positive rate** kept at/under an agreed threshold across a reporting cycle — the
  difference between a control finance trusts and one they ignore.
- A **financial incident/alert triage workflow** with controlled access to NPI evidence, an Activity
  Explorer trail, and optional SIEM forwarding.
- **Five PowerShell tools** (posture assessment, policy config helper, validation runner, match/
  false-positive report, scope/health helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **Financial/NPI leaks blocked** across the channels data actually walks out through — email, cloud
  sharing, and USB/print on finance endpoints.
- **Minimal disruption** — simulation-first plus tuning means the control catches leaks without a wave of
  false positives on GL/reference numbers, and any policy reverts to simulation instantly if needed.
- **Defensible and auditable** — matches raise alerts triaged to disposition, with evidence retained for
  the GLBA safeguards / SOX control record.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP, EDM, fingerprinting, and trainable classifiers require
E5 / E5 Compliance and onboarded devices** (verify your tenant), and template names/portal paths evolve.
This solution provides the **technical configuration and the evidence**; *which* data is NPI under GLBA,
*which* records are SOX-scoped, *which* classifiers legally apply, the **enforced action per category**,
any **retention obligation**, and the **acceptable false-positive threshold** are **compliance, records,
privacy, and legal determinations**, captured alongside the delivered evidence.
