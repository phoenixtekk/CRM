# Executive Summary — HIPAA / PHI DLP Pack (Microsoft Purview)

## The problem
Protected health information (PHI) leaves HIPAA-regulated organizations through the channels people use
every day — an email to the wrong recipient, an "anyone with the link" cloud share, a member list
pasted into Teams, or a discharge summary copied to a USB stick or printed. Without a working
data-loss control, those disclosures are invisible until they become an incident — and, potentially, a
reportable breach. The common failed attempt — switching data-loss controls straight to "block" —
floods the help desk with false positives, breaks clinical and billing workflows, and gets turned off
within a week.

## The solution
Implement **Microsoft Purview Data Loss Prevention (DLP)** tuned for **PHI** across all five locations —
**Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only the
Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Detection is driven by
the **HIPAA-relevant sensitive information types** Microsoft ships — including the built-in **"U.S.
Health Insurance Act (HIPAA)"** template and its underlying SITs (SSN, ICD-9-CM, ICD-10-CM, DEA Number)
— extended with **custom SITs / Exact Data Match** for your own medical record and member identifiers.
The defining discipline is that **every policy is built and proven in SIMULATION first** (Microsoft's
built-in test mode that shows what *would* be blocked, with zero user impact), tuned for a **low
false-positive rate** using the fact that **PHI is a combination** (identifier + clinical detector),
then enforced to a **pilot ring** — encrypting outbound PHI email rather than simply blocking — then
expanded. The result: PHI leaks are controlled without breaking care.

## What it delivers
- A mapped **PHI classification layer** — the right detector for each in-scope category, reusing the
  built-in HIPAA SITs and adding custom/EDM only for real gaps (your MRN, your member ID).
- **DLP policies across email, cloud, Teams, and endpoint**, each proven in simulation, tuned, and
  enforced through policy tips, user justification/override, encryption, or block.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a
  control clinicians trust and one they ignore.
- An **incident/alert triage workflow with a Privacy/Security-Officer escalation path** so every
  potential PHI disclosure is acted on, with an evidence trail in Activity Explorer and optional SIEM
  forwarding.
- **Five PowerShell tools** (posture assessment, policy config helper, validation checker,
  match/false-positive report, scope/health helper) — read-only or `-WhatIf` by default, simulation-only
  where they write, no credentials in code.

## Business outcomes
- **PHI leaks controlled** across the channels PHI actually walks out through — email, cloud sharing,
  and USB/print on endpoints — with outbound PHI email **encrypted**, not just blocked.
- **Minimal disruption** — simulation-first plus co-occurrence tuning means the control catches PHI
  without a wave of false positives, and any policy reverts to simulation instantly if needed.
- **Defensible and auditable** — matches raise alerts that are triaged to disposition and escalated
  appropriately, with evidence retained as the HIPAA control record.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented
  and tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP and advanced classifiers require E5 / E5 Compliance
and onboarded devices** (verify your tenant), and the HIPAA template/SIT library evolves. This solution
provides the **technical configuration and the evidence**; *which* data is PHI, *which* classifiers
legally apply, the **enforced action per category**, the **acceptable false-positive threshold**, and —
decisively — **whether any event is a reportable HIPAA breach** are **compliance, privacy, and legal
determinations**, captured alongside the delivered evidence.
