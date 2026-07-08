# Executive Summary — Document Fingerprinting (Microsoft Purview)

## The problem
Most sensitive business runs on **standard forms and templates** — onboarding packets, intake sheets,
benefits and government forms, contract templates. They share the same layout and boilerplate every time;
only the filled-in values change. When one of those forms is emailed to the wrong person, shared "anyone
with the link," or dropped into a Teams chat, generic content detectors often miss it — the *form itself*
is the sensitive artifact, and a keyword or credit-card pattern isn't what identifies it. The leak is
invisible until it becomes an incident.

## The solution
Use **Microsoft Purview Document Fingerprinting** to turn each standard form into a **sensitive
information type** built from the form's own text. Purview reads a blank/representative template, computes
a compact **fingerprint** of its word pattern (the document itself is not stored), and thereafter
recognizes *any* copy of that form — regardless of the values typed into it. That fingerprint is then
wired into **Data Loss Prevention (DLP)** so movement of the forms through **email, SharePoint, OneDrive,
and Teams** is detected and controlled — using only the Microsoft Purview portal and Security & Compliance
PowerShell. As with every solution in this category, the DLP policy carrying the fingerprint is **proven
in SIMULATION first** — Microsoft's built-in test mode that shows what *would* be caught, with zero user
impact — then enforced to a **pilot ring**, then expanded.

## What it delivers
- **Fingerprint SITs** for your standard forms — high-precision detection that keys off the form's
  structure, not a fragile keyword, with related forms grouped where sensible.
- A **DLP policy** across email, cloud, and Teams that detects the forms, proven in simulation, tuned for
  specificity, and enforced through policy tips, user justification/override, or block.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  people trust and one they ignore.
- An **incident/alert triage workflow** so every match is acted on, with an evidence trail in Activity
  Explorer and optional SIEM forwarding.
- A **fingerprint refresh process** so detection stays current as forms are revised.
- **Five PowerShell tools** (posture discovery, fingerprint/SIT builder, wiring validator, detection
  report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **Standard forms detected** as they move through the channels data actually leaks through.
- **High precision, minimal disruption** — a fingerprint keys off the whole form pattern, so it fires on
  your forms and stays quiet on unrelated content; simulation-first plus instant rollback keeps the
  business running.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence
  retained.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented
  and tooled to run in-house.

## Boundaries (so scope is clear)
Fingerprinting detects **text-pattern** matches — it will not catch an image-only scan, a
password-protected file, or a form edited beyond recognition, and DLP locations/actions are
licensing-dependent (**verify your tenant**). This solution provides the **technical configuration and the
evidence**; *which* forms are in scope, *which* legal/regulatory obligation applies to each, and the
**enforced action per form** are **compliance, privacy, and legal determinations**, captured alongside the
delivered evidence.
