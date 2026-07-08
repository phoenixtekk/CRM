# 2. Requirements Guide — Android Enterprise Enrollment Troubleshooting

These are the prerequisites **specific to running this diagnostic playbook**. They sit on top of the
**Global Requirements (Android)** published once for the whole category — a Microsoft 365 tenant with
Intune and Android Enterprise, the managed Google Play binding (account enterprise OR Google Workspace),
least-privilege Intune admin roles, a decided enrollment method with Graph PowerShell, network reachability
to Google/Microsoft endpoints, and a pilot scope with change control. Verify those first; this guide adds
what a troubleshooting engagement needs beyond them, each with **how to verify** and **how to implement if
missing**.

> **Scope note.** This solution assumes the binding and enrollment program already exist and are *failing* —
> it diagnoses and repairs them. If the managed Google Play connection has never been created, stand it up
> with the connection solution first, then return here to troubleshoot.

## R1. A reproducible test device you can wipe and re-enroll
- **Description:** A dedicated **`Repro Device – Android – Test`** — a physical or supported virtual Android
  device you are free to **factory reset and re-enroll repeatedly** — matching the OEM, OS version, and
  enrollment method of the failing fleet as closely as possible.
- **Why required:** The method is Reproduce → Isolate → Resolve. You cannot isolate a fault you cannot
  reproduce on demand, and you must not test fixes on a user's production device.
- **How to verify:** Confirm you have a device you can wipe, its OS build number, and whether it has Google
  Mobile Services (GMS). Confirm it matches the failing population's OEM/OS/method.
- **How to implement if missing:** Obtain a representative device (borrow one from the affected population if
  possible), record its build, and confirm GMS presence. For non-GMS/China-market hardware, note it — the
  account-add flow differs.

## R2. Visibility into the device enrollment network (proxy, firewall, TLS inspection)
- **Description:** Knowledge of, and read visibility into, the **network path the device enrolls on** — the
  proxy/firewall in front of it and whether **TLS/SSL inspection** is applied to Google/Microsoft hosts.
- **Why required:** Blocked endpoints and TLS interception of Google hosts are among the most common
  "can't add a Google account" and stalled-enrollment root causes; you must be able to test reachability from
  the same network the device uses and to identify inspection rules.
- **How to verify:** Run `ANDROIDDX-EndpointReachability.ps1` from the device's network segment; confirm you
  know who owns the proxy/firewall and can request an allowlist/exemption change.
- **How to implement if missing:** Establish a contact for the network team and a path to test from the
  device network (or on the device's Wi-Fi). Obtain the current proxy config and TLS-inspection policy.

## R3. The tenant's binding model identified (account enterprise vs Google Workspace)
- **Description:** A clear statement of **which of the two mutually exclusive managed Google Play models** the
  tenant uses: **managed Google Play account enterprise** (no Google Workspace) or **Google Workspace /
  Cloud Identity ↔ Intune third-party EMM**.
- **Why required:** The two models fail — and are repaired — differently; the account-add flow and the
  binding-owner account differ. Diagnosing the wrong model wastes the session.
- **How to verify:** Intune admin center → **Devices > Android > Android enterprise** (Connection/Enrollment)
  — read the connection and owner account; `ANDROIDDX-BindingHealth.ps1` reports `OwnerUserPrincipalName` and
  `BindStatus`.
- **How to implement if missing:** Confirm with the tenant whether Google Workspace is in use; record the
  model in `Binding Health – Android – Baseline`. Do **not** switch models to troubleshoot — that is a
  high-impact change under change control.

## R4. Read scopes for the diagnostic tools (least privilege)
- **Description:** The **read-only Microsoft Graph scopes** the tools need:
  `DeviceManagementServiceConfig.Read.All`, `DeviceManagementConfiguration.Read.All`,
  `DeviceManagementManagedDevices.Read.All`; plus `Group.ReadWrite.All` and `User.Read.All` **only** for the
  scope-group helper.
- **Why required:** Discovery, binding-health, and diagnostic-report tools read binding/enrollment/device
  state; only the scope helper writes (group membership), and it is `-WhatIf`-gated.
- **How to verify:** `Connect-MgGraph` succeeds with the read scopes; `ANDROIDDX-EnrollmentReadiness.ps1`
  runs without a permissions error.
- **How to implement if missing:** Have an admin consent the read scopes for the account running the tools.
  Grant the group-write scope only when you run the scope helper.

## R5. Access to a comparable dev tenant/config for dev-vs-prod isolation (when that is the symptom)
- **Description:** When the reported symptom is **"works in dev, fails in prod,"** access to the **working dev
  tenant's configuration** (or an exported snapshot of it) to diff against prod.
- **Why required:** The dev-vs-prod node isolates by **diffing** the two configurations; without the working
  reference you cannot see the drift.
- **How to verify:** You can export a config snapshot from both tenants with `ANDROIDDX-DiagnosticReport.ps1
  -JsonPath` and diff them with `ANDROIDDX-EndpointReachability.ps1 -CompareConfig`.
- **How to implement if missing:** Obtain read access (or a snapshot export) from whoever owns the dev tenant.
  If prod is the only environment, isolate against the documented expected configuration instead.

## R6. A change window and rollback plan for high-impact repairs
- **Description:** An approved **change window** and a written **rollback** for any repair that touches the
  **binding, the connector, an enrollment profile/token, or an AMAPI-related setting** — because these are
  high-impact and may affect **existing** enrolled devices.
- **Why required:** Re-establishing a binding, regenerating a token, or an AMAPI-related change can affect
  more than the one device under test; the pilot-first model and a rollback protect the fleet. Whether such a
  change forces **re-enrollment** is version-dependent — **verify against current Microsoft guidance / your
  tenant** before committing.
- **How to verify:** A named approver, a change window, and a documented rollback exist before any fleet-wide
  or connector-level change.
- **How to implement if missing:** Agree change control and write the rollback (e.g. how to restore the prior
  enrollment profile / binding state) before you apply anything beyond the reproduction device.

## Requirements summary
| # | Requirement | Verify | Implement if missing |
|---|---|---|---|
| R1 | Reproducible wipe-and-retry test device | Device you can factory reset; OS build & GMS known; matches fleet | Obtain a representative device; record build/GMS |
| R2 | Device-network visibility (proxy/TLS) | Reachability test runs from device network; proxy/TLS owner known | Get network-team contact and current proxy/TLS policy |
| R3 | Binding model identified | Intune Android enterprise page / `BindingHealth` owner & status | Confirm Workspace use; record model; don't switch to troubleshoot |
| R4 | Least-privilege read scopes | `Connect-MgGraph` + readiness tool run clean | Admin-consent the read scopes; group-write only for scope helper |
| R5 | Dev config/snapshot for dev-vs-prod | Snapshot export + `-CompareConfig` diff possible | Obtain dev read access/snapshot, or diff vs expected config |
| R6 | Change window + rollback for high-impact repairs | Named approver, window, written rollback | Agree change control; write rollback before connector/AMAPI change |
