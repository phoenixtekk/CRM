# 2. Requirements — Enablement Kit: Identity Modernization with Entra

The **category-level** prerequisites (an Entra ID tenant, P1/P2 licensing, administrative roles,
break-glass accounts, healthy AD, UPN/domain hygiene, network access) are documented once in
**`global-requirements-entra-id-solutions.md`** — confirm those first; they are not repeated here.

Below are the prerequisites specific to running this **enablement kit** and its labs. Because this is
training, the strong recommendation is to run the labs in a **non-production tenant** or, if you must
use production, strictly against the small **pilot lab group** you create, with every control in
**report-only / preview**.

Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A lab pilot group
Description: A dedicated Entra security group named **`Identity Modernization – Pilot – Lab`** holding
only a handful of lab / test identities.
Why required: Every guided lab targets this group so no policy or method change can affect real users.
It is the "Pilot" scope in the deployment model.
How to verify: Entra admin center → **Groups → All groups**; confirm the group exists and contains
only lab members. Or run `EKIDMOD-Validate.ps1`, which checks for it.
How to implement if missing: Create it with `EKIDMOD-LabSetup.ps1` (preview-first, `-WhatIf` by
default), or manually: **Groups → New group** → Security → name `Identity Modernization – Pilot – Lab`.

## R2. Sample / test identities
Description: Two to five non-privileged **cloud-only** test users (for example
`labuser1@contoso.onmicrosoft.com`) to exercise the labs.
Why required: Labs assign policies, methods, and access packages to real principals; using disposable
test users keeps live users untouched and lets you safely observe enforcement.
How to verify: Entra → **Users**; confirm the test users exist and are members of the pilot group.
How to implement if missing: Create them with `EKIDMOD-LabSetup.ps1` (preview-first), or **Users →
New user → Create new user**. Do not use real employee accounts.

## R3. Microsoft Graph PowerShell SDK
Description: The `Microsoft.Graph` PowerShell module (v2+) installed on the operator workstation.
Why required: The discovery, validation, reporting, and lab-setup helpers use Graph cmdlets.
How to verify: `Get-Module Microsoft.Graph -ListAvailable` returns a v2+ module; `EKIDMOD-Validate.ps1`
also reports this.
How to implement if missing: `Install-Module Microsoft.Graph -Scope CurrentUser`. Consent to the
least-privilege read scopes when prompted (for example `Directory.Read.All`, `Policy.Read.All`,
`AuditLog.Read.All`, `UserAuthenticationMethod.Read.All`).

## R4. Feature licensing awareness (P1 / P2 / Governance / GSA / Verified ID)
Description: Awareness of which building blocks need which license, before the corresponding lab.
Why required: Several labs use features that require **Entra ID P1** (Conditional Access), **Entra ID
P2** (risk-based CA, Identity Protection, PIM), **Entra ID Governance** (access reviews, entitlement
management), **Global Secure Access**, or **Verified ID**. Some capabilities are in preview. *Do not
assume availability — verify current licensing and preview status in your own tenant.*
How to verify: M365 admin center → **Billing → Licenses**; and the feature blade will indicate if a
capability is unavailable or preview. `EKIDMOD-Validate.ps1` reports detected service plans.
How to implement if missing: Assign the required license to your lab users, or skip that lab and read
its concept section. Trial licenses are acceptable for training — *verify eligibility in your tenant.*

## R5. (Optional) Log Analytics / Microsoft Sentinel with Entra diagnostic settings
Description: An Entra **Diagnostic setting** streaming `SignInLogs` / `AuditLogs` to a Log Analytics
workspace (optionally onboarded to Microsoft Sentinel).
Why required: Only for the **KQL analysis lab** and `EKIDMOD-Signals.kql`. The rest of the kit works
without it.
How to verify: Entra → **Monitoring → Diagnostic settings** shows a setting sending logs to a
workspace; the workspace has recent `SigninLogs`.
How to implement if missing: Entra → **Diagnostic settings → Add** → select `SignInLogs`,
`AuditLogs` → send to a Log Analytics workspace. *A workspace and log retention may incur Azure cost —
verify in your subscription.* If unavailable, read the KQL lab as concept only.

## R6. (Optional) A coexistence / hybrid reference
Description: Read access to any existing hybrid sync configuration (Entra Connect / Cloud Sync) or
federated (AD FS) domains.
Why required: Only for the **migration & coexistence** lab, so the team can inspect the real starting
point (federated domains, sync engine) without changing it.
How to verify: Entra → **Identity → Settings → Domain names** shows domain authentication type
(Managed vs Federated); `EKIDMOD-Discovery.ps1` reports federated domains.
How to implement if missing: Not required — the coexistence lab can be completed conceptually with
the provided patterns if no hybrid environment exists.
