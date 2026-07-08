# Executive Summary — CMMC / CUI DLP Pack (Microsoft Purview)

## The problem
Organizations holding **Controlled Unclassified Information (CUI)** under a federal contract must show, under
**DFARS 252.204-7012**, **NIST SP 800-171**, and **CMMC**, that CUI does not leave the boundary
uncontrolled. But CUI is defined by **marking**, not by a magic detector — there is no single built-in "CUI"
type — so a data-loss program that ignores marking will both miss real CUI and fire on everything. And the
classic failure — switching data-loss controls straight to "block" — floods the help desk with false
positives, blocks contract work, and gets turned off within a week.

## The solution
Stand up **CUI-tuned Microsoft Purview Data Loss Prevention (DLP)** across all five locations — **Exchange
email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only the Microsoft Purview
portal, Security & Compliance PowerShell, and Microsoft Graph. Detection is **marking-aware**: policies key
off the **`CUI` sensitivity label** (the primary, precise signal that follows your marking decision) with a
**CUI banner/marking keyword type** as a backstop for marked-but-unlabeled CUI. The defining discipline is
that **every policy is built and proven in SIMULATION first** — Microsoft's built-in test mode that shows
what *would* be blocked with zero user impact — then tuned for a **low false-positive rate**, then enforced
to a **pilot ring**, then expanded across the CUI-handling enclave. The result: CUI leaks are blocked without
blocking the contract.

## What it delivers
- A **marking-aware detection layer** — the `CUI` label as primary signal plus a keyword backstop built from
  your **real** CUI markings (never invented).
- **DLP policies across email, cloud, Teams, and endpoint**, scoped to the CUI enclave, each proven in
  simulation, tuned, and enforced through policy tips, justification/override, or block/encrypt.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  people trust and one they ignore.
- An **incident/alert triage workflow with a retained evidence trail** in Activity Explorer — the auditable
  record an assessor or contracting officer expects.
- **Five PowerShell tools** (posture assessment, policy config helper, validation-gate checker, match/
  false-positive & evidence report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **CUI leaks blocked** across the channels controlled data actually walks out through — external email,
  cloud sharing, and USB/print on endpoints.
- **Minimal disruption** — simulation-first plus enclave scoping and tuning means the control catches CUI
  without a wave of false positives, and any policy reverts to simulation instantly if needed.
- **Operable, auditable, and defensible** — matches raise alerts that are triaged to disposition, with an
  evidence trail retained to support the control narrative.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
CUI DLP is licensing-/tenant-dependent — **Endpoint DLP and label-based conditions require E5 / E5 Compliance
and onboarded devices**, and CUI enclaves are frequently **GCC High**, where availability and portal paths
must be **verified** (never assumed). This solution provides the **technical configuration and the
evidence**. *Which* data is CUI, *which* categories/markings apply, the **enforced action per condition**,
GCC High residency, DFARS incident-reporting obligations, and — critically — **whether a NIST SP 800-171 /
CMMC practice is satisfied, the SPRS score, and the assessment outcome** are **compliance, contracts, legal,
and certified-assessor (C3PAO) determinations**, captured alongside the delivered evidence.
