# 1. Solution Overview — Endpoint DLP for macOS (Microsoft Purview)

## What this solution is
This solution extends **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)** to **macOS
devices**. It covers the whole path: **onboarding** Macs into Microsoft Purview device management,
configuring the **Endpoint DLP settings** and a **DLP policy** that monitors and controls **egress
channels** on the Mac (cloud/browser upload, USB removable media, network share, clipboard, print,
and access by unallowed apps) — piloting the policy in **simulation / test mode** first, validating
what it would catch, and only then moving to **enforce** on a controlled scope.

Mac endpoints are frequently the **blind spot** in a DLP program: the same sensitive content that is
blocked from leaving a Windows PC can walk out on a Mac over USB, a browser upload, or a network
copy. This package closes that gap in Purview, the same tenant and policy engine you already use — no
third-party endpoint DLP product.

It is **vendor-neutral** on the management plane: macOS onboarding is authored for both **Microsoft
Intune** and **Jamf Pro** at the pattern level, with the Intune path given step-by-step and the Jamf
equivalent named and deferred to Jamf's documentation for its console specifics.

## The macOS Endpoint DLP model in one paragraph
Endpoint DLP works by **onboarding** a device so a management/monitoring agent reports device
activity to Microsoft Purview. On macOS this agent relies on macOS **system and network extensions**,
a **Full Disk Access** grant, and an **onboarding package** delivered by your MDM (Intune or Jamf).
Once a Mac is onboarded and appears in Purview **device onboarding**, a **DLP policy** scoped to the
**Devices (Endpoint)** location applies to it. The policy's **rules** detect sensitive content (by
sensitive information type, sensitivity label, or other conditions) and apply **endpoint
restrictions** to egress activities — **Audit**, **Warn/Block with override**, or **Block**. Global
behavior (which browsers are approved, which apps are "unallowed", which cloud domains are
sensitive/approved, path exclusions) lives in **Endpoint DLP settings** and is shared by all endpoint
policies.

> **Licensing / plan note (verify your licensing/tenant).** Endpoint DLP is part of **Microsoft
> Purview Data Loss Prevention** and is licensed with **Microsoft 365 E5 / E5 Compliance** (or
> equivalent). macOS Endpoint DLP support and the exact set of monitored activities are **evolving and
> version-dependent** — Microsoft supports Endpoint DLP on the **three latest major macOS releases**.
> Confirm current macOS support, licensing, and per-activity availability against Microsoft's public
> documentation and your tenant before relying on any specific control.

## Egress channels this solution targets on macOS
macOS Endpoint DLP can monitor and restrict a **subset** of the endpoint activities available on
Windows. The channels this solution configures (each **verify current support for your macOS
version**):

- **Cloud / browser upload** — uploading sensitive files to a **cloud service domain** from a browser,
  and uploading from an **unallowed / non-approved browser**. Coverage of **service domains** and
  **sensitive service domains** on non-Edge browsers (Chrome, Firefox) requires the **Microsoft
  Purview browser extension**; Edge is supported without an add-on.
- **USB / removable media** — copying sensitive files to a USB or other removable drive.
- **Network share** — copying sensitive files to a network share.
- **Clipboard** — copying sensitive content to the clipboard (paste into another app/browser).
- **Print** — printing sensitive files.
- **Unallowed apps / restricted app groups** — access to sensitive files by apps you designate as
  restricted (e.g. personal cloud-sync or messaging apps).

For each channel the DLP rule sets an **action**: **Audit** (log only — the safe pilot default),
**Block with override / Warn** (user can justify), or **Block** (hard stop). This solution pilots at
**Audit / simulation** and only tightens to Block after validation.

## What is authored exactly vs deferred
- **Exact navigation is given** for the **Microsoft Purview portal** (`purview.microsoft.com`) —
  **Device onboarding**, **Endpoint DLP settings**, and **Data Loss Prevention → Policies** — and for
  the **Intune** onboarding path and **Security & Compliance PowerShell** (`Connect-IPPSSession`)
  automation.
- **Jamf Pro** onboarding is integrated at the **pattern level** — where a step (deploy onboarding
  package, approve system/network extensions, grant Full Disk Access via a PPPC/TCC profile) is a Jamf
  console action, this solution names the action and defers the Jamf specifics to Jamf's
  documentation.
- **Records/retention/legal/regulatory determinations** — *which* data is regulated, *what* must be
  blocked vs merely audited, and *whether* a given activity is permissible — are **deferred to the
  organization's compliance, privacy, records, and legal functions**. This solution delivers the
  **technical configuration and the evidence**, not the policy determination.
- **Purview is evolving and licensing-dependent** — where a control's availability on macOS is
  version- or plan-dependent, this package flags **"verify your licensing / tenant / macOS version"**
  rather than asserting it.

## Benefits
- **Closes the Mac blind spot** — the same Purview DLP engine now watches egress on macOS, not just
  Windows and cloud.
- **One policy plane** — Macs are governed by DLP policies in the tenant you already run; no separate
  endpoint-DLP product.
- **Safe by construction** — every policy is piloted in **simulation / test (Audit)** first, validated
  in Activity Explorer, then enforced — high-impact blocking is never flipped on blind.
- **Evidenced** — Activity Explorer and the provided reporting script show exactly what the policy
  would catch (and later, blocks), so the control is **defensible**.
- **Automatable & safe** — Security & Compliance PowerShell / Graph scripts are read-only or run in
  **-WhatIf / test mode** by default, with no credentials in code.

## Limitations (be honest with buyers)
- **macOS support is a subset and evolving.** Not every Windows Endpoint DLP activity exists on macOS,
  and support is limited to the **three latest major macOS versions** — **verify current coverage**.
- **Onboarding is real endpoint work.** macOS requires **system/network extension approval**, **Full
  Disk Access**, and an **onboarding package** via MDM — a misconfigured extension/TCC profile means
  the Mac never reports and the policy silently does nothing.
- **Determinations are not ours.** What to block, what is regulated, and whether an activity is allowed
  are **compliance/records/legal** decisions — this package configures and evidences, it does not
  decide.
- **Enforcement is high-impact.** A Block rule can interrupt legitimate work — hence **simulation →
  Audit → Block** with pass/fail gates and a documented rollback.

## The standard deployment model
> **Assess** the Mac fleet and in-scope data → **Design** the onboarding + policy + endpoint settings →
> **Configure** onboarding and a DLP policy in **test/simulation (Audit)** → **Pilot** on a handful of
> onboarded Macs → **Validate** in Activity Explorer against pass/fail gates → **Expand** and only then
> move rules to **Block (enforce)** in waves.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)**, with
> explicit pass/fail gates and a documented rollback.
