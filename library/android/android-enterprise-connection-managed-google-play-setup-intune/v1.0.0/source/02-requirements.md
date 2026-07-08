# 2. Requirements Guide — Android Enterprise Connection & Managed Google Play Setup

These are the **solution-specific** prerequisites for connecting Intune to managed Google Play and
standing up the four enrollment models. They **build on** the shared category requirements in
**`global-requirements-android.md`** (tenant + Intune, the binding model, least-privilege roles, enrollment
method decision + Graph toolchain, network reachability, and a pilot scope with change control) — read
those first; this guide does not repeat them, it adds what is specific to the **foundation** solution.

For each requirement: **Description** · **Why it's required** · **How to verify** · **How to implement if
missing**.

---

## 2.1 A deliberate binding-model decision: account enterprise (this solution) vs Google Workspace
- **Description:** A recorded decision that this tenant uses the **managed Google Play account enterprise**
  model (for organizations **without Google Workspace**), not the **Google Workspace / Cloud Identity ↔
  Intune third-party EMM** model. See category requirement 2.
- **Why it's required:** The two binding models are **mutually exclusive** and configured differently.
  This solution builds **account enterprise**; if the organization uses Google Workspace, the Workspace ↔
  Intune EMM solution is the correct product instead.
- **How to verify:** Confirm whether the organization uses **Google Workspace / Cloud Identity**. In the
  Intune admin center → **Devices > Android > Android enterprise** (or **Enrollment**), confirm no
  conflicting connection already exists.
- **How to implement if missing:** Decide with the identity owner. If **no Google Workspace** → proceed
  here. If **Google Workspace** → stop and use the Workspace integration solution.

## 2.2 A managed Google Play account owner (an organizational identity, not a personal Gmail)
- **Description:** When you connect Intune to managed Google Play (account enterprise), Google asks you to
  **sign in with a Google account** that becomes the **owner** of the managed Google Play enterprise. Use
  an **organization-controlled account** (e.g. a shared/service identity the organization owns), **never a
  personal Gmail** and never a personal admin's account.
- **Why it's required:** The owning account is durable and tied to the enterprise binding; a personal or
  individual account creates a bus-factor and lifecycle risk for the whole Android estate.
- **How to verify:** Confirm a suitable organization-owned Google account exists and its credentials are
  held by the organization (record the account identity — reuse it; do not store its password in code or
  docs).
- **How to implement if missing:** Create/designate an organization-owned Google account for this purpose
  before starting the connection step. *(The exact managed Google Play sign-in screen is Google-hosted and
  deferred to Google's documentation.)*

## 2.3 Global Administrator for the initial binding; Intune Administrator thereafter
- **Description:** The **initial** managed Google Play connection typically requires **Global
  Administrator** (it establishes a tenant-wide binding and consents on Google's side). Ongoing enrollment
  restriction and enrollment-profile work is done as **Intune Administrator** (least privilege). See
  category requirement 3.
- **Why it's required:** The binding is a tenant-level trust; day-to-day profile/restriction changes are
  not and should run under the least-privilege role.
- **How to verify:** Confirm role assignments in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin perform the one-time binding under change control,
  then use Intune Administrator for the rest.

## 2.4 Enrollment restrictions planned per model (what may enrol, and how)
- **Description:** A plan for the **enrollment platform restrictions** that decide, for Android, which
  Android Enterprise models are **allowed** (personally-owned work profile / corporate-owned device
  owner) and whether **personally owned** devices may enrol at all. This is the control that makes BYOD
  work profile possible (or blocks it) and that keeps unwanted models out.
- **Why it's required:** Enrollment restrictions are enforced **at enrollment time**; getting them wrong
  either blocks the model you want or lets in a model you do not. In particular, **personally-owned work
  profile (BYOD) has no device-side profile** — it is enabled purely by the restriction.
- **How to verify:** Intune → **Devices > Enrollment > Enrollment restrictions** (Device platform
  restrictions) → review the **Android Enterprise (work profile)** and **Android (device administrator)**
  settings; assess with **`ANDROIDENT-Discovery.ps1`**.
- **How to implement if missing:** Decide the allowed models per audience and configure with
  **`ANDROIDENT-Set-EnrollmentRestrictions.ps1`** (default `-WhatIf`).

## 2.5 A device supply appropriate to each corporate-owned model
- **Description:** For **fully managed**, **corporate-owned work profile**, and **dedicated/COSU**, the
  devices must be **company-owned** and **factory-reset** (or new) so they can enrol at first-run with an
  enrollment token / QR code (or zero-touch / Google account, per your chosen enrollment method). BYOD
  devices are user-owned and enrol from Company Portal.
- **Why it's required:** Corporate-owned enrollment happens during **out-of-box / setup**; a device that
  is already set up personally cannot become fully managed without a reset.
- **How to verify:** Confirm the pilot devices for each corporate-owned model are company-owned and can be
  reset; confirm one BYOD test phone is available.
- **How to implement if missing:** Source/reset company devices for the corporate-owned pilots; identify a
  BYOD test phone.

## 2.6 Managed Google Play app sync and endpoint reachability
- **Description:** After binding, Intune **syncs the app catalog** from managed Google Play, and devices
  must reach the **Google (managed Google Play, Android)** and **Microsoft (Intune, Entra)** endpoints to
  add the managed Google account and enrol. See category requirement 5.
- **Why it's required:** A blocked endpoint is the most common cause of "can't add a Google account" and
  stalled app sync during enrollment.
- **How to verify:** Confirm the connection reports a recent successful **app sync**
  (`ANDROIDENT-Discovery.ps1` surfaces last-sync status); confirm the required endpoints are allowed on
  the device network.
- **How to implement if missing:** Allow the documented Google/Microsoft endpoints; trigger a sync and
  confirm it succeeds before enrolling.

## 2.7 Microsoft Graph PowerShell for the provided automation
- **Description:** A workstation with the **Microsoft Graph PowerShell SDK** (PowerShell 5.1+ or 7+) to run
  this solution's five scripts. See category requirement 4.
- **Why it's required:** Assessment, configuration (safe-by-default), validation, and reporting are
  delivered as Graph PowerShell.
- **How to verify:** `Connect-MgGraph` succeeds with the read scopes; `Get-Module -ListAvailable
  Microsoft.Graph.Authentication` returns a version.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Never store
  credentials or secrets in scripts — the scripts use interactive delegated sign-in.

---

> **Requirement-to-script map.** `ANDROIDENT-Discovery.ps1` (2.1, 2.4, 2.6 — read-only assessment) ·
> `ANDROIDENT-Set-ScopeTargeting.ps1` (2.4, pilot scope groups) ·
> `ANDROIDENT-Set-EnrollmentRestrictions.ps1` (2.4 — `-WhatIf`) ·
> `ANDROIDENT-New-EnrollmentProfile.ps1` (2.5 — `-WhatIf`) · `ANDROIDENT-Report.ps1` (readiness +
> per-model enrollment coverage). The **managed Google Play sign-in** (2.2) is Google-hosted and completed
> in the Intune connection flow — deferred to Google's documentation.
