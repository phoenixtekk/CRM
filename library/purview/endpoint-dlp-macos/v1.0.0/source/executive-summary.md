# Executive Summary — Endpoint DLP for macOS (Microsoft Purview)

Data Loss Prevention programs are often built for Windows and the cloud — and leave **Macs as the
blind spot**. The same sensitive content that is blocked from leaving a Windows PC can walk off a Mac
over a USB drive, a browser upload, a network copy, the clipboard, or a print job. That is a
compliance gap and a real data-risk exposure. The fix does not require a new product: **Microsoft
Purview Endpoint DLP** already extends to **macOS**, in the tenant and policy engine you run today.

This solution delivers macOS Endpoint DLP end to end: **onboarding** Macs into Purview device
management (via **Intune** or **Jamf Pro**), configuring the shared **Endpoint DLP settings**, and
building a **DLP policy** that monitors and controls the key **egress channels** on the Mac —
piloted in **simulation / test (Audit)** first, validated in **Activity Explorer**, and only then
**enforced** on a controlled scope. It is written for an administrator with no prior macOS
Endpoint-DLP experience.

## What you get
- A plain-language **Solution Overview** of how macOS Endpoint DLP works — onboarding, the
  system/network extensions and Full Disk Access, the egress channels, and the simulation-first model.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category
  Purview requirements — licensing, roles, toolchain, classification intent, stakeholders, pilot — are
  referenced, not repeated).
- An **Implementation Guide** of precise, ordered **Purview + Intune + Security & Compliance
  PowerShell** steps: onboard the Macs, set Endpoint DLP settings, create the policy **in
  test/simulation**, pilot, validate, then enforce — each object named, with pass/fail gates and a
  one-command rollback.
- Five **PowerShell scripts** for readiness discovery, safe policy creation (`-WhatIf`, test-mode
  only), validation, Activity-Explorer reporting, and an onboarding/scope health check.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
macOS endpoints **onboarded** to Purview and **watched** across cloud/browser upload, USB, network
share, clipboard, print, and restricted-app access — **audited in simulation**, **validated** with
evidence, and **enforced** (Block) on the channels compliance approves, in waves. The Mac blind spot is
closed inside the DLP program you already own.

## The deployment model
**Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce)** — build onboarding and
the policy, prove them silently on a handful of Macs, then enforce and roll out in waves.

## An honest note
macOS Endpoint DLP support is a **subset of Windows** and is **evolving** (limited to the three latest
major macOS versions); onboarding requires real endpoint work (extension approval + Full Disk Access
via MDM). Enforcement is **high-impact** — hence simulation-first with a documented rollback. **Which**
data is regulated and **what** must be blocked are **compliance, records, and legal** determinations;
this package provides the technical configuration and the evidence, not the determination — and flags
**"verify your licensing / tenant / macOS version"** wherever availability is plan- or version-
dependent.

## Outcome
A macOS fleet inside your **Microsoft Purview** DLP program — onboarded, monitored across the key
egress channels, piloted in simulation, validated, and enforced on a controlled scope: a closed blind
spot that is configured, evidenced, and defensible.
