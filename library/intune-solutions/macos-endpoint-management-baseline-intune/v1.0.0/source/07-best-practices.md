# 7. Best Practices — macOS Endpoint Management Baseline (Microsoft Intune)

Field-proven recommendations for building and operating a macOS baseline in Intune.

## Naming and structure
- **Name every object, and reuse the names verbatim.** Use the convention from this solution:
  `macOS Baseline – <Area> – Pilot` / `– Production`, `macOS Baseline – Compliance`,
  `macOS Baseline – Pilot Devices` / `– Production Devices`. Consistent names make status pages,
  reports, and the included scripts readable.
- **Put a version/scope tag in every description** (`macOS-Baseline-v1.0`). It is the fastest way to
  identify which policies belong to this baseline when a tenant has dozens.
- **One area per policy.** Keep the core configuration, restrictions, and software-update settings in
  **separate** settings-catalog policies. You can then assign, adjust, or roll back one area without
  disturbing the others.

## Prefer the settings catalog
- **Build in the settings catalog first; reach for a custom `.mobileconfig` only when the catalog
  cannot express the setting.** The catalog is discoverable, reports per-setting status, and is far
  easier to audit than an opaque uploaded profile.
- When you *must* use a custom `.mobileconfig`, author it from **Apple's public MDM payload
  documentation**, keep the source file in change control, and document exactly which setting it
  delivers (Intune only reports "applied", not per-setting detail, for custom profiles).

## Avoid conflicting authorities
- **Do not configure the same setting in two places.** Two policies (or a legacy template plus a
  catalog policy) setting the same payload is the top cause of **Conflict / Error** device status.
  Run `MACBASE-Discovery.ps1` before you build to find existing macOS policies that already touch your
  target areas.
- If a setting shows **Conflict**, find both authorities and remove the setting from one — do not just
  re-push.

## Group and assignment strategy
- **Assign to device groups, not user groups,** for a device baseline — it applies at enrollment
  regardless of who signs in.
- Use a **dynamic device group** (e.g. filtered on the Mac device attribute) for
  `macOS Baseline – Production Devices` so new Macs inherit the baseline automatically. Keep the pilot
  group **static and small**.
- Use `MACBASE-Set-ScopeTargeting.ps1` (defaults to `-WhatIf`) to stage and apply group assignments
  the repeatable way instead of clicking each policy by hand.

## Pilot discipline
- **Always pilot.** Even a "safe" baseline can surprise a workflow (a restriction, a login-window
  change, an update deadline). A small representative pilot catches it on a few Macs.
- **Soak for several business days** with real apps before expanding. Treat the Testing Guide gate as
  mandatory, not optional.
- Keep a **rollback note** ready: removing a policy's group assignment is the fastest safe revert.

## Software updates
- **Make update behaviour deliberate.** Enforce automatic download/install and a **minimum OS
  version** so Macs do not fall years behind, but set a **realistic deadline** so an enforced restart
  never interrupts work without warning.
- Software-update enforcement — especially Declarative Device Management-based enforcement — is
  **macOS-version-dependent.** Confirm the capability against your fleet's macOS versions before
  relying on it; configure from what Intune presents.

## Compliance and Conditional Access
- **Set compliance rules that mean something** (minimum OS, FileVault, firewall). Compliance is what
  makes the baseline *provable* and what other systems consume.
- If you later gate access on device compliance, that is **Conditional Access** — a separate solution.
  Get the baseline compliant first; wire access control second.

## Ongoing operation
- **Detect drift on a schedule.** Run `MACBASE-Report.ps1` periodically (and after each rollout wave)
  and remediate with `MACBASE-Remediation.ps1` (dry-run first).
- **Watch the APNs certificate expiry.** It expires annually; a lapsed APNs certificate silently stops
  **all** Mac management. `MACBASE-Discovery.ps1` surfaces the expiry — renew well ahead.
- **Record every change** (who, what, rollback) and keep the version tag current.

## Scope boundaries (don't reinvent other solutions)
- This is the **general baseline**. Enrollment/ADE, formal CIS/STIG hardening, Defender onboarding, and
  Conditional Access are **separate** solutions — reference them; do not rebuild them inside the
  baseline.
