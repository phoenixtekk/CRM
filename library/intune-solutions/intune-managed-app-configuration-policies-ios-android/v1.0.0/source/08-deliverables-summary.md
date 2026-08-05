# 8. Deliverables Summary

## What you receive
- **Implementation Solution Guide (Word + PDF)** — the complete, click-by-click package:
  - **Solution Overview** — App Configuration Policies, the two delivery channels (managed devices vs
    managed apps), the enrolled vs MAM distinction, authoring key/value pairs (iOS plist, Android
    schema, designer vs enter-XML), SSO routing, and how app config coexists with App Protection and
    supersedence.
  - **Requirements** — each prerequisite with Why / Verify / Implement-if-missing, plus the
    category-level global requirements and US Government endpoint notes.
  - **Implementation** — build the App Configuration Policy for **iOS/iPadOS** (plist) **and**
    **Android Enterprise** (managed configurations), the **SAP Ariba Procurement** worked example
    (pre-fill site/realm/environment/role + route to Entra ID), the managed-app (MAM) channel, and
    pilot → production expansion. Every object named.
  - **Testing & Validation** — pass/fail gates, centered on the end-to-end test: an enrolled device
    opens Ariba and lands pre-configured at the Entra ID / Conditional Access sign-in.
  - **Troubleshooting** — plist errors, key typos, "config not applying," MAM-vs-MDM confusion,
    SSO-routing failures, supersedence, and Government-cloud gotchas.
  - **Best Practices** — channel choice, vendor-key discipline, hostname-not-URL, naming, SSO
    plumbing, rollout, and operations.

- **Five Microsoft Graph PowerShell tools** (read-only by default, cloud-aware for Commercial and US
  Gov; no credentials stored):
  - `APPCFG-Preflight.ps1` — confirm Graph scopes/roles and the correct cloud before changes.
  - `APPCFG-Get-AppConfigPolicies.ps1` — export existing managed-device **and** managed-app App
    Configuration Policies with their assignments (baseline / source control).
  - `APPCFG-Validate-Assignment.ps1` — confirm a specific device/user received a given policy.
  - `APPCFG-Report-AppConfig.ps1` — which apps have configuration and which do not (coverage gaps).
  - `APPCFG-Remediation.ps1` — guarded staging of a missing assignment; **`-WhatIf` by default**,
    writes only with explicit `-Commit`.

- **Templates** (generic + Ariba placeholder, clearly commented that vendor keys must be confirmed):
  - `ios-appconfig.plist` — sample iOS Managed App Configuration property list (generic).
  - `ios-appconfig-ariba.plist` — the Ariba placeholder plist from the worked example.
  - `android-managed-config.json` — sample Android managed-configuration document (generic).
  - `android-managed-config-ariba.json` — the Ariba placeholder Android managed config.

## Outcome
Apps that configure themselves on first launch — pre-filled with the correct host, realm,
environment, and role — and route every sign-in to Microsoft Entra ID so Conditional Access can
enforce access, proven on a pilot device before you expand. Buy once, reuse across unlimited apps and
devices.

## Accuracy note
The SAP Ariba configuration **key names** in this package are **placeholders**. The authoritative keys
live in the *SAP Ariba Procurement Mobile App Guide* → **"Configuring SAP Ariba Procurement mobile app
in Mobile Device Management Tool"** — confirm them there before production use (**"verify against SAP
Ariba documentation"**). The build/assign/validate **mechanics** are correct regardless of the exact
keys. SAP states the Ariba Procurement app is not MDM-certified on Android as of current documentation.
