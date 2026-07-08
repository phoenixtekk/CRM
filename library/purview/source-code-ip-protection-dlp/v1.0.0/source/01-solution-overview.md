# 1. Solution Overview — Source-Code & IP Protection DLP (Microsoft Purview)

## What this solution is
Source code and intellectual property are among the organization's most valuable — and most portable —
assets. A developer emails a code snippet to a personal account, copies a repository to a USB drive,
uploads proprietary designs to a personal cloud, or pastes a key algorithm into a chat. By default nothing
detects that the content is source code or IP, and nothing stops it from leaving. This solution closes
that gap with **Microsoft Purview Data Loss Prevention (DLP)** plus **classifiers** that detect and protect
source code and IP **across channels**:

- **Detect source code and IP** — use Purview's built-in **Source Code trainable classifier**, plus
  **custom sensitive information types / keyword dictionaries** for project code-names, internal
  identifiers, and IP markings, so the policy acts on content that *is* source code or IP, not just files
  with a certain extension.
- **Protect across channels** — apply the DLP policy across **Exchange (email), SharePoint, OneDrive,
  Teams**, and **endpoints/devices (Endpoint DLP)** so exfiltration is governed on the paths that matter:
  email to external recipients, uploads to personal cloud, **copy to USB/removable media**, and unmanaged
  browser uploads.
- **Educate and restrict** — show a **policy tip**, notify the user, alert admins, and (after piloting)
  **block or restrict** the egress action for content that matches, so protection teaches and enforces.
- **Prove it in test mode first** — every DLP policy is created in **test/simulation mode**, so you see
  exactly what it *would* match and block on real activity before any enforcement affects a developer's
  workflow.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com) and **Security &
Compliance PowerShell** (`Connect-IPPSSession`) — no third-party tooling. Policies are configured,
**piloted in test mode on a small ring first**, validated against pass/fail gates, then enforced and
expanded.

> **DLP detects and governs egress; it is not a code-repository security tool.** This solution detects
> source code / IP in the M365 data flow and on endpoints and controls how it can leave. It does not secure
> the Git server, scan repositories for secrets, or replace developer-platform controls — those are
> complementary. This solution delivers the Purview DLP half across email, collaboration, and endpoints.

## Why this matters
- **Code and IP leave through everyday actions.** Email, personal cloud upload, USB copy, and chat are all
  normal — and all exfiltration paths for the crown jewels. DLP inspects the content and governs the action.
- **Content beats extension as a control.** A renamed file or a pasted snippet defeats extension-based
  rules. The Source Code classifier and custom IP types match on what the content *is*.
- **Endpoint DLP closes the USB/upload gap.** Email and SharePoint DLP don't see a copy to a USB stick or a
  browser upload — Endpoint DLP does, extending protection to the device.
- **It is defensible and auditable.** "Source code and marked IP cannot be emailed externally or copied to
  USB, and every attempt is logged" is a statement you can evidence with a policy and its reports, not a
  hope.

## How it works
1. **Assess.** Read the tenant's current state — existing **DLP policies and rules**, which locations they
   cover, the availability of the **Source Code classifier** and relevant **sensitive information types**,
   and whether **Endpoint DLP** device onboarding is in place — all read-only.
2. **Design.** With security/IP owners, decide the **detection** (Source Code classifier + custom IP
   types/keywords), the **channels** (email, SharePoint/OneDrive, Teams, endpoint), the **actions**
   (restrict/block egress, notify, policy tip, alert), and the **exceptions** (approved repos/tools) —
   aligned to the IP-classification intent your stakeholders set.
3. **Configure.** Create the **`Source-Code & IP DLP – Policy`** with its rule(s) across the in-scope
   channels in Purview, scoped to the pilot, **in test mode** (no enforcement yet).
4. **Pilot.** Run the policy in **test/simulation mode** on a pilot ring — never enforcing on day one — and
   review what it *would* match and block on real developer activity. Blocking egress is **high-impact**
   for developer workflow; prove the matches first.
5. **Validate.** Confirm the policy detects source code / IP across the intended channels, that policy tips
   and alerts fire, and that false positives (build tools, legitimate sharing) are tuned out — against the
   pass/fail gates.
6. **Expand.** Move the policy from test to **enforce** once validated and stakeholders approve, broaden
   scope and channels, and hand ongoing tuning and reporting to operations.

## The DLP design (used throughout)
Names below are examples; the **determination** of what is protected IP and which egress to block belongs
to your security, IP, and legal stakeholders — this solution provides the technical implementation.

| Element | Design intent |
|---|---|
| DLP policy | `Source-Code & IP DLP – Policy` (Exchange + SharePoint + OneDrive + Teams + Endpoint) |
| Detection rule | `Source-Code Detection Rule` — Source Code classifier + custom IP types/keywords |
| Actions | Restrict/block egress (external email, USB copy, cloud/browser upload), notify (policy tip), alert admins |
| Mode | **Test (with/without policy tips) during pilot; Enforce after validation** |
| Pilot ring | `Source-Code DLP – Pilot Ring – Stage1` — a small set of developer users/devices |
| Scope/design map | `Source-Code DLP – Map` |
| Coverage report | `Source-Code DLP – Coverage Report` |

> **Licensing / plan note — verify against your own tenant.** DLP for Exchange/SharePoint/OneDrive/Teams is
> included with **Microsoft 365 E3**; **Endpoint DLP**, **trainable classifiers** (including Source Code),
> and advanced DLP conditions generally require **E5 / E5 Compliance**. **Endpoint DLP** also requires
> **device onboarding** (shared with Microsoft Defender for Endpoint). Confirm the exact capability
> availability, the classifier/SIT names, and portal paths for *your* tenant in Microsoft's documentation
> before you design — the DLP surface is evolving. Where a capability is unavailable, scope to what your
> plan supports and record the rest as **deferred**.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default; creates in test mode), Validation, and Reporting — built on Security &
  Compliance PowerShell, **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** What constitutes protected IP, which egress is acceptable (approved repos, partner
> sharing), and any legal obligation are **determinations owned by your security, IP, and legal
> functions**. This solution provides the technical configuration and the evidence — and never enforces
> before you validate in test mode — not the determination.
