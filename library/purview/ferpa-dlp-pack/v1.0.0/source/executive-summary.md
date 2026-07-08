# Executive Summary — FERPA DLP Pack (Microsoft Purview)

## The problem
Student **education records** — grades, disciplinary records, student identifiers, financial-aid data, and
the personally identifiable information tied to them — leave the institution through the channels people use
every day: an email with a class roster attached, an "anyone with the link" gradebook share, a student ID
pasted into Teams, or a records file copied to USB or printed from a faculty laptop. FERPA (20 U.S.C.
§ 1232g; 34 CFR Part 99) requires those records to be protected; without a working data-loss control, leaks
are invisible until they become an incident. The common failed attempt — switching data-loss controls
straight to "block" — floods the help desk with false positives and gets turned off within a week.

## The solution
Stand up **Microsoft Purview Data Loss Prevention (DLP)**, tuned for education records, across all five
locations — **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only the
Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Detection is driven by
**sensitive information types** (built-in SSN/name/address types, a **custom Student ID SIT** tuned to your
local format, and **Exact Data Match** against the real records where near-zero false positives matter), and
the defining discipline is that **every policy is built and proven in SIMULATION first** — Microsoft's
built-in test mode that shows what *would* be blocked, with zero user impact — then tuned for a **low
false-positive rate**, then enforced to a **pilot ring**, then expanded. The result: record leaks are blocked
without blocking teaching and administration.

## What it delivers
- A mapped **classification layer** for education records — the right detector for each in-scope category,
  reusing built-in types and adding a Student ID custom SIT / EDM / trainable classifiers only for real gaps.
- **DLP policies across email, cloud, Teams, and endpoint**, each proven in simulation, tuned, and enforced
  through policy tips, user justification/override, or block.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  faculty trust and one they ignore.
- An **incident/alert triage workflow** so every match is acted on, with an evidence trail in Activity
  Explorer, least-privilege evidence access, and optional SIEM forwarding.
- **Five PowerShell tools** (posture assessment, policy config helper, validation checker, match/false-
  positive report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **Record leaks blocked** across the channels student data actually walks out through — email, cloud
  sharing, and USB/print on endpoints.
- **Minimal disruption** — simulation-first plus tuning means the control catches leaks without a wave of
  false positives, and any policy reverts to simulation instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence retained
  for a defensible FERPA compliance posture.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP and advanced classifiers require E5 / E5 Compliance (or A5)
and onboarded devices** (verify your tenant). This solution provides the **technical configuration and the
evidence**; *which* records are FERPA-protected, what is **directory** versus **non-directory** information,
which disclosures are permitted, the **enforced action per category**, and the **acceptable false-positive
threshold** are **FERPA-compliance, registrar, privacy, and legal determinations**, captured alongside the
delivered evidence.
