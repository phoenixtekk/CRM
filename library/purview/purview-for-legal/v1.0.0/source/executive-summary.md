# Executive Summary — Microsoft Purview for Legal

## The problem
A law firm or corporate legal department holds the tenant's most sensitive concentration of material:
**attorney-client privileged** content and **matter records** carrying retention, records, and
legal-hold obligations. Generic tenant configuration does not fit that reality — privilege is
inadvertently disclosed by a mis-sent email or mislabeled file, matter content is under- or
over-retained, and there is no evidence that any control is actually in place. Left unaddressed, that is
both a compliance gap and a data-risk exposure, and it surfaces at the worst possible moment: during a
matter or an audit.

## The solution
A complete, self-guided **Legal-tailored program** built on **Microsoft Purview** — one that *curates and
sequences* the granular Purview capabilities for a legal organization rather than re-teaching each one.
It maps the in-scope obligations to four configured Purview controls — **sensitivity labels** (privileged
and matter-confidential, with encryption), **DLP** (preventing inadvertent disclosure of privileged
material across email, SharePoint, OneDrive, Teams and endpoints), **retention & records** (matter-based
retention plus governed disposition), and **Audit** (the evidence trail) — tracks them in **Compliance
Manager**, **pilots the high-impact ones in simulation/test/disabled mode**, validates them, and produces
an **evidence binder** (control → configuration → proof) you can hand to an auditor or produce in a
matter. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you commit) do the
assessment, scoping, configuration, validation, and evidence reporting.

## What you get
- **An obligation-to-control register** — every in-scope obligation mapped to the Purview object that implements it, with the required behavior and a named approver.
- **Privilege protection** — an encrypted sensitivity label for privileged content and a matter-confidential label, published to the legal population, with encryption scoped to legal's approved design.
- **Inadvertent-disclosure prevention, simulation-first** — a DLP policy built **in simulation** across email/SharePoint/OneDrive/Teams/Endpoint, its matches reviewed and tuned before a single block, then enforced under sign-off.
- **A governed matter-records lifecycle** — matter-based retention piloted with a non-regulatory label first, with disposition review where the schedule requires, and legal-hold coordination (hold decisions stay legal's).
- **An audit-ready evidence binder** — control → configuration → proof, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before
enforcement, with pass/fail gates and documented rollback. DLP is validated **in simulation** before it
ever blocks; the irreversible **regulatory-records** label is gated hardest of all, applied only under
explicit legal/records sign-off.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (encryption labels, Teams/Endpoint DLP,
records/regulatory records, and Audit Premium require E5 or the E5 Compliance add-on) and the portal is
**actively evolving** — capabilities and paths are cited or flagged **"verify your licensing/tenant,"**
never assumed. Above all: **what is privileged, how matters map, retention adequacy, disposition
triggers, and whether a matter is under legal hold are deferred to your legal, records, and compliance
functions** — this solution provides the technical control and the evidence, not the determination.
**Legal holds and eDiscovery case actions remain the legal function's; this program references the method
read-only and never creates or releases a hold.**

## The bottom line
A Legal program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so when
privilege must be protected, a matter's records produced, or a control shown to an auditor, the
capability is already in place and defensible.
