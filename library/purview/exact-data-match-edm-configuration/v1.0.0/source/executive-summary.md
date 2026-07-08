# Executive Summary — Exact Data Match (EDM) in Microsoft Purview

## The problem
Pattern-based data classifiers guess. A built-in credit-card, SSN, or account-number detector fires on
*anything shaped like* the sensitive value — including test data, a random number, or an employee's own
details — so it over-matches, buries the triage team in false positives, and gets tuned down or turned
off. The organization is left either **over-blocking legitimate work** or **under-protecting the real
records** that matter — with no way to say "protect *these specific* customers, and only these."

## The solution
Implement **Exact Data Match (EDM)** in Microsoft Purview, using only the Microsoft Purview portal,
Security & Compliance PowerShell / Graph, and Microsoft's **EDM Upload Agent**. EDM matches on your
**actual records** — the exact account numbers, IDs, and PII in your own database — and on nothing
else. Crucially, it is **privacy-preserving**: the source data is **hashed and salted on a machine you
control**, and **only the one-way hashes are uploaded** — the plaintext never leaves your environment.
The resulting sensitive information type is used in a DLP policy that is **built and proven in
SIMULATION first**, then tuned, then enforced to a pilot ring, then expanded — so exact protection goes
live without disrupting the business.

## What it delivers
- An **EDM schema** and **EDM sensitive information type** that match your real records exactly — an
  exact primary value plus supporting elements in proximity, at a defined confidence.
- A **privacy-preserving data pipeline** — hash-and-upload with the EDM Upload Agent, plaintext kept
  local and securely deleted, the salt held as a secret, and a **refresh schedule** so matching stays
  current.
- A **DLP policy** referencing the EDM SIT, proven in simulation and enforced through policy tips,
  override, or block.
- A **near-zero false-positive rate** — the defining EDM advantage: look-alike and not-in-data values
  are correctly ignored, so the control is trusted and can be safely enforced.
- **Five PowerShell tools** (readiness, schema helper, validation, reporting, scope helper) —
  read-only or `-WhatIf` by default, with **no credentials, salts, or record data in code**.

## Business outcomes
- **Exact protection** — the right *specific* records are detected and protected, not everything that
  merely looks similar.
- **Trusted, low-noise control** — a near-zero false-positive rate is the difference between a control
  people rely on and one they ignore, and it makes enforcement defensible.
- **Privacy by design** — sensitive data is hashed locally; only hashes are uploaded; plaintext is
  securely deleted — a posture you can show privacy and compliance.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented
  and tooled to run in-house.

## Boundaries (so scope is clear)
EDM is licensing-dependent — it requires **Microsoft 365 E5 / E5 Compliance / Information Protection &
Governance** (verify your tenant), and **Government clouds (GCC High / DoD) use a distinct Upload Agent
and endpoints**. This solution provides the **technical configuration and the evidence**; *which*
records are lawful to load, the **enforced action**, and the **minimisation and retention** of the
loaded data are **compliance, privacy, and legal determinations**, captured alongside the delivered
evidence.
