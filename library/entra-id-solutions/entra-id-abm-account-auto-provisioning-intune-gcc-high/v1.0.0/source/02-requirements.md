# Requirements — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

The category-level prerequisites are in `global-requirements-entra-id-solutions.md` — confirm those
first (Entra tenant, licensing, admin roles, break-glass accounts, network access). This document
adds the requirements **specific to this solution on GCC High**, each with how to **verify** it and
how to **implement it if missing**.

> Everything below assumes the **US sovereign cloud**. Use the `*.us` portals and
> `Connect-MgGraph -Environment USGov`. Confirm the parity gap in `gcc-high-parity-notes.md` before
> you spend money or time — some requirements only matter if you pursue a path GCC High does not
> support today.

---

## R0. (Gate) Decision — supported path vs unsupported federation/SCIM link
Description: A recorded decision on whether your requirement can be met on the **supported GCC High
path** (ABM ⇄ Intune Government enrollment) or depends on the **unsupported** Entra ⇄ ABM
federation/SCIM link (national clouds excluded by Apple).
Why: This decision determines whether the rest of the deployment is achievable in GCC High today.
Skipping it risks configuring toward a capability that cannot complete.
Verify: A short written statement citing `gcc-high-parity-notes.md`, approved by the project owner.
Implement: Read `gcc-high-parity-notes.md`, re-check the Apple federated-authentication page live,
confirm with your security/compliance team, and record the decision before any configuration.

## R1. GCC High tenant with Government licensing
Description: An active GCC High Entra tenant carrying Government SKUs — Microsoft 365 **G3/G5 Gov** (or
equivalent) that includes **Entra ID P1/P2** and **Intune for Government**.
Why: Apple enrollment through Intune Government requires the Government Intune service and Entra P1/P2
for scoping and Conditional Access.
Verify: Sign in to `https://portal.office365.us` → `Billing → Licenses`; confirm Government SKUs with
Intune and Entra P1/P2. Sign in to `https://entra.microsoft.us` as an administrator.
Implement: Assign Government licensing (M365 G3/G5 Gov or EMS Gov + Intune for Government).

## R2. Administrative roles (sovereign)
Description: **Intune Administrator** (for the Apple enrollment configuration) and a **Global
Administrator** available for one-time consent steps; least privilege thereafter.
Why: Linking ABM to Intune and creating enrollment profiles requires Intune Administrator; some
one-time trust/consent actions require Global Administrator.
Verify: `entra.microsoft.us` → `Roles and administrators`; confirm the operator holds Intune
Administrator and that a Global Administrator is available.
Implement: Assign **Intune Administrator** to the operator; reserve **Global Administrator** for
one-time consent, then step down to least privilege.

## R3. Break-glass accounts (sovereign)
Description: Two cloud-only emergency-access Global Administrator accounts (`@onmicrosoft.us` /
your `.onmicrosoft.com` sovereign vanity), excluded from broad Conditional Access/MFA lockout.
Why: Enrollment and Conditional Access changes can lock out admins; break-glass restores access.
Verify: `entra.microsoft.us` → `Users`; confirm two cloud-only accounts with stored strong
credentials and sign-in monitoring.
Implement: Create two cloud-only Global Administrator accounts, exclude them from broad policies, and
store credentials securely.

## R4. Apple Business Manager account
Description: An active Apple Business Manager account at `business.apple.com` with an administrator
who can create tokens and manage Managed Apple IDs.
Why: ABM is where the MDM server (Intune) is linked, ADE tokens are issued, and Managed Apple IDs
live. ABM is a single global Apple service — there is no sovereign variant.
Verify: Sign in to `https://business.apple.com` as an ABM Administrator; confirm the organization is
enrolled and verified.
Implement: Enrol your organization in Apple Business Manager and complete Apple's verification.
Note (**verify for GCC High**): ABM is not a sovereign service; the sovereign constraint is only on
the Entra federation/SCIM link into ABM, not on ABM itself.

## R5. Intune Government configured for Apple
Description: Intune Government reachable at `https://endpoint.microsoft.us`, with the Apple **MDM push
certificate (APNs)** established.
Why: Apple device enrollment through Intune requires a valid APNs certificate and the Intune
Government service.
Verify: `endpoint.microsoft.us` → `Devices → Enrollment → Apple` → confirm a valid, non-expired Apple
MDM push certificate. Run `ABMPROVG-Discovery.ps1`.
Implement: In `endpoint.microsoft.us`, create/download the APNs CSR, obtain the certificate from
Apple, and upload it; record the Apple ID used so it can be renewed annually.

## R6. ABM ⇄ Intune enrollment tokens (ADE / User Enrollment)
Description: An Automated Device Enrollment (ADE) token (and/or User Enrollment configuration) linking
ABM to Intune Government.
Why: This is the **supported** GCC High mechanism to enrol Apple devices and apply the Managed Apple
ID experience through Intune.
Verify: `endpoint.microsoft.us` → `Devices → Enrollment → Apple → Enrollment program tokens`; confirm
a valid, non-expired token synced with ABM. Run `ABMPROVG-Validation.ps1`.
Implement: In ABM, add Intune Government as an MDM server, download the public key, upload it to
`endpoint.microsoft.us`, then upload the ABM token back to Intune; set the token to sync.

## R7. Managed Apple ID approach (ABM-native, not Entra federation)
Description: A documented standard (`ABM-Managed-AppleID-Standard`) for how Managed Apple IDs are
created — **manually, via ABM SFTP, or via the ABM API** — since Entra federation/SCIM is not
available in GCC High.
Why: With the federation/SCIM link unavailable, Managed Apple ID lifecycle must be handled by ABM's
own tooling; a written standard keeps it repeatable and auditable.
Verify: A documented naming and creation standard exists and matches how accounts are created in ABM.
Implement: Choose an ABM-native creation method, document the naming convention and lifecycle
(create/suspend/delete), and record it as `ABM-Managed-AppleID-Standard`.

## R8. Network endpoints for US Government Intune + Apple
Description: Outbound HTTPS to the **US Government Intune** service endpoints and to Apple's ABM/APNs
endpoints from managed devices and the admin workstation.
Why: Enrollment, policy delivery, and ABM/APNs communication depend on these being reachable through
sovereign filtering.
Verify: From the admin workstation and a test device, reach `endpoint.microsoft.us`,
`login.microsoftonline.us`, `graph.microsoft.us`, `business.apple.com`, and Apple's push endpoints;
compare to Microsoft's published US Government Intune network endpoints.
Implement: Allow the US Government Intune network endpoints and Apple ABM/APNs ranges through the
proxy/firewall. Source: *Network endpoints for US government deployments (Intune)* —
https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints

## R9. Microsoft Graph PowerShell SDK targeting US Gov
Description: A workstation with the **Microsoft Graph PowerShell SDK** installed, able to run
`Connect-MgGraph -Environment USGov` against `graph.microsoft.us`.
Why: All five solution scripts connect to the sovereign Graph endpoint; the Commercial endpoint
rejects GCC High credentials.
Verify: `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph -Environment
USGov` succeeds. Run `ABMPROVG-Discovery.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; use `-Environment USGov` on every
connect. Source: *Connect-MgGraph* —
https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

## R10. Pilot scope groups
Description: The named groups `ABM-Apple-Pilot-Devices` and `ABM-Apple-Enroll-Users` for staged
rollout.
Why: Staged Pilot → Validate → Expand requires a small, named scope you can widen in waves.
Verify: `entra.microsoft.us` → `Groups`; confirm both groups exist. Run
`ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf`.
Implement: Create the groups (or let `ABMPROVG-Set-ScopeTargeting.ps1` create/populate the pilot group
with `-WhatIf` removed after review).

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
