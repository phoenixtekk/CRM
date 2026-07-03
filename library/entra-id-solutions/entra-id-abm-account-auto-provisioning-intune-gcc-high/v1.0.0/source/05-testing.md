# Testing & Validation — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Use this pass/fail matrix at each phase gate. Run the scripts with
`Connect-MgGraph -Environment USGov` (the scripts do this for you). All portal checks use the `*.us`
sovereign URLs.

> Reminder: on GCC High the **Entra ⇄ ABM federation/SCIM auto-provisioning** path is **not
> supported** (Apple excludes national clouds). Tests below validate the **supported** path (ABM ⇄
> Intune Government enrollment) — there is deliberately **no** test for SCIM provisioning success,
> because that connector is not available in the US Government cloud.

---

## T0. Parity decision recorded
- **Check:** A written, approved decision exists stating the requirement is met by the supported GCC
  High path (or the project is stopped/escalated if it depends on federation/SCIM).
- **Pass:** Decision document present and approved, citing `gcc-high-parity-notes.md`.
- **Fail:** No decision recorded — do not proceed.

## T1. Sovereign sign-in and Graph environment
- **Check:** `Connect-MgGraph -Environment USGov` succeeds; the connected context shows a
  `graph.microsoft.us` / US Gov environment.
- **Pass:** Connected to the US Gov Graph endpoint with the expected tenant ID.
- **Fail:** Auth error, or connection lands on the Commercial endpoint (you omitted `-Environment
  USGov`).

## T2. Licensing and roles
- **Check:** `portal.office365.us` shows Government SKUs with Intune Government and Entra P1/P2; the
  operator holds Intune Administrator.
- **Pass:** Correct Government licensing and roles present.
- **Fail:** Commercial SKUs, missing Intune Government, or insufficient role.

## T3. Apple MDM push certificate (APNs)
- **Check:** `endpoint.microsoft.us` → `Devices → Enrollment → Apple` shows a valid, non-expired APNs
  certificate; `ABMPROVG-Validation.ps1` reports it present.
- **Pass:** Certificate valid, expiry > 30 days out, renewal Apple ID recorded.
- **Fail:** Missing/expired certificate, or unknown renewal Apple ID.

## T4. ABM ⇄ Intune Government token
- **Check:** `endpoint.microsoft.us` → `Enrollment program tokens` shows a valid, non-expired token
  named for the ABM link (`Intune-Gov-MDM`), last sync recent; `ABMPROVG-Validation.ps1` confirms.
- **Pass:** Token valid, syncing, expiry > 30 days out.
- **Fail:** Token missing, expired, or not syncing.

## T5. ADE profile exists and is assigned
- **Check:** `ABM-ADE-Profile-Gov` exists and is assigned to `ABM-Apple-Pilot-Devices`.
- **Pass:** Profile present and assigned to the pilot scope.
- **Fail:** Profile missing or unassigned.

## T6. Pilot enrollment succeeds
- **Check:** A wiped, ABM-assigned pilot device runs Setup Assistant and appears ADE-enrolled in
  `endpoint.microsoft.us`, receiving the assigned profile/policy.
- **Pass:** Device enrolls automatically and shows compliant/managed with policy applied.
- **Fail:** Device does not enroll automatically, or does not receive policy.

## T7. Managed Apple ID sign-in (ABM-native)
- **Check:** Signing in with an **ABM-created Managed Apple ID** behaves per
  `ABM-Managed-AppleID-Standard`.
- **Pass:** Managed Apple ID sign-in works as designed.
- **Fail (expected on the federation path):** Attempting to sign in with an **Entra work account via
  federation** fails — this is **expected** in GCC High and is not a defect; it confirms the parity
  gap. Do not log this as a bug.

## T8. Scope targeting is deterministic
- **Check:** `ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf` lists the intended pilot membership with no
  unexpected additions/removals.
- **Pass:** Planned membership matches intent; applying it yields exactly that.
- **Fail:** Unexpected members, or `-WhatIf` output differs from applied result.

## T9. Reporting is accurate
- **Check:** `ABMPROVG-Report.ps1` output matches what the portals show (token, APNs, enrolled pilot
  devices, group membership).
- **Pass:** Report matches portal reality.
- **Fail:** Report diverges from the portal — investigate before trusting it.

## T10. Remediation is safe by default
- **Check:** `ABMPROVG-Remediation.ps1` runs in `-WhatIf` mode by default and only changes state when
  `-WhatIf` is removed.
- **Pass:** Default run makes no changes and previews actions clearly.
- **Fail:** Any change occurs without explicitly removing `-WhatIf`.

---

## Phase gate summary

| Phase | Must pass |
| --- | --- |
| Assess | T0, T1, T2 |
| Configure | T3, T4, T5 |
| Pilot | T6, T7, T8 |
| Validate | T9, T10 (plus re-confirm T3–T6) |
| Expand | Re-run T4–T9 after each wave |

Record the result (pass/fail + date) for each test at each gate so the deployment is auditable.
