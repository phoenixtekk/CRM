# Executive Summary — GDPR / PII DLP Pack (Microsoft Purview)

## The problem
**Personal data** relating to identifiable individuals — names tied to national identifiers, passport and tax
numbers, financial account data, contact details, and the special-category data that attracts extra
protection — leaves the organisation through the channels people use every day: an email with a customer list
attached, an "anyone with the link" HR spreadsheet share, a national ID pasted into Teams, or a records file
copied to USB or printed from a laptop. GDPR (Regulation (EU) 2016/679) requires that personal data be
protected; without a working data-loss control, exposures are invisible until they become a reportable
incident. The common failed attempt — switching data-loss controls straight to "block" — floods the help
desk with false positives and gets turned off within a week.

## The solution
Stand up **Microsoft Purview Data Loss Prevention (DLP)**, tuned for EU personal data, across all five
locations — **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only the
Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Detection is driven by
**sensitive information types** (the EU/GDPR built-in set — national ID, passport, TIN, IBAN, and more — a
**custom SIT** for any bespoke national or internal identifier, **trainable classifiers** for
special-category data, and **Exact Data Match** against the real records where near-zero false positives
matter), and the defining discipline is that **every policy is built and proven in SIMULATION first** —
Microsoft's built-in test mode that shows what *would* be blocked, with zero user impact — then tuned for a
**low false-positive rate**, then enforced to a **pilot ring**, then expanded. The result: personal-data
leaks are blocked without blocking legitimate business.

## What it delivers
- A mapped **classification layer** for EU personal data — the right detector for each in-scope category,
  reusing the EU/GDPR built-in types and adding a custom SIT / EDM / trainable classifiers only for real gaps.
- **DLP policies across email, cloud, Teams, and endpoint**, each proven in simulation, tuned, and enforced
  through policy tips, user justification/override, or block — with optional **cross-border/external-transfer
  awareness**.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  staff trust and one they ignore.
- An **incident/alert triage workflow** so every match is acted on, with an evidence trail in Activity
  Explorer, least-privilege evidence access, a **DPO/breach hand-off**, and optional SIEM forwarding.
- **Five PowerShell tools** (posture assessment, policy config helper, validation checker, match/false-
  positive report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **Personal-data leaks blocked** across the channels data actually walks out through — email, cloud sharing,
  and USB/print on endpoints — including external/cross-border movement.
- **Minimal disruption** — simulation-first plus tuning means the control catches leaks without a wave of
  false positives, and any policy reverts to simulation instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition and handed to the DPO for
  breach assessment, with evidence retained for a defensible GDPR posture.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP and advanced classifiers require E5 / E5 Compliance and
onboarded devices** (verify your tenant). This solution provides the **technical configuration and the
evidence**; the **lawful basis**, what is **special-category (Article 9)** data, whether a transfer is a
**restricted cross-border transfer** and its safeguard, the **enforced action per category**, the retention
position, and the **acceptable false-positive threshold** are **data-protection, privacy (DPO), and legal
determinations**, captured alongside the delivered evidence.
