# Requirements

Confirm each prerequisite before you begin. Each lists **why** it is required, **how to verify**, and
**how to implement** if missing.

## 1. Intune administrator + Entra read access

- **Description:** A role that can read sign-in logs and edit enrollment configuration — **Intune
  Administrator** and **Global Reader** / **Security Reader** for the sign-in logs, or least-privilege
  equivalents.
- **Why required:** You read the failed enrollment sign-in and, where needed, edit MDM scope,
  enrollment restrictions, or Conditional Access.
- **How to verify:** Sign in to **Entra admin center** (`entra.microsoft.com`; GCC High:
  `entra.microsoft.us`) → **Sign-in logs**, and **Intune admin center** (`intune.microsoft.com`) →
  **Devices → Enrollment**.
- **How to implement if missing:** Have an admin grant the roles.

## 2. The diagnostic IDs from the failure screen

- **Description:** The **Activity Id**, **Session Id**, and **Timestamp** shown on the "Access Denied"
  page (and the affected user's UPN).
- **Why required:** These correlation IDs locate the exact failed sign-in and its failure reason — the
  deterministic root cause.
- **How to verify:** You have the three values and the user's identity from the screenshot / user.
- **How to implement if missing:** Have the user reproduce the failure and capture the diagnostic block,
  or provide the UPN and approximate time.

## 3. Microsoft Graph PowerShell

- **Description:** The **Microsoft.Graph** module to read the sign-in, the user's license, the MDM
  scope, the enrollment restrictions, and the Conditional Access policies.
- **Why required:** The included scripts turn each gate into a yes/no answer.
- **How to verify:** `Get-Module -ListAvailable Microsoft.Graph`; `Connect-MgGraph` succeeds.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` (scopes include
  `AuditLog.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `DeviceManagementServiceConfig.Read.All`).

## 4. Confirmation of enrollment type (BYO vs corporate/ADE)

- **Description:** Whether this device is **personally-owned** (BYO Company Portal enrollment) or
  **corporate / Automated Device Enrollment (ADE)** via Apple Business Manager.
- **Why required:** The relevant enrollment restriction differs (personal-device block vs ADE profile
  assignment), and corporate devices add an ABM check.
- **How to verify:** Ask how the device is intended to be managed; check ABM if corporate.
- **How to implement if missing:** Confirm the enrollment type before choosing the remediation path.

## 5. Ability to reproduce and retry on the device

- **Description:** Access to the affected iOS/iPadOS device (or a test device with the same user) to
  remove the management profile and retry enrollment after the fix.
- **Why required:** Validation is a successful re-enrollment plus a successful sign-in in the logs.
- **How to verify:** You can reach the device or a test account.
- **How to implement if missing:** Arrange a test device/account for validation.

## 6. Change approval for MDM scope / restriction / CA changes

- **Description:** Approved change record before editing the MDM user scope, enrollment restrictions, or
  a Conditional Access policy.
- **Why required:** These affect enrollment tenant-wide; changes should be staged.
- **How to verify:** Change ticket approved with the identified gate named.
- **How to implement if missing:** Raise the change with the root-cause finding from this guide.

> **Category-wide prerequisites** common to every Intune solution are listed in
> `global-requirements-intune-solutions.md`. General iOS enrollment (ADE/ABM, Company Portal) and
> enrollment-time device grouping are covered by the companion Intune enrollment solutions.
