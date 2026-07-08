# 1. Solution Overview — Microsoft Purview for Healthcare (HIPAA/PHI)

## What this delivers
Healthcare organizations hold **electronic protected health information (ePHI)** — patient records,
diagnoses, insurance identifiers, clinical correspondence — under specific obligations (in the U.S.,
the HIPAA Privacy and Security Rules). This solution configures a **Healthcare-tailored Microsoft
Purview program** — sensitivity labels, Data Loss Prevention (DLP), retention/records, and the
supporting classification — so PHI is **classified, protected, retained on a defined schedule, and
its handling is evidenced**. It is the same Purview toolset, tuned for a PHI data estate and rolled
out on a pilot-first model so clinical work is never disrupted.

> **Scope boundary.** This solution provides the **technical configuration method and the evidence** —
> it does **not** make regulatory, records, or legal determinations. *Which* data is a designated
> record set, *how long* medical records must be retained (this is set by state law and your records
> schedule and varies widely — often longer for minors), whether a HIPAA obligation applies, and any
> legal-hold or insider-risk case action are **deferred to your compliance, records, privacy, and
> legal functions.** You supply the schedule and the classification intent; the solution implements it.

## The four Purview capabilities, tuned for PHI
1. **Sensitivity labels** — persistent tags (for example `Public`, `Internal`, `Confidential - PHI`,
   `Highly Confidential - PHI Restricted`) that can encrypt content, apply visual markings, and
   restrict sharing so PHI stays protected wherever a file travels — inside or outside the tenant.
2. **Data Loss Prevention (DLP)** — policies that detect PHI (for example the built-in **U.S. Health
   Insurance Act (HIPAA)** template and health-related sensitive information types) and take
   action — audit, warn, or block — as users share it across Exchange, SharePoint, OneDrive, Teams,
   and managed endpoints.
3. **Retention and records** — labels and policies that keep PHI-related content for a
   schedule-defined period and then dispose of it (or block deletion for declared records), so the
   organization meets its retention obligations without hoarding or over-deleting.
4. **Classification and reporting** — sensitive information types, trainable classifiers, and the
   Purview audit / Activity explorer that make PHI coverage visible and reportable.

## How it works
1. You design a small PHI-aware label taxonomy and publish it with a label policy so labels appear in
   Outlook, Word, Excel, and the web. **Auto-labeling** can apply the PHI label automatically based on
   content (for example content matching the HIPAA sensitive-information types) — always in
   **simulation** first.
2. DLP policies reference the healthcare sensitive-information types and/or the PHI sensitivity label.
   Each policy is first deployed in **audit/test mode**; you review the matches (the DLP audit gate),
   tune out false positives, and only then switch to enforce (warn or block).
3. Retention labels and policies set how long PHI-related content lives and what happens at the end of
   the period, using **the schedule your records/legal function supplies**. Records management adds
   declared, immutable records and disposition review.
4. Every action is logged in the Purview audit and Activity explorer, so PHI classification and DLP
   coverage can be reported and defended.

## What you can control
- The label taxonomy, priority order, and the protection each label applies (encryption, PHI markings,
  sharing restrictions) — scoped so PHI-restricted content follows the **minimum-necessary** principle.
- Where labels are published and whether auto-labeling applies the PHI label by content match.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoint devices), the health/PHI sensitive
  information types or label a policy matches, and the action (audit, notify, block) plus policy tips.
- Retention duration, trigger, and end-of-life action (delete, retain, or declare a record) — driven
  by **your** records schedule; records management and disposition review.

## Benefits
- **Protection that travels** — a PHI sensitivity label encrypts and marks content so ePHI stays
  protected outside the tenant, supporting the HIPAA Security Rule's technical-safeguard expectations.
- **Fewer leaks, clinician-safe** — DLP tuned in audit before enforcement blocks real PHI exposure
  without blocking legitimate care coordination.
- **Defensible retention** — PHI-related content is kept and disposed on a defined schedule you can
  evidence in an audit.
- **Reportable coverage** — PHI classification and DLP events are visible per service and fleet-wide.

## Limitations (be honest with buyers)
- Several capabilities (auto-labeling at rest, endpoint DLP, DSPM/DSPM for AI, insider risk,
  communication compliance, advanced records) require **Microsoft 365 E5** or the **E5 Compliance**
  add-on, and some features are in preview — the Requirements Guide names the licensing; **verify your
  licensing/tenant**.
- **Encryption can affect clinical and third-party apps.** A label that encrypts content may block
  legacy EHR integrations, PACS viewers, or apps that do not understand the protection. **Pilot before
  broad enforcement** and plan emergency-access / continuity-of-care handling with clinical IT.
- **Retention deletion is irreversible** once the period elapses — validate the schedule on a pilot
  scope, and use disposition review for records so nothing is auto-deleted unreviewed.
- Purview protects PHI **within Microsoft 365 and onboarded endpoints** — PHI in a separate EHR,
  imaging system, or medical device is out of scope for these controls.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).** Design the PHI
> taxonomy → publish labels → configure auto-labeling in simulation → build DLP in audit and tune (the
> DLP audit gate) → set retention/records from your schedule → pilot → validate → expand — with
> explicit pass/fail gates and a documented rollback, and all regulatory/records/legal determinations
> deferred to the relevant governance functions.
