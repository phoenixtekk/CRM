# 3. Implementation Guide — Privileged Access Workstation (PAW) for Cloud Administration

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`)
and the Microsoft Entra admin center (`https://entra.microsoft.com`). The Conditional Access
enforcement policy is created in **Report-only** first; you enforce only after the Testing Guide
passes. Break-glass accounts (via `CA Break-Glass Exclusion`) are excluded from enforcement
throughout.

> Model: build and mark the hardened PAW, define compliance, create the device-filter enforcement
> policy in report-only, wire PIM, pilot, validate the report-only results, flip to enforce in stages,
> then expand. Every object uses `<Purpose> – <Scope> – <Stage>` and is reused by name in Testing and
> Troubleshooting.

## Naming convention (create/verify these exact names)
| Object | Name |
|---|---|
| Pilot admin (user) group | `PAW Admins – Cloud Admin – Pilot` |
| Pilot device group | `PAW Devices – Admin Devices – Pilot` |
| Break-glass exclusion group | `CA Break-Glass Exclusion` |
| Compliance policy | `Compliance – PAW – Pilot` |
| Security baseline profile | `Baseline – PAW Security – Pilot` |
| ASR profile | `ASR – PAW – Pilot` |
| Application-control policy | `AppControl – PAW – Pilot` |
| Device restrictions (isolation) | `Restrictions – PAW Isolation – Pilot` |
| Enforcement policy | `CA – Require PAW for Privileged Roles – Pilot (Report-Only)` |
| Device marker | `extensionAttribute1 = PAW` |

## Step 1 — Assess and record the starting state
1. Run `ENTPAW-Discovery.ps1` to inventory privileged roles and who holds them, existing device compliance policies, any Conditional Access device-filter policies, and the chosen device-marker attribute's current use. Keep the output as your before-state.
2. Confirm the operated roles are onboarded to PIM as eligible (Requirement 2.5) and that `CA Break-Glass Exclusion` exists. Do not proceed until break-glass exclusion is confirmed.

## Step 2 — Create the pilot groups
1. Entra -> `Groups -> New group` -> Security -> `PAW Admins – Cloud Admin – Pilot`; add the pilot admins' dedicated admin accounts (not break-glass). Create.
2. `New group` -> Security -> `PAW Devices – Admin Devices – Pilot`; you will add the pilot PAW devices here (or use dynamic membership on the device marker). Create.

## Step 3 — Enrol and build the hardened PAW in Intune
1. Enrol each pilot PAW into Intune (Autopilot or automatic enrolment). Keep the operator as a standard user (no local admin).
2. `Intune -> Endpoint security -> Security baselines`; create the Windows security baseline profile `Baseline – PAW Security – Pilot`; assign to `PAW Devices – Admin Devices – Pilot`.
3. `Endpoint security -> Attack surface reduction`; create `ASR – PAW – Pilot` with the ASR rules enabled (block credential stealing, Office child processes, untrusted executables, etc.); assign to the device group.
4. `Endpoint security -> Application control` (App Control for Business / WDAC); create `AppControl – PAW – Pilot` in an allow-list posture so only approved admin tooling runs; assign to the device group. *Verify current App Control feature availability and start in audit mode.*
5. `Devices -> Configuration`; create `Restrictions – PAW Isolation – Pilot` to remove/block general-purpose email and open web browsing (block consumer apps, restrict browsers to admin endpoints, disable personal mail profiles); assign to the device group.

## Step 4 — Define what a PAW is (compliance policy)
1. `Intune -> Devices -> Compliance policies -> Create policy` (Windows); name `Compliance – PAW – Pilot`.
2. Require the hardened posture (firewall on, BitLocker on, Secure Boot, real-time protection, minimum OS, and where used a custom compliance script that checks the PAW marker/baseline). Set non-compliant action appropriately. Assign to `PAW Devices – Admin Devices – Pilot`. Create.

## Step 5 — Mark the PAW devices for the device filter
1. Decide the marker: this guide uses `extensionAttribute1 = PAW` on the Entra device object.
2. Run `ENTPAW-DeviceTag.ps1` with the default `-WhatIf` to preview setting `extensionAttribute1 = PAW` on the pilot PAW devices; re-run without `-WhatIf` once confirmed. Only PAWs get this marker.
3. Confirm the marker in Entra -> `Devices -> (device) -> Properties`, and (if using dynamic membership) that `PAW Devices – Admin Devices – Pilot` picks up marked devices.

## Step 6 — Create the Conditional Access device-filter policy (Report-only)
1. Entra -> `Protection -> Conditional Access -> Policies -> + New policy`; name `CA – Require PAW for Privileged Roles – Pilot (Report-Only)`.
   - Assignments -> Users: include `PAW Admins – Cloud Admin – Pilot`; **exclude `CA Break-Glass Exclusion`**.
   - Target resources: select the privileged/admin surfaces — `Microsoft Admin Portals` and the management apps (for example Windows Azure Service Management API / Microsoft Graph), or scope by directory role where supported.
   - Conditions -> Filter for devices: set to **Include** devices where the rule is `device.extensionAttribute1 -eq "PAW"` — i.e. the policy applies when the device is NOT a PAW, so you can block; alternatively configure Grant to require a compliant device AND use the filter to require the PAW marker. Use the filter/grant combination that means "only a marked, compliant PAW is allowed".
   - Grant: **Require device to be marked as compliant** (and, if desired, require multi-factor authentication). For non-PAW/non-compliant devices the effective result is Block.
   - Enable policy: **Report-only**. Create.
2. Run `ENTPAW-Validate.ps1` to confirm the policy exists, is report-only, targets the pilot admins, uses the PAW device filter, and excludes break-glass.

## Step 7 — Wire PIM activation from the PAW
1. Confirm the operated roles are eligible in PIM (Requirement 2.5) with an activation policy requiring MFA, justification, and (recommended) approval.
2. Have a pilot admin sign in from the PAW and activate the role in PIM. This is how privilege is exercised — just-in-time, from the clean device only.
3. Optionally require the sensitive authentication context (from the Identity Protection & Advanced Conditional Access solution) on activation for defence in depth.

## Step 8 — Pilot and read the report-only results
1. Have pilot admins attempt privileged actions from the PAW (should succeed) and from a non-PAW device (report-only shows "would block"). Run `ENTPAW-Validate.ps1` and `ENTPAW-Report.ps1`.
2. Entra -> `Sign-in logs -> Report-only`; confirm `CA – Require PAW for Privileged Roles – Pilot (Report-Only)` would allow PAW sign-ins and would block non-PAW privileged sign-ins, and that **no break-glass account** shows an apply.
3. This is the pass/fail gate. Do not enforce until the report-only results match intent (see Testing Guide).

## Step 9 — Flip to enforcement (staged)
1. Set the policy `Enable policy` to **On**, or use `ENTPAW-Set-CAState.ps1` (default `-WhatIf` preview, with a break-glass guard) to flip it from report-only to enabled after review.
2. Immediately confirm a pilot admin can still administer from the PAW and that a non-PAW privileged sign-in is now blocked; keep a break-glass account ready. Rename the policy dropping `(Report-Only)` once enforced.
3. If enforcement causes unexpected blocks, revert to report-only immediately (`ENTPAW-Set-CAState.ps1 -TargetState reportOnly`) and investigate.

## Step 10 — Expand to production
1. Broaden `PAW Admins – Cloud Admin – Pilot` to all privileged operators and `PAW Devices – Admin Devices – Pilot` to all PAWs (keeping `CA Break-Glass Exclusion` excluded), re-validating in report-only for the wider scope before enforcing.
2. Move App Control from audit to enforced once tuning is complete; finalise isolation restrictions.
3. Stand up monitoring: run `ENTPAW-Report.ps1` on a schedule to catch any privileged sign-in attempted from a non-PAW device.

---
### Order of operations
`Assess/discovery -> Pilot groups -> Build PAW (baseline/ASR/app control/isolation) -> Compliance policy -> Mark devices -> CA device-filter policy (report-only) -> PIM from PAW -> Read report-only -> Staged enforce -> Expand`
