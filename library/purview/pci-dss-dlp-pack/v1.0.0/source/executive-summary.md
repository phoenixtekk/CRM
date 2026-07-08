# Executive Summary — PCI-DSS DLP Pack (Microsoft Purview)

## The problem
Payment card numbers spread far beyond the systems built to hold them. A **Primary Account Number (PAN)**
ends up in an email to a customer, pasted into a Teams chat, saved in a spreadsheet on OneDrive, copied to
a USB stick, or printed from a laptop — every one a **cardholder-data exposure** and a **PCI-DSS gap** that
also widens the scope an assessor has to examine. Left unaddressed, this "PAN sprawl" is invisible until it
becomes an incident. The common failed attempt — switching a card-data control straight to "block" — halts
legitimate payment workflows, floods the help desk with false positives, and gets turned off within a week.

## The solution
Implement **Microsoft Purview Data Loss Prevention (DLP), tuned for cardholder data**, across all five
locations — **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only
the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Detection anchors on
the built-in **Credit Card Number** sensitive information type (a card-brand pattern + **Luhn** checksum +
supporting keywords), with **Exact Data Match** against your real PANs where near-zero false positives are
required. The defining discipline is that **every policy is built and proven in SIMULATION first** —
Microsoft's built-in test mode that shows what *would* be blocked, with zero user impact — then tuned for a
**low false-positive rate**, then enforced to a **pilot ring**, then expanded. The result: card-data leaks
are blocked without blocking the payment business.

## What it delivers
- A confirmed **PAN detector** — the built-in Credit Card Number SIT (and optional EDM on your real PANs),
  tuned to distinguish real card numbers from Luhn-valid internal reference numbers.
- **DLP policies across email, cloud, Teams, and endpoint**, each proven in simulation, tuned, and enforced
  through policy tips, user justification/override, or block/encrypt.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  people trust and one they ignore.
- A **PAN-incident/alert triage workflow** so every card-data match is investigated, with an evidence
  trail in Activity Explorer and optional SIEM forwarding — the artifacts an assessor wants to see.
- **Five PowerShell tools** (posture assessment, policy config helper, endpoint-readiness checker,
  match/false-positive report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **PAN leaks blocked** across the channels card data actually walks out through — email, cloud sharing,
  and USB/print on endpoints.
- **Minimal disruption** — simulation-first plus tuning means the control catches card-data exposure
  without a wave of false positives, and any policy reverts to simulation instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence retained
  for the assessor.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP and EDM require E5 / E5 Compliance and onboarded
devices** (verify your tenant). This solution provides the **technical configuration and the evidence**;
the **CDE boundary and PCI scope**, *which* card-data flows are in scope, the **enforced action per flow**,
the **acceptable false-positive threshold**, and **PCI-DSS compliance/attestation** are **compliance, PCI,
and QSA determinations**, captured alongside the delivered evidence. This solution does not attest to
PCI-DSS compliance.
