# Solution Overview — Endpoint DLP for Windows in Microsoft Purview

## What this solution delivers

Sensitive data does not only leave the organization over email and SharePoint links. On a Windows
laptop it walks out the **local** doors: a file copied to a **USB stick**, sent to a **printer**,
lifted through the **clipboard** into a personal webmail tab, dropped onto an unmanaged **network
share**, or **uploaded** to a personal cloud account in a browser. Server-side DLP (Exchange,
SharePoint, OneDrive, Teams) never sees any of it — those actions happen entirely on the endpoint.
**Microsoft Purview Endpoint DLP** closes that gap: once a Windows device is **onboarded**, Purview
can **see and control** those on-device activities against your sensitive content.

This solution walks a competent-but-novice administrator through a **complete, repeatable Windows
Endpoint DLP deployment**:

1. **Onboard Windows devices** to Microsoft Purview so the endpoint activities become visible —
   confirming the device prerequisites (supported Windows build, AV/onboarding health) and choosing
   an onboarding method (Intune, Group Policy, local script, or Configuration Manager).
2. **Configure the Endpoint DLP global settings** that every endpoint policy depends on — the
   pieces that define *what counts as* a USB device, a corporate printer, an allowed browser, or a
   sanctioned cloud domain (removable-media / printer / network-share groups, browser and service
   domain restrictions, restricted apps, file-path exclusions).
3. **Author a Windows Endpoint DLP policy** with rules for the five egress channels —
   **USB / removable media**, **print**, **clipboard**, **network share**, and **cloud egress**
   (browser upload) — each keyed to your sensitive content (sensitivity labels and/or sensitive
   information types), **piloted in simulation/test mode first** so nothing is blocked until you
   have validated it.
4. **Validate, then expand** — prove that each channel is seen and *would* act (audit → warn →
   block) on a small pilot device group, then move rules from simulation to **enforce** and widen
   scope deliberately, with an explicit pass/fail gate and a documented rollback at every step.

The result turns a set of **uncontrolled local exfiltration paths** into a **monitored, then
enforced** control set on Windows endpoints — configured, piloted, validated, and defensible in
Microsoft Purview.

## What Endpoint DLP is (and is not)

- **It is** the extension of Purview Data Loss Prevention to the **Devices** location — the ability
  to detect and act on **on-device** activities (copy to USB, print, clipboard, copy to network
  share, upload/egress via browser, and related activities) against content that matches your DLP
  conditions.
- **It requires onboarding.** A Windows device must be **onboarded to Microsoft Purview** (the same
  onboarding surface shared with **Microsoft Defender for Endpoint**) before any endpoint activity
  is visible or controllable. **No onboarding, no endpoint DLP.**
- **It is not** a substitute for your Exchange/SharePoint/OneDrive/Teams DLP — it is the **Devices**
  location alongside them. A single DLP policy can cover multiple locations; this solution focuses
  on the **Devices** location for Windows.
- **It is licensing-dependent.** Endpoint DLP is a premium capability (typically **Microsoft 365
  E5**, the **E5 Compliance**, or the **E5 Information Protection & Governance** add-on) and
  in-scope users must be licensed. Some endpoint activities and settings are newer or in preview and
  the portal evolves — **verify capability availability and exact portal paths against your
  licensing/tenant** rather than assuming (see `global-requirements-purview.md` §1).

## The five egress channels this solution controls

Each is an **on-device activity** Endpoint DLP can detect and, in a rule, **Audit**, **Warn with
override**, or **Block**:

| Channel | On-device activity controlled |
|---|---|
| **USB / removable media** | Copying a matching file to a USB / removable storage device (with allow-listed *device groups* for corporate-issued media). |
| **Print** | Printing a matching file (with allow-listed *printer groups* for sanctioned printers). |
| **Clipboard** | Copying matching content to the clipboard for paste into another app / browser. |
| **Network share** | Copying a matching file to a network share (with allow-listed *network-share groups*). |
| **Cloud egress (browser upload)** | Uploading a matching file to, or accessing it from, an **unallowed browser** or a **non-sanctioned service/cloud domain** (service-domain and sensitive-service-domain restrictions). |

> **Browser coverage.** **Microsoft Edge** is covered natively. **Chrome** and **Firefox** require
> the **Microsoft Purview browser extension** to see and control cloud-egress and clipboard-to-web
> activity. Confirm the extension is deployed to in-scope browsers — **verify against your tenant.**

## Simulate first — this is a high-impact control

Endpoint DLP **block** actions stop real work at the moment someone tries to copy, print, or upload.
A mis-scoped rule can block a legitimate user mid-task. Therefore **every** policy in this solution
is deployed in **simulation / test mode first** (the DLP policy modes *Test with notifications* /
*Test without notifications*; in the portal, *"Run the policy in simulation mode."*) — the policy
**evaluates and records what it *would* do without blocking anyone** — validated on a small pilot
device group, and only then moved to **enforce**. **Verify the exact simulation/test terminology in
your tenant** (the portal wording evolves).

> **Determinations are not yours to make.** *Which* data is sensitive, *which* channels must be
> blocked versus merely audited, and *whether* a given user's action is a policy violation are
> **compliance / records / security / HR-legal determinations** — this solution delivers the
> technical configuration and the evidence, not the determination (see
> `global-requirements-purview.md` §5).

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand (enforce).**

- **Assess** — confirm licensing, least-privilege roles, device-onboarding readiness, the in-scope
  sensitive content, the pilot device group, and compliance/security stakeholder sign-off.
- **Design** — decide which channels **audit** vs **warn** vs **block**, define the device / printer
  / network-share groups and the browser/service-domain lists, name every object, and set the pilot
  scope.
- **Configure** — onboard devices, set the Endpoint DLP global settings, then build the policy and
  its five rules in **simulation/test mode**.
- **Pilot** — run in simulation on the pilot devices; confirm each channel is seen and *would* act
  without blocking anyone.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — move rules from simulation to enforce and widen device scope **only** after the gate
  passes; roll back per `03-implementation.md` if a gate fails.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing**
  (pass/fail gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** +
  **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph): a **Discovery**
  inventory of onboarding readiness and existing endpoint DLP config, a **Configure/Remediation**
  helper that builds the policy + rules in **simulation (`-WhatIf` first)**, a **Validation**
  checker, a **Reporting** rollup of endpoint DLP configuration and activity, and a **scope/health**
  helper — **read-only or `-WhatIf` by default; no credentials in code.**

> **Sources.** Microsoft Learn — *Learn about Microsoft Purview Endpoint data loss prevention*,
> *Get started with / Onboard Windows devices into Microsoft Purview*, *Configure endpoint DLP
> settings*, *Create and deploy data loss prevention policies* (conditions, actions, simulation
> mode), and the *Microsoft Purview browser extension*. Endpoint DLP is **licensing-dependent** and
> the Purview portal is **evolving** — **verify capability availability, portal paths, and cmdlet
> parameters against your licensing/tenant** rather than assuming.
