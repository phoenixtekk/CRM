# 1. Solution Overview — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

## What this solution is
SharePoint and OneDrive fill up and never empty. Sites accumulate a decade of documents; departed
employees' OneDrive accounts linger; the same file exists in five versions across three libraries. Some
of that content **must be kept** for a regulatory or business period; much of it **should be cleaned up**
once it ages out. Doing neither is the default, and it is both a compliance gap (you can't prove you keep
what you must) and a risk (you're holding stale, discoverable content you no longer need). This solution
closes that gap with **Microsoft Purview Data Lifecycle Management** — **retention policies** for
SharePoint and OneDrive that:

- **Retain** content for a defined period so it can't be permanently deleted before its time — satisfying
  the "keep it" side of the schedule.
- **Clean up** content when it ages out — **retain-then-delete** (keep for N years, then remove) or
  **delete-only** — satisfying the "don't hoard it" side.
- **Scope precisely** — apply to **all** SharePoint sites and OneDrive accounts, or to a targeted set via
  a **static scope** (named sites/accounts) or an **adaptive scope** (a rule over site/user properties),
  so the right content gets the right rule.
- **Operate safely** — SharePoint/OneDrive retention keeps deleted-but-retained content in the
  **Preservation Hold Library** so nothing is lost mid-flight, and the policy is proven on a **limited
  pilot scope in retain-only mode first** before any deletion is enabled.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com) and **Security &
Compliance PowerShell** (`Connect-IPPSSession`) — no third-party tooling. Policies are configured,
**piloted on a limited scope first**, validated against pass/fail gates, then expanded.

> **Retention *policies* apply a period to a location; retention *labels* classify individual items.**
> This solution uses **retention policies** (and adaptive/static scopes) to apply a lifecycle to
> SharePoint sites and OneDrive accounts at the location level. Item-level **retention labels** and
> **records management / file plans** are a complementary, separate effort. The two work together; this
> solution delivers the location-level lifecycle.

## Why this matters
- **You can't prove retention you didn't configure.** "We keep project records for seven years" is a
  policy statement only when a retention policy enforces it — otherwise a user can permanently delete a
  document tomorrow.
- **Stale content is liability.** Every obsolete file you keep past its usefulness is discoverable in
  litigation, exposed in a breach, and clutter in search. Cleanup that runs on a schedule shrinks that
  surface without anyone remembering to do it.
- **Departed-employee OneDrive sprawl.** OneDrive accounts of leavers accumulate; a lifecycle policy
  gives them a defined end instead of indefinite, unmanaged persistence.
- **It is defensible and auditable.** "Every in-scope site retains for the schedule and cleans up after"
  is a statement you can evidence with a policy and a report, not a hope.

## How it works
1. **Assess.** Read the tenant's current state — existing **retention policies and rules**, which
   SharePoint/OneDrive locations they cover, and whether adaptive scopes exist — all read-only.
2. **Design.** With records/compliance, translate the **retention schedule** into concrete rules: what
   period, retain-only vs retain-then-delete vs delete-only, and the **scope** (all locations, a static
   set, or an adaptive rule) for each. The schedule itself is a records/legal determination — you
   implement it.
3. **Configure.** Create the **`SPO-OneDrive Retention – Policy`** and its rule(s) in Purview, scoped to
   the pilot first, **starting in retain-only** where deletion is intended (add deletion after
   validation).
4. **Pilot.** Apply to a **limited pilot scope** (`SPO Lifecycle – Pilot Scope – Stage1`: a small set of
   sites / an adaptive-scope subset) — never all locations on day one. Deletion is **irreversible after
   the hold window**; prove the scope and behavior first.
5. **Validate.** Confirm the policy covers exactly the intended locations, that retained content is held
   (Preservation Hold Library), and — only when you deliberately test deletion — that cleanup behaves as
   designed, against the pass/fail gates.
6. **Expand.** Broaden the scope to all intended locations, enable the **delete** action once retain-only
   is validated and stakeholders approve, and hand ongoing coverage and reporting to operations.

## The lifecycle design (used throughout)
Names below are examples; the **schedule** (periods, what to keep, what to delete) is a records/compliance
**determination** — this solution provides the technical implementation.

| Element | Design intent |
|---|---|
| Retention policy | `SPO-OneDrive Retention – Policy` (SharePoint + OneDrive locations) |
| Retain-only rule | Keep in-scope content for the schedule's period; no deletion (start here) |
| Retain-then-delete rule | Keep for N years from create/modify, then delete (enabled after validation) |
| Scope | `all locations`, a **static scope** (named sites/accounts), or an **adaptive scope** (rule over properties) |
| Pilot scope | `SPO Lifecycle – Pilot Scope – Stage1` — limited sites / adaptive subset |
| Schedule/design map | `Lifecycle Schedule – Map` |
| Coverage report | `Lifecycle – Coverage Report` |

> **Licensing / plan note — verify against your own tenant.** Basic retention policies for SharePoint and
> OneDrive are available with Microsoft 365 E3; **adaptive scopes** and advanced retention capabilities
> generally require **E5 / E5 Compliance**. Confirm the exact capability availability and portal paths for
> *your* tenant in Microsoft's documentation before you design — the Data Lifecycle Management surface is
> evolving. Where a capability (e.g. adaptive scope) is unavailable, use a **static scope** and record the
> advanced capability as **deferred**.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default), Validation, and Reporting — built on Security & Compliance PowerShell,
  **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** The **retention schedule** — how long content must be kept, what is a record, what may be
> deleted and when, and any legal hold — is a **determination owned by your records-management,
> compliance, and legal functions**. This solution provides the technical configuration and the evidence,
> and (critically) never deletes on its own — deletion is enabled deliberately after validation and
> approval. It provides the method, not the determination.
