# Executive Summary — Microsoft Purview PCI-DSS Compliance Program

## The problem

If your organization stores, processes, or transmits payment-card data, **PCI-DSS is not optional** —
and "are we compliant?" has no defensible answer without a control-by-control record backed by
evidence. Most teams discover the gaps the hard way: in a QSA review or an SAQ, when the auditor asks
*where is the cardholder data, what protects it, who logs access to it, and prove it.* Cardholder data
(the Primary Account Number) tends to sprawl into email, files, and chats where no one is watching, and
the evidence that controls exist is scattered across screenshots and spreadsheets. Left unaddressed,
this is both a **compliance gap** and a **data-breach exposure** on the highest-value data you hold.

## The solution

This solution stands up a **PCI-DSS-aligned compliance program in Microsoft Purview** — the controls
that protect cardholder data, the mapping from PCI-DSS requirements to those controls, and the
**audit-ready evidence** tying it all together — configured **the responsible way**:

- **The requirements Purview can actually enforce, done right.** A **DLP policy** that detects the
  **Credit Card Number** sensitive information type and a **cardholder-data sensitivity label**
  (Requirement 3 — protect stored account data); **unified audit logging** enabled and retained
  (Requirement 10 — log and monitor access); and **least-privilege role separation** (Requirement 7 —
  restrict access by need-to-know).
- **Piloted in simulation first.** The cardholder-data DLP is deployed in **simulation/test mode**, so
  you can see exactly what *would* be caught — and tune out false positives — **before** it can block a
  single legitimate payment operation. Enforcement comes only after validation, under change control.
- **The whole standard in one record.** **Compliance Manager**, built around the **PCI-DSS assessment
  template**, maps every requirement to an owner, a status, and evidence — including **evidence links**
  for the requirements Purview can't enforce (firewalls, segmentation, physical, anti-malware, testing),
  so the record represents the complete standard.

The result is a governed, defensible position: cardholder data detected and protected, access logged,
duties separated, and every control evidenced — **without over-blocking the business**.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot (simulate) → Validate → Expand** —
that assesses readiness, agrees the control map and CDE scope with the compliance stakeholders,
configures the least-privilege guardrails and audit logging, creates the PCI-DSS assessment and action
plan, deploys the cardholder-data DLP **in simulation** and the label, validates the evidence, and only
then moves the DLP to enforce and expands to the full requirement set. Every high-impact change is
piloted and reversible.

The solution ships as **self-guided documentation plus five PowerShell tools** (Security & Compliance
PowerShell / Graph) that assess readiness and role separation, configure the cardholder-data DLP in
simulation, validate the technical evidence behind the controls, produce a leadership posture rollup,
and stage role/scope and enforcement changes — all **read-only or `-WhatIf` by default**, with **no
credentials in code**.

## Why it matters

- **Protect the crown jewels** — detect and control cardholder data before it becomes a breach, on the
  highest-value data you hold.
- **Defensible evidence, clear ownership** — a QSA-ready record mapping every requirement to an owner,
  a status, and proof, produced as a routine rather than a fire drill.
- **No business disruption** — simulation-first DLP means you tune before you enforce, so legitimate
  payment operations keep running.
- **A fast, focused win** — the Purview-enforceable PCI-DSS controls delivered and validated at a
  fraction of consulting cost; a foundation you extend to the full requirement set.

## Important boundaries

Microsoft Purview features are **licensing-dependent** — the PCI-DSS assessment template, endpoint DLP,
auto-labeling, and Audit (Premium) require **Microsoft 365 E5 / E5 Compliance** or add-ons; some
capabilities are in preview — and the portal is **evolving**, so availability should be **verified
against your licensing and tenant**. Purview covers the **data-protection, access-governance, and
logging** requirements and centralizes evidence for the rest; it does **not** provide firewalls,
segmentation, vulnerability scanning, or physical controls. Critically, **how your Cardholder Data
Environment is scoped, which SAQ/version applies, and whether the evidence satisfies PCI-DSS are QSA /
compliance / legal determinations** — this solution provides the technical method and the evidence, not
the attestation.
