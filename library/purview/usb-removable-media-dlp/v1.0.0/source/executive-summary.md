# Executive Summary — USB & Removable-Media DLP in Microsoft Purview

## The problem

Removable media is the classic exfiltration path. A file copied to a **USB stick**, an SD card, or an
external drive walks out the door in a pocket — and server-side DLP (Exchange, SharePoint, OneDrive,
Teams) never sees it, because the copy happens entirely on the endpoint. Left unaddressed, that is
both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution governs data to **USB and removable media** end to end in Microsoft Purview, using
**two complementary control layers** on onboarded devices:

- **Endpoint DLP — removable media (content-aware):** detects and acts on *copy a sensitive file to
  removable storage* — Audit / Warn / Block — keyed to your sensitive content (sensitivity labels
  and/or sensitive information types), with an allow-list for corporate-issued media.
- **Device control — removable-storage access (device-aware):** allows / audits / blocks read, write,
  or execute on removable storage **by device group**, independent of content — so unapproved USB
  devices can be blocked or made read-only regardless of what is on them.

Together they deliver *block / audit / allow **by policy*** for USB and removable media. Crucially,
the content layer is **piloted in simulation/test mode** and the device layer **audit-first** — each
records what it *would* do without blocking anyone — validated on a small device ring, and only then
moved to **enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation/audit) → Validate → Expand (enforce).**

Because removable-media block and read-only actions stop work at the moment of the action, nothing is
enforced until it has been proven, in simulation/audit, to see the right activity and act only on the
right content and the right devices — with a fast rollback available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing
  (pass/fail gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery,
  configuration (simulation, `-WhatIf` first), validation, reporting, and scope/health — all
  **read-only or preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured across both layers, that each was
  validated in simulation/audit before enforcement, and that enforcement behaves as designed.

## Scope and boundaries

- Endpoint DLP and device control are **licensing-dependent** (typically Microsoft 365 E5 / E5
  Compliance / E5 Information Protection & Governance) and the Purview portal and device-control
  surfaces **evolve** — capability availability and exact paths are **verified against your
  licensing/tenant**, never assumed. Device-control policy deployment is a **management-tool** action
  (Intune / GPO / OMA-URI), not a Security & Compliance PowerShell cmdlet.
- **Regulatory, records, and legal determinations** — which data is sensitive, which devices are
  approved, and whether an action is a violation — remain with your **compliance, security, records,
  privacy, and legal** functions. This solution provides the **technical method and the evidence**,
  not the determination.

## The bottom line

The **classic USB exfiltration path** becomes a **monitored, then enforced** control set in Microsoft
Purview — content-aware and device-aware, **configured, piloted in simulation/audit, validated, and
defensible.**
