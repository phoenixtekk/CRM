# Executive Summary — Microsoft Defender for Endpoint Integration (Government / GCC High)

## The problem
Microsoft Defender for Endpoint (MDE) in **GCC High** is **not** the Commercial product behind a
different sign-in. The sovereign-cloud admin portals differ (every one is a `.us` host), the device
onboarding and telemetry endpoints differ, the automation environment differs (US Gov Microsoft
Graph), and **some capabilities lag, are limited, or are absent** versus Commercial. Teams that
follow Commercial guidance on a GCC High tenant get sent to portals that show the wrong tenant and
lean on features that silently aren't there — producing gaps that only surface during an incident or
an audit.

## What this solution does
This is the **Government (GCC High) edition** of the MDE Integration solution. It takes a novice
administrator, click by click, through wiring **Defender for Endpoint** to **Microsoft Intune** on a
**US sovereign-cloud** tenant so that **device risk drives compliance and access**:

- Enable the **Intune ↔ MDE connector** in the **GCC High Defender portal** (`security.microsoft.us`).
- Onboard devices via an Intune **EDR policy** using **Auto from connector**, so the sensor registers
  to the **US Government** environment.
- Wire the **machine risk score** into a device **compliance policy**, and optionally enforce with
  **Conditional Access** (require a compliant device).
- **Pilot → validate → expand** in waves, with a gate at each boundary.

Throughout, it uses the correct **`.us` portals**, the **US Gov MDE API** base URIs, the
**Gov/GCC/DoD connectivity URL lists**, and **US Gov Graph** (`-Environment USGov`) — and it calls
out the **Commercial-vs-GCC High/DoD parity gaps** (with citations) so you configure to what your
tenant actually has.

## What's included
- Nine documents: overview (with a Commercial-vs-GCC High section), requirements, ordered
  implementation, testing gates, troubleshooting, best practices, a **cited parity reference**, this
  summary, and the shared category requirements.
- **Five PowerShell scripts** (discovery, validation, reporting, safe remediation, scope targeting),
  all connecting to **US Gov Graph**; read-only tools are read-only, change tools default to
  **`-WhatIf`**.

## Why it matters
- **Correct by construction:** sovereign portals and Gov endpoints, so nothing silently talks to the
  Commercial cloud.
- **Parity handled:** you know which features are present in GCC High/DoD and where to write a manual
  playbook — no surprises mid-incident.
- **Proven before you scale:** every capability is validated on a pilot with explicit pass/fail gates
  before fleet rollout, and each wave leaves an evidence record for audit (useful for CMMC/DoD
  programs).

## Bottom line
Microsoft Defender for Endpoint deployed **correctly on GCC High** — right portals, right endpoints,
parity gaps handled — and **proven on a pilot before you scale**. Self-guided, tested, at a fraction
of consulting cost.

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"; Intune ↔
Defender integration guidance. Verify GCC High / DoD specifics in your tenant.*
