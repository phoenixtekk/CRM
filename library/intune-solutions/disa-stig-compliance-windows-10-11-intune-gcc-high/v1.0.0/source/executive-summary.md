# Executive Summary — DISA STIG Compliance for Windows 10 & 11 in Microsoft Intune (Government / GCC High edition)

## The situation

Government and defense organizations must bring Windows 10 & 11 endpoints into alignment with **DISA Security Technical Implementation Guides (STIGs)** — the DoD's authoritative Windows hardening standard — and increasingly deliver that hardening through **cloud management (Microsoft Intune)** rather than legacy Group Policy. When those tenants run in the **US sovereign cloud (GCC High / IL4 or DoD / IL5)**, the work is materially different from Commercial: the admin portals live on **`*.us`** domains, automation targets **US Government Microsoft Graph**, and a number of Intune capabilities are **delayed, limited, or absent** versus the Commercial service.

## The problem this solves

Following Commercial guidance on a GCC High/DoD tenant fails in two costly ways: sign-ins and scripts hit the wrong cloud, and administrators design around features that **do not exist** in the sovereign environment — discovering the gap only after a failed rollout. Separately, STIGs were written for domain-joined Windows, so each rule must be **translated** into an Intune setting, and mis-scoping a lockdown across an IL4/IL5 fleet is expensive to unwind.

## What we deliver

A self-guided, tested implementation package specifically for **GCC High / DoD**:

- **Correct sovereign specifics throughout** — `intune.microsoft.us`, `portal.azure.us`, `portal.office365.us`, US Gov Graph (`graph.microsoft.us` / `dod-graph.microsoft.us`), and PowerShell **`-Environment USGov` / `USGovDoD`**.
- **A cited Commercial-vs-GCC-High/DoD parity reference** so the deployment routes around missing features (classic Autopilot, Windows Update feature/quality policies, Remote Help, Security Copilot, Cloud PKI) rather than failing on them — every gap pinned to a Microsoft US Gov source and flagged **"verify for GCC High/DoD."**
- **A gated method** — *Assess → Configure → Pilot → Validate → Expand* — with explicit pass/fail criteria that catch breakage in a handful of pilot devices, not thousands.
- **Five US-Gov-Graph-aware PowerShell scripts** — read-only Discovery, Validation, and Reporting for evidence, plus Remediation and Scope-Targeting that default to a safe **`-WhatIf`** preview.

## What we deliberately do **not** do

We do **not** reproduce or invent DISA STIG rule content. The benchmarks (rule IDs, CCIs, severities, check/fix text) are authored by **DISA** and obtained from the **DoD Cyber Exchange** (`public.cyber.mil`), read in **STIG Viewer**. We supply the **repeatable Intune delivery and validation mechanism** and a method to map DISA's authoritative rules to Intune settings — keeping your program aligned to the real standard, not a copy of it.

## The outcome

Windows 10 & 11 STIG alignment **deployed correctly on a GCC High / DoD tenant** — right portals, right endpoints, parity gaps handled, and **evidence captured at every phase gate** — proven on a pilot before it scales, and maintainable as DISA revises the benchmarks.

## Why it matters to decision-makers

- **Risk reduction:** avoids the silent-failure and fleet-wide-lockdown mistakes that make sovereign STIG rollouts expensive.
- **Audit readiness:** each phase produces a retained evidence artifact and a benchmark-version → policy-version record — the audit story auditors ask for.
- **Cost:** a self-guided, tested package at a fraction of bespoke consulting, while keeping the authoritative standard where it belongs — with DISA.
