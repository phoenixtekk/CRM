# Executive Summary — Browser & Network DLP in Microsoft Purview

## The problem

Users move sensitive data off the organization every day through the most ordinary path of all: the
**web browser**. A document is dragged into a personal Google Drive or Dropbox, a spreadsheet is pasted
into a consumer AI chat, a file is uploaded through a browser to an unsanctioned SaaS app. To the
network this is just HTTPS; to compliance it is **data walking out the door with no control and no
record**. Email and SharePoint DLP never see it — it happens in the browser, on the device. Left
unaddressed, that is both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution delivers **Microsoft Purview Browser & Network DLP** end to end. It confirms devices are
**onboarded** to Purview, deploys the **Microsoft Purview browser extension** (Chrome/Firefox) and
relies on **native Edge** integration so browser uploads become visible, groups the destinations that
matter — personal cloud and unsanctioned file-sharing/SaaS — into a **sensitive service domain group**,
sets the **unallowed-browsers** control so sensitive items can't be moved through a browser Purview
can't inspect, and authors a **Devices-scoped DLP policy** restricting uploads of your sensitive content
(sensitivity labels and/or sensitive information types) to those destinations. Crucially, the control is
**piloted in simulation/test mode first** — it records what it *would* audit, warn, or block without
stopping anyone — validated on a small device ring, and only then moved to **enforce** (Audit → Warn →
Block).

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

Because a web-upload block stops legitimate work at the moment of the action, nothing is enforced until
it has been proven, in simulation, to see the right browsers and destinations and act only on the right
content — with a one-command rollback available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing (pass/fail
  gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery,
  configuration (simulation, `-WhatIf` first), validation, upload-activity reporting, and
  scope/health — all **read-only or preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured, that the control was validated in
  simulation before enforcement, and that enforcement behaves as designed.

## Scope and boundaries

- Endpoint DLP browser & network controls are **licensing-dependent** (typically Microsoft 365 E5 / E5
  Compliance / E5 Information Protection & Governance; some settings in preview) and the Purview portal
  **evolves** — capability availability and exact paths are **verified against your licensing/tenant**,
  never assumed.
- Coverage depends on **onboarding and the browser extension**; the unallowed-browsers control is a
  steering control, not a guarantee against a determined user on unmanaged equipment.
- This solution focuses on **browser uploads to unsanctioned/personal web destinations**. Other Endpoint
  DLP channels (USB/removable media, print, clipboard/screen capture, network share) and other DLP
  locations (Exchange, SharePoint, OneDrive, Teams, cloud apps via Defender for Cloud Apps) are the
  subject of their own dedicated solutions.
- **Regulatory, records, and legal determinations** — which data is sensitive, which destinations are
  unsanctioned, whether an upload must be blocked versus audited, and whether an action is a violation —
  remain with your **compliance, security, records, privacy, and legal** functions. This solution
  provides the **technical method and the evidence**, not the determination.

## The bottom line

The most common **uncontrolled web-upload path** for sensitive data becomes a **monitored, then
enforced** control in Microsoft Purview — **configured, piloted in simulation, validated, and
defensible.**
