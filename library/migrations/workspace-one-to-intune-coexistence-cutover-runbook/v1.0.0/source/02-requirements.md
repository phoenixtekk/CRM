# 2. Requirements Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Verify **every** requirement before running any cutover. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-migrations.md` (G1–G7);
this guide adds the coexistence-and-cutover-specific requirements.

## 2.1 Both-platform admin access (target and source)
**Description:** Intune Administrator (target) plus administrative access to the Workspace ONE UEM console (source).
**Why:** Coexistence is operated from both sides — you assign and validate in Intune/Entra, and you retire devices in Workspace ONE.
**Verify:** `https://intune.microsoft.com` loads and you hold Intune Administrator; you can sign in to the Workspace ONE UEM console. Run `WS1COEX-Discovery.ps1` to confirm Graph access to the target.
**Implement:** Obtain the Intune Administrator role (least privilege) and the source-console admin role from the platform owner `[WS1 — see VMware docs]`.

## 2.2 Single compliance authority decided
**Description:** A documented decision on which platform owns device compliance during coexistence (the migration target, Intune, is the recommended authority once a cohort is enrolled).
**Why:** Two compliance engines reporting to Conditional Access produce inconsistent compliant/non-compliant states and lockouts.
**Verify:** The decision is written into the `Coexistence Guardrails – Tenant – Configure` and Conditional Access references the chosen authority.
**Implement:** Document the authority; ensure Intune compliance policies exist and are assigned to the migration target groups before tightening Conditional Access.

## 2.3 Conditional Access readiness (scoped, not tenant-wide)
**Description:** Conditional Access policies that can require compliant/Intune-enrolled devices must be **scoped to cohort groups**, not all users, during coexistence.
**Why:** A tenant-wide "require compliant device" policy will lock out every user whose device is not yet Intune-managed.
**Verify:** Entra → **Protection → Conditional Access** — any device-compliance/enrollment policy targets a cohort group, not All users. Run `WS1COEX-Validation.ps1` for per-device readiness.
**Implement:** Create or edit the policy to assign only the current cohort group; expand assignment one cohort at a time. See Implementation Step 2.

## 2.4 Cohort plan and cohort groups
**Description:** A `Cohort Cutover Order – Fleet – Pilot` plan and one Microsoft Entra security group per cohort.
**Why:** Cutover is sequenced; each cohort is a unit that is gated, cut over, validated, or rolled back together.
**Verify:** Entra → **Groups** — cohort groups exist (e.g. `Cutover Cohort – Pilot – Stage1`); the order plan is documented.
**Implement:** Build cohort groups with `WS1COEX-Set-CohortTargeting.ps1`; define order by risk (pilot, low-impact, high-impact) per the global requirement G6.

## 2.5 Target enrollment channels active
**Description:** The enrollment plumbing for each in-scope platform is live in Intune (APNs for Apple, managed Google Play for Android, automatic enrollment for Windows).
**Why:** A device cannot become Intune-managed during cutover if the target enrollment channel is not active.
**Verify:** Intune shows the relevant connector/cert/token **Active** for each platform in scope (global requirement G5). Run `WS1COEX-Validation.ps1`.
**Implement:** Configure the APNs certificate, ABM/ADE token, managed Google Play, and Windows automatic enrollment as needed (global requirement G5).

## 2.6 No-double-targeting rule for apps and profiles
**Description:** A written rule that the same app, Wi-Fi/VPN profile, or certificate is not delivered by both platforms to the same cohort at the same time.
**Why:** Dual delivery causes app duplication, profile collisions, and certificate revocation conflicts.
**Verify:** Intune app/profile assignments for a cohort do not overlap with still-active Workspace ONE assignments for that cohort `[WS1 — see VMware docs]`. Captured in the `Coexistence Guardrails – Tenant – Configure`.
**Implement:** Sequence delivery — keep the source delivering until the cohort cuts over, then remove the source assignment as part of the cutover step.

## 2.7 Change control and a tested rollback
**Description:** An approved change window, a comms channel, and a `Rollback Plan – Cohort – Validate` that has been tested on the pilot cohort before any production cutover.
**Why:** Cutover touches live production devices and live sign-ins; it must be reversible and coordinated (global requirement G7).
**Verify:** The rollback procedure is written, approved, and proven once on the pilot. Run `WS1COEX-Remediation.ps1 -WhatIf` to preview the rollback actions.
**Implement:** Write the rollback per platform, schedule the change window, and rehearse rollback on the pilot cohort before expanding.

## 2.8 Coexistence and cutover status reporting
**Description:** The ability to report which devices are Workspace ONE-only, Intune-only, dual-managed, or compliant.
**Why:** Go/no-go gates depend on knowing the exact management state of every device in a cohort.
**Verify:** Run `WS1COEX-Report.ps1` and confirm it returns per-device management/compliance state.
**Implement:** Install the Microsoft Graph PowerShell SDK and grant the read scopes the scripts request (see Implementation).

---
## Checklist
- [ ] Intune Administrator (target) and Workspace ONE UEM admin (source) access — `WS1COEX-Discovery.ps1`
- [ ] Single compliance authority decided and documented
- [ ] Conditional Access scoped to cohort groups (not All users) — `WS1COEX-Validation.ps1`
- [ ] Cohort plan written; cohort Entra groups created — `WS1COEX-Set-CohortTargeting.ps1`
- [ ] Target enrollment channels Active for each in-scope platform
- [ ] No-double-targeting rule for apps/profiles in place
- [ ] Change window approved; rollback tested on the pilot — `WS1COEX-Remediation.ps1 -WhatIf`
- [ ] Coexistence/cutover status report runs — `WS1COEX-Report.ps1`
