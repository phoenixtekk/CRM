# 1. Solution Overview — SharePoint Online DLP (Microsoft Purview)

## What this solution is
SharePoint and OneDrive are where the organization's documents live — and sharing is one click away. A
site owner shares a library "with anyone," a user forwards a OneDrive link outside the company, a document
full of customer PII sits in a site that's open to the whole tenant. Any of those can put sensitive
content in front of the wrong audience, and by default nothing inspects the content or the share. This
solution closes that gap with **Microsoft Purview Data Loss Prevention (DLP)** for SharePoint and
OneDrive — policies that inspect documents for **sensitive content** and govern how they can be
**shared**:

- **Detect sensitive content** — match documents against **sensitive information types** (credit-card,
  national ID, health, financial), **sensitivity labels**, keyword/dictionary conditions, or trainable
  classifiers, so the policy acts on what a document *contains*, not just where it sits.
- **Govern sharing and external access** — detect and (after piloting) **block or restrict external
  sharing**, sharing with "everyone," or access by people outside the organization, so sensitive
  documents don't leave through a share link.
- **Educate with policy tips and notify** — show the user a **policy tip** at the point of sharing and
  notify/alert admins, so protection teaches rather than just blocks.
- **Prove it in test mode first** — every DLP policy is created in **test/simulation mode** (test with or
  without policy tips), so you see exactly what it *would* match and block on real content before any
  enforcement affects a user.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com) and **Security &
Compliance PowerShell** (`Connect-IPPSSession`) — no third-party tooling. Policies are configured,
**piloted in test mode first**, validated against pass/fail gates, then enforced and expanded.

> **DLP acts on content and actions, not on storage cleanup.** This solution inspects SharePoint/OneDrive
> documents and controls sharing/external access. It does **not** retain or delete content (that's the
> Data Lifecycle solution) or classify items with sensitivity labels (that's an Information Protection
> solution) — though DLP can *use* those labels as a condition. The three are complementary; this
> solution delivers the DLP half for SharePoint and OneDrive.

## Why this matters
- **A share link is an exfiltration path.** "Share with anyone" turns an internal document into a public
  one with one click. DLP inspects the content and can stop the share when the document is sensitive.
- **Content beats location as a control.** A site's permissions don't know what's inside its documents.
  DLP matches on the actual sensitive information, so a customer-PII spreadsheet is protected wherever it
  lands.
- **Policy tips change behavior.** A tip at the moment of sharing ("this document contains customer data
  — sharing externally is restricted") stops mistakes before they happen and trains users over time.
- **It is defensible and auditable.** "SharePoint/OneDrive documents containing regulated data cannot be
  shared externally, and every match is logged" is a statement you can evidence with a policy and its
  reports, not a hope.

## How it works
1. **Assess.** Read the tenant's current state — existing **DLP policies and rules**, which locations they
   cover, and the **sensitive information types** and labels available to match on — all read-only.
2. **Design.** With compliance/security, decide which **sensitive content** to detect, which **sharing
   actions** to govern (external sharing, "everyone" sharing, external access), the **actions** (restrict
   access, block sharing, notify, policy tip), and the **exceptions** — aligned to the classification
   intent your stakeholders set.
3. **Configure.** Create the **`SPO-OneDrive DLP – Policy`** with its rule(s) in Purview, scoped to the
   pilot, **in test mode** (no enforcement yet).
4. **Pilot.** Run the policy in **test/simulation mode** on the pilot sites — never enforcing on day one —
   and review what it *would* match and block on real content. DLP enforcement is **high-impact** for
   collaboration; prove the matches first.
5. **Validate.** Confirm the policy matches the intended sensitive content and share conditions, that
   policy tips and admin alerts fire, and that false positives are tuned out — against the pass/fail
   gates.
6. **Expand.** Move the policy from test to **enforce** once validated and stakeholders approve, broaden
   the scope to all intended locations, and hand ongoing tuning and reporting to operations.

## The DLP design (used throughout)
Names below are examples; the **determination** of which content is sensitive and which sharing to block
belongs to your compliance, security, and privacy stakeholders — this solution provides the technical
implementation.

| Element | Design intent |
|---|---|
| DLP policy | `SPO-OneDrive DLP – Policy` (SharePoint + OneDrive locations) |
| Detection rule | `SPO DLP – External Sharing Rule` — sensitive info type/label + shared-externally condition |
| Actions | Restrict access / block external sharing, notify the user (policy tip), alert admins |
| Mode | **Test (with/without policy tips) during pilot; Enforce after validation** |
| Pilot scope | `SPO DLP – Pilot Sites – Stage1` — limited sites/OneDrive accounts |
| Scope/design map | `DLP Scope – Map` |
| Coverage report | `SPO DLP – Coverage Report` |

> **Licensing / plan note — verify against your own tenant.** DLP for SharePoint/OneDrive/Exchange is
> included with **Microsoft 365 E3**; some advanced DLP capabilities (certain classifiers, richer
> conditions) require **E5 / E5 Compliance**. Confirm the exact capability availability, the sensitive
> information types, and portal paths for *your* tenant in Microsoft's documentation before you design —
> the DLP surface is evolving. Where a capability is unavailable, scope to what your plan supports and
> record the rest as **deferred**.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default; creates in test mode), Validation, and Reporting — built on Security &
  Compliance PowerShell, **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** Which content is sensitive, which sharing is acceptable, and any regulatory obligation on
> the data are **determinations owned by your compliance, security, and privacy functions**. This
> solution provides the technical configuration and the evidence — and never enforces before you validate
> in test mode — not the determination.
