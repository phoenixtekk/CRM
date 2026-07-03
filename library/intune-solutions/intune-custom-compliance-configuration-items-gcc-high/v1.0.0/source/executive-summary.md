# Executive Summary — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

## The problem

Intune's built-in device-compliance settings don't cover every control a government organization must enforce — a required security-agent version, a registry hardening value, a TPM/BIOS attribute, a third-party app baseline. **Custom compliance** closes that gap: a PowerShell discovery script plus a JSON rules file let Intune grade any value you can read from a Windows device, and drive Conditional Access from the result.

On a **GCC High** (US sovereign cloud) tenant, doing this correctly is not the commercial procedure with a different login. The admin portals, the device service endpoints, and the Microsoft Graph API are all **`*.us` / US Gov** URLs, some capabilities lag or differ from commercial, and the failure mode is often **silent** — a device shows "not evaluated" rather than an error. Applying commercial guidance to a government tenant produces exactly this quiet breakage.

## The solution

This is the **Government (GCC High) edition** of the Intune Custom Compliance & Configuration Items solution. It re-authors the entire deployment for the US sovereign cloud:

- **Correct sovereign portals and endpoints throughout** — `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, `login.microsoftonline.us`, `graph.microsoft.us`, `*.manage.microsoft.us` — with an explicit **Commercial vs GCC High** map so nothing is applied to the wrong cloud.
- **Ordered, click-by-click implementation** with GCC-High-specific caveats called out **at the step where they matter** (the Default-scope-tag requirement for scripts; SSL inspection unsupported on `*.manage.microsoft.us`; Graph Explorer unavailable; feature-lag checks).
- **Five PowerShell scripts** that connect to **US Gov Graph** with `-Environment USGov` — discovery, validation, reporting, safe remediation, and scope/target-group building — read-only by default, with remediation and scope changes gated behind `-WhatIf`.
- A **cited GCC High parity reference** and a **testing/troubleshooting** playbook with pass/fail gates.

## How it's delivered

The standard, proven model: **Assess → Configure → Pilot → Validate → Expand**, with a gate at the end of each phase. Nothing scales to production until it's proven on a pilot group inside the government tenant — the only reliable way to confirm the mechanics actually grade in GCC High, given that Microsoft documents custom compliance generally rather than GCC-High-specifically.

## The outcome

Intune Custom Compliance deployed correctly on GCC High: right portals, right endpoints, parity gaps handled, and validated on a pilot before it touches the fleet. A novice government admin can follow it end-to-end; an experienced one gets the sovereign-cloud gotchas documented instead of discovered in production.

> **Assurance:** every URL and behavior is either cited to current Microsoft Learn documentation (retrieved July 2026) or explicitly flagged **"verify for GCC High."** Nothing is invented. See `gcc-high-parity-notes.md` for the full cited reference.
