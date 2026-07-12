# 1. Solution Overview — optimization: Endpoint Security with Microsoft Intune

## What this solution is
This is a **optimization** — a structured tuning engagement for an **existing, working** Microsoft Intune endpoint-security estate. It is deliberately **distinct from the read-only assessment**: the assessment *tells you* what to improve; this solution *applies* the improvements, pilot-first, with **before/after measurement** and a **rollback** for every change. If you have not yet deployed endpoint security through Intune, this is the wrong solution — deploy first (see *Where to go next* in Best Practices), then optimize.

It focuses on the four highest-value tuning levers on a mature Intune endpoint-security deployment:

1. **Baseline & policy tuning** — migrate **security baselines** to the current version, reconcile customized settings, and align antivirus/ASR/EDR/firewall/disk-encryption policy to current best practice.
2. **Conflict reduction** — find where **two or more policies set the same setting differently** (the cause of "conflict"/"error" states) and consolidate to a single authoritative policy per setting.
3. **Compliance tuning** — reduce false **non-compliant** flags, catch the real gaps, and understand the **Conditional Access** impact before tightening.
4. **Coverage expansion** — find devices and users **not assigned** baseline, compliance, or Defender policy, and bring them into scope with a consistent group/assignment model.

## How the technology works (the levers)
- **Security baselines** are Microsoft-published, versioned bundles of recommended settings (Security Baseline for Windows, Defender for Endpoint baseline, Edge baseline). New versions ship regularly; devices on an **old baseline version** drift from current guidance. Migrating means creating the new-version baseline, carrying forward justified customizations, and retiring the old one.
- **Policy conflict** happens when a device is targeted by **multiple** configuration/endpoint-security/baseline policies that set the **same** setting to **different** values. Intune reports the device/setting as **Conflict** or **Error**, and the effective value is undefined. The fix is to make **one** policy authoritative for each setting and remove the overlap.
- **Compliance policies** evaluate device state (encryption, OS version, Defender health, risk level) and mark devices **compliant / non-compliant**; **Conditional Access** then grants or blocks access based on that. Tuning means the thresholds reflect reality (so you don't flag benign devices) while still catching genuine gaps — and understanding the CA blast radius before enforcing.
- **Assignments** target policies to **Entra groups** (device or user). A device only gets a control if a policy is **assigned** to a group it belongs to — coverage gaps come from unassigned devices, empty dynamic groups, or exclusions that swallowed too much.

## The standard deployment model
> **Assess (baseline the current estate) → Configure (stage the tuning: new baseline version, conflict consolidation, compliance thresholds, assignment model) → Pilot (apply to a device ring) → Validate (measure the before/after delta) → Expand (ring by ring across the estate).** Every disruptive change (especially compliance/Conditional Access) starts **report-only / staged**, and every step names a rollback.

## Scope (what this solution changes)
- Migrates **security baselines** to the current version and reconciles customized settings.
- **Resolves policy conflicts** by consolidating to a single authoritative policy per setting.
- **Tunes compliance policies** (thresholds, grace periods, actions) and clarifies the Conditional Access impact.
- **Expands assignments** to unassigned/stragging devices with a consistent group model.
- Captures a **before/after metrics baseline** (conflict/error counts, non-compliant proportion, coverage %) so the improvement is measurable.

## Out of scope
- **First-time Intune / endpoint-security deployment** — this tunes an existing deployment (deployment solution referenced in Best Practices).
- **Full device-configuration / MDM management** beyond endpoint security (app deployment, Wi-Fi/VPN profiles, Autopilot) — this focuses on the security policies.
- **Conditional Access design as a whole** — this tunes the compliance→CA impact of endpoint security; broader CA architecture is a separate identity engagement.
- **Regulatory, records/legal, and acceptable-risk determinations** — deferred to the customer's compliance/security/identity functions.

## Connections and authentication used
- The **Microsoft Intune admin center** (`https://intune.microsoft.com`) → **Endpoint security** (Antivirus, Disk encryption, Firewall, EDR, ASR, Account protection, Security baselines), **Devices → Compliance**, and **Groups**.
- The **Microsoft Entra admin center** (`https://entra.microsoft.com`) → **Conditional Access** (to review the compliance grant impact) and **Groups**.
- **Microsoft Graph PowerShell** (`Microsoft.Graph.Authentication` and DeviceManagement modules) for read-only discovery, conflict reporting, validation, before/after metrics, and the `-WhatIf`-gated assignment helper — least-privilege scopes such as `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`, and `Group.Read.All`.
- Least-privilege roles: **Intune Read Only Operator** / **Security Reader** for read-only work; **Endpoint Security Manager** (and **Intune Administrator** where required) for applying changes.

## Limitations (be honest with buyers)
- Some capabilities are **plan-gated**: Intune requires the appropriate plan/license per user; Defender-for-Endpoint settings surfaced through Intune (ASR/EDR reporting) need **Defender for Endpoint P2**. *Verify current plan requirements and availability in your tenant.*
- Policy changes **propagate on the device check-in cadence**, not instantly — allow sync time before judging a change.
- Resolving conflicts requires deciding **which** policy is authoritative — that is a design decision this solution structures but the security team owns.
- Compliance tuning changes **who can access what** via Conditional Access; that is why CA impact is reviewed **report-only first** and the identity team owns the enforce decision.
