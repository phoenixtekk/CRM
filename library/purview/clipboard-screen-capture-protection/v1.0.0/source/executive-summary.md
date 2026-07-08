# Executive Summary — Clipboard & Screen-Capture Protection in Microsoft Purview

## The problem

Sensitive data leaves endpoints through the two most mundane paths of all — a user **copies content to
the clipboard** and pastes it into personal webmail, chat, or a note-taking app; or a user **takes a
screenshot** of a sensitive document, dashboard, or record and the pixels walk out as an image. Both
**bypass every control that watches the file**: the document can be encrypted, un-shareable, and blocked
from email, yet the copy-paste and the screenshot never touch any of those controls. Left unaddressed,
that is both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution delivers **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)** restrictions for
**copy to clipboard** and **screen capture** of sensitive content on **onboarded Windows and macOS
devices**, end to end. It confirms the sensitive-content detectors (sensitivity labels and/or sensitive
information types), configures the Endpoint DLP settings that define sanctioned apps and browsers, and
authors a single policy whose rule restricts the two activities — keyed to your sensitive content.
Crucially, every restriction is **piloted in simulation/test mode first** — it records what it *would* do
without blocking anyone — validated on a small device ring, and only then moved to **enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

Because endpoint block actions stop work at the moment of the action, nothing is enforced until it has
been proven, in simulation, to catch the right content and leave sanctioned copy-paste and normal
screenshots alone — with a one-setting rollback to simulation available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing (pass/fail
  gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery, configuration
  (simulation, `-WhatIf` first), validation, reporting, and scope/health readiness — all **read-only or
  preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured, that the clipboard and screen-capture
  restrictions were validated in simulation before enforcement, that the false-positive rate is low, and
  that matches raise alerts that are triaged.

## Scope and boundaries

- Endpoint DLP is **licensing-dependent** (typically Microsoft 365 E5 / the E5 Compliance add-on) and
  requires **onboarded devices**; the Purview portal **evolves** — capability availability and exact paths
  are **verified against your licensing/tenant**, never assumed.
- **Screen-capture restriction is newer and may be in preview**, is limited to supported apps/browsers and
  minimum OS builds, and evolves — this solution **flags "verify your licensing/tenant"** and can deliver
  **clipboard restriction first** where screen capture is not yet available.
- **Regulatory, records, and legal determinations** — which data is sensitive, whether copy/screenshot must
  be **blocked** versus **audited**, and whether a user's action is a violation — remain with your
  **compliance, security, records, privacy, and legal** functions. This solution provides the **technical
  method and the evidence**, not the determination.

## The bottom line

Two **uncontrolled exfiltration paths** — the clipboard and the screenshot — become a **monitored, then
enforced** control set in Microsoft Purview: **configured, piloted in simulation, validated, and
defensible.**
