# Executive Summary — Microsoft Purview DLP, Labels & Retention (Government / GCC High)

## The problem

Microsoft Purview in **GCC High is not the Commercial product with a different sign-in.** The admin
portals are separate US sovereign-cloud endpoints (`compliance.microsoft.us`, `security.microsoft.us`,
`login.microsoftonline.us`), and **several Purview capabilities lag, are limited, or are absent**
versus Commercial. A government tenant configured from Commercial runbooks silently fails — options
simply are not present, and steps assume features that do not exist in GCC High.

## What this solution does

It deploys the three Purview pillars — **sensitivity labels + auto-labeling**, **Data Loss
Prevention**, and **retention + records management** — **correctly for GCC High**: the right portals,
the right endpoints, and the Commercial-vs-GCC-High **feature parity gaps called out at the exact
step where they matter**. It follows a repeatable **Assess → Configure → Pilot → Validate → Expand**
model with pass/fail gates, so the configuration is proven on a named pilot before it scales.

## The GCC High differences that matter (doc-confirmed)

Drawn from Microsoft's *Plan for Microsoft Purview — GCC High deployments* service description:

- **Named-entity sensitive information types** are **not available** — DLP and auto-labeling are
  built from GA building blocks (built-in SITs, Exact Data Match, keywords, regex).
- **Auto-labeling on Office *mobile* clients** is **not available**; service-side (EXO/SPO/OneDrive)
  and desktop/web client-side auto-labeling **are**.
- **Auto-applying *records* labels with trainable classifiers**, and **applying a retention label
  action at end of the retention period**, are **not available** — condition/event-based retention
  is used instead.
- **Records-management Power Automate and several Graph APIs** are **not available**.
- **Adaptive Protection** (risk-based DLP) is **rolling out to Gov clouds** — verify before relying
  on it. **Microsoft Priva** is **not available**.

Where a GCC High specific could not be confirmed, the solution states the Commercial behavior and
**explicitly flags "verify for GCC High"** rather than inventing menus or parity claims.

## Business outcome

An ungoverned data estate — unclassified data, DLP noise, no retention, compliance gaps — becomes a
**governed** one: data **labeled, protected, and retained** on a US sovereign cloud, configured the
repeatable way, validated on a pilot, and safe to expand. Self-guided and tested, at a fraction of
consulting cost.

**Deployment model:** Assess → Configure → Pilot → Validate → Expand.
