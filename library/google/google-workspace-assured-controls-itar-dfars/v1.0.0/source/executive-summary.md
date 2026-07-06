# Executive Summary — Regulated Google Workspace: Assured Controls, ITAR & DFARS

## The problem
Enterprises with **ITAR** or **DFARS** obligations cannot simply turn on Google Workspace for
controlled data. Controlled Unclassified Information and export-controlled technical data need three
boundaries the default tenant does not provide: **where data lives** (residency/sovereignty),
**who can touch it in support** (provider-access limits), and **a policy configuration** aligned to the
applicable regime and to internal compliance policy. Turned on without these, Workspace leaves
controlled data with no sovereignty guarantee, open provider-support access, and no evidence to show an
auditor.

## The solution
Configure Google Workspace for controlled data using **Assured Controls** (a paid add-on on Frontline
Plus / Enterprise Plus) and the related **data-region**, **access-management**, and **access-approval**
capabilities:
- **Data-region residency** — pin data at rest to the required region (typically the **United States**).
- **Access Management** — limit which Google support staff can act on the data (**U.S.-persons-only**,
  or **CJIS / IRS 1075-authorized** staff), addressing the foreign-person-access concern.
- **Access Approvals + Access Transparency** — require approval before any provider access, with a
  logged, auditable trail.
- **Client-Side Encryption** — where legal relies on the ITAR end-to-end-encryption carve-out.
- **Compliance evidence** — policy-compliance log events, data-regions reporting, and compliance
  exports as audit proof.

Everything is deployed **pilot-first** on a curated OU, **validated against the required posture**, and
**expanded** only after legal/compliance sign-off — with named, reusable configurations and a
documented rollback.

## What is explicitly out of scope
**Regulatory interpretation is deferred to legal/compliance.** This solution delivers the **technical
configuration and the evidence** — it does **not** make legal determinations about whether a
configuration satisfies ITAR, DFARS/NIST 800-171, or any regime for your data. It never invents Assured
Controls specifics; edition-/contract-dependent details are cited or flagged **"verify in your tenant."**

## Business outcome
Controlled data in Google Workspace with **sovereignty, provider-access boundaries, and an audit-ready
evidence trail** — aligned to ITAR/DFARS and internal policy, proven on a pilot before you scale.
Self-guided and tested, at a fraction of the cost of a bespoke compliance engagement — with the legal
determination left, correctly, to your compliance team.

## Effort & risk
- **Effort tier:** T4 — architecture/governance work on a live, regulated environment.
- **Risk posture:** read-only discovery/validation/reporting; state-changing steps default to `-WhatIf`;
  pilot gate and rollback on every production change.
- **Prerequisites:** Assured Controls add-on on a qualifying edition; named legal/compliance owners;
  data classification; super-admin/scoped compliance roles; a pilot OU.
