# Executive Summary — Print DLP (Microsoft Purview)

Every other data-loss control watches the file — email DLP, external-sharing blocks, encryption. None of
them sees a user open a sensitive document, press **Print**, and walk out with paper that has no audit
trail, no revocation, and no way back. Printing is the quiet blind spot in most data-protection programs,
and it is exactly the path a regulator or a breach post-mortem will ask about.

This solution closes it using **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)**: a policy
that watches the **Print activity** on onboarded devices and — when a document's content matches your
**sensitive information types** or carries a sensitive **sensitivity label** — can **audit**, **warn with a
policy tip and allow-with-justification**, or **block** the print, while telling **sanctioned corporate
printers** apart from **network, local, and print-to-PDF/XPS** output. It stands the control up end to end
using only the **Purview portal**, **Security & Compliance PowerShell**, and **Microsoft Graph** — no
third-party agent — and is written for an administrator with no prior Endpoint DLP experience.

## What you get
- A plain-language **Solution Overview** of the print exfiltration gap, how the Print activity and **printer
  groups** work, the complementary **sensitivity-label PRINT usage right**, and the simulate→enforce
  discipline.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category Purview
  requirements — tenant/compliance licensing, DLP roles, S&C PowerShell + Graph, in-scope data,
  stakeholders, pilot + change control — are referenced, not repeated).
- An **Implementation Guide** of precise, ordered steps: build the detectors, define printer groups, create
  the Devices-only Print policy **in simulation**, tune false positives down, enforce to a pilot ring, then
  expand — each artifact named, with pass/fail gates and rollback.
- Five **PowerShell scripts** for posture discovery, safe configuration (`-WhatIf`, simulation-only),
  policy-shape validation, activity reporting, and endpoint-readiness checks.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Printing of sensitive content is **controlled by policy** — proven in simulation, tuned to a low
false-positive rate, enforced from a ring outward, with corporate printing preserved, restricted prints
audited and alerted, and the control **defensible and evidenced**.

## The deployment model
**Assess → Design → Configure → Pilot (simulate) → Validate → Expand** — build the policy in simulation,
prove it against real print activity, enforce on a handful of users, then roll out in waves.

## An honest note
Endpoint DLP requires **onboarded devices and the right licensing** (typically **E5 / E5 Compliance** —
**verify your licensing/tenant**), and a Devices-location policy is inert until onboarding is complete.
**Windows** print restriction is the most complete; **macOS** print support and specific behaviours evolve —
where behaviour is OS-/tenant-dependent this package flags **"verify against current Microsoft guidance /
your tenant"** rather than asserting it. Which data is in scope and what the enforced action must be are
**compliance, privacy, and legal determinations**, deferred to those functions; this package delivers the
technical method and the evidence, not the determination.

## Outcome
A print-DLP control that stops sensitive documents from walking out on paper — configured, piloted in
simulation, validated against pass/fail gates, and operable — so the capability is in place and defensible
in Microsoft Purview.
